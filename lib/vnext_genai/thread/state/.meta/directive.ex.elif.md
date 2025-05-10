# State.Directive

## Overview
The `GenAI.State.Directive` module defines a directive that applies selection values to specified state entries, allowing for dynamic configuration of the GenAI state.

## Structure
```elixir
defstruct [
  # map of selector record to selection entry or entries.
  entries: %{},
  vsn: 1.0
]
```

## Fields
- `entries`: A map where keys are selector records and values are selection entries or collections of entries
- `vsn`: Version number for the structure

## Purpose
Directives provide a mechanism to modify state entries in a consistent way, allowing for:
- Changing model settings
- Adjusting provider configurations
- Updating runtime parameters
- Setting other session-specific values

## Usage
Directives are typically created and applied to a session state to influence how the GenAI system behaves. They work in conjunction with the `GenAI.State.Entry` module, which holds the actual values affected by directives.

When a directive is applied, it adds selectors to the relevant state entries, which then determine the effective values for those entries at runtime.