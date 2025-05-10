# Thread.Standard

Default thread implementation providing basic GenAI interaction context. Implements ThreadProtocol with a graph-based approach to storing configuration nodes, messages, and settings.

## Implementation
- Maintains thread state through `graph` field containing linked nodes
- Uses `append_node` to add configuration items to the graph
- Delegates execution to appropriate provider based on effective model
- Delegates state inspection methods to LegacyStateProtocol

## Key Components
- Node validation ensures only valid entity types are added to the graph
- Provider selection happens at runtime based on effective model
- Settings resolution follows hierarchical override pattern

## Related
- [thread_protocol.ex.elif.md](thread_protocol.ex.elif.md) - Protocol definition
- [legacy_state_protocol.ex.elif.md](legacy_state_protocol.ex.elif.md) - State inspection
- [graph.ex.elif.md](../../graph.ex.elif.md) - Graph implementation