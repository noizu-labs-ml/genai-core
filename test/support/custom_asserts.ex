defmodule GenAI.Graph.Asserts do
  # <REMOVED UUID HERE> is_graph :: auto-generated pointer for public function is_graph
  defmacro is_graph(graph) do
    quote(do: is_struct(unquote(graph), GenAI.VNext.Graph))
  end

  # <REMOVED UUID HERE> is_link :: auto-generated pointer for public function is_link
  defmacro is_link(graph) do
    quote(do: is_struct(unquote(graph), GenAI.Graph.Link))
  end

  # <REMOVED UUID HERE> is_node :: auto-generated pointer for public function is_node
  defmacro is_node(graph) do
    quote(do: GenAI.Graph.NodeProtocol.impl_for(unquote(graph)))
  end

  # <REMOVED UUID HERE> graph_size :: auto-generated pointer for public function graph_size
  defmacro graph_size(graph) do
    quote do
      nodes = GenAI.VNext.Graph.nodes!(unquote(graph))
      length(nodes)
    end
  end

  # <REMOVED UUID HERE> graph_constraint :: auto-generated pointer for public function graph_constraint
  defmacro graph_constraint(item, constraint) do
    quote do
      unquote(item) == unquote(constraint)
    end
  end

  # <REMOVED UUID HERE> graph_node_handle :: auto-generated pointer for public function graph_node_handle
  defmacro graph_node_handle(node, constraint) do
    quote do
      {:ok, handle} = GenAI.Graph.NodeProtocol.handle(unquote(node))
      graph_constraint(handle, unquote(constraint))
    end
  end

  # <REMOVED UUID HERE> graph_node :: auto-generated pointer for public function graph_node
  defmacro graph_node(graph, constraints) do
    quote do
      gn_nodes = GenAI.VNext.Graph.nodes!(unquote(graph))

      Enum.find(
        gn_nodes,
        fn gn ->
          Enum.all?(
            unquote(constraints),
            fn
              {:handle, v} ->
                graph_node_handle(gn, v)
            end
          )
        end
      )
    end
  end

  #
  #    defmacro assert_graph(graph, [do: block]) do
  #        IO.inspect(block, label: "BLOCK")
  #        quote do
  #            :ok
  #        end
  #    end
  #

  # <REMOVED UUID HERE> __using__ :: auto-generated pointer for public function __using__
  defmacro __using__(_) do
    quote do
      require GenAI.Graph.Asserts

      import GenAI.Graph.Asserts,
        only: [
          is_graph: 1,
          is_link: 1,
          is_node: 1,
          graph_size: 1,
          graph_node: 2,
          graph_node_handle: 2,
          graph_constraint: 2
        ]
    end
  end
end
