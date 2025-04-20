#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting.SafetySetting do
  @moduledoc """
  Represents a Model Safety Setting (used by Gemini)
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  #@derive GenAI.Thread.SessionProtocol
  defnodestruct(category: nil, threshold: nil)
  defnodetype(category: term, threshold: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Setting}
end