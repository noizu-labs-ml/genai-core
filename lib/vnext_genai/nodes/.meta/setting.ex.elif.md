# Setting
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/setting.ex)

Base setting representation for configuration in graph. Provides key-value storage for settings that affect inference execution.

## Implementation
- Uses NodeBehaviour for graph integration
- Stores setting name and value pairs
- Implements directive application for session integration
- Provides custom inspection for debugging

## Key Components
- Setting field for parameter name
- Value field for parameter value
- Directive creation for thread state integration
- Graph node compatibility through protocol derivation

## Related
- [setting/model_setting.ex.elif.md](setting/model_setting.ex.elif.md) - Model-specific settings
- [setting/provider_setting.ex.elif.md](setting/provider_setting.ex.elif.md) - Provider-specific settings
- [setting/safety_setting.ex.elif.md](setting/safety_setting.ex.elif.md) - Safety-related settings