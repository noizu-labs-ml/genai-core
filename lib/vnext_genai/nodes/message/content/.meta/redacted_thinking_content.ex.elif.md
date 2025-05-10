# Message.Content.RedactedThinkingContent
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/redacted_thinking_content.ex)

Redacted thinking content for messages. Provides a placeholder for thoughts that should not be directly visible.

## Purpose
Offers a way to indicate that thinking content exists but should not be directly exposed to users. This enables hiding internal processes while still maintaining their presence in the message structure.

## Key Components
- Data field for storing redacted information
- Version tracking for compatibility

## Implementation
- Minimal structure with redacted data field
- Implements ContentProtocol for standardized access
- Designed to maintain structure while hiding content

## Related
- [thinking_content.ex.elif.md](thinking_content.ex.elif.md) - Thinking content implementation
- [text_content.ex.elif.md](text_content.ex.elif.md) - Text content implementation
- [content_protocol.ex.elif.md](content_protocol.ex.elif.md) - Content protocol definition