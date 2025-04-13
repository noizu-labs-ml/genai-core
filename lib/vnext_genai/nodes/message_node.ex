defmodule GenAI.Graph.MessageNode do
  @moduledoc """
  A module representing a message node in a graph structure.
  This module defines the structure and behavior of a message node,
  including its identifier and content.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  defnodestruct(content: nil)
  defnodetype(content: term)
end
