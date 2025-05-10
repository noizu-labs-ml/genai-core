# Session.StateEntry
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/thread/session/state/state_entry.ex)

State entry structure for session state. Represents individual entries in the session state system.

## Purpose
Provides a container for values stored in the session state. Entries store the actual values modified by directives, with support for update operations.

## Key Components
- Value field for storing entry data
- Version tracking for compatibility
- Update handling for directive application
- Support for concrete value structures

## Implementation
- Simple structure focused on value storage
- Handles initialization of new entries
- Processes concrete value updates
- Preserves existing entry state during updates

## Related
- [directive.ex.elif.md](directive.ex.elif.md) - Directive implementation
- [../state.ex.elif.md](../state.ex.elif.md) - Session state structure
- [directive/directive_behaviour.ex.elif.md](directive/directive_behaviour.ex.elif.md) - Directive behavior