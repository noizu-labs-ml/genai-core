# Inspect Implementation
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/inspect.ex)

Custom inspection implementation for GenAI types. Provides readable representations of complex graph objects.

## Purpose
Enhances debugging and exploration by providing detail-level control for inspecting GenAI objects. The implementation adapts output based on the context and verbosity requirements.

## Key Components
- Detail levels based on limit settings (low, medium, high, infinity)
- Support for multiple GenAI node types
- Special handling for Link visualization
- Connector formatting for source and target nodes

## Implementation
- Inspects objects with context-appropriate detail
- Uses struct-specific inspect_*_detail methods
- Provides compact link visualization for relationships
- Adapts verbosity based on context needs

## Related
- [../graph/link.ex.elif.md](../graph/link.ex.elif.md) - Link implementation with inspection
- [model.ex.elif.md](model.ex.elif.md) - Model with inspection support
- [setting.ex.elif.md](setting.ex.elif.md) - Setting with inspection support