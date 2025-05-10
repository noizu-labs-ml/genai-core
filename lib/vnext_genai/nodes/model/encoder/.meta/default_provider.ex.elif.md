# Model.Encoder.DefaultProvider
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/model/encoder/default_provider.ex)

Default implementation for model encoder behavior. Provides standard request formatting and parameter handling.

## Purpose
Offers a default implementation of the encoder functionality needed to prepare API requests for models. This handles common tasks like authentication, parameter formatting, and request body construction.

## Key Components
- Request header preparation with authentication
- Request body construction for inference
- Hyperparameter application with validation
- Sentinel checks for conditional parameters
- Value adjusters for parameter modification

## Implementation
- Authentication handling from various sources
- Dynamic hyperparameter application with renaming
- Parameter validation through sentinels
- Value adjustment through customizable functions
- Hierarchical settings resolution

## Related
- [../encoder_behaviour.ex.elif.md](../encoder_behaviour.ex.elif.md) - Encoder behavior definition
- [../../model.ex.elif.md](../../model.ex.elif.md) - Model implementation using encoder
- [../../../inference_provider/inference_provider_behaviour.ex.elif.md](../../../inference_provider/inference_provider_behaviour.ex.elif.md) - Provider behavior