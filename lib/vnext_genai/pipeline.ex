defmodule GenAI.Pipeline do
  @moduledoc """
  Explicit immutable conversation processing. Extraction pushes typed values onto a
  branch-local stack; classification consumes payload and criteria. Transformations
  invalidate existing frames. Forks are `GenAI.Thread.Fork` thread values and every join must
  specify `:reduce`, `:select` or `:append`.

  Operations accept a thread, pipeline, or `{:ok, pipeline}` and return tagged
  results, so ordinary Elixir pipes preserve failures without additional inference.
  """
  alias GenAI.Pipeline.{Branch, Frame, Selector, Snapshot}
  alias GenAI.Thread.Fork
  defstruct [:thread, frames: [], context: nil, options: [], artifacts: %{}]

  @type t :: %__MODULE__{
          thread: term(),
          frames: [Frame.t()],
          context: term(),
          options: keyword(),
          artifacts: map()
        }

  @doc "Constructs a pipeline and resolves pending graph nodes without inference."
  def new(thread, options \\ [])
  def new(%Fork{} = fork, _options), do: Fork.normalize(fork)
  def new({:fork, _} = legacy, _options), do: Fork.normalize(legacy)

  def new(thread, options) do
    context = Keyword.get(options, :context, Noizu.Context.system())

    with {:ok, thread} <- Snapshot.materialize(thread, context, options) do
      {:ok, %__MODULE__{thread: thread, context: context, options: options}}
    end
  end

  @doc "Extracts a value using last-message, callback/MFA, or a safe selector."
  def extract(input, selector, options \\ [])

  def extract({:ok, {:fork, _} = legacy}, selector, options),
    do: extract(legacy, selector, options)

  def extract({:fork, _} = legacy, selector, options) do
    with {:ok, fork} <- Fork.normalize(legacy), do: extract(fork, selector, options)
  end

  def extract({:ok, %Fork{} = fork}, selector, options), do: extract(fork, selector, options)

  def extract(%Fork{} = fork, selector, options),
    do: broadcast(fork, &extract(&1, selector, options), options)

  def extract(input, selector, options) do
    with {:ok, pipeline} <- coerce(input),
         {:ok, pipeline} <- refresh(pipeline),
         {:ok, value} <-
           extract_value(pipeline, selector, options) do
      kind = Keyword.get(options, :kind, :payload)

      if kind == :both and is_map(value) and Map.has_key?(value, :payload) and
           Map.has_key?(value, :criteria) do
        revision = Snapshot.revision(pipeline.thread)

        frames = [
          %Frame{kind: :criteria, value: value.criteria, revision: revision, source: selector},
          %Frame{kind: :payload, value: value.payload, revision: revision, source: selector}
        ]

        {:ok, %{pipeline | frames: frames ++ pipeline.frames}}
      else
        if kind in [:payload, :criteria, :result] do
          frame = %Frame{
            kind: kind,
            value: value,
            revision: Snapshot.revision(pipeline.thread),
            source: selector
          }

          {:ok, %{pipeline | frames: [frame | pipeline.frames]}}
        else
          {:error, :invalid_frame_kind}
        end
      end
    end
  end

  @doc "Walks messages in an explicit direction and collects selector results."
  def aggregate(input, selector, options \\ []) do
    extract(input, {:aggregate, selector}, options)
  end

  @doc "Consumes the latest payload/criteria frames; classifier defaults are separate from chat defaults."
  def classify(input, options \\ [])
  def classify({:ok, {:fork, _} = legacy}, options), do: classify(legacy, options)

  def classify({:fork, _} = legacy, options) do
    with {:ok, fork} <- Fork.normalize(legacy), do: classify(fork, options)
  end

  def classify({:ok, %Fork{} = fork}, options), do: classify(fork, options)
  def classify(%Fork{} = fork, options), do: broadcast(fork, &classify(&1, options), options)

  def classify(input, options) do
    with {:ok, pipeline} <- coerce(input),
         {:ok, pipeline} <- refresh(pipeline),
         :ok <- fresh_frames(pipeline),
         {:ok, payload} <- payload_frame(pipeline),
         {:ok, questions} <- criteria(pipeline, options),
         request = %GenAI.Classifier.Request{
           input: payload.value,
           questions: questions,
           model: options[:model],
           provider: options[:provider],
           options: Keyword.get(options, :classifier_options, [])
         },
         {:ok, result} <- GenAI.classify(request, options) do
      remaining = consume_frames(pipeline.frames, [:payload, :criteria])

      frame = %Frame{
        kind: :result,
        value: result,
        source: :classifier,
        revision: Snapshot.revision(pipeline.thread)
      }

      {:ok, %{pipeline | frames: [frame | remaining]}}
    else
      nil -> {:error, :missing_payload}
      false -> {:error, :missing_criteria}
      [] -> {:error, :missing_criteria}
      {:error, _} = error -> error
      _ -> {:error, :invalid_classifier_frames}
    end
  end

  @doc "Replaces the continuing thread and invalidates all extraction frames."
  def transform(input, callback, options \\ [])

  def transform({:ok, {:fork, _} = legacy}, callback, options),
    do: transform(legacy, callback, options)

  def transform({:fork, _} = legacy, callback, options) do
    with {:ok, fork} <- Fork.normalize(legacy), do: transform(fork, callback, options)
  end

  def transform({:ok, %Fork{} = fork}, callback, options),
    do: transform(fork, callback, options)

  def transform(%Fork{} = fork, callback, options),
    do: broadcast(fork, &transform(&1, callback, options), options)

  def transform(input, callback, options) do
    with {:ok, pipeline} <- coerce(input),
         {:ok, thread} <- Selector.invoke(fn -> callback.(pipeline.thread, options) end),
         {:ok, thread} <- Snapshot.materialize(thread, pipeline.context, pipeline.options) do
      {:ok, %{pipeline | thread: thread, frames: []}}
    end
  end

  @doc "Appends a correlated assistant tool call and tool response; optional final text/JSON is deterministic."
  def append_result(input, options \\ [])
  def append_result({:ok, {:fork, _} = legacy}, options), do: append_result(legacy, options)

  def append_result({:fork, _} = legacy, options) do
    with {:ok, fork} <- Fork.normalize(legacy), do: append_result(fork, options)
  end

  def append_result({:ok, %Fork{} = fork}, options), do: append_result(fork, options)

  def append_result(%Fork{} = fork, options),
    do: broadcast(fork, &append_result(&1, options), options)

  def append_result(input, options) do
    with {:ok, pipeline} <- coerce(input),
         {:ok, pipeline} <- refresh(pipeline),
         :ok <- fresh_frames(pipeline),
         [%Frame{} = frame | rest] <- pipeline.frames,
         {:ok, value} <- serializable(frame.value) do
      id = UUID.uuid4()
      name = Keyword.get(options, :name, "pipeline_result")
      call = %GenAI.Message.ToolCall{id: id, tool_name: name, arguments: %{kind: frame.kind}}
      usage = GenAI.Message.ToolUsage.new(role: :assistant, content: nil, tool_calls: [call])

      response =
        GenAI.Message.ToolResponse.new(tool_call_id: id, tool_name: name, tool_response: value)

      thread = GenAI.with_messages(pipeline.thread, [usage, response])

      case Keyword.get(options, :final, false) do
        false ->
          {:ok, %{pipeline | thread: thread, frames: rest}}

        :json ->
          {:ok,
           %{
             pipeline
             | thread: GenAI.with_message(thread, GenAI.Message.assistant(Jason.encode!(value))),
               frames: rest
           }}

        :text ->
          rendered = if is_binary(value), do: value, else: Jason.encode!(value)

          {:ok,
           %{
             pipeline
             | thread: GenAI.with_message(thread, GenAI.Message.assistant(rendered)),
               frames: rest
           }}

        _ ->
          {:error, :invalid_final_representation}
      end
    else
      [] -> {:error, :empty_stack}
      {:error, _} = error -> error
    end
  end

  @doc "Forks into named isolated pipelines. Nested forks are explicit; joins reject uncollapsed nested results."
  def fork(input, branches, options \\ [])
  def fork({:ok, input}, branches, options), do: fork(input, branches, options)

  def fork(%Fork{} = input, branches, options),
    do: broadcast(input, fn pipeline -> fork(pipeline, branches, options) end, options)

  def fork(input, branches, options) do
    with {:ok, pipeline} <- coerce(input), {:ok, pipeline} <- refresh(pipeline) do
      entries = Enum.to_list(branches)
      ids = Enum.map(entries, fn {id, _} -> id end)

      cond do
        entries == [] ->
          {:error, :empty_fork}

        length(entries) > 64 ->
          {:error, :fork_limit}

        length(Enum.uniq(ids)) != length(ids) ->
          {:error, :duplicate_branch_id}

        true ->
          seeds =
            Enum.map(entries, fn {id, callback} ->
              {%Branch{id: id, base: pipeline.thread, pipeline: pipeline}, callback}
            end)

          parallel(
            seeds,
            fn {branch, callback} ->
              case Selector.invoke(fn -> callback.(branch.pipeline) end) do
                {:ok, %Fork{} = nested} ->
                  %{branch | pipeline: nested}

                {:ok, value} ->
                  case coerce(value) do
                    {:ok, value} -> %{branch | pipeline: value}
                    {:error, reason} -> %{branch | error: reason}
                  end

                {:error, reason} ->
                  %{branch | error: reason}
              end
            end,
            options
          )
      end
    end
  end

  @doc "Copies a pipeline with stable 0-based branch identities."
  def split(input, count, options \\ []) do
    if is_integer(count) and count in 1..64 do
      fork(input, Enum.map(0..(count - 1), &{&1, fn p -> p end}), options)
    else
      {:error, :invalid_split_count}
    end
  end

  @doc "Runs one inference per branch (bounded parallelism) and appends its first assistant choice once."
  def next_turn(input, options \\ [])
  def next_turn({:ok, {:fork, _} = legacy}, options), do: next_turn(legacy, options)

  def next_turn({:fork, _} = legacy, options) do
    with {:ok, fork} <- Fork.normalize(legacy), do: next_turn(fork, options)
  end

  def next_turn({:ok, input}, options), do: next_turn(input, options)
  def next_turn({:error, _} = error, _options), do: error

  def next_turn(%Fork{} = fork, options), do: broadcast(fork, &next_turn(&1, options), options)

  def next_turn(input, options) do
    with {:ok, pipeline} <- coerce(input),
         {:ok, pipeline} <- refresh(pipeline),
         {:ok, {completion, thread}} <- run_turn(pipeline, options),
         %{choices: [%{message: message} | _]} <- completion,
         {:ok, thread} <- Snapshot.materialize(thread, pipeline.context, pipeline.options) do
      delta = Enum.drop(Snapshot.messages(thread), length(Snapshot.messages(pipeline.thread)))
      already_present = Enum.any?(delta, &same_message?(&1, message))
      thread = if already_present, do: thread, else: GenAI.with_message(thread, message)

      {:ok,
       %{
         pipeline
         | thread: thread,
           frames: [],
           artifacts: Map.put(pipeline.artifacts, :completion, completion)
       }}
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_chat_completion}
    end
  end

  @doc "Joins with an explicit :reduce, :select, or :append mode; failed branches prevent convergence."
  def join(input, options \\ [])
  def join({:ok, {:fork, _} = legacy}, options), do: join(legacy, options)

  def join({:fork, _} = legacy, options) do
    with {:ok, fork} <- Fork.normalize(legacy), do: join(fork, options)
  end

  def join({:ok, input}, options), do: join(input, options)
  def join({:error, _} = error, _options), do: error

  def join(%Fork{branches: branches}, options) when is_list(branches) do
    with {:ok, branches} <- normalize_branches(branches) do
      cond do
        options[:mode] not in [:reduce, :select, :append] ->
          {:error, :explicit_join_mode_required}

        branches == [] ->
          {:error, :empty_fork}

        Enum.any?(branches, & &1.error) ->
          {:error, {:branch_failures, branches}}

        Enum.any?(branches, &match?(%Fork{}, &1.pipeline)) ->
          {:error, :nested_join_required}

        true ->
          join_branches(branches, options)
      end
    end
  end

  def join(_, _), do: {:error, :invalid_fork}

  defp join_branches(branches, options) do
    refreshed =
      Enum.map(branches, fn branch ->
        case refresh(branch.pipeline) do
          {:ok, p} -> %{branch | pipeline: p}
          {:error, reason} -> %{branch | error: reason}
        end
      end)

    base = hd(refreshed).base
    prefix = Snapshot.messages(base)

    compatible =
      Enum.all?(refreshed, fn branch ->
        is_nil(branch.error) and
          (options[:mode] == :select or
             (Snapshot.messages(branch.base) == prefix and
                List.starts_with?(Snapshot.messages(branch.pipeline.thread), prefix)))
      end)

    if compatible do
      case options[:mode] do
        :select ->
          select_branch(refreshed, options)

        :reduce ->
          case options[:reducer] do
            fun when is_function(fun, 1) ->
              with {:ok, value} <- Selector.invoke(fn -> fun.(refreshed) end) do
                p = %{hd(refreshed).pipeline | thread: base, frames: []}

                frame = %Frame{
                  kind: :result,
                  value: value,
                  source: :join,
                  revision: Snapshot.revision(base)
                }

                {:ok, %{p | frames: [frame]}}
              end

            _ ->
              {:error, :missing_join_reducer}
          end

        :append ->
          tagged_deltas =
            Enum.flat_map(
              refreshed,
              fn branch ->
                Enum.map(
                  Enum.drop(Snapshot.messages(branch.pipeline.thread), length(prefix)),
                  &{branch.id, &1}
                )
              end
            )

          with :ok <- unique_delta_ids(tagged_deltas, prefix) do
            deltas = Enum.map(tagged_deltas, &elem(&1, 1))

            {:ok,
             %{hd(refreshed).pipeline | thread: GenAI.with_messages(base, deltas), frames: []}}
          end
      end
    else
      {:error, :incompatible_branch_prefix}
    end
  end

  defp select_branch(branches, options) do
    selection =
      case options[:selector] do
        fun when is_function(fun, 1) ->
          Selector.invoke(fn -> fun.(branches) end)

        {:classifier, classifier_options} ->
          choices = Enum.map(branches, &%{id: to_string(&1.id), label: to_string(&1.id)})

          request = %GenAI.Classifier.Request{
            input:
              Enum.map(
                branches,
                &%{
                  id: to_string(&1.id),
                  messages:
                    Enum.map(Snapshot.messages(&1.pipeline.thread), fn m ->
                      Selector.content(m)
                    end)
                }
              ),
            questions: [
              %GenAI.Classifier.Question{
                id: "branch",
                type: :choice,
                choices: choices,
                instructions:
                  Keyword.get(
                    classifier_options,
                    :instructions,
                    "Choose the best branch to continue the conversation."
                  )
              }
            ],
            model: classifier_options[:model],
            provider: classifier_options[:provider]
          }

          with {:ok, result} <- GenAI.classify(request, classifier_options),
               [answer] <- result.answers do
            selected =
              if is_nil(answer.choice_id) and is_integer(answer.index),
                do: Enum.at(branches, answer.index),
                else: Enum.find(branches, &(to_string(&1.id) == answer.choice_id))

            {:ok, if(selected, do: {:selected, selected.id})}
          end

        nil ->
          {:ok, options[:branch]}

        _ ->
          {:error, :invalid_join_selector}
      end

    with {:ok, id} <- selection do
      id =
        case id do
          {:selected, value} -> value
          value -> value
        end

      case Enum.find(branches, &(&1.id == id)) do
        nil -> {:error, :unknown_branch}
        branch -> {:ok, branch.pipeline}
      end
    end
  end

  defp run_turn(pipeline, options) do
    run_options = Keyword.get(options, :run_options, [])

    callback =
      case options[:run] do
        nil ->
          fn -> GenAI.run(pipeline.thread, pipeline.context, run_options) end

        fun when is_function(fun, 3) ->
          fn -> fun.(pipeline.thread, pipeline.context, run_options) end

        _ ->
          fn -> {:error, :invalid_run_function} end
      end

    timeout = Keyword.get(options, :timeout, 30_000)

    if is_integer(timeout) and timeout in 1..300_000 do
      {:ok, supervisor} = Task.Supervisor.start_link()

      try do
        task = Task.Supervisor.async_nolink(supervisor, fn -> Selector.invoke(callback) end)

        case Task.yield(task, timeout) do
          {:ok, value} ->
            value

          {:exit, reason} ->
            {:error, {:run_exit, reason}}

          nil ->
            Task.shutdown(task, :brutal_kill)
            {:error, :timeout}
        end
      after
        Supervisor.stop(supervisor)
      end
    else
      {:error, :invalid_parallel_limits}
    end
  end

  @doc false
  def run_inference(input, options \\ []) do
    with {:ok, pipeline} <- coerce(input),
         {:ok, pipeline} <- refresh(pipeline) do
      run_turn(pipeline, options)
    end
  end

  defp extract_value(pipeline, {:inference, prompt}, options) when is_binary(prompt),
    do: GenAI.Pipeline.InferenceExtractor.run(pipeline, prompt, options)

  defp extract_value(pipeline, selector, options),
    do: Selector.extract(Snapshot.messages(pipeline.thread), selector, options)

  defp broadcast(%Fork{} = fork, callback, options),
    do: Fork.map_pipelines(fork, callback, options)

  defp unique_delta_ids(deltas, prefix) do
    seen = Map.new(prefix, &{Map.get(&1, :id), :base}) |> Map.delete(nil)

    Enum.reduce_while(deltas, {:ok, seen}, fn {branch_id, message}, {:ok, seen} ->
      id = Map.get(message, :id)

      if not is_nil(id) and Map.has_key?(seen, id) do
        {:halt, {:error, {:duplicate_message_id, id, [seen[id], branch_id]}}}
      else
        {:cont, {:ok, Map.put(seen, id, branch_id)}}
      end
    end)
    |> case do
      {:ok, _} -> :ok
      error -> error
    end
  end

  defp same_message?(%{id: id}, %{id: id}) when not is_nil(id), do: true
  defp same_message?(%{role: role, content: content}, %{role: role, content: content}), do: true
  defp same_message?(_, _), do: false

  defp normalize_branches(branches) when is_list(branches) do
    branches
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn
      {%Branch{} = branch, _}, {:ok, acc} ->
        {:cont, {:ok, acc ++ [branch]}}

      {input, index}, {:ok, acc} ->
        case coerce(input) do
          {:ok, pipeline} ->
            {:cont, {:ok, acc ++ [%Branch{id: index, base: pipeline.thread, pipeline: pipeline}]}}

          error ->
            {:halt, error}
        end
    end)
  end

  defp normalize_branches(_), do: {:error, :invalid_fork}

  defp parallel(seeds, fun, options) do
    concurrency = Keyword.get(options, :max_concurrency, 4)
    timeout = Keyword.get(options, :timeout, 30_000)

    if is_integer(concurrency) and concurrency in 1..64 and is_integer(timeout) and
         timeout in 1..300_000 do
      {:ok, supervisor} = Task.Supervisor.start_link()

      try do
        results =
          Task.Supervisor.async_stream_nolink(supervisor, seeds, fun,
            max_concurrency: concurrency,
            timeout: timeout,
            on_timeout: :kill_task,
            ordered: true
          )
          |> Enum.zip(seeds)
          |> Enum.map(fn
            {{:ok, branch}, _} -> branch
            {{:exit, reason}, {branch, _}} -> %{branch | error: {:branch_exit, reason}}
          end)

        %Fork{branches: results, options: options}
      after
        Supervisor.stop(supervisor)
      end
    else
      {:error, :invalid_parallel_limits}
    end
  end

  defp frame_value(pipeline, kind) do
    case Enum.find(pipeline.frames, &(&1.kind == kind)) do
      nil -> nil
      frame -> frame.value
    end
  end

  defp payload_frame(pipeline) do
    case Enum.find(pipeline.frames, &(&1.kind == :payload)) do
      nil -> {:error, :missing_payload}
      frame -> {:ok, frame}
    end
  end

  defp criteria(pipeline, options) do
    case Keyword.get(options, :questions) || frame_value(pipeline, :criteria) do
      questions when is_list(questions) and questions != [] -> {:ok, questions}
      nil -> {:error, :missing_criteria}
      [] -> {:error, :missing_criteria}
      _ -> {:error, :invalid_criteria}
    end
  end

  defp fresh_frames(pipeline) do
    revision = Snapshot.revision(pipeline.thread)

    if Enum.all?(pipeline.frames, &(&1.revision == revision)),
      do: :ok,
      else: {:error, :stale_frame}
  end

  defp consume_frames(frames, kinds) do
    {frames, _} =
      Enum.map_reduce(frames, kinds, fn frame, remaining ->
        if frame.kind in remaining,
          do: {nil, List.delete(remaining, frame.kind)},
          else: {frame, remaining}
      end)

    Enum.reject(frames, &is_nil/1)
  end

  defp serializable(%GenAI.Model{model: name, provider: provider}) do
    serializable(%{name: name, provider: provider})
  end

  defp serializable(%_{} = value), do: serializable(Map.from_struct(value))

  defp serializable(value) when is_map(value) do
    Enum.reduce_while(value, {:ok, %{}}, fn {key, value}, {:ok, acc} ->
      case if(is_binary(key) or is_atom(key),
             do: serializable(value),
             else: {:error, :non_serializable_result}
           ) do
        {:ok, v} -> {:cont, {:ok, Map.put(acc, key, v)}}
        error -> {:halt, error}
      end
    end)
  end

  defp serializable(value) when is_list(value) do
    Enum.reduce_while(value, {:ok, []}, fn value, {:ok, acc} ->
      case serializable(value) do
        {:ok, v} -> {:cont, {:ok, acc ++ [v]}}
        error -> {:halt, error}
      end
    end)
  end

  defp serializable(value)
       when is_binary(value) or is_number(value) or is_boolean(value) or is_nil(value),
       do: {:ok, value}

  defp serializable(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  defp serializable(_), do: {:error, :non_serializable_result}

  @doc false
  def coerce({:ok, value}), do: coerce(value)
  def coerce({:error, _} = error), do: error
  def coerce(%Fork{} = fork), do: Fork.normalize(fork)
  def coerce({:fork, _} = legacy), do: Fork.normalize(legacy)
  def coerce(%__MODULE__{} = pipeline), do: {:ok, pipeline}
  def coerce(thread), do: new(thread)

  @doc false
  def refresh(pipeline) do
    with {:ok, thread} <-
           Snapshot.materialize(pipeline.thread, pipeline.context, pipeline.options) do
      {:ok, %{pipeline | thread: thread}}
    end
  end
end
