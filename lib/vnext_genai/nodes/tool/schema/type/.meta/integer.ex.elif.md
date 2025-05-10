# Tool.Schema.Integer
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type/integer.ex)

Integer schema type for JSON Schema. This module handles whole number parameters in tools.

## Purpose
Provides representation and validation for integer values in tool schemas. Unlike the Number type, this specifically works with whole numbers and their constraints.

## Key Components
- Type checking to identify integer schemas
- Range constraints (minimum, maximum values)
- Multiple-of validation for divisibility rules
- Exclusive ranges for strict inequality checks

## Implementation
- Extracts constraints from JSON schema
- Provides clear validation rules for integers
- Enforces whole number requirements
- Maintains documentation through description field

## Related
- [../type_behaviour.ex.elif.md](../type_behaviour.ex.elif.md) - Type behavior definition
- [number.ex.elif.md](number.ex.elif.md) - General number type implementation
- [string.ex.elif.md](string.ex.elif.md) - String type implementation