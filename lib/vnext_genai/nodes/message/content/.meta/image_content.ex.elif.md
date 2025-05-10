# Message.Content.ImageContent
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/image_content.ex)

Image content representation for messages. Handles various image formats and sources for inclusion in GenAI messages.

## Implementation
- Supports multiple image sources (file, URI, base64, upload)
- Handles different image formats (png, jpeg, gif, etc.)
- Provides Base64 encoding for binary transfer
- Implements ContentProtocol for standardized access

## Key Functions
- `new/2` - Create image content from various sources
- `base64/2` - Encode image data to Base64
- `file_type/1` - Determine image type from extension
- `resolution/1` - Get image resolution information

## Related
- [../content_protocol.ex.elif.md](../content_protocol.ex.elif.md) - Content protocol definition
- [text_content.ex.elif.md](text_content.ex.elif.md) - Text content implementation
- [../../message.ex.elif.md](../../message.ex.elif.md) - Message implementation