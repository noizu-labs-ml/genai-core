# Tool
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool.ex)

Representation of a function that can be called by AI models. Provides schema definition for tool parameters and metadata.

## Implementation
- Uses NodeBehaviour for graph integration
- Supports JSON schema for parameter definition
- Implements directive application for session integration
- Provides serialization/deserialization from JSON and YAML

## Key Components
- Name and description for tool identification
- Parameters schema for function signatures
- JSON Schema compatibility for cross-provider support
- ToolProtocol implementation for standardized access

## Related
- [tool_protocol.ex.elif.md](tool/tool_protocol.ex.elif.md) - Tool protocol definition
- [schema/type.ex.elif.md](tool/schema/type.ex.elif.md) - Schema type system
- [message/tool_use_content.ex.elif.md](message/content/tool_use_content.ex.elif.md) - Tool usage in messages