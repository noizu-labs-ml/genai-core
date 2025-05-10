# Records.Link
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/records/link.ex)

Record definitions for graph links in GenAI. These structures define how different parts of the AI system connect to each other.

## Purpose
Provides specialized data structures that represent connections between nodes in the graph. Think of these as the wires that connect different components together to form a complete system.

## Key Components
- Handle management for symbolic node references
- Element lookup structures for graph traversal
- Connector definitions for endpoint specification
- Context tracking during graph operations

## Record Types
- `graph_handle` - Named reference to graph elements with scope
- `element_context` - Container for node, link, and parent references
- `element_lookup` - Reference structure for element traversal
- `connector` - Connection point definition with socket information
- `anchor_link` - Special link type for anchored connections

## Related
- [graph/link.ex.elif.md](../../graph/link.ex.elif.md) - Link implementation
- [graph.ex.elif.md](../../graph.ex.elif.md) - Graph using links
- [node.ex.elif.md](node.ex.elif.md) - Node records connecting via links