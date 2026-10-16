defmodule GenAI.Thread.Fork do
  @moduledoc """
  An immutable thread tree. Leaf branches own isolated pipelines; internal
  branches own another Fork. All ThreadProtocol operations dispatch to leaves.
  A raw `{:fork, branches}` is accepted at ingress, never returned by new operations.
  """
  alias GenAI.Pipeline.{Branch, Snapshot}
  alias __MODULE__.{Error, Outcome, Result}
  defstruct branches: [], context: nil, options: []

  def normalize(%__MODULE__{} = fork), do: normalize_branches(fork)
  def normalize({:fork, branches}), do: normalize(%__MODULE__{branches: branches})
  def normalize(_), do: {:error, :invalid_fork}

  defp normalize_branches(%{branches: branches} = fork) when is_list(branches) do
    branches =
      Enum.with_index(branches)
      |> Enum.map(fn
        {%Branch{} = branch, _} ->
          branch

        {value, index} ->
          case GenAI.Pipeline.coerce(value) do
            {:ok, pipeline} when is_struct(pipeline, GenAI.Pipeline) ->
              %Branch{id: index, base: pipeline.thread, pipeline: pipeline}

            _ ->
              value
          end
      end)

    ids = for %Branch{id: id} <- branches, do: id

    cond do
      branches == [] ->
        {:error, :empty_fork}

      length(ids) != length(branches) ->
        {:error, :invalid_branch}

      length(branches) > 64 ->
        {:error, :fork_limit}

      length(Enum.uniq(ids)) != length(ids) ->
        {:error, :duplicate_branch_id}

      true ->
        Enum.reduce_while(branches, {:ok, []}, fn branch, {:ok, acc} ->
          case branch.pipeline do
            pipeline when is_struct(pipeline, GenAI.Pipeline) ->
              if scalar_thread?(pipeline.thread),
                do: {:cont, {:ok, [branch | acc]}},
                else: {:halt, {:error, :invalid_branch_thread}}

            nested ->
              case normalize(nested) do
                {:ok, nested} -> {:cont, {:ok, [%{branch | pipeline: nested} | acc]}}
                error -> {:halt, error}
              end
          end
        end)
        |> case do
          {:ok, branches} -> {:ok, %{fork | branches: Enum.reverse(branches)}}
          error -> error
        end
    end
  end

  defp normalize_branches(_), do: {:error, :invalid_fork}

  @doc "Evaluate each leaf once under a global nested-tree concurrency budget."
  def evaluate(input, operation, callback, options \\ []) do
    evaluate_pipelines(
      input,
      operation,
      fn pipeline, path ->
        case callback.(pipeline.thread, path) do
          {:ok, {value, thread}} ->
            if scalar_thread?(thread),
              do: {:ok, {value, update_thread(pipeline, thread)}},
              else: {:error, :invalid_branch_thread}

          {:error, reason, thread} ->
            if scalar_thread?(thread),
              do: {:error, reason, update_thread(pipeline, thread)},
              else: {:error, :invalid_branch_thread}

          other ->
            other
        end
      end,
      options
    )
  end

  @doc false
  def evaluate_pipelines(input, operation, callback, options \\ []) do
    with {:ok, fork} <- normalize(input),
         {:ok, limits} <- limits(Keyword.merge(fork.options || [], options || [])) do
      work = leaves(fork)
      {:ok, supervisor} = Task.Supervisor.start_link()

      try do
        completed =
          Task.Supervisor.async_stream_nolink(
            supervisor,
            work,
            fn {path, branch} -> evaluate_leaf(branch, path, callback) end,
            max_concurrency: limits.concurrency,
            timeout: limits.timeout,
            on_timeout: :kill_task,
            ordered: true
          )
          |> Enum.zip(work)
          |> Enum.map(fn
            {{:ok, result}, _} ->
              result

            {{:exit, reason}, {path, branch}} ->
              failed(
                branch,
                path,
                if(reason == :timeout, do: :timeout, else: {:branch_exit, reason})
              )
          end)

        result = %Result{operation: operation, outcomes: Enum.map(completed, &elem(&1, 2))}
        updated = rebuild(fork, Map.new(completed, fn {path, branch, _} -> {path, branch} end))

        if Enum.any?(result.outcomes, &(&1.status == :error)),
          do: {:error, %Error{operation: operation, fork: updated, result: result}},
          else: {:ok, {result, updated}}
      after
        Supervisor.stop(supervisor)
      end
    end
  end

  defp limits(options) do
    concurrency = Keyword.get(options, :max_concurrency, 4)
    timeout = Keyword.get(options, :timeout, 30_000)

    if is_integer(concurrency) and concurrency in 1..64 and
         is_integer(timeout) and timeout in 1..300_000,
       do: {:ok, %{concurrency: concurrency, timeout: timeout}},
       else: {:error, :invalid_parallel_limits}
  end

  def leaves(%__MODULE__{branches: branches}, prefix \\ []) do
    Enum.flat_map(branches, fn branch ->
      path = prefix ++ [branch.id]

      case branch.pipeline do
        %__MODULE__{} = nested when is_nil(branch.error) -> leaves(nested, path)
        _ -> [{path, %{branch | path: path}}]
      end
    end)
  end

  defp rebuild(%__MODULE__{} = fork, completed, prefix \\ []) do
    %{
      fork
      | branches:
          Enum.map(fork.branches, fn branch ->
            path = prefix ++ [branch.id]

            case branch.pipeline do
              %__MODULE__{} = nested when is_nil(branch.error) ->
                %{branch | path: path, pipeline: rebuild(nested, completed, path)}

              _ ->
                Map.fetch!(completed, path)
            end
          end)
    }
  end

  defp evaluate_leaf(%{error: reason} = branch, path, _) when not is_nil(reason),
    do: failed(branch, path, reason)

  defp evaluate_leaf(branch, path, callback) do
    case callback.(branch.pipeline, path) do
      {:ok, {value, pipeline}}
      when is_struct(pipeline, GenAI.Pipeline) or is_struct(pipeline, __MODULE__) ->
        {path, %{branch | pipeline: pipeline, path: path},
         %Outcome{id: branch.id, path: path, value: value}}

      {:error, reason, pipeline} when is_struct(pipeline, GenAI.Pipeline) ->
        failed(%{branch | pipeline: pipeline}, path, reason)

      {:error, reason} ->
        failed(branch, path, reason)

      _ ->
        failed(branch, path, :invalid_branch_result)
    end
  rescue
    exception -> failed(branch, path, {:branch_exception, exception.__struct__})
  catch
    kind, _ -> failed(branch, path, {:branch_exception, kind})
  end

  @doc false
  def map_pipelines(fork, callback, options) do
    result =
      evaluate_pipelines(
        fork,
        :pipeline,
        fn pipeline, _ ->
          case GenAI.Pipeline.Selector.invoke(fn -> callback.(pipeline) end) do
            {:ok, value} when is_struct(value, GenAI.Pipeline) or is_struct(value, __MODULE__) ->
              {:ok, {nil, value}}

            {:error, reason} ->
              {:error, reason}

            _ ->
              {:error, :invalid_branch_result}
          end
        end,
        options
      )

    case result do
      {:ok, {_, updated}} -> updated
      {:error, %Error{fork: updated}} -> updated
      error -> error
    end
  end

  defp failed(branch, path, reason),
    do:
      {path, %{branch | error: reason, path: path},
       %Outcome{id: branch.id, path: path, status: :error, reason: reason}}

  defp update_thread(pipeline, thread) do
    thread =
      case Snapshot.materialize(thread, pipeline.context, pipeline.options) do
        {:ok, projected} -> projected
        _ -> thread
      end

    frames = if revision(pipeline.thread) == revision(thread), do: pipeline.frames, else: []
    %{pipeline | thread: thread, frames: frames}
  end

  defp scalar_thread?(thread),
    do: not is_struct(thread, __MODULE__) and not is_nil(GenAI.ThreadProtocol.impl_for(thread))

  defp revision(thread) do
    case Snapshot.materialize(thread, nil, []) do
      {:ok, projected} -> Snapshot.revision(projected)
      _ -> make_ref()
    end
  end

  @doc false
  def mutate(fork, operation, arguments, tagged? \\ false) do
    result =
      evaluate(fork, operation, fn thread, _ ->
        case apply(GenAI.ThreadProtocol, operation, [thread | arguments]) do
          {:ok, updated} -> {:ok, {nil, updated}}
          {:error, reason} -> {:error, reason}
          updated -> {:ok, {nil, updated}}
        end
      end)

    case result do
      {:ok, {_, updated}} -> if tagged?, do: {:ok, updated}, else: updated
      {:error, %Error{fork: updated}} = error -> if tagged?, do: error, else: updated
      error -> error
    end
  end

  @doc false
  def project(fork, operation, arguments, artifact? \\ false) do
    result =
      evaluate(fork, operation, fn thread, path ->
        with {:ok, arguments} <- arguments_for(arguments, path),
             context = if(artifact?, do: fork.context, else: Enum.at(arguments, -2)),
             options = if(artifact?, do: fork.options, else: List.last(arguments)),
             {:ok, thread} <- Snapshot.materialize(thread, context, options || []) do
          case apply(GenAI.ThreadProtocol, operation, [thread | arguments]) do
            {:ok, value} when artifact? -> {:ok, {value, thread}}
            result -> result
          end
        end
      end)

    case result do
      {:ok, {value, _}} when artifact? -> {:ok, value}
      result -> result
    end
  end

  defp arguments_for(arguments, path) do
    Enum.reduce_while(arguments, {:ok, []}, fn
      %Result{} = result, {:ok, values} ->
        case Result.fetch(result, path) do
          {:ok, value} -> {:cont, {:ok, values ++ [value]}}
          error -> {:halt, error}
        end

      value, {:ok, values} ->
        {:cont, {:ok, values ++ [value]}}
    end)
  end

  @doc false
  def execute(fork, command, context, options) when command in [:run, :stream] do
    evaluate(
      fork,
      command,
      fn thread, path ->
        options = Keyword.put(options || [], :fork_path, path)

        if command == :stream,
          do: GenAI.Thread.Fork.Stream.execute(thread, context, options, path),
          else: GenAI.ThreadProtocol.execute(thread, command, context, options)
      end,
      options || []
    )
  end

  def execute(_fork, command, _context, _options),
    do: {:error, {:unsupported_fork_command, command}}
