defmodule GenAI.Model do
  @moduledoc """
  Represents a Provider Model plus picker details and encoder.
  """

  @vsn 1.0
  
  require GenAI.Records.Directive
  import GenAI.Records.Directive
  
  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  #@derive GenAI.Thread.SessionProtocol
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
  
  
  def apply_node_directives(this, graph_link, graph_container, session, context, options)
  def apply_node_directives(this, _, _, session, context, options) do
    entry = model_entry()
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end



end

defimpl GenAI.ModelProtocol, for: [GenAI.Model] do

  def handle(subject), do: {:ok, subject.model}

  def encoder(subject), do: {:ok, subject.encoder || Module.concat([subject.provider, Encoder])}

  def provider(subject), do: {:ok, subject.provider}

  def name(subject), do: {:ok, subject.model}

  def encode_message(subject, message, thread_context, context, options) do
    with {:ok, encoder} <- encoder(subject) do
      encoder.encode_message(message, thread_context, context, options)
    end
  end

  def encode_tool(subject, tool, thread_context, context, options) do
    with {:ok, encoder} <- encoder(subject) do
      encoder.encode_tool(tool, thread_context, context, options)
    end
  end

  def register(subject, thread_context), do: {:ok, {subject, thread_context}}
end