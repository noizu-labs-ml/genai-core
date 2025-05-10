# Session.State
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/thread/session/state.ex)

Advanced state container for thread sessions. Manages directives, settings, and execution state for inference.

## Implementation
- Maintains directive stack with position tracking
- Stores thread messages and settings
- Provides structured access paths for different entry types
- Supports various state entry types through record patterns

## Key Components
- Directives list and position for execution tracking
- Settings maps for different scopes (general, model, provider, safety)
- Thread and message collections for conversation history
- Stack and data generators for advanced state management
- Tools and artifacts for execution extensions

## Related
- [runtime.ex.elif.md](runtime.ex.elif.md) - Runtime information for session
- [../session.ex.elif.md](../session.ex.elif.md) - Session implementation using state
- [directive.ex.elif.md](state/directive.ex.elif.md) - Directive implementation