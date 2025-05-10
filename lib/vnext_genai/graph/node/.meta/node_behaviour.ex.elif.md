# NodeBehaviour

## Overview
The `GenAI.Graph.NodeBehaviour` module defines the behavior that graph node elements must adhere to. It provides callbacks that nodes must implement and helper macros for defining node types and structures.

## Callbacks
- `new/0`: Creates a new node instance
- `new/1`: Creates a new node with the specified options
- `id/1`: Gets the node's identifier
- `handle/1`: Gets the node's handle
- `handle/2`: Gets the node's handle with a default value
- `name/1`: Gets the node's name
- `name/2`: Gets the node's name with a default value
- `description/1`: Gets the node's description
- `description/2`: Gets the node's description with a default value

## Helper Macros

### defnodetype/1
Defines the type of a node with default fields included. This macro automatically includes common fields like `:id`, `:handle`, `:name`, `:description`, `:inbound_links`, `:outbound_links`, `:finger_print`, `:meta`, and `:vsn`.

Example:
```elixir
defnodetype [
  internal: boolean,
]
```

### defnodestruct/1
Defines the struct of a node with default fields included. This macro automatically includes common fields like `:id`, `:handle`, `:name`, `:description`, `:outbound_links`, `:inbound_links`, `:finger_print`, `:meta`, and `:vsn`.

Example:
```elixir
defnodestruct [
  value: nil,
]
```

## Usage via __using__
When a module uses `GenAI.Graph.NodeBehaviour`, it automatically:
1. Implements the `GenAI.Graph.NodeBehaviour` behavior
2. Imports the `defnodestruct/1` and `defnodetype/1` macros
3. Sets up appropriate delegates to the node protocol provider
4. Makes the common node functions available

Example:
```elixir
defmodule MyNode do
  use GenAI.Graph.NodeBehaviour
  
  # Node implementation details...
end
```