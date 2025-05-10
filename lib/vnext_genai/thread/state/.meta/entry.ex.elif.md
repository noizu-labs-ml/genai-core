# State.Entry

## Overview
The `GenAI.State.Entry` module represents a setting entry in the GenAI state, such as model, provider, or temperature settings applied through directives.

## Structure
```elixir
defstruct [
  # current effective value
  effective_value: :pending,
  # list of selectors set by directives to control how the effective entry is calculated.
  selectors: [],
  vsn: 1.0
]
```

## Fields
- `effective_value`: The current value for this setting, initially set to `:pending`
- `selectors`: A list of selectors set by directives that determine how the effective entry value is calculated
- `vsn`: Version number for the structure

## Functions

### apply_selector/2
```elixir
def apply_selector(this = %__MODULE__{}, selector) :: %__MODULE__{}
```

Applies a selector to the entry, updating the selectors list and resetting the effective value to `:pending`.

#### Parameters
- `this`: The current entry struct
- `selector`: The selector to apply

#### Returns
- Updated entry struct with the new selector and effective_value reset to `:pending`

## Usage
Used to manage individual setting values within the GenAI state, allowing for dynamic adjustments through directives and providing a way to calculate effective values based on multiple selector inputs.