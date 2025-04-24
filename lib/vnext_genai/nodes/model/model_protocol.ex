defprotocol GenAI.ModelProtocol do
  def handle(model)
  def encoder(model)
  def provider(model)
  def name(model)
  def encode_message(model, message, thread_context, context, options)
  def encode_tool(model, tool, thread_context, context, options)
  def register(model, state)
end