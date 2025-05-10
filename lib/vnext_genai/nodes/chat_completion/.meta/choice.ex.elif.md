# ChatCompletion.Choice
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/chat_completion/choice.ex)

Individual completion choice from an AI model response. Represents a single generated response option.

## Purpose
Provides a structured representation for individual response alternatives from an AI model. Each choice includes the message content and metadata about how the response was terminated.

## Key Components
- Index for identifying the choice position
- Message containing the generated content
- Finish reason explaining why generation stopped
- Logprobs for token probability information

## Implementation
- Normalizes finish reasons across different providers
- Supports creation from maps and structs
- Maps provider-specific reason codes to standard format
- Maintains consistent structure regardless of source

## Related
- [../chat_completion.ex.elif.md](../chat_completion.ex.elif.md) - Parent completion containing choices
- [usage.ex.elif.md](usage.ex.elif.md) - Usage statistics for the completion
- [../../message.ex.elif.md](../../message.ex.elif.md) - Message implementation