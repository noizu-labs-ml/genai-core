defprotocol GenAI.MessageProtocol do
  @moduledoc """
  Message normalization protocol.

  `message/1` resolves the canonical message representation of a value and
  `content/1` its content parts, so encoders and thread builders can
  introspect messages uniformly. Implemented by the message structs under
  `GenAI.Message` (messages, tool responses, tool usage) alongside the
  content protocols for the `GenAI.Message.Content.*` part types (text,
  image, audio, document, thinking, tool result, ...).
  """

  # <REMOVED UUID HERE> message :: auto-generated pointer for public function message
  def message(message)
  # <REMOVED UUID HERE> content :: auto-generated pointer for public function content
  def content(message)
end
