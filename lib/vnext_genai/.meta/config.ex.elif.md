# Config
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/config.ex)

Configuration management for GenAI framework. Handles global and process-specific settings for the framework.

## Implementation
- Provides functions for managing configuration settings
- Supports different scopes (global/process) for configuration
- Enables configuration reset functionality

## Key Functions
- `reset/1` - Reset configuration for a specific scope

## Related
- [inference_provider_behaviour.ex.elif.md](inference_provider/inference_provider_behaviour.ex.elif.md) - Provider behavior using configuration
- [../genai.ex.elif.md](../.meta/genai.ex.elif.md) - Main module using configuration