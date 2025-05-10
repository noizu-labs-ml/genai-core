# Message.Content.ToolUseContent
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/tool_use_content.ex)

Tool usage representation for messages. Encapsulates tool calls made by AI models within message content.

## Implementation
- Stores tool name and arguments for function calls
- Includes unique identifier for call tracking
- Implements ContentProtocol for standardized access
- Provides constructor for simplified creation

## Key Components
- Tool name for function identification
- Arguments map containing parameters
- ID field for unique reference
- ContentProtocol implementation for content access

## Related
- [../content_protocol.ex.elif.md](../content_protocol.ex.elif.md) - Content protocol definition
- [tool_result_content.ex.elif.md](tool_result_content.ex.elif.md) - Tool result implementation
- [../../tool_usage.ex.elif.md](../tool_usage.ex.elif.md) - Tool usage implementation