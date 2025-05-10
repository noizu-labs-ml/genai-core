# Tool.Schema.Enum
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type/enum.ex)

Enumeration schema type for JSON Schema. This module handles parameters that must be one of a predefined set of values.

## Purpose
Provides representation for enumerated values in tool schemas. Enums restrict a parameter to a limited set of possible string values, like choosing from a list of options.

## Key Components
- Type checking to identify enum schemas
- Enum array containing allowed values
- String-based implementation for value storage
- Description field for documentation

## Implementation
- Detects enums based on "enum" field presence
- Stores allowed values as a string array
- Uses string as the base type for the values
- Maintains documentation through description field

## Related
- [../type_behaviour.ex.elif.md](../type_behaviour.ex.elif.md) - Type behavior definition
- [string.ex.elif.md](string.ex.elif.md) - String type implementation
- [object.ex.elif.md](object.ex.elif.md) - Object type implementation