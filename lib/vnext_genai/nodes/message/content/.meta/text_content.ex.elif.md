# Message.Content.TextContent
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/text_content.ex)

Text content representation for messages. Provides structure for text-based message content with metadata.

## Implementation
- Stores text message content with type information
- Supports citation tracking for referenced sources
- Implements ContentProtocol for standardized access
- Provides constructor for simplified creation

## Key Components
- Text storage for message content
- Type categorization (input, prompt, documentation, etc.)
- Citation support for reference tracking
- System flag for system-level messages

## Related
- [../content_protocol.ex.elif.md](../content_protocol.ex.elif.md) - Content protocol definition
- [image_content.ex.elif.md](image_content.ex.elif.md) - Image content implementation
- [../../message.ex.elif.md](../../message.ex.elif.md) - Message implementation