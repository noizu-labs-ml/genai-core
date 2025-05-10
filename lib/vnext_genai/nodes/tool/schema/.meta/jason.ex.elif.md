# Jason.Encoder for Schema Types
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/jason.ex)

JSON encoding implementation for GenAI schema types. Enables serialization to JSON format for API communications.

## Purpose
Provides JSON serialization capabilities for tool and schema types. This allows these structures to be properly encoded when making API requests to AI providers that use JSON Schema for tool definitions.

## Key Components
- Tool encoding with name, description, and parameters
- Schema type encoding with appropriate field filtering
- Version field exclusion for cleaner output
- Nil value filtering for concise representation

## Implementation
- Uses Jason library for efficient JSON encoding
- Filters internal-only fields from serialization
- Handles all schema types through a shared implementation
- Preserves JSON Schema compatibility in output

## Related
- [type.ex.elif.md](type.ex.elif.md) - Schema type system
- [type/object.ex.elif.md](type/object.ex.elif.md) - Object schema implementation
- [../tool.ex.elif.md](../tool.ex.elif.md) - Tool implementation