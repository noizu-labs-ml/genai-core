defmodule GenAI.Graph.ToolNode do
  @moduledoc """
  A module representing a tool node in a graph structure.
  This module defines the structure and behavior of a tool node,
  including its identifier and content.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  defnodestruct(content: nil)
  defnodetype(content: term)
end
