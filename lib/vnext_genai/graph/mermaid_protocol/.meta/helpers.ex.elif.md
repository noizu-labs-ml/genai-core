# MermaidProtocol.Helpers

## Overview
The `GenAI.Graph.MermaidProtocol.Helpers` module provides utility functions for generating Mermaid diagrams from GenAI graph structures. These helpers make it easier to create consistent and well-formatted Mermaid diagram code.

## Functions

### mermaid_id/1
```elixir
@spec mermaid_id(term) :: term
```

Formats an ID to ensure compatibility with Mermaid diagram syntax. It primarily handles string IDs by replacing hyphens with underscores, which are more compatible with Mermaid's node ID requirements.

#### Parameters
- `id`: The ID to format for Mermaid compatibility

#### Returns
- Formatted ID suitable for use in Mermaid diagrams

### indent/1, indent/2
```elixir
@spec indent(string :: String.t()) :: String.t()
@spec indent(string :: String.t(), depth :: integer) :: String.t()
```

Indents a string by a specified depth (defaults to 1). This is useful for creating properly nested Mermaid diagram code.

#### Parameters
- `string`: The string to indent
- `depth` (optional): The indentation depth (defaults to 1)

#### Returns
- Indented string with each line prefixed by the appropriate number of spaces

### diagram_type/1
```elixir
@spec diagram_type(options :: term) :: atom
```

Returns the diagram type based on the provided options. Currently, it always returns `:state_diagram_v2`.

#### Parameters
- `options`: Options for determining the diagram type (currently unused)

#### Returns
- Atom representing the Mermaid diagram type (`:state_diagram_v2`)

## Usage
These helper functions are used by modules implementing the `GenAI.Graph.MermaidProtocol` to create consistent Mermaid diagram representations of GenAI graph structures.