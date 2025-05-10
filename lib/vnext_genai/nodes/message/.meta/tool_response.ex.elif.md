# Message.ToolResponse
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/tool_response.ex)

Tool response representation in message threads. Contains the results returned from tool execution.

## Purpose
Provides a structure for representing the outputs of tool calls within a conversation. Links tool responses back to their originating calls for coherent conversation flow.

## Key Components
- Tool name for function identification
- Tool response containing result data
- Tool call ID for linking to original request
- Node behavior for graph integration

## Implementation
- Uses NodeBehaviour for graph integration
- Implements type compatibility with Message
- Supports directive application for session state
- Provides custom inspection for debugging

## Related
- [tool_usage.ex.elif.md](tool_usage.ex.elif.md) - Tool usage representation
- [content/tool_result_content.ex.elif.md](content/tool_result_content.ex.elif.md) - Tool result content
- [content/tool_use_content.ex.elif.md](content/tool_use_content.ex.elif.md) - Tool usage content