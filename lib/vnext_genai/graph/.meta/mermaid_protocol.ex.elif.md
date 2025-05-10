# MermaidProtocol

## Overview
The `GenAI.Graph.MermaidProtocol` protocol defines the interface for converting GenAI graph elements into Mermaid diagram representations. Mermaid is a markdown-based diagramming and charting tool that renders text definitions into diagrams.

## Callbacks

### mermaid_id/1
```elixir
@spec mermaid_id(term) :: term
```

Formats an ID for use in a Mermaid diagram, ensuring it follows Mermaid's syntax requirements.

#### Parameters
- `id`: The ID to format

#### Returns
- Formatted ID for Mermaid compatibility

### encode/1
```elixir
@spec encode(term) :: {:ok, term} | {:error, term}
```

Converts a graph element to Mermaid output with default options.

#### Parameters
- `graph_element`: The graph element to encode

#### Returns
- `{:ok, output}`: Successfully encoded Mermaid representation
- `{:error, reason}`: Error details if encoding fails

### encode/2
```elixir
@spec encode(term, term) :: {:ok, term} | {:error, term}
```

Converts a graph element to Mermaid output with specified options.

#### Parameters
- `graph_element`: The graph element to encode
- `options`: Options controlling the encoding process

#### Returns
- `{:ok, output}`: Successfully encoded Mermaid representation
- `{:error, reason}`: Error details if encoding fails

### encode/3
```elixir
@spec encode(term, term, term) :: {:ok, term} | {:error, term}
```

Converts a graph element to Mermaid output with options and state.

#### Parameters
- `graph_element`: The graph element to encode
- `options`: Options controlling the encoding process
- `state`: Current state for stateful encoding

#### Returns
- `{:ok, output}`: Successfully encoded Mermaid representation
- `{:error, reason}`: Error details if encoding fails

## Usage
This protocol is implemented by various graph elements to provide consistent conversion to Mermaid diagram syntax. This allows for visualization of complex graph structures through Mermaid diagrams.