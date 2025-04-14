defmodule GenAI.Model do
  @moduledoc """
  Represents a Provider Model plus picker details and encoder.
  """

  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  @derive GenAI.Thread.SessionProtocol
  defnodestruct(
    provider: nil,
    encoder: nil,
    model: nil,
    details: nil
  )
  defnodetype(
    provider: term,
    encoder: term,
    model: term,
    details: term
  )
end

defimpl GenAI.ModelProtocol, for: [GenAI.Model] do

  def handle(subject), do: {:ok, subject.model}

  def encoder(subject), do: {:ok, subject.encoder || subject.provider}

  def provider(subject), do: {:ok, subject.provider}

  def name(subject), do: {:ok, subject.model}

  def encode_message(subject, message, thread_context) do
    with {:ok, encoder} <- encoder(subject) do
      encoder.encode_message(message, thread_context)
    end
  end

  def encode_tool(subject, tool, thread_context) do
    with {:ok, encoder} <- encoder(subject) do
      encoder.encode_tool(tool, thread_context)
    end
  end

  def register(subject, thread_context), do: {:ok, {subject, thread_context}}
end