# ThreadProtocol

Core protocol defining interface for thread context operations. Establishes contracts for thread implementations, enabling consistent interaction patterns regardless of thread type.

## Key Functions
- Configuration: `with_model`, `with_tool`, `with_setting`
- Authentication: `with_api_key`, `with_api_org`
- Message handling: `with_message`, `with_messages`
- Execution: `execute` (run/stream/report)
- Introspection: `effective_model`, `effective_settings`

## Related
- [standard.ex.elif.md](standard.ex.elif.md) - Standard implementation
- [session.ex.elif.md](session.ex.elif.md) - Session-based implementation
- [state.ex.elif.md](state.ex.elif.md) - Thread state management