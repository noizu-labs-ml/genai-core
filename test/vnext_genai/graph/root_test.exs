defmodule GenAI.Graph.RootTest do
  # import VNextGenAI.Test.Support.Common
  use ExUnit.Case,
      async: true

  require Logger
  alias GenAI.VNext.Graph
  alias GenAI.Graph.Node
  alias GenAI.Graph.Link
  alias GenAI.Records.Link, as: L
  require GenAI.Records.Link

  def sut(scenario \\ :default)
  def sut(:default) do
    graph_b = Graph.new(id: :B)
    |> Graph.add_node(Node.new(id: :Node1B, handle: L.graph_handle(scope: :local, name: :foo), name: "N1B"), head: true)
    |> Graph.add_node(Node.new(id: :Node2B, name: "N2B"))
    |> Graph.add_link(Link.new(:Node1B, :Node2B))

    graph = Graph.new(id: :A)
            |> Graph.add_node(Node.new(id: :Node1A, handle: L.graph_handle(name: :foo),  name: "N1A"), head: true)
            |> Graph.add_node(Node.new(id: :Node2A, handle: L.graph_handle(scope: :global, name: :bar), name: "N2A"))
            |> Graph.add_node(graph_b)
            |> Graph.add_link(Link.new(:Node1A, :Node2A))
            |> Graph.add_link(Link.new(:Node2A, :B))

    hl = GenAI.Graph.NodeProtocol.build_handle_lookup(graph, [])
    el = GenAI.Graph.NodeProtocol.build_node_lookup(graph, [])

    # TODO method to get handles and ids for lookup table from graphs
    # TODO add get node method to Graph.NodeProtocol return {:error, :not_found} by default

    %GenAI.Graph.Root{
      graph: graph,
    }
    |> GenAI.Graph.Root.merge_lookup_table_entries(el)
    |> GenAI.Graph.Root.merge_handles(hl)


  end

  describe "Basic Graph Root Coverage" do

    @tag :me
    test "setup Root - get by element" do
      sut = sut()
      {:ok, e} = GenAI.Graph.Root.element(sut, :Node1B)
      assert e.id == :Node1B
    end


    @tag :me
    test "setup Root - get by handle" do
      sut = sut()
      {:ok, e} = GenAI.Graph.Root.element_by_handle(sut, :foo, :B)
      assert e.id == :Node1B
    end

  end

end
