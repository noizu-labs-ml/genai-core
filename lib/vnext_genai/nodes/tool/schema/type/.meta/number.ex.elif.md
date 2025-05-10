# Tool.Schema.Number
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/tool/schema/type/number.ex)

Number schema type for JSON Schema. This module helps tools understand when a parameter should be a number (like 1.5 or 42).

## Purpose
Handles numeric validation for tool parameters, ensuring numbers are within expected ranges and formats. It turns JSON descriptions of numbers into structured Elixir types that can be validated.

## Key Components
- Type checking to identify number schemas
- Range constraints (minimum, maximum values)
- Multiple-of validation for divisibility rules
- Exclusive ranges for strict inequality checks

## Implementation
- Extracts constraints from JSON schema
- Provides clear validation rules
- Supports both integers and floating-point numbers
- Maintains documentation through description field

## Related
- [../type_behaviour.ex.elif.md](../type_behaviour.ex.elif.md) - Type behavior definition
- [integer.ex.elif.md](integer.ex.elif.md) - Integer-specific type
- [string.ex.elif.md](string.ex.elif.md) - String type implementation