defmodule GenAI.Setting do
  @moduledoc """
  A module representing a setting node in a graph structure.
  This module defines the structure and behavior of a setting node,
  including its identifier, setting, and value.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  @derive GenAI.Thread.SessionProtocol
  defnodestruct(setting: nil, value: nil)
  defnodetype(setting: term, value: term)
end