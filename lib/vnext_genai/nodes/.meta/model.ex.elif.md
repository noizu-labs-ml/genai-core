# Model
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/model.ex)

Representation of AI model with provider, encoder, and metadata. Core component for model selection and configuration.

## Implementation
- Uses NodeBehaviour for graph integration
- Stores provider, encoder, and model identifier
- Implements ModelProtocol for standardized access
- Supports directive application for session integration

## Key Components
- Provider reference for service selection
- Encoder reference for token handling
- Model identifier for specific implementation
- Details field for additional metadata

## Related
- [model_protocol.ex.elif.md](model/model_protocol.ex.elif.md) - Model protocol definition
- [external_model.ex.elif.md](model/external_model.ex.elif.md) - External model implementation
- [encoder_behaviour.ex.elif.md](model/encoder_behaviour.ex.elif.md) - Encoder behavior definition