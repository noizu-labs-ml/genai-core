# MessageProtocol
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/message_protocol.ex)

Protocol defining operations for message entities. Provides a consistent interface for accessing message data regardless of implementation.

## Implementation
- Defines methods for message access and content retrieval
- Enables polymorphic message handling across different types
- Supports standardized message processing in the framework

## Key Functions
- `message/1` - Access or convert message entity
- `content/1` - Extract content from message entity

## Related
- [content_protocol.ex.elif.md](content_protocol.ex.elif.md) - Content handling protocol
- [../message.ex.elif.md](../message.ex.elif.md) - Message implementation
- [tool_usage.ex.elif.md](tool_usage.ex.elif.md) - Tool usage in messages