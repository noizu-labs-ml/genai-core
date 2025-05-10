# Records.Node
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/records/node.ex)

Record definitions for node processing states in GenAI. These special structures tell the system what to do next when processing nodes in a graph.

## Purpose
Provides structured data types that represent the different states and transitions that can occur during node processing. Think of these as traffic signals that direct the flow of processing.

## Key Components
- Process flow control records for graph traversal
- Error handling structures for failure cases
- Session state tracking during processing
- Yield mechanisms for asynchronous operations

## Record Types
- `process_next` - Signal to continue to the next node
- `process_end` - Signal that processing is complete
- `process_yield` - Signal to pause processing temporarily
- `process_error` - Signal that an error occurred during processing

## Related
- [graph.ex.elif.md](../../graph.ex.elif.md) - Graph using node records
- [vnext.graph.ex.elif.md](../../vnext.graph.ex.elif.md) - Advanced graph using node records
- [directive.ex.elif.md](directive.ex.elif.md) - Directive records working with nodes