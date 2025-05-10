# ExternalModel
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/model/external_model.ex)

Representation of an externally managed model. Provides access to models hosted in external systems or local processes.

## Implementation
- Uses NodeBehaviour for graph integration
- Stores reference to external resource and manager
- Implements ModelProtocol for standardized access
- Supports directive application for session integration

## Key Components
- Resource handle for external model reference
- Manager reference for lifecycle management
- Configuration for model parameters
- Standard model fields (provider, encoder, model name)

## Related
- [model_protocol.ex.elif.md](model_protocol.ex.elif.md) - Model protocol definition
- [encoder_behaviour.ex.elif.md](encoder_behaviour.ex.elif.md) - Encoder behavior definition
- [../model.ex.elif.md](../model.ex.elif.md) - Standard model implementation