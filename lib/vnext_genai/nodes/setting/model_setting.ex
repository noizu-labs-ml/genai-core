#===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
#===============================================================================

defmodule GenAI.Setting.ModelSetting do
  @moduledoc """
  Represents a Provider Setting (used by Gemini)
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  @derive GenAI.Thread.SessionProtocol
  defnodestruct(model: nil, setting: nil, value: nil)
  defnodetype(model: nil, setting: term, value: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Setting}
end