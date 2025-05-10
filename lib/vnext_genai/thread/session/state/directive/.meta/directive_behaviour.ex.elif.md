# DirectiveBehaviour

## Overview
This behaviour module defines the contract for directive modules that can be applied to a GenAI session state.

## Key Callbacks

### apply_directive/4
```elixir
@callback apply_directive(directive :: any, session :: any, context :: any, options :: any) ::
            {:ok, session :: any} | {:error, details :: any}
```

Applies a directive to a session state within a given context.

#### Parameters
- `directive`: The directive to apply
- `session`: The current session state
- `context`: Context information for applying the directive
- `options`: Additional options for directive application

#### Returns
- `{:ok, session}`: The updated session state after successfully applying the directive
- `{:error, details}`: Error details if directive application fails

## Implementation Notes
Modules implementing this behaviour should provide specific logic for modifying session state based on the directive type and content.