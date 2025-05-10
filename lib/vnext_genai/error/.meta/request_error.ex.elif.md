# RequestError
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/error/request_error.ex)

Exception for request errors in the GenAI framework. Provides standardized error handling for API requests.

## Implementation
- Uses Elixir's exception system
- Includes message for human-readable error descriptions
- Stores details for additional error context
- Simplifies error propagation across the framework

## Key Components
- Message field for error description
- Details field for structured error data
- Exception behavior for stack trace and error handling

## Related
- [../inference_provider/inference_provider_behaviour.ex.elif.md](../inference_provider/inference_provider_behaviour.ex.elif.md) - Provider behavior using request errors
- [../helpers.ex.elif.md](../helpers.ex.elif.md) - Helper functions for error handling