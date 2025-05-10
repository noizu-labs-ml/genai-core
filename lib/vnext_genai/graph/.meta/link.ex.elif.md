# Graph.Link
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/graph/link.ex)

Link representation connecting nodes in a graph. Provides functionality for establishing and managing connections between nodes.

## Implementation
- Uses connector structure for source and target endpoints
- Provides ID and handle-based reference system
- Includes metadata fields for type, label, and description
- Follows result-based API pattern with ok/error tuples

## Key Components
- Source/target connectors for linking endpoints
- ID and handle management for unique identification
- Type and label functionality for relationship classification
- Connector conversion utilities for different input types

## Related
- [node.ex.elif.md](../graph/.meta/node.ex.elif.md) - Node implementation
- [graph.ex.elif.md](../../.meta/graph.ex.elif.md) - Graph implementation using links
- [node_protocol.ex.elif.md](../graph/node/.meta/node_protocol.ex.elif.md) - Node protocol