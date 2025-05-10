# Thread.State

Core data structure for storing thread configuration and state. Maintains settings, messages, and artifacts for thread operations.

## Structure
- `model`: Selected model(s) for inference
- `tools`: Available tools for the thread
- `settings`: General settings for thread execution
- `model_settings`: Model-specific settings
- `provider_settings`: Provider-specific settings
- `safety_settings`: Safety configuration
- `messages`: Thread messages collection
- `artifacts`: Additional data related to thread execution

## Related
- [thread_protocol.ex.elif.md](thread_protocol.ex.elif.md) - Protocol using this state
- [standard.ex.elif.md](standard.ex.elif.md) - Implementation using this state
- [legacy_state_protocol.ex.elif.md](legacy_state_protocol.ex.elif.md) - Protocol for state inspection