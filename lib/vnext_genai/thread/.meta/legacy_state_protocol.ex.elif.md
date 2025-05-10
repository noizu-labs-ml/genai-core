# Thread.LegacyStateProtocol
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/thread/legacy_state_protocol.ex)

Protocol for thread state manipulation and introspection. Provides backward compatibility for older state management patterns.

## Implementation
- Defines methods for applying different node types to thread state
- Provides artifact storage and retrieval functionality
- Offers effective value resolution methods for runtime configuration
- Maintains compatibility with legacy thread implementations

## Key Functions
- State modification: `apply_model`, `apply_setting`, `apply_tool`
- Artifact handling: `set_artifact`, `get_artifact`
- State introspection: `effective_model`, `effective_settings`, `effective_messages`

## Related
- [thread_protocol.ex.elif.md](thread_protocol.ex.elif.md) - Main thread protocol
- [standard.ex.elif.md](standard.ex.elif.md) - Implementation using this protocol
- [state.ex.elif.md](state.ex.elif.md) - Thread state definition