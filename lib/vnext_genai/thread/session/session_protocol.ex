defprotocol GenAI.Thread.SessionProtocol do
  def process_node(graph_node, scope, context, options)
end

defimpl GenAI.Thread.SessionProtocol, for: Any do
  require GenAI.Records.Session
  alias GenAI.Records.Session, as: Node

  defmacro __deriving__(module, _, options) do
    options = Macro.escape(options)
    quote do
      defimpl GenAI.Thread.SessionProtocol, for: unquote(module) do
        @provider unquote(options[:provider]) || GenAI.Thread.SessionProtocol.DefaultProvider
        defdelegate process_node(graph_node, scope, context, options), to: @provider
      end
    end
  end
end




