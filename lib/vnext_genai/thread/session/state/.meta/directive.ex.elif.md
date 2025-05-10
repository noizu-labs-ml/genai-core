# Session.State.Directive
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/thread/session/state/directive.ex)

Session state directive implementation. Provides operations for building and applying state changes through directives.

## Purpose
Enables modular and trackable state modifications in the session system through the directive pattern. Directives encapsulate specific state changes that can be applied, tracked and potentially reversed.

## Key Components
- Directive structure with source tracking
- Entry collection for multiple operations
- Fingerprinting for identification
- Application logic for state updates

## Implementation
- Creates directives with static value entries
- Applies directives to update state
- Handles special cases like message entries
- Uses state entry paths for targeted updates
- Supports directive fingerprinting for identification

## Related
- [state_entry.ex.elif.md](state_entry.ex.elif.md) - State entry implementation
- [directive_behaviour.ex.elif.md](directive/directive_behaviour.ex.elif.md) - Directive behavior
- [../../state.ex.elif.md](../../state.ex.elif.md) - Thread state structure