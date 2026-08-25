defmodule GenAI.ToolChain do
  @moduledoc """
  Explicit, bounded model/tool loop.

  This runner is opt-in: `GenAI.run/1-3` retains its existing single-inference
  semantics. A chain advertises registered tools, runs inference, executes any
  returned calls, appends normalized tool responses, and repeats until the model
  stops requesting tools or a bound is reached.

  The configurable limits are themselves capped (`64` iterations and `256`
  calls) so untrusted options cannot create an unbounded agent loop.
  """

  alias GenAI.Tool.{Call, Registry, Result, Telemetry}

  defmodule Summary do
    @moduledoc "Execution counters returned with a completed chain."
    defstruct iterations: 0, tool_calls: 0, tool_errors: 0, stop_reason: nil
  end

  @max_iterations 64
  @max_tool_calls 256
  @default_iterations 8
  @default_tool_calls 32

  @type result :: {:ok, {GenAI.ChatCompletion.t(), term(), Summary.t()}} | {:error, term()}

  @doc "Runs a thread through a bounded sequence of inference and tool calls."
  @spec run(term(), Registry.t(), term(), keyword()) :: result()
  def run(thread, registry, context, options \\ [])

  def run(thread, %Registry{} = registry, context, options) when is_list(options) do
    started = System.monotonic_time()
    limits = limits(options)
    thread = GenAI.with_tools(thread, Registry.tools(registry))
    summary = %Summary{}

    Telemetry.emit(
      [:tool_chain, :run, :start],
      %{system_time: System.system_time(), tool_count: length(Registry.tools(registry))},
      %{max_iterations: limits.iterations, max_tool_calls: limits.tool_calls},
      options
    )

    result = iterate(thread, registry, context, options, limits, summary)
    duration = System.monotonic_time() - started

    case result do
      {:ok, {_, _, final_summary}} ->
        Telemetry.emit(
          [:tool_chain, :run, :stop],
          %{
            duration: duration,
            iterations: final_summary.iterations,
            tool_calls: final_summary.tool_calls,
            tool_errors: final_summary.tool_errors
          },
          %{status: :ok, stop_reason: final_summary.stop_reason},
          options
        )

      {:error, reason} ->
        Telemetry.emit(
          [:tool_chain, :run, :stop],
          %{duration: duration},
          %{status: :error, reason: safe_reason(reason)},
          options
        )
    end

    result
  rescue
    exception ->
      Telemetry.emit(
        [:tool_chain, :run, :exception],
        %{duration: 0},
        %{status: :error, kind: :error, reason: exception.__struct__},
        options
      )

      {:error, {:chain_exception, exception}}
  catch
    kind, reason -> {:error, {:chain_exception, {kind, reason}}}
  end

  defp iterate(thread, registry, context, options, limits, summary) do
    if summary.iterations >= limits.iterations do
      {:error, {:chain_limit, :max_iterations, summary}}
    else
      with {:ok, {completion, updated_thread}} <- run_inference(thread, context, options),
           {:ok, calls} <- extract_calls(completion) do
        summary = %{summary | iterations: summary.iterations + 1}

        cond do
          calls == [] ->
            {:ok, {completion, updated_thread, %{summary | stop_reason: :complete}}}

          summary.tool_calls + length(calls) > limits.tool_calls ->
            {:error, {:chain_limit, :max_tool_calls, summary}}

          true ->
            assistant_messages = tool_usage_messages(completion)

            next_thread =
              if Keyword.get(options, :append_assistant_message, true),
                do: GenAI.with_messages(updated_thread, assistant_messages),
                else: updated_thread

            {next_thread, summary, halt_error} =
              Enum.reduce_while(calls, {next_thread, summary, nil}, fn call,
                                                                       {acc_thread, acc_summary,
                                                                        _} ->
                {outcome, result} = execute_call(registry, call, context, options)

                next_summary = %{
                  acc_summary
                  | tool_calls: acc_summary.tool_calls + 1,
                    tool_errors:
                      acc_summary.tool_errors + if(result.status == :error, do: 1, else: 0)
                }

                next_thread = GenAI.with_message(acc_thread, Result.to_message(result))

                if outcome == :error and Keyword.get(options, :on_tool_error, :continue) == :halt do
                  {:halt, {next_thread, next_summary, {:tool_error, result}}}
                else
                  {:cont, {next_thread, next_summary, nil}}
                end
              end)

            if halt_error,
              do: {:error, halt_error},
              else: iterate(next_thread, registry, context, options, limits, summary)
        end
      end
    end
  end

  defp run_inference(thread, context, options) do
    run_options = Keyword.get(options, :run_options, [])

    case Keyword.get(options, :run) do
      nil -> GenAI.run(thread, context, run_options)
      function when is_function(function, 3) -> function.(thread, context, run_options)
      function when is_function(function, 2) -> function.(thread, context)
      _ -> {:error, :invalid_run_function}
    end
  end

  defp extract_calls(%GenAI.ChatCompletion{choices: choices}) when is_list(choices) do
    choices
    |> Enum.flat_map(fn
      %{message: %GenAI.Message.ToolUsage{tool_calls: calls}} when is_list(calls) -> calls
      %{message: %{tool_calls: calls}} when is_list(calls) -> calls
      _ -> []
    end)
    |> Enum.reduce_while({:ok, []}, fn call, {:ok, acc} ->
      case Call.normalize(call) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, reason} -> {:halt, {:error, {:invalid_tool_call, reason}}}
      end
    end)
    |> case do
      {:ok, calls} -> {:ok, Enum.reverse(calls)}
      error -> error
    end
  end

  defp extract_calls(_), do: {:error, :invalid_chat_completion}

  defp tool_usage_messages(%GenAI.ChatCompletion{choices: choices}) do
    Enum.flat_map(choices || [], fn
      %{message: %GenAI.Message.ToolUsage{} = message} -> [message]
      _ -> []
    end)
  end

  defp execute_call(registry, call, context, options) do
    case Registry.execute(registry, call, context, options) do
      {:ok, result} ->
        {:ok, result}

      {:error, %Result{} = result} ->
        {:error, result}

      {:error, reason} ->
        {:error,
         %Result{
           call_id: call.id,
           name: call.name,
           status: :error,
           error: reason
         }}
    end
  end

  defp limits(options) do
    %{
      iterations:
        options |> Keyword.get(:max_iterations, @default_iterations) |> clamp(1, @max_iterations),
      tool_calls:
        options |> Keyword.get(:max_tool_calls, @default_tool_calls) |> clamp(1, @max_tool_calls)
    }
  end

  defp clamp(value, min, max) when is_integer(value),
    do: value |> Kernel.max(min) |> Kernel.min(max)

  defp clamp(_, min, _), do: min

  defp safe_reason(reason) when is_atom(reason) or is_binary(reason) or is_number(reason),
    do: reason

  defp safe_reason(reason) when is_tuple(reason), do: elem(reason, 0)
  defp safe_reason(_), do: :error
end
