defmodule GenAI.Graph.ModelNode do
  @moduledoc """
  A module representing a model node in a graph structure.
  This module defines the structure and behavior of a model node,
  including its identifier and content.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  defnodestruct(content: nil)
  defnodetype(content: term)
end
