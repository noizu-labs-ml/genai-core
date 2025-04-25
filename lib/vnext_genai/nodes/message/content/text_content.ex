defmodule GenAI.Message.Content.TextContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct [
    system: nil,
    type: :input, # prompt, except, paste,  documentation, directory
    text: nil,
    vsn: @vsn
  ]

  def new(message) do
    %__MODULE__{text: message}
  end

  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end

end
