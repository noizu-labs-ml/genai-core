defmodule GenAI.Graph.ProviderSettingNode do
  @moduledoc """
  A module representing a llm provider (openai, google, etc.)  setting node in a graph structure.
  This module defines the structure and behavior of a provider setting node,
  including its identifier, provider, setting, and value.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  defnodestruct(provider: nil, setting: nil, value: nil)
  defnodetype(provider: term, setting: term, value: term)
end
