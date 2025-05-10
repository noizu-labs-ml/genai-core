# Message
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message.ex)

Unified message structure supporting various content types for GenAI interactions. Represents messages exchanged between users, assistants, and systems.

## Implementation
- Uses NodeBehaviour for graph integration
- Supports multiple content types (text, images, tools)
- Provides convenience constructors for common message types
- Implements MessageProtocol for standardized access

## Key Functions
- Role-specific constructors: `user()`, `assistant()`, `system()`
- Content type handling: `image()` for image resources
- Directive application for session integration

## Related
- [message_protocol.ex.elif.md](message/message_protocol.ex.elif.md) - Message protocol definition
- [content_protocol.ex.elif.md](message/content_protocol.ex.elif.md) - Content protocol
- [image_content.ex.elif.md](message/content/image_content.ex.elif.md) - Image content implementation