defmodule GenAI.Message.ToolCall do
  @moduledoc """
  Represents a tool call in a message thread.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  @derive GenAI.Thread.SessionProtocol
  defnodestruct(role: nil, content: nil, tool_calls: nil)
  defnodetype(role: term, content: term, tool_calls: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Message}


  defimpl GenAI.MessageProtocol do
    def message(message), do: message
    def content(_), do: :unsupported
  end

end
