# Setting.SafetySetting
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/setting/safety_setting.ex)

Safety setting representation for content moderation. Provides configuration for AI model content filtering.

## Implementation
- Extends base Setting with safety-specific fields
- Uses NodeBehaviour for graph integration
- Implements directive application for session integration
- Provides custom inspection for debugging

## Key Components
- Category field for harm category type
- Threshold field for blocking threshold level
- Type compatibility with base Setting via do_node_type
- Directive generation for safety settings

## Related
- [../setting.ex.elif.md](../setting.ex.elif.md) - Base setting implementation
- [model_setting.ex.elif.md](model_setting.ex.elif.md) - Model-specific settings
- [provider_setting.ex.elif.md](provider_setting.ex.elif.md) - Provider-specific settings