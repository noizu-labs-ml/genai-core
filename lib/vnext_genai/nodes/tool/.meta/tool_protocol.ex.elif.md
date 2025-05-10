# ToolProtocol
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/tool_protocol.ex)

Protocol for tool identification and operations. Provides a consistent interface for accessing tool information.

## Implementation
- Defines method for tool name retrieval
- Enables polymorphic tool handling across implementations
- Supports standardized tool access in the framework

## Key Functions
- `name/1` - Retrieve the name of a tool

## Related
- [../tool.ex.elif.md](../tool.ex.elif.md) - Tool implementation
- [schema/type.ex.elif.md](schema/type.ex.elif.md) - Schema type system
- [../../message/content/tool_use_content.ex.elif.md](../../message/content/tool_use_content.ex.elif.md) - Tool usage in messages