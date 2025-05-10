# Setting.ModelSetting
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/setting/model_setting.ex)

Model-specific setting representation. Provides configuration for individual model parameters.

## Implementation
- Extends base Setting with model specification
- Uses NodeBehaviour for graph integration
- Implements directive application for session integration
- Provides custom inspection for debugging

## Key Components
- Model field for targeting specific model
- Setting field for parameter name
- Value field for parameter value
- Type compatibility with base Setting via do_node_type

## Related
- [../setting.ex.elif.md](../setting.ex.elif.md) - Base setting implementation
- [provider_setting.ex.elif.md](provider_setting.ex.elif.md) - Provider-specific settings
- [safety_setting.ex.elif.md](safety_setting.ex.elif.md) - Safety-related settings