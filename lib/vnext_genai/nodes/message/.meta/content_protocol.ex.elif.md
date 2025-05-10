# Message.ContentProtocol
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content_protocol.ex)

Protocol for handling different types of content in messages. Provides a unified interface for accessing message content regardless of type.

## Implementation
- Defines content retrieval method for message components
- Includes default implementation for BitString (text content)
- Enables polymorphic content handling across different types

## Key Functions
- `content/1` - Extract or convert content from message component

## Related
- [text_content.ex.elif.md](content/text_content.ex.elif.md) - Text content implementation
- [image_content.ex.elif.md](content/image_content.ex.elif.md) - Image content implementation
- [tool_use_content.ex.elif.md](content/tool_use_content.ex.elif.md) - Tool use content implementation