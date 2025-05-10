# Session.Runtime
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/thread/session/runtime.ex)

Runtime state container for thread sessions. Tracks execution context and configuration during inference.

## Implementation
- Maintains command and configuration information
- Stores runtime data and metadata
- Supports monitoring through dedicated field
- Provides command application functionality

## Key Components
- Command field for execution strategy
- Config list for runtime parameters
- Data map for execution state
- Monitors map for runtime observers
- Meta map for additional information

## Related
- [../session.ex.elif.md](../session.ex.elif.md) - Session implementation using runtime
- [state.ex.elif.md](state.ex.elif.md) - State management for session
- [../../thread_protocol.ex.elif.md](../../thread_protocol.ex.elif.md) - Thread protocol definition