# Setting.ProviderSetting
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/setting/provider_setting.ex)

Provider-specific setting representation. Provides configuration for individual provider parameters.

## Implementation
- Extends base Setting with provider specification
- Uses NodeBehaviour for graph integration
- Implements directive application for session integration
- Provides custom inspection for debugging

## Key Components
- Provider field for targeting specific provider
- Setting field for parameter name
- Value field for parameter value
- Type compatibility with base Setting via do_node_type

## Related
- [../setting.ex.elif.md](../setting.ex.elif.md) - Base setting implementation
- [model_setting.ex.elif.md](model_setting.ex.elif.md) - Model-specific settings
- [safety_setting.ex.elif.md](safety_setting.ex.elif.md) - Safety-related settings