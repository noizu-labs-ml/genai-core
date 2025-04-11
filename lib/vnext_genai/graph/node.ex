defmodule VNextGenAI.Graph.Node do
  @vsn 1.0
  @moduledoc """
  Represent a node on graph (generic type).
  """

  use VNextGenAI.Graph.NodeBehaviour
  @derive VNextGenAI.Graph.NodeProtocol
  defnodestruct(value: nil)

  defnodetype(value: term)

  @doc """
  Create a new node.
  """
  @spec new(keyword | nil) :: __MODULE__.t()
  def new(options \\ nil) do
    %__MODULE__{
      id: options[:id] || UUID.uuid4(),
      handle: options[:handle] || nil,
      name: options[:name] || nil,
      description: options[:description] || nil,
      inbound_links: %{},
      outbound_links: %{}
    }
  end
end

defimpl VNextGenAI.Graph.MermaidProtocol, for: VNextGenAI.Graph.Node do
  require VNextGenAI.Records.Link
  alias VNextGenAI.Records, as: R

  @spec mermaid_id(VNextGenAI.Graph.Node.t()) :: String.t()
  def mermaid_id(subject) do
    VNextGenAI.Graph.MermaidProtocol.Helpers.mermaid_id(subject.id)
  end

  @spec encode(VNextGenAI.Graph.Node.t()) :: {:ok, String.t()} | {:error, term}
  def encode(graph_element), do: encode(graph_element, [])

  @spec encode(VNextGenAI.Graph.Node.t(), keyword) :: {:ok, String.t()} | {:error, term}
  def encode(graph_element, options), do: encode(graph_element, options, %{})

  @spec encode(VNextGenAI.Graph.Node.t(), keyword, map) :: {:ok, String.t()} | {:error, term}
  def encode(graph_element, options, state) do
    case VNextGenAI.Graph.MermaidProtocol.Helpers.diagram_type(options) do
      :state_diagram_v2 -> state_diagram_v2(graph_element, options, state)
      x -> {:error, {:unsupported_diagram, x}}
    end
  end

  @spec state_diagram_v2(VNextGenAI.Graph.Node.t(), keyword, map) :: {:ok, String.t()} | {:error, term}
  def state_diagram_v2(graph_node, options, state)

  def state_diagram_v2(graph_node, _, state) do
    identifier = VNextGenAI.Graph.MermaidProtocol.Helpers.mermaid_id(graph_node.id)
    container = List.first(state[:container])

    n =
      cond do
        graph_node.name ->
          """
          state "#{graph_node.name}" as #{identifier}
          """

        graph_node.handle ->
          """
          state "#{graph_node.handle}" as #{identifier}
          """

        :else ->
          """
          state "A Node" as #{identifier}
          """
      end

    transitions =
      graph_node.outbound_links
      |> Enum.map(fn {_, links} ->
        Enum.map(
          links,
          fn link_id ->
            # TODO - Node protocol needs to return a get_link method that accepts node, container
            {:ok, link} = VNextGenAI.Graph.link(container, link_id)
            {:ok, R.Link.connector(node: n)} = VNextGenAI.Graph.Link.target_connector(link)
            "#{identifier} --> #{VNextGenAI.Graph.MermaidProtocol.Helpers.mermaid_id(n)}"
          end
        )
      end)
      |> List.flatten()
      |> Enum.join("\n")

    if transitions != "" do
      graph = n <> transitions <> "\n"
      {:ok, graph}
    else
      graph = n <> transitions
      {:ok, graph}
    end
  end
end
