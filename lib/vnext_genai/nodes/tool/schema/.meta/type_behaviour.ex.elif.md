# Tool.Schema.TypeBehaviour
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type_behaviour.ex)

Behavior defining required functions for schema type implementations. Establishes common interface for JSON Schema type handling.

## Implementation
- Defines callbacks for type checking and JSON conversion
- Establishes foundation for schema validation system
- Enables polymorphic type handling across schema implementations

## Key Functions
- `is_type/1` - Check if a map represents the specific type
- `from_json/1` - Convert JSON schema representation to type struct

## Related
- [type.ex.elif.md](type.ex.elif.md) - Base type implementation
- [string.ex.elif.md](type/string.ex.elif.md) - String type implementation
- [object.ex.elif.md](type/object.ex.elif.md) - Object type implementation