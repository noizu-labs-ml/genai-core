# ChatCompletion
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/chat_completion.ex)

Representation of AI model response with choices and usage statistics. Encapsulates the result of a generative AI inference.

## Implementation
- Uses NodeBehaviour for graph integration
- Stores model response data including choices and usage
- Supports JSON conversion for API compatibility
- Preserves additional details in flexible structure

## Key Components
- Model and provider identification
- Response choices containing generated content
- Usage statistics for token consumption
- Details field for provider-specific metadata

## Related
- [choice.ex.elif.md](chat_completion/choice.ex.elif.md) - Choice implementation
- [usage.ex.elif.md](chat_completion/usage.ex.elif.md) - Usage statistics
- [model.ex.elif.md](model.ex.elif.md) - Model definition