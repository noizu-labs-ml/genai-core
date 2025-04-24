defmodule GenAI.ChatCompletion do
  @moduledoc """
  Encodes a LLM ChatCompletion response.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol

  defnodestruct(
    model: nil,
    provider: nil,
    seed: nil,
    choices: nil,
    usage: nil,
    details: nil
  )

  defnodetype(
    model: term,
    provider: term,
    seed: term,
    choices: term,
    usage: term,
    details: term
  )
end
