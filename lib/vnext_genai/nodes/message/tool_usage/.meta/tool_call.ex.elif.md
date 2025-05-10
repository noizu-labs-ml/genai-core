# Message.ToolCall
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/tool_usage/tool_call.ex)

Individual tool call representation. Defines a single function call from an AI model.

## Purpose
Provides a structured representation for individual function/tool calls made by AI models. This enables capturing specific function invocations with their arguments.

## Key Components
- ID field for unique call identification
- Type field for categorizing calls (default: function)
- Tool name identifying the function to call
- Arguments map containing call parameters

## Implementation
- Simple structure for function call representation
- JSON serialization support for API integration
- Maintains type information for extensibility
- Arguments stored as map for flexibility

## Related
- [../tool_usage.ex.elif.md](../tool_usage.ex.elif.md) - Parent tool usage
- [../../content/tool_use_content.ex.elif.md](../../content/tool_use_content.ex.elif.md) - Tool use content
- [../../tool_response.ex.elif.md](../../tool_response.ex.elif.md) - Response to tool calls