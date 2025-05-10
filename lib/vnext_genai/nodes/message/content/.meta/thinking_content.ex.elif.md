# Message.Content.ThinkingContent
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/thinking_content.ex)

Thinking process content for messages. Captures the AI model's internal reasoning process.

## Purpose
Provides a way to represent the AI's internal thought process or reasoning steps. This allows for more transparent and explainable AI interactions by exposing the model's thinking.

## Key Components
- Thinking field containing the reasoning process
- Signature field for verification or attribution
- Version tracking for compatibility

## Implementation
- Simple structure for thought process representation
- Implements ContentProtocol for standardized access
- Designed to expose model reasoning in a structured way

## Related
- [redacted_thinking_content.ex.elif.md](redacted_thinking_content.ex.elif.md) - Redacted thinking implementation
- [text_content.ex.elif.md](text_content.ex.elif.md) - Text content implementation
- [content_protocol.ex.elif.md](content_protocol.ex.elif.md) - Content protocol definition