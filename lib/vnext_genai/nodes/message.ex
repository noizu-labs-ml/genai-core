defmodule GenAI.Message do
  @moduledoc """
  Struct for representing a chat message.
  """
  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(role: nil, content: nil)
  defnodetype(role: term, content: term)

  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = message_entry(msg: this.id)
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end

  def message(role, message, options \\ nil) do
    options = Keyword.merge(options || [], role: role, content: message)
    new(options)
  end

  def user(message, options \\ nil) do
    message(:user, message, options)
  end

  def system(message, options \\ nil) do
    message(:system, message, options)
  end

  def assistant(message, options \\ nil) do
    message(:assistant, message, options)
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
      Enum.map(content, &GenAI.Message.ContentProtocol.content(&1))
    end
  end
end
