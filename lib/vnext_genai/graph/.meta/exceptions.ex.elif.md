# Graph.Exception

## Overview
The `GenAI.Graph.Exception` module defines a generic exception structure for graph-related errors in the GenAI system.

## Structure
```elixir
defexception message: nil, details: nil
```

## Fields
- `message`: A string describing the error
- `details`: Additional information about the error

## Usage
This exception is used throughout the GenAI graph system to provide standardized error handling for various graph operations. It encapsulates both a human-readable message and structured details for programmatic error handling.

Example:
```elixir
raise GenAI.Graph.Exception, message: "Invalid node reference", details: %{node_id: "123", error: :not_found}
```