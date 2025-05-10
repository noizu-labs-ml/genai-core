# Standard.LegacyStateProtocol Implementation
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/thread/standard.legacy_state_protocol.ex)

Implementation of the LegacyStateProtocol for Standard thread type. Provides state management for the standard thread context.

## Purpose
Handles state operations for the standard thread implementation, including state mutation, state inspection, and effective value resolution. This enables the thread to maintain and access its configuration state.

## Key Components
- State modification methods for various node types
- Effective value resolution for runtime configuration
- Message and tool encoding with provider-specific format
- Artifact storage and retrieval for thread data

## Implementation
- Organizes settings in hierarchical structure
- Uses stacks for priority-based selection
- Processes messages with provider-specific encoding
- Formats tools according to model requirements
- Maintains safety settings for content filtering

## Related
- [standard.ex.elif.md](standard.ex.elif.md) - Standard thread implementation
- [legacy_state_protocol.ex.elif.md](legacy_state_protocol.ex.elif.md) - Protocol definition
- [state.ex.elif.md](state.ex.elif.md) - Thread state structure