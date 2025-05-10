# Records.Directive
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/records/directive.ex)

Record definitions for directive processing in GenAI. This module is like a box of small instruction cards used to tell the AI what to do.

## Purpose
Provides structured data types that represent different kinds of instructions (directives) used throughout the GenAI system. These are like small, specific notes that help organize settings, models, and messages.

## Key Components
- Hyperparameter definitions for model settings
- Entry selector records for different state components
- Value containers for concrete data values
- Type definitions for validation and documentation

## Record Types
- `hyper_param` - Defines AI model settings with validation rules
- Message, model, and tool entry records for state access
- Setting records for different configuration scopes
- Value records for concrete data representation

## Related
- [session/state.ex.elif.md](../../thread/session/state.ex.elif.md) - State using directives
- [session/state/directive.ex.elif.md](../../thread/session/state/directive.ex.elif.md) - Directive implementation
- [node.ex.elif.md](node.ex.elif.md) - Node records working with directives