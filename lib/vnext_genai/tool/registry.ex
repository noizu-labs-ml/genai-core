defmodule GenAI.Tool.Registry do
  @moduledoc """
  Immutable registry that gives heterogeneous tool sources one deterministic
  model-facing namespace.

  Names are exposed as `source__tool` by default. Invalid characters become
  `_`; collisions fail with `{:error, {:tool_name_collision, name}}` unless the
  caller explicitly selects `collision: :keep` or `collision: :replace`.
  """

  alias GenAI.Tool.{Call, Result, Telemetry}

  defmodule Entry do
    @moduledoc false
    @enforce_keys [:name, :source_id, :source_name, :module, :source, :tool]
    defstruct [:name, :source_id, :source_name, :module, :source, :tool, options: []]
  end

  defstruct entries: %{}, sources: %{}, options: []

  @type t :: %__MODULE__{entries: %{String.t() => Entry.t()}, sources: map(), options: keyword()}

  @max_timeout 120_000
  @default_timeout 15_000

  @spec new(keyword()) :: t()
  def new(options \\ []), do: %__MODULE__{options: options}

  @doc "Registers and snapshots the current tools from a source."
  @spec register(t(), term(), module(), term(), term(), keyword()) ::
          {:ok, t()} | {:error, term()}
  def register(registry, source_id, module, source, context \\ nil, options \\ [])

  def register(%__MODULE__{} = registry, source_id, module, source, context, options)
      when is_atom(module) and is_list(options) do
    started = System.monotonic_time()
    source_id = to_string(source_id)
    merged_options = Keyword.merge(registry.options, options)

    Telemetry.emit(
      [:tool_source, :register, :start],
      %{system_time: System.system_time()},
      %{source: source_id},
      merged_options
    )

    result =
      with :ok <- validate_source(module),
           {:ok, descriptors} <- module.list_tools(source, context, merged_options),
           true <- is_list(descriptors) || {:error, :invalid_tool_list},
           {:ok, entries} <- build_entries(descriptors, source_id, module, source, merged_options),
           {:ok, registry} <- merge_entries(registry, source_id, entries, merged_options) do
        {:ok, registry}
      end

    duration = System.monotonic_time() - started

    case result do
      {:ok, updated} ->
        Telemetry.emit(
          [:tool_source, :register, :stop],
          %{
            duration: duration,
            source_tool_count: map_size(entries_for_source(updated, source_id)),
            total_tool_count: map_size(updated.entries)
          },
          %{source: source_id, status: :ok},
          merged_options
        )

        {:ok, updated}

      {:error, reason} = error ->
        Telemetry.emit(
          [:tool_source, :register, :stop],
          %{duration: duration},
          %{source: source_id, status: :error, reason: safe_reason(reason)},
          merged_options
        )

        error
    end
  rescue
    exception ->
      Telemetry.emit(
        [:tool_source, :register, :exception],
        %{duration: 0},
        %{source: source_id, status: :error, kind: :error, reason: exception.__struct__},
        options
      )

      {:error, {:source_exception, exception}}
  catch
    kind, reason -> {:error, {:source_exception, {kind, reason}}}
  end

  @doc "Returns model-facing `GenAI.Tool` values in deterministic name order."
  @spec tools(t()) :: [GenAI.Tool.t()]
  def tools(%__MODULE__{entries: entries}) do
    entries
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {_, entry} -> entry.tool end)
  end

  @doc "Returns the registered model-facing names in deterministic order."
  def names(%__MODULE__{entries: entries}), do: entries |> Map.keys() |> Enum.sort()

  @doc "Executes a normalized call through its owning source."
  @spec execute(t(), term(), term(), keyword()) ::
          {:ok, Result.t()} | {:error, Result.t() | term()}
  def execute(registry, call, context \\ nil, options \\ [])

  def execute(%__MODULE__{} = registry, call, context, options) do
    with {:ok, call} <- Call.normalize(call),
         {:ok, entry} <- fetch_entry(registry, call.name) do
      execute_entry(entry, call, context, Keyword.merge(registry.options, options))
    end
  end

  defp execute_entry(entry, call, context, options) do
    started = System.monotonic_time()
    options = Keyword.merge(entry.options, options)
    metadata = %{source: entry.source_id, tool: call.name, call_id: call.id}
    metadata = Telemetry.metadata(metadata, %{arguments: call.arguments}, options)

    Telemetry.emit(
      [:tool, :execute, :start],
      %{system_time: System.system_time()},
      metadata,
      options
    )

    timeout = options |> Keyword.get(:timeout, @default_timeout) |> clamp(1, @max_timeout)

    task =
      Task.async(fn ->
        try do
          entry.module.call_tool(
            entry.source,
            entry.source_name,
            call.arguments,
            context,
            options
          )
        rescue
          exception -> {:error, {:source_exception, exception}}
        catch
          kind, reason -> {:error, {:source_exception, {kind, reason}}}
        end
      end)

    outcome =
      task
      |> Task.yield(timeout)
      |> case do
        {:ok, value} ->
          value

        {:exit, reason} ->
          {:error, {:source_exit, reason}}

        nil ->
          Task.shutdown(task, :brutal_kill)
          {:error, :timeout}
      end

    duration = System.monotonic_time() - started
    result = normalize_result(outcome, entry, call, duration)

    stop_metadata =
      Telemetry.metadata(
        Map.put(metadata, :status, result.status),
        %{result: result.content, error: result.error},
        options
      )

    Telemetry.emit([:tool, :execute, :stop], %{duration: duration}, stop_metadata, options)

    if result.status == :ok, do: {:ok, result}, else: {:error, result}
  rescue
    exception ->
      duration = 0
      result = normalize_result({:error, {:source_exception, exception}}, entry, call, duration)

      Telemetry.emit(
        [:tool, :execute, :exception],
        %{duration: duration},
        %{
          source: entry.source_id,
          tool: call.name,
          call_id: call.id,
          status: :error,
          kind: :error,
          reason: exception.__struct__
        },
        options
      )

      {:error, result}
  catch
    kind, reason ->
      duration = 0

      {:error,
       normalize_result({:error, {:source_exception, {kind, reason}}}, entry, call, duration)}
  end

  defp validate_source(module) do
    if function_exported?(module, :list_tools, 3) and function_exported?(module, :call_tool, 5),
      do: :ok,
      else: {:error, {:invalid_tool_source, module}}
  end

  defp build_entries(descriptors, source_id, module, source, options) do
    Enum.reduce_while(descriptors, {:ok, %{}}, fn descriptor, {:ok, entries} ->
      with {:ok, source_name, description, parameters} <- normalize_descriptor(descriptor),
           name <- exposed_name(source_id, source_name, options) do
        if Map.has_key?(entries, name) do
          {:halt, {:error, {:tool_name_collision, name}}}
        else
          tool = GenAI.Tool.new(name: name, description: description, parameters: parameters)

          entry = %Entry{
            name: name,
            source_id: source_id,
            source_name: source_name,
            module: module,
            source: source,
            tool: tool,
            options: options
          }

          {:cont, {:ok, Map.put(entries, name, entry)}}
        end
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_descriptor(%GenAI.Tool{} = tool),
    do:
      normalize_descriptor(%{
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      })

  defp normalize_descriptor(descriptor) when is_list(descriptor),
    do: normalize_descriptor(Map.new(descriptor))

  defp normalize_descriptor(descriptor) when is_map(descriptor) do
    name = value(descriptor, :name)
    description = value(descriptor, :description) || ""

    parameters =
      value(descriptor, :parameters) || value(descriptor, :input_schema) ||
        value(descriptor, :inputSchema) || %{"type" => "object", "properties" => %{}}

    if is_binary(name) and name != "" and is_binary(description) and
         (is_map(parameters) or is_struct(parameters)),
       do: {:ok, name, description, parameters},
       else: {:error, {:invalid_tool_descriptor, descriptor}}
  end

  defp normalize_descriptor(descriptor), do: {:error, {:invalid_tool_descriptor, descriptor}}

  defp exposed_name(source_id, source_name, options) do
    raw =
      if Keyword.get(options, :namespace, true),
        do: "#{source_id}__#{source_name}",
        else: source_name

    sanitized = String.replace(raw, ~r/[^a-zA-Z0-9_-]/u, "_")
    max = options |> Keyword.get(:max_name_length, 64) |> clamp(1, 128)
    String.slice(sanitized, 0, max)
  end

  defp merge_entries(registry, source_id, entries, options) do
    collision = Keyword.get(options, :collision, :error)

    duplicate =
      entries |> Map.keys() |> Enum.sort() |> Enum.find(&Map.has_key?(registry.entries, &1))

    cond do
      collision not in [:error, :keep, :replace] ->
        {:error, {:invalid_collision_policy, collision}}

      duplicate && collision == :error ->
        {:error, {:tool_name_collision, duplicate}}

      duplicate && collision == :keep ->
        {:ok,
         %{
           registry
           | entries: Map.merge(entries, registry.entries),
             sources: Map.put(registry.sources, source_id, true)
         }}

      true ->
        {:ok,
         %{
           registry
           | entries: Map.merge(registry.entries, entries),
             sources: Map.put(registry.sources, source_id, true)
         }}
    end
  end

  defp fetch_entry(registry, name) do
    case Map.fetch(registry.entries, name) do
      {:ok, entry} -> {:ok, entry}
      :error -> {:error, {:unknown_tool, name}}
    end
  end

  defp entries_for_source(registry, source_id) do
    Map.filter(registry.entries, fn {_name, entry} -> entry.source_id == source_id end)
  end

  defp normalize_result({:ok, content}, entry, call, duration),
    do: %Result{
      call_id: call.id,
      name: call.name,
      source: entry.source_id,
      status: :ok,
      content: content,
      duration: duration
    }

  defp normalize_result({:error, reason}, entry, call, duration),
    do: %Result{
      call_id: call.id,
      name: call.name,
      source: entry.source_id,
      status: :error,
      error: reason,
      duration: duration
    }

  defp normalize_result(other, entry, call, duration),
    do: %Result{
      call_id: call.id,
      name: call.name,
      source: entry.source_id,
      status: :error,
      error: {:invalid_source_result, other},
      duration: duration
    }

  defp value(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))

  defp clamp(value, min, max) when is_integer(value),
    do: value |> Kernel.max(min) |> Kernel.min(max)

  defp clamp(_, min, _), do: min

  defp safe_reason(reason) when is_atom(reason) or is_binary(reason) or is_number(reason),
    do: reason

  defp safe_reason(reason) when is_tuple(reason), do: elem(reason, 0)
  defp safe_reason(_), do: :error
end
