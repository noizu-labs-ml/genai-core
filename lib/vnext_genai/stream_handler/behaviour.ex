defmodule GenAI.StreamHandler do

  # ⟦𓉆𓀠𓀲𓎫⟧ begin_stream :: auto-generated pointer for public function begin_stream
  def begin_stream(handler, session, context, options) when is_atom(handler) do
    handler.begin_stream(handler, session, context, options)
  end
  def begin_stream(%{__struct__: h} = handler, session, context, options) do
    h.begin_stream(handler, session, context, options)
  end

  # ⟦𓂄𓏏𓇋𓈐𓎯⟧ normalize_finish :: Shared stop-reason normalization for stream decoders.
  def normalize_finish("stop"), do: :stop
  def normalize_finish("end_turn"), do: :stop
  def normalize_finish("stop_sequence"), do: :stop
  def normalize_finish("length"), do: :max_tokens
  def normalize_finish("max_tokens"), do: :max_tokens
  def normalize_finish("tool_calls"), do: :tool_call
  def normalize_finish("tool_use"), do: :tool_call
  def normalize_finish("function_call"), do: :tool_call
  def normalize_finish("content_filter"), do: :content_filter
  def normalize_finish(reason) when is_atom(reason), do: reason
  def normalize_finish(reason) when is_binary(reason), do: String.to_atom(reason)

end

defmodule GenAI.StreamHandler.Behaviour do
  @callback begin_stream(handler :: term, session :: term, context :: term, options :: term) :: {:ok, {{state :: term, handler :: term}, session :: term}} | {:error, reason :: term}
  @callback handle_event(event :: term, state :: term) :: {:cont, state :: term} | {:halt, state :: term}
end

