defmodule GenAI.Message.ToolCall do
  @moduledoc """
  Represents a tool call in a message thread.
  """

  @vsn 1.0
  defstruct [
    role: nil,
    content: nil,
    tool_calls: nil,
    vsn: @vsn
  ]

  defimpl GenAI.MessageProtocol do
    def message(message), do: message
    def content(_), do: :unsupported
  end

end
