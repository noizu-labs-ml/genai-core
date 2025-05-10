# Message.Content.ToolResultContent
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/tool_result_content.ex)

Tool result representation for messages. Encapsulates responses from tool calls made by AI models within message content.

## Implementation
- Stores tool name and response data from function calls
- Includes reference to originating tool use ID
- Tracks timing information for caching and expiration
- Implements ContentProtocol for standardized access

## Key Components
- Tool name for function identification
- Tool use ID for call correlation
- Response data containing function results
- Timing fields for cache management (fetched_at, cached_at, expires_at)

## Related
- [../content_protocol.ex.elif.md](../content_protocol.ex.elif.md) - Content protocol definition
- [tool_use_content.ex.elif.md](tool_use_content.ex.elif.md) - Tool usage implementation
- [../../tool_usage.ex.elif.md](../tool_usage.ex.elif.md) - Tool usage implementation