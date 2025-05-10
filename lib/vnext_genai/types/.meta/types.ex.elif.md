# Types

## Overview
The `GenAI.Types` module defines core type specifications used throughout the GenAI system. It provides consistent type definitions for common data structures and function return values.

## Type Definitions

### Element Attributes
- `@type handle :: term`: Element handle used for referencing elements
- `@type name :: term`: Element name
- `@type description :: term`: Element description
- `@type finger_print :: term`: Element fingerprint used for change detection

### Error Handling
- `@type details :: tuple | atom | bitstring()`: Error details
- `@type ok(r) :: {:ok, r}`: Success response with result value
- `@type error(e) :: {:error, e}`: Error response with error details
- `@type result(r, e) :: ok(r) | error(e)`: Function return type representing either success or failure

## Usage
These type definitions are used throughout the GenAI system to provide consistent type annotations and ensure type safety. They represent common patterns and structures in the codebase.

The `result(r, e)` type is particularly important as it represents the standard return value pattern for functions that might fail, allowing for consistent error handling with pattern matching.

Example usage:
```elixir
@spec get_element(id :: String.t()) :: GenAI.Types.result(Element.t(), :not_found | :invalid_id)
def get_element(id) do
  case lookup_element(id) do
    nil -> {:error, :not_found}
    element -> {:ok, element}
  end
end
```