# Tool.Schema.Null
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type/null.ex)

Null schema type for JSON Schema. This module handles parameters that should specifically be null.

## Purpose
Provides representation for null values in tool schemas. This type is used when a parameter must be explicitly null, rather than just optional or undefined.

## Key Components
- Type checking to identify null schemas
- Description field for documentation
- Simple structure with fixed value validation

## Implementation
- Extracts description from JSON schema
- Provides null type identification
- Implements TypeBehaviour for consistent interface
- Maintains type value "null" for schema validation

## Related
- [../type_behaviour.ex.elif.md](../type_behaviour.ex.elif.md) - Type behavior definition
- [bool.ex.elif.md](bool.ex.elif.md) - Boolean type implementation
- [string.ex.elif.md](string.ex.elif.md) - String type implementation