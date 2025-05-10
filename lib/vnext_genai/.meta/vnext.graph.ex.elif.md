# VNext.Graph

## Overview
The `GenAI.VNext.Graph` module defines a graph data structure for representing AI graphs, threads, conversations, UML diagrams, and other structured data. It provides comprehensive functionality for creating, modifying, and traversing graph structures.

## Structure
```elixir
defnodetype(
  nodes: %{T.Graph.graph_node_id() => T.Graph.graph_node()},
  node_handles: %{T.handle() => T.Graph.graph_node_id()},
  links: %{T.Graph.graph_link_id() => T.Graph.graph_link()},
  link_handles: %{T.handle() => T.Graph.graph_link_id()},
  head: T.Graph.graph_node_id() | nil,
  last_node: T.Graph.graph_node_id() | nil,
  last_link: T.Graph.graph_link_id() | nil
)
```

## Key Functions

### Node Management
- `add_node/3`: Adds a node to the graph
- `attach_node/3`: Attaches a node to the graph and links it to the last inserted item
- `node/2`: Retrieves a node by ID
- `nodes/2`: Retrieves all nodes in the graph
- `by_handle/2`: Retrieves a node by handle
- `member?/2`: Checks if a node is a member of the graph
- `head/1`: Gets the head node of the graph
- `last_node/1`: Gets the last added node of the graph

### Link Management
- `add_link/3`: Adds a link to the graph
- `link/2`: Retrieves a link by ID
- `link_by_handle/2`: Retrieves a link by handle
- `last_link/1`: Gets the last added link of the graph

### Settings Management
- `setting/4`: Retrieves a setting with fallback to defaults
- Various internal helper functions for setting management

### Node Processing
- `process_node/6`: Processes a node in the graph, delegating to the node's protocol
- `do_process_node/6`: Handles the recursive processing of nodes based on process responses

## Settings
The graph supports several configuration settings:
- `auto_head`: Automatically set new nodes as head if no head exists
- `update_last`: Update the last_node pointer when adding nodes
- `update_last_link`: Update the last_link pointer when adding links
- `auto_link`: Automatically link new nodes to the last node

## Mermaid Protocol Implementation
The module implements the `GenAI.Graph.MermaidProtocol` for rendering graphs as Mermaid diagrams, supporting:
- State diagram visualization (stateDiagram-v2)
- Node and link representation
- Entry point highlighting

## Usage
This graph structure serves as a foundation for various GenAI components, providing:
1. A way to represent structured data as graphs
2. Support for traversing and manipulating graph structures
3. Mechanisms for processing graph nodes in sequence
4. Visualization capabilities through Mermaid diagrams