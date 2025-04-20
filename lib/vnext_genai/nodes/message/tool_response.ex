defmodule GenAI.Message.ToolResponse do
  @moduledoc """
  Represents a tool response in a message thread.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  #@derive GenAI.Thread.SessionProtocol
  defnodestruct(tool_name: nil, tool_response: nil, tool_call_id: nil)
  defnodetype(tool_name: term, tool_response: term, tool_call_id: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Message}

  defimpl GenAI.MessageProtocol do
    def message(message), do: message
    def content(_), do: :unsupported
  end

end
