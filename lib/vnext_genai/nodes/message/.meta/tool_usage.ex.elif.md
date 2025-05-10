# Message.ToolUsage
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/tool_usage.ex)

Tool usage representation in message threads. Contains the tool calls made by AI models.

## Purpose
Provides a structure for representing tool calls within a conversation. This enables capturing function calls requested by the AI model as part of message handling.

## Key Components
- Role field identifying the caller (usually assistant)
- Content containing text related to tool usage
- Tool calls collection with individual function calls
- User field for optional user identification

## Implementation
- Uses NodeBehaviour for graph integration
- Implements type compatibility with Message
- Supports directive application for session state
- Provides custom inspection with length optimization

## Related
- [tool_response.ex.elif.md](tool_response.ex.elif.md) - Tool response representation
- [tool_usage/tool_call.ex.elif.md](tool_usage/tool_call.ex.elif.md) - Individual tool call
- [content/tool_use_content.ex.elif.md](content/tool_use_content.ex.elif.md) - Tool usage content