defprotocol GenAI.Thread.SessionProtocol do
  def process_node(graph_node, scope, context, options)
end


defimpl GenAI.Thread.SessionProtocol, for: Any do
  require GenAI.Records.Session
  alias GenAI.Records.Session, as: Node

  defmacro __deriving__(module, _, options) do
    options = Macro.escape(options)
    quote do
      defimpl GenAI.Thread.SessionProtocol, for: unquote(module) do
        @provider unquote(options[:provider]) || GenAI.Thread.SessionProtocol.DefaultProvider
        defdelegate process_node(graph_node, scope, context, options), to: @provider
      end
    end
  end
end

defmodule GenAI.Thread.SessionProtocol.DefaultProvider do
  require GenAI.Records.Session
  alias GenAI.Records.Session, as: Node

  #-----------------------------------------------
  # process_node
  #-----------------------------------------------
  @doc """
  Apply/process a node. check/update fingerprint and add any appropriate directives to state.
  """
  def process_node(%{__struct__: module} = graph_node, scope, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :process_node, 4) do
      module.process_node(graph_node, scope, context, options)
    else
      do_process_node(graph_node, scope, context, options)
    end
  end


  def do_process_node(graph_node, scope, context, options)
  def do_process_node(
        %{__struct__: module} = graph_node,
        scope = Node.scope(
          graph_container: graph_container,
        ),
        context,
        options) do
    # What occurs durring process_node?
    # 1. We update state (if any)
    #    When is state updated? this doesn't occur in most nodes other than loop entry nodes, nodes that fetch data or loop iterator content.
    # 2. we apply any directives/messages.
    #    We will keep directives and messages separate.
    # 3. We check if we have any outbound links.
    # 4. We process the next node or end
    # 5. telemetry?
    IO.inspect(graph_node.__struct__, label: "Processing Node ---- ")
    process_node_response(graph_node, graph_container, scope)
  end

  def process_node_response(graph_node, graph_container, update) do
    with {:ok, links} <- GenAI.Graph.NodeProtocol.outbound_links(
      graph_node,
      graph_container,
      expand: true
    ) do
      links = links
              |> Enum.map(fn {socket, links} -> links end)
              |> List.flatten()
      # Single node support only
      case links do
        [] ->
          Node.process_end(
            exit_on: {graph_node, :no_links},
            update: update
          )
        [link] ->
          Node.process_next(
            link: link,
            update: update
          )
      end
    end
  end
end

defimpl GenAI.Thread.SessionProtocol, for: GenAI.Graph.Root do
  require GenAI.Records.Session
  alias GenAI.Records.Session, as: Node

  def process_node(subject, scope, context, options) do
    subject = subject
              |> GenAI.Graph.Root.merge_lookup_table_entries(GenAI.Graph.NodeProtocol.build_node_lookup(subject.graph, []))
              |> GenAI.Graph.Root.merge_handles(GenAI.Graph.NodeProtocol.build_handle_lookup(subject.graph, []))

    updated_scope = Node.scope(
      scope,
      graph_node: subject.graph,
      graph_link: nil,
      graph_container: subject,
      session_root: subject
    )
      GenAI.Thread.SessionProtocol.process_node(subject.graph, updated_scope, context, options)
  end
end

defimpl GenAI.Thread.SessionProtocol, for: GenAI.VNext.Graph do
  require GenAI.Records.Session
  require GenAI.Records.Link
  alias GenAI.Records.Session, as: Node
  alias GenAI.Records.Link

  def process_node(subject, scope, context, options) do
    with {:ok, head} <- GenAI.VNext.Graph.head(subject)  do
      updated_scope = Node.scope(
        scope,
        graph_node: head,
        graph_link: nil,
        graph_container: subject,
      )
      do_process_node(updated_scope, context, options)
    end
  end

  def do_process_node(
        Node.scope(
          graph_node: node,
        ) = scope,
        context,
        options) do
    case GenAI.Thread.SessionProtocol.process_node(node, scope, context, options) do
      Node.process_next(link: link, update: update) ->

        with {:ok, scope} <- merge_scope(scope, update),
             {:ok, Link.connector(node: target)} <- GenAI.Graph.Link.target_connector(link),
             {:ok, next} <- GenAI.Graph.Root.element(Node.scope(scope, :session_root), target) do
          scope = Node.scope(scope, graph_node: next, graph_link: link)
          do_process_node(scope, context, options)
        end

      x = Node.process_end() -> x
      x = Node.process_error() -> x
      x = Node.process_yield() -> x
    end
  end

  def merge_scope(scope, update) do
    Node.scope(
      graph_node: aa,
      graph_link: ab ,
      graph_container: ac,
      session_root: ad,
      session_state: ae,
      session_runtime: af
    ) = scope

    Node.scope(
      graph_node: ba,
      graph_link: bb ,
      graph_container: bc,
      session_root: bd,
      session_state: be,
      session_runtime: bf
    ) = update

    update = Node.scope(scope,
      graph_node: ba || aa,
      graph_link: bb || ab ,
      graph_container: bc || ac,
      session_root: bd || ad,
      session_state: be || ae,
      session_runtime: bf || af
    )
    {:ok, update}
  end

end

