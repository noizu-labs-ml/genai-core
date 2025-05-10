# Graph

Data structure for representing relationships between GenAI nodes. Provides functionality for node management, link tracking, and traversal.

## Implementation
- Maintains collections of nodes and links with unique identifiers
- Tracks head node and last node/link for efficient access
- Supports handle-based reference system for symbolic access
- Provides traversal and processing capabilities

## Key Components
- Node management with ID generation and handle mapping
- Link management for tracking relationships between nodes
- Processing model following visitor pattern
- Custom inspection for debugging

## Related
- [graph/node.ex.elif.md](graph/node.ex.elif.md) - Node implementation
- [graph/link.ex.elif.md](graph/link.ex.elif.md) - Link implementation
- [graph/node_protocol.ex.elif.md](graph/node_protocol.ex.elif.md) - Node protocol