# Tool.Schema.Object
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type/object.ex)

Object schema type implementation for JSON Schema. Handles complex object structures for tool parameters.

## Implementation
- Implements TypeBehaviour for object schema handling
- Recursively processes nested property schemas
- Handles object-specific constraints and validation rules
- Provides type detection and conversion from JSON

## Key Components
- Type identification for object schemas
- Properties map for nested schema definitions
- Required properties list for validation
- Additional properties control for extension
- Constraint fields (min_properties, max_properties)

## Related
- [../type_behaviour.ex.elif.md](../type_behaviour.ex.elif.md) - Type behavior definition
- [../type.ex.elif.md](../type.ex.elif.md) - Type factory implementation
- [string.ex.elif.md](string.ex.elif.md) - String type implementation