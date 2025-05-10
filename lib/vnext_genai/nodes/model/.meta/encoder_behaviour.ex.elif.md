# Model.EncoderBehaviour
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/model/encoder_behaviour.ex)

Behavior module defining the contract for model encoders. Establishes the interface for transforming requests and responses between the framework and provider APIs.

## Implementation
- Defines callbacks for request and response transformation
- Provides default implementations through __using__ macro
- Handles message and tool encoding for provider compatibility
- Supports dynamic setting configuration based on model capabilities

## Key Functions
- Request preparation: `headers`, `endpoint`, `request_body`
- Response handling: `completion_response`
- Format conversion: `encode_tool`, `encode_message`, `normalize_messages`
- Settings management: `with_dynamic_setting`, `hyper_params`

## Related
- [model_protocol.ex.elif.md](model_protocol.ex.elif.md) - Model protocol definition
- [default_provider.ex.elif.md](encoder/default_provider.ex.elif.md) - Default encoder implementation
- [../model.ex.elif.md](../model.ex.elif.md) - Model implementation