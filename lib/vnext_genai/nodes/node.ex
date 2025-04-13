defmodule GenAI.Graph.Node do
  @vsn 1.0
  @moduledoc """
  Represent a node on graph (generic type).
  """

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  defnodestruct(content: nil)
  defnodetype(content: term)
end