defmodule GenAI.StreamHandler.Default do
  @behaviour GenAI.StreamHandler.Behaviour

  defmodule Accumulator do
    defstruct [
      headers: nil,
      status: nil,
      chunks: [],
      buffer: "",
      completed: false,
      error: nil,
      trailers: nil,
      # Streaming decode state (populated when a stream decoder is registered)
      decoder: nil,
      sink: nil,
      sse_buffer: "",
      events: [],
      text: "",
      thinking: "",
      tool_calls: [],
      usage: nil,
      finish: nil,
      model: nil,
      provider: nil,
      completion: nil
    ]
  end

  @doc """
  Initialize streaming with default handler that returns handle_event callback.

  Options injected by the provider stream path:

    - `:stream_decoder` — module decoding provider SSE frames (e.g.
      `GenAI.StreamHandler.OpenAI`); when nil the handler only raw-accumulates
    - `:stream_sink` — pid or 1-arity fun forwarded each decoded event as
      `{:genai, event}` / `event`
    - `:stream_model` / `:stream_provider` — stamped onto the final completion
  """
  def begin_stream(_handler, session, _context, options) do
    options = options || []

    # Initialize state for collecting stream chunks
    initial_state = %Accumulator{
      decoder: options[:stream_decoder],
      sink: options[:stream_sink],
      model: options[:stream_model],
      provider: options[:stream_provider]
    }

    # Return initial state and callback function reference
    {:ok, {{initial_state, &__MODULE__.handle_event/2}, session}}
  end

  @doc """
  Handle streaming events from Finch.stream_while
  Processes status, headers, data chunks, and trailers
  """
  # ⟦𓆬𓐓𓋧𓍧⟧ handle_event :: Handle streaming events from Finch.stream_while
  def handle_event(event, state) do
    case event do
      {:status, status} ->
        # Store HTTP status
        {:cont, Map.put(state, :status, status)}

      {:headers, headers} ->
        # Store headers
        {:cont, Map.put(state, :headers, headers)}

      {:data, chunk} ->
        # Accumulate data chunks (and decode when a decoder is registered)
        updated_state = state
          |> Map.update(:chunks, [chunk], &(&1 ++ [chunk]))
          |> Map.update(:buffer, chunk, &(&1 <> chunk))
          |> decode_chunk(chunk)
        {:cont, updated_state}

      {:trailers, trailers} ->
        # Store trailers if any
        {:cont, Map.put(state, :trailers, trailers)}

      _ ->
        # Continue with current state for unknown events
        {:cont, state}
    end
  end

  # ⟦𓅓𓎝𓇏𓈌𓆏⟧ decode_chunk :: Parse SSE frames and fold decoded events into the accumulator.
  defp decode_chunk(state, _chunk) when is_nil(state.decoder), do: state

  defp decode_chunk(state, chunk) do
    {sse_events, sse_buffer} = GenAI.StreamHandler.SSE.feed(state.sse_buffer, chunk)
    state = %{state | sse_buffer: sse_buffer}

    Enum.reduce(sse_events, state, &reduce_sse_event/2)
  end

  defp reduce_sse_event(:done, state) do
    %{state | completed: true}
  end

  defp reduce_sse_event({:data, payload}, state) do
    case Jason.decode(payload, keys: :atoms) do
      {:ok, json} ->
        state.decoder.stream_event(json)
        |> Enum.reduce(state, &reduce_stream_event/2)
        |> rebuild_completion()

      _ ->
        state
    end
  end

  defp reduce_stream_event({:text, text}, state) do
    state
    |> forward({:text, text})
    |> append_event({:text, text})
    |> Map.update!(:text, &(&1 <> text))
  end

  defp reduce_stream_event({:thinking, thinking}, state) do
    state
    |> forward({:thinking, thinking})
    |> append_event({:thinking, thinking})
    |> Map.update!(:thinking, &(&1 <> thinking))
  end

  defp reduce_stream_event({:tool_call, tool_call}, state) do
    state
    |> forward({:tool_call, tool_call})
    |> append_event({:tool_call, tool_call})
    |> Map.update!(:tool_calls, &(&1 ++ [tool_call]))
  end

  defp reduce_stream_event({:usage, usage}, state) do
    merged =
      Map.merge(state.usage || %{}, usage, fn _, old, new -> new || old end)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    # providers that report prompt/completion separately (Anthropic) may update
    # them across events — keep total_tokens consistent whenever both are known
    merged =
      case {merged[:prompt_tokens], merged[:completion_tokens]} do
        {p, c} when is_integer(p) and is_integer(c) -> Map.put(merged, :total_tokens, p + c)
        _ -> merged
      end

    state
    |> forward({:usage, merged})
    |> append_event({:usage, merged})
    |> Map.put(:usage, merged)
  end

  defp reduce_stream_event({:finish, finish}, state) do
    state
    |> forward({:finish, finish})
    |> append_event({:finish, finish})
    |> Map.put(:finish, finish)
  end

  # ⟦𓋾𓎂𓇑𓏏𓆭⟧ append_event :: Track decoded events on the accumulator.
  defp append_event(state, event), do: %{state | events: state.events ++ [event]}

  # ⟦𓅡𓏎𓉢𓍪𓎔⟧ forward :: Push a decoded event to the sink (pid → message, fun → call).
  defp forward(state, event) do
    case state.sink do
      pid when is_pid(pid) ->
        send(pid, {:genai, event})
        state

      fun when is_function(fun, 1) ->
        fun.(event)
        state

      _ ->
        state
    end
  end

  # ⟦𓈁𓏏𓇋𓎲𓍣⟧ rebuild_completion :: Materialize the accumulated ChatCompletion.
  defp rebuild_completion(state) do
    %{state | completion: build_completion(state)}
  end

  defp build_completion(state) do
    empty? =
      state.text == "" and state.thinking == "" and state.tool_calls == [] and
        is_nil(state.usage) and is_nil(state.finish)

    if empty? do
      nil
    else
      choice = %GenAI.ChatCompletion.Choice{
        index: 0,
        message: GenAI.Message.assistant(state.text),
        finish_reason: state.finish
      }

      usage =
        case state.usage do
          nil ->
            nil

          u ->
            %GenAI.ChatCompletion.Usage{
              prompt_tokens: u[:prompt_tokens],
              completion_tokens: u[:completion_tokens],
              total_tokens: u[:total_tokens]
            }
        end

      GenAI.ChatCompletion.new(
        model: state.model,
        provider: state.provider,
        choices: [choice],
        usage: usage
      )
    end
  end
end

defmodule GenAI.StreamHandler.Accumulate do
  @moduledoc """
  Streaming handler that decodes provider SSE streams, forwards each
  normalized event live to a sink, and accumulates the final
  `GenAI.ChatCompletion` (available as `state.completion` when the stream
  ends).

  Use via:

      thread
      |> GenAI.with_stream_handler(%GenAI.StreamHandler.Accumulate{sink: self()})
      # ...
      {:ok, {acc, _session}} = GenAI.stream(thread, context)

      # in the sink process:
      #   handle_info({:genai, {:text, chunk}}, s) — one per content delta
      #   acc.completion — final %GenAI.ChatCompletion{}

  `sink` may be a pid (events delivered as `{:genai, event}` messages) or a
  1-arity fun (called with each event). Omit the sink to only accumulate.
  """
  @behaviour GenAI.StreamHandler.Behaviour

  defstruct [:sink]

  # ⟦𓉐𓎛𓇋𓏅𓆄⟧ begin_stream :: Delegate to Default with the sink injected.
  def begin_stream(handler, session, context, options) do
    options = Keyword.merge(options || [], stream_sink: handler.sink)
    GenAI.StreamHandler.Default.begin_stream(nil, session, context, options)
  end

  def handle_event(event, state) do
    GenAI.StreamHandler.Default.handle_event(event, state)
  end
end
