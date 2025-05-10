# ModelMetadata.DefaultProvider

## Overview
The `GenAI.ModelMetadata.DefaultProvider` module provides a default implementation for retrieving model metadata when a specific provider implementation isn't available or doesn't supply complete information.

## Functions

### get/3
```elixir
def get(scope, model, options \\ nil)
```

Retrieves basic model metadata with default information.

#### Parameters
- `scope`: The provider scope for the model
- `model`: The model identifier
- `options`: Additional options (unused in the default implementation)

#### Returns
- `{:ok, %GenAI.Model{}}`: A GenAI.Model struct with basic information:
  - `provider`: Set to the provided scope
  - `model`: Set to the provided model identifier
  - `details`: An empty `GenAI.ModelDetails{}` struct

## Usage
This default provider ensures that even when specific model metadata isn't available from a provider, a minimal model structure is still returned. This prevents errors when working with models that have limited metadata and provides a consistent interface regardless of the metadata's completeness.

It's typically used as a fallback when:
- A provider doesn't implement its own metadata provider
- A provider's metadata retrieval fails
- A model is specified that doesn't exist in the provider's official catalog