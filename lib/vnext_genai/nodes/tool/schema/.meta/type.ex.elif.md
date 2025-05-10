# Tool.Schema.Type
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type.ex)

Factory module for creating schema type instances from JSON Schema. Handles type detection and conversion for tool parameter schemas.

## Implementation
- Registers all available schema type implementations
- Provides factory method for JSON Schema conversion
- Uses type detection to select appropriate implementation
- Returns structured type representation for validation

## Key Functions
- `from_json/1` - Convert JSON schema to appropriate type struct

## Related
- [type_behaviour.ex.elif.md](type_behaviour.ex.elif.md) - Type behavior definition
- [string.ex.elif.md](type/string.ex.elif.md) - String type implementation
- [object.ex.elif.md](type/object.ex.elif.md) - Object type implementation