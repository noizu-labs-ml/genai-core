# Types.Graph

## Overview
The `GenAI.Types.Graph` module provides type definitions and guards for the GenAI graph system, ensuring consistent type usage throughout the codebase.

## Type Definitions

### Graph Elements
- `@type graph :: term`: A GenAI.VNext.Graph object
- `@type graph_id :: term`: A GenAI.VNext.Graph object identifier
- `@type graph_link :: term`: A GenAI.VNext.Graph link object
- `@type graph_link_id :: term`: A GenAI.VNext.Graph link object identifier
- `@type graph_node :: term`: A GenAI.VNext.Graph node object
- `@type graph_node_id :: term`: A GenAI.VNext.Graph node object identifier

### Link Metadata
- `@type link_type :: term`: GenAI.VNext.Graph link type (e.g., comment, path, etc.)
- `@type link_label :: term`: GenAI.VNext.Graph link label (e.g., "Log Output")

## Guards

### is_graph_id/1
```elixir
defguard is_graph_id(id)
         when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)
```

A guard to check if a value is a valid Graph ID.

### is_node_id/1
```elixir
defguard is_node_id(id)
         when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)
```

A guard to check if a value is a valid Node ID.

### is_link_id/1
```elixir
defguard is_link_id(id)
         when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)
```

A guard to check if a value is a valid Link ID.

## Usage
These types and guards are used throughout the GenAI graph system to ensure type safety and provide clear documentation of expected data structures. The guards can be used in function declarations to enforce type constraints at compile time.