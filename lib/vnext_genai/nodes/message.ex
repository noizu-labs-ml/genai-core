defmodule GenAI.Message do
  @moduledoc """
  Struct for representing a chat message.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  #@derive GenAI.Thread.SessionProtocol
  defnodestruct(role: nil, content: nil)
  defnodetype(role: term, content: term)


  def message(role, message) do
    new(role: role, content: message)
  end

  def user(message) do
    message(:user, message)
  end

  def system(message) do
    message(:system, message)
  end

  def assistant(message) do
    message(:assistant, message)
  end


  @doc """
  Load image resource.
  """
  def image(resource, options \\ nil)
  def image(resource, nil) do
    GenAI.Message.Content.ImageContent.new(resource)
  end
  def image(resource, options) do
    GenAI.Message.Content.ImageContent.new(resource, options)
  end



  defimpl GenAI.MessageProtocol do
    def message(message), do: message

    def content(message)
    def content(%{content: content}) when is_bitstring(content) do
      content
    end
    def content(%{content: content}) when is_list(content) do
      Enum.map(content, & GenAI.Message.ContentProtocol.content(&1))
    end
  end

end
