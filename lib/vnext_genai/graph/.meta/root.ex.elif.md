# Graph.Root

## Overview
The `GenAI.Graph.Root` module defines the root data structure that contains nested graphs, nodes, and other structures. It provides a comprehensive lookup and traversal mechanism for working with graph elements by ID or handle.

## Structure
```elixir
defstruct [
  # Entry Point
  graph: nil,
  # uuid => element_lookup, handle => {:resolver, %{paths => element_entry}} | element_entry
  lookup_table: %{by_element: %{}, by_handle: %{}},
  # id of last inserted node
  last_node: nil,
  # id of last inserted link
  last_link: nil
]
```

## Key Functions

### Element Lookup
- `element_entry/2`: Retrieves an element lookup entry by element ID
- `handle_entry/3`: Retrieves an element lookup entry by handle and optional base node
- `nearest_handle_entry/3`: Retrieves the closest nested handle under a specified base
- `element/2`: Retrieves a nested element by ID from the graph
- `element_by_handle/3`: Retrieves a nested element by handle from the graph
- `get_nested_element/2`: Extracts a nested entry by path from a source element

### Lookup Table Operations
- `merge_lookup_table_entries/2`: Merges element lookup entries into the lookup table
- `merge_handles/2`: Merges a list of handle entries into the lookup table
- `merge_handle/2`: Merges a single graph handle entry into the lookup table

### Graph Context
- `graph_context_by_link/3`: Retrieves graph context by link and source element
- Various helper functions for resolving different types of graph contexts

### Node Processing
- `process_node/6`: Processes a node within the graph, updating the session with the root and delegating processing to the node

## Usage
The `GenAI.Graph.Root` is the foundational structure for working with complex nested graphs in the GenAI system. It provides:

1. A hierarchical representation of graph elements
2. Fast lookup by ID and handle
3. Context-aware handle resolution (global, standard, and local scopes)
4. Traversal of the graph structure by path
5. Processing of graph nodes within a session context