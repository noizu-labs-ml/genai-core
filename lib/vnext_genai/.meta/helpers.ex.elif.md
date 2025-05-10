# Helpers
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/helpers.ex)

Utility functions for common operations in the GenAI framework. Provides error handling, response labeling, and other helper functionality.

## Implementation
- Offers macros and functions for error handling
- Provides response labeling for debugging and tracing
- Follows functional programming patterns for response transformation
- Includes extensive documentation with examples

## Key Functions
- `with_label/2` - Label block response with macro
- `apply_label/2` - Label response directly
- `on_error/3` - Handle error responses with various strategies

## Related
- [inference_provider/helpers.ex.elif.md](inference_provider/helpers.ex.elif.md) - Inference provider helpers
- [thread/standard.ex.elif.md](thread/standard.ex.elif.md) - Standard thread implementation using helpers
- [graph.ex.elif.md](graph.ex.elif.md) - Graph implementation using helpers