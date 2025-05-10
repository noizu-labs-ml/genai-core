# InferenceProvider.Helpers

## Overview
The `GenAI.InferenceProvider.Helpers` module provides utility functions for making API calls and managing settings when working with LLM providers. These helpers simplify common tasks related to API communication and parameter handling.

## API Call Functions

### api_call/5
```elixir
@doc """
Make API Call Via Finch.
"""
def api_call(type, url, headers, body \\ nil, options \\ [])
```

Makes an API call using Finch, handling JSON serialization of the request body.

#### Parameters
- `type`: HTTP method (e.g., `:post`, `:get`)
- `url`: API endpoint URL
- `headers`: HTTP headers
- `body`: Request body (will be JSON encoded if not nil)
- `options`: Additional options for the request

#### Returns
- `{:ok, response}`: Successful response
- Raises `GenAI.RequestError` if JSON encoding fails

## Settings Management Functions

### with_required_setting/3
```elixir
@doc """
Set required setting or raise RequestError if not present.
"""
def with_required_setting(body, setting, settings)
```

Adds a required setting to the request body, raising an error if not present.

#### Parameters
- `body`: The request body map
- `setting`: The setting key
- `settings`: Map of available settings

#### Returns
- Updated body with the setting
- Raises `GenAI.RequestError` if the setting is missing

### optional_field/3
```elixir
@doc """
Set optional field if present.
"""
def optional_field(body, _, nil)
def optional_field(body, field, value)
```

Adds an optional field to the request body if the value is not nil.

#### Parameters
- `body`: The request body map
- `field`: The field key
- `value`: The field value

#### Returns
- Updated body with the field if value is not nil

### with_setting/4
```elixir
@doc """
Apply setting or default value if not present.
"""
def with_setting(body, setting, settings, default \\ nil)
```

Adds a setting to the request body, using a default value if not present.

#### Parameters
- `body`: The request body map
- `setting`: The setting key
- `settings`: Map of available settings
- `default`: Default value if setting is not present

#### Returns
- Updated body with the setting

### with_setting_as/5
```elixir
@doc """
Apply setting as_setting or default value if not present.
"""
def with_setting_as(body, as_setting, setting, settings, default \\ nil)
```

Adds a setting to the request body under a different key, using a default value if not present.

#### Parameters
- `body`: The request body map
- `as_setting`: The key to use in the request body
- `setting`: The setting key in the settings map
- `settings`: Map of available settings
- `default`: Default value if setting is not present

#### Returns
- Updated body with the setting under the specified key

## Internal Helpers

### finch_options/1
Configures Finch options for API calls, including timeouts.

## Usage
These helper functions are used throughout the inference provider implementation to simplify API communication and parameter handling when making requests to LLM providers.