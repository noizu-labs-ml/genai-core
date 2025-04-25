defmodule GenAI.Message.ToolUsage do
  @moduledoc """
  Represents a tool call in a message thread.
  """
  @vsn 1.0
  # @TODO struct for individual tool calls, Rename to ToolUsage
  require GenAI.Records.Directive
  import GenAI.Records.Directive
  
  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  #@derive GenAI.Thread.SessionProtocol
  defnodestruct(role: nil, content: nil, tool_calls: nil)
  defnodetype(role: term, content: term, tool_calls: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Message}
  
  def apply_node_directives(this, graph_link, graph_container, session, context, options)
  def apply_node_directives(this, _, _, session, context, options) do
    entry = message_entry(msg: this.id)
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end

  defimpl GenAI.MessageProtocol do
    def message(message), do: message
    def content(_), do: :unsupported
  end

end
