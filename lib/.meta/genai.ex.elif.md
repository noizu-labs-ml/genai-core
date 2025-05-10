# GenAI Module
[Source](/github/ai/genai_all/genai_core/lib/genai.ex)

## Purpose
Core entry point for the GenAI framework providing a unified API for LLM interactions. Implements a delegation pattern to abstract provider-specific implementations behind a consistent interface, enabling seamless access to various LLM providers through standardized thread contexts.

## Architecture
The module establishes a fluent interface for configuring inference contexts, handling message management, and executing inference operations. It delegates to protocol implementations while abstracting the underlying complexity of provider interactions, thread management, and execution strategies.

## Interface
```elixir
# Thread context initialization
chat(:default | :standard | :session, options \\ nil) 

# Thread configuration methods
with_model(thread_context, model)
with_tool(thread_context, tool)
with_setting(thread_context, setting, value)
with_message(thread_context, message, options \\ nil)

# Execution methods
run(thread_context, context, options \\ nil)    # Synchronous inference
stream(thread_context, context, options \\ nil) # Streaming inference
report(thread_context, context, options \\ nil) # Detailed execution report
```

## Related
- [thread_protocol.ex.elif.md](vnext_genai/thread/.meta/thread_protocol.ex.elif.md) - Protocol defining thread operation interfaces
- [standard.ex.elif.md](vnext_genai/thread/.meta/standard.ex.elif.md) - Default thread implementation
- [session.ex.elif.md](vnext_genai/thread/.meta/session.ex.elif.md) - Session-aware thread implementation