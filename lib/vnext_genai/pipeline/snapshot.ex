defmodule GenAI.Pipeline.Snapshot do
  @moduledoc false
  require GenAI.Records.Node

  @neutral_nodes [
    GenAI.Graph.Node,
    GenAI.Message,
    GenAI.Message.ToolUsage,
    GenAI.Message.ToolResponse,
    GenAI.Model,
    GenAI.Setting,
    GenAI.Setting.ModelSetting,
    GenAI.Setting.ProviderSetting,
    GenAI.Setting.SafetySetting,
    GenAI.Tool
  ]

  # Materialize graph/directive state without invoking a model or provider encoder.
  def materialize(%GenAI.Thread.Session{} = thread, context, options) do
    if projected?(thread) do
      {:ok, thread}
    else
      project_session(thread, context, options)
    end
  end

  def materialize(%GenAI.Thread.Standard{} = thread, _context, _options) do
    with :ok <- neutral_graph(thread.graph),
         {:ok, updated} <- GenAI.Legacy.NodeProtocol.apply(thread.graph, thread) do
      result =
        updated.state.messages
        |> Enum.reverse()
        |> Enum.reduce_while({:ok, {[], %{}}}, fn message, {:ok, {messages, ids}} ->
          id = Map.get(message, :id)

          case {id, Map.fetch(ids, id)} do
            {nil, _} -> {:cont, {:ok, {[message | messages], ids}}}
            {_, :error} -> {:cont, {:ok, {[message | messages], Map.put(ids, id, message)}}}
            {_, {:ok, ^message}} -> {:cont, {:ok, {messages, ids}}}
            _ -> {:halt, {:error, {:conflicting_message_id, id}}}
          end
        end)

      with {:ok, {messages, _ids}} <- result do
        {:ok, %{updated | state: %{updated.state | messages: messages}, graph: %GenAI.Graph{}}}
      end
    end
  end

  def materialize(_, _, _), do: {:error, :unsupported_thread}

  def messages(%GenAI.Thread.Session{} = thread) do
    thread.state.thread
    |> Enum.reverse()
    |> Enum.map(&thread.state.thread_messages[&1].value)
  end

  def messages(%GenAI.Thread.Standard{} = thread), do: Enum.reverse(thread.state.messages)

  def revision(thread), do: :crypto.hash(:sha256, :erlang.term_to_binary(messages(thread)))

  defp projected?(thread) do
    match?([%GenAI.Graph.Node{}], Map.values(thread.root.graph.nodes)) and
      not GenAI.Thread.Session.pending_directives?(thread)
  end

  defp project_session(thread, context, options) do
    with :ok <- neutral_graph(thread.root.graph) do
      result =
        if map_size(thread.root.graph.nodes) == 0,
          do: GenAI.Records.Node.process_end(session: thread),
          else: GenAI.Graph.Root.process_node(thread.root, nil, nil, thread, context, options)

      case result do
        GenAI.Records.Node.process_end(session: updated) ->
          with {:ok, updated} <- GenAI.Thread.Session.apply_directives(updated, context, options) do
            state = %{
              updated.state
              | thread: updated.state.thread |> Enum.reverse() |> Enum.uniq() |> Enum.reverse()
            }

            graph =
              GenAI.VNext.Graph.new(nil) |> GenAI.VNext.Graph.attach_node(GenAI.Graph.Node.new())

            root = %GenAI.Graph.Root{graph: graph}
            {:ok, %{updated | state: state, root: root}}
          end

        other ->
          {:error, {:graph_projection, other}}
      end
    end
  end

  defp neutral_graph(%GenAI.VNext.Graph{nodes: nodes}), do: neutral_nodes(Map.values(nodes))
  defp neutral_graph(%GenAI.Graph{nodes: nodes}), do: neutral_nodes(nodes)
  defp neutral_graph(_), do: {:error, :unsafe_projection_node}

  defp neutral_nodes(nodes) do
    Enum.reduce_while(nodes, :ok, fn
      %GenAI.VNext.Graph{} = graph, :ok ->
        case neutral_graph(graph) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end

      %{__struct__: module}, :ok when module in @neutral_nodes ->
        {:cont, :ok}

      _, :ok ->
        {:halt, {:error, :unsafe_projection_node}}
    end)
  end
end
