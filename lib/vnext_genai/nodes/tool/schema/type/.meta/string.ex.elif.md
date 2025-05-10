# Tool.Schema.String
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type/string.ex)

String schema type implementation for JSON Schema. Handles string validation constraints for tool parameters.

## Implementation
- Implements TypeBehaviour for string schema handling
- Converts JSON Schema string attributes to Elixir struct
- Handles string-specific constraints (length, pattern, format)
- Provides type detection and conversion from JSON

## Key Components
- Type identification for string schemas
- Description field for documentation
- Validation constraints (min_length, max_length, pattern)
- Format specification (email, date-time, etc.)

## Related
- [../type_behaviour.ex.elif.md](../type_behaviour.ex.elif.md) - Type behavior definition
- [../type.ex.elif.md](../type.ex.elif.md) - Type factory implementation
- [object.ex.elif.md](object.ex.elif.md) - Object type implementation