# InferenceProviderBehaviour
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/inference_provider/inference_provider_behaviour.ex)

Behavior module defining the contract for AI model inference providers. Establishes the interface for provider implementations to interact with various AI services.

## Implementation
- Defines required callbacks for provider operations
- Provides default implementations through __using__ macro
- Facilitates standardized provider configuration
- Supports delegation to default provider for common functions

## Key Functions
- Core provider identification: `config_key`, `default_encoder`
- Request building: `headers`, `endpoint`, `request_body`
- Inference execution: `run`, `chat`
- Configuration management: `effective_settings`, `standardize_model`

## Related
- [default_provider.ex.elif.md](inference_provider/default_provider.ex.elif.md) - Default implementation
- [helpers.ex.elif.md](inference_provider/helpers.ex.elif.md) - Helper functions
- [../model.ex.elif.md](../nodes/model.ex.elif.md) - Model implementation