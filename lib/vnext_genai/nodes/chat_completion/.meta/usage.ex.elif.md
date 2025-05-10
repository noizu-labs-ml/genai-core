# ChatCompletion.Usage
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/chat_completion/usage.ex)

Token usage statistics for AI model completions. Tracks consumption metrics for billing and optimization.

## Purpose
Provides a standardized structure for recording token usage across different parts of the AI interaction. This information is critical for cost tracking and optimization.

## Key Components
- Prompt tokens count for input consumption
- Completion tokens count for output generation
- Total tokens for overall usage tracking

## Implementation
- Simple structure with token count fields
- Supports creation from maps and structs
- Filters fields to ensure valid structure
- Maintains consistent format across providers

## Related
- [../chat_completion.ex.elif.md](../chat_completion.ex.elif.md) - Parent completion containing usage stats
- [choice.ex.elif.md](choice.ex.elif.md) - Completion choices with usage
- [../../model.ex.elif.md](../../model.ex.elif.md) - Model that generates completions