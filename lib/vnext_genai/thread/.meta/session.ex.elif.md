# Thread.Session

Advanced thread implementation with directive handling capability. Extends basic thread functionality with state management, directives processing, and runtime configuration.

## Implementation
- Uses root graph and state separation for better structure
- Maintains directive stack for deferred operations 
- Implements directive application mechanism
- Enhanced node handling with ID generation

## Key Components
- Directive system for sequence-aware operations
- Runtime context for advanced execution configurations
- Graph node uniqueness through generated IDs

## Related
- [thread_protocol.ex.elif.md](thread_protocol.ex.elif.md) - Protocol definition
- [session/state.ex.elif.md](session/state.ex.elif.md) - Session state implementation
- [session/runtime.ex.elif.md](session/runtime.ex.elif.md) - Runtime management