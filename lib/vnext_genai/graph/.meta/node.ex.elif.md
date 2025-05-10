# Graph.Node
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/graph/node.ex)

Base node representation for graph entities. Provides type checking and common node functionality.

## Implementation
- Uses NodeBehaviour for shared behavior definition
- Derives NodeProtocol for standard protocol compliance
- Provides type validation functionality

## Key Components
- Content field for storing node data
- Type validation functions for runtime type checking
- Node protocol implementation for standard operations

## Related
- [node_behaviour.ex.elif.md](node_behaviour.ex.elif.md) - Node behavior definition
- [node_protocol.ex.elif.md](node_protocol.ex.elif.md) - Node protocol definition
- [graph.ex.elif.md](../graph.ex.elif.md) - Graph implementation using nodes