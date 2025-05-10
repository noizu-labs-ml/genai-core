# Provider.ModelsBehaviour

## Overview
The `GenAI.Provider.ModelsBehaviour` module defines a behaviour for loading model metadata from providers in the GenAI system. It standardizes how model information is retrieved across different providers.

## Callbacks

### load_metadata/1
```elixir
@callback load_metadata(options :: any) :: term
```

Loads metadata for models from a provider.

#### Parameters
- `options`: Configuration options for loading metadata

#### Returns
- Provider-specific model metadata

## Helper Functions

### load_metadata/2 (provider map)
```elixir
def load_metadata(%{provider: handler}, options)
```

Extracts the provider handler from a map and delegates to the handler's `load_metadata/1` function.

#### Parameters
- `%{provider: handler}`: Map containing a provider reference
- `options`: Configuration options for loading metadata

#### Returns
- Result of calling the provider's `load_metadata/1` function

### load_metadata/2 (direct handler)
```elixir
def load_metadata(handler, options)
```

Directly calls the handler's `load_metadata/1` function.

#### Parameters
- `handler`: Provider module
- `options`: Configuration options for loading metadata

#### Returns
- Result of calling the provider's `load_metadata/1` function

## Usage
This behaviour is implemented by provider modules to ensure a consistent interface for loading model metadata. It's used when:
- Initializing the GenAI system to load available models
- Refreshing model metadata at runtime
- Retrieving capability information for models