end

defimpl GenAI.ThreadProtocol, for: GenAI.Thread.Fork do
  alias GenAI.Thread.Fork

  for {name, arity} <- GenAI.ThreadProtocol.__protocol__(:functions),
      name not in [:execute, :get_artifact, :set_artifact, :append_directive] do
    args = Macro.generate_arguments(arity - 1, __MODULE__)

    if String.starts_with?(Atom.to_string(name), "effective_") do
      def unquote(name)(fork, unquote_splicing(args)),
        do: Fork.project(fork, unquote(name), [unquote_splicing(args)])
    else
      def unquote(name)(fork, unquote_splicing(args)),
        do: Fork.mutate(fork, unquote(name), [unquote_splicing(args)])
    end
  end

  def execute(fork, command, context, options), do: Fork.execute(fork, command, context, options)
  def get_artifact(fork, key), do: Fork.project(fork, :get_artifact, [key], true)
  def set_artifact(fork, key, value), do: Fork.mutate(fork, :set_artifact, [key, value], true)

  def append_directive(fork, directive, context, options),
    do: Fork.mutate(fork, :append_directive, [directive, context, options], true)
end

defimpl Inspect, for: GenAI.Thread.Fork do
  def inspect(fork, _opts), do: "#GenAI.Thread.Fork<#{length(fork.branches)} branches>"
end
