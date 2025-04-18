defmodule GenAI.Message.ToolResponse do
  @moduledoc """
  Represents a tool response in a message thread.
  """

  @vsn 1.0
  defstruct [
    name: nil,
    response: nil,
    tool_call_id: nil,
    vsn: @vsn
  ]

  defimpl GenAI.MessageProtocol do
    def message(message), do: message
    def content(_), do: :unsupported
  end

end
