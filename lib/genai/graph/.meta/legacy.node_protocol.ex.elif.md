# Legacy.NodeProtocol

## Overview
The `GenAI.Legacy.NodeProtocol` defines a protocol for applying different node types to a thread context in the GenAI system. It provides a consistent interface for various node types to modify thread state through a single `apply/2` function.

## Protocol Definition
```elixir
defprotocol GenAI.Legacy.NodeProtocol do
  def apply(node, thread_context)
end
```

### apply/2
Applies a node to a thread context, potentially modifying the thread state.

#### Parameters
- `node`: The node to apply
- `thread_context`: The current thread context

#### Returns
- `{:ok, thread_context}`: Updated thread context after applying the node
- `{:error, details}`: Error details if application fails

## Implementations

### For GenAI.Graph.Node
Provides a default no-op implementation that simply returns the thread context unchanged.

### For GenAI.Tool
Delegates to `GenAI.Thread.LegacyStateProtocol.apply_tool/2` to apply a tool to the thread context.

### For GenAI.Setting and its subtypes
Delegates to specific methods in `GenAI.Thread.LegacyStateProtocol` based on the setting type:
- `GenAI.Setting`: `apply_setting/2`
- `GenAI.Setting.SafetySetting`: `apply_safety_setting/2`
- `GenAI.Setting.ModelSetting`: `apply_model_setting/2`
- `GenAI.Setting.ProviderSetting`: `apply_provider_setting/2`

### For GenAI.Model and GenAI.ExternalModel
Handles model registration and application to the thread context:
1. Checks if the model implements `GenAI.ModelProtocol`
2. If it does, registers the model with the thread context
3. Applies the registered model to the thread context
4. If it doesn't, applies the model directly

### For GenAI.Message, GenAI.Message.ToolUsage, and GenAI.Message.ToolResponse
Delegates to `GenAI.Thread.LegacyStateProtocol.apply_message/2` to apply messages to the thread context.

### For GenAI.Graph
Applies all nodes in the graph to the thread context in sequence, stopping on the first error.

## Usage
This protocol provides a unified interface for applying various node types to a thread context, simplifying the integration of different components within the GenAI system. It's particularly useful for processing complex structures like graphs and ensuring consistent behavior across different node types.