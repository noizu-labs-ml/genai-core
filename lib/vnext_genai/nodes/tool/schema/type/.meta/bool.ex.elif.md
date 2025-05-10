# Tool.Schema.Bool
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type/bool.ex)

Boolean schema type for JSON Schema. This module handles true/false values in tool parameters.

## Purpose
Provides representation for boolean parameters in tool schemas. This is one of the simplest schema types, supporting only true or false values with description.

## Key Components
- Type checking to identify boolean schemas
- Description field for documentation
- Simple structure with minimal validation needs

## Implementation
- Extracts description from JSON schema
- Provides boolean type identification
- Implements TypeBehaviour for consistent interface
- Maintains simplicity due to boolean's binary nature

## Related
- [../type_behaviour.ex.elif.md](../type_behaviour.ex.elif.md) - Type behavior definition
- [null.ex.elif.md](null.ex.elif.md) - Null type implementation
- [string.ex.elif.md](string.ex.elif.md) - String type implementation