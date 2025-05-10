# ModelProtocol
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/model/model_protocol.ex)

Protocol defining operations for model entities. Provides a consistent interface for accessing model information and services.

## Implementation
- Defines methods for model identification and access
- Enables provider and encoder resolution
- Supports model registration with thread state
- Enables polymorphic model handling across implementations

## Key Functions
- `handle/1` - Retrieve model identifier
- `encoder/1` - Get token encoder for the model
- `provider/1` - Get provider implementation for the model
- `name/1` - Get model name for display
- `register/2` - Register model with thread state

## Related
- [../model.ex.elif.md](../model.ex.elif.md) - Model implementation
- [encoder_behaviour.ex.elif.md](encoder_behaviour.ex.elif.md) - Encoder behavior definition
- [external_model.ex.elif.md](external_model.ex.elif.md) - External model implementation