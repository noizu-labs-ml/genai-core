# ModelMetadata.ProviderBehaviour

## Overview
The `GenAI.ModelMetadata.ProviderBehaviour` module defines a behaviour for retrieving model metadata from providers. It standardizes how model information is accessed across different providers in the GenAI system.

## Callbacks

### get/2
```elixir
@callback get(scope :: module, model_name :: String.t()) :: {:ok, term} | {:error, term}
```

Retrieves metadata for a specific model from a provider without additional options.

#### Parameters
- `scope`: The provider scope/module
- `model_name`: The name of the model to retrieve metadata for

#### Returns
- `{:ok, model_metadata}`: Successfully retrieved model metadata
- `{:error, details}`: Error details if retrieval fails

### get/3
```elixir
@callback get(scope :: module, model_name :: String.t(), options :: term) ::
            {:ok, term} | {:error, term}
```

Retrieves metadata for a specific model from a provider with additional options.

#### Parameters
- `scope`: The provider scope/module
- `model_name`: The name of the model to retrieve metadata for
- `options`: Additional options for metadata retrieval

#### Returns
- `{:ok, model_metadata}`: Successfully retrieved model metadata
- `{:error, details}`: Error details if retrieval fails

## Helper Functions

### get/3
```elixir
def get(handler, scope, model)
```

Delegates to a handler's `get/2` function.

#### Parameters
- `handler`: The metadata provider module
- `scope`: The provider scope/module
- `model`: The model name

#### Returns
- Result of calling the handler's `get/2` function

### get/4
```elixir
def get(handler, scope, model, options)
```

Delegates to a handler's `get/3` function.

#### Parameters
- `handler`: The metadata provider module
- `scope`: The provider scope/module
- `model`: The model name
- `options`: Additional options

#### Returns
- Result of calling the handler's `get/3` function

## Usage
This behaviour is implemented by provider-specific metadata modules to ensure a consistent interface for retrieving model information. It standardizes how applications access model capabilities, limitations, and other metadata across different LLM providers.