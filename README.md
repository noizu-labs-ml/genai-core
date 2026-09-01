# Contributing
Please feel free to submit an feature request/issues/clarification items you ahve under Issues! ^_^. 

-----

GenAI Core Library
====

GenAI Core contains base protocols used by GenAI to simplify the process of 
merging in new features and functionality from
the genai_core_vnext repo. 

The intent of the core library is to isolate out core functionality to make 
extensibility more straight forward and to
isolate the exllama support as an add to make using with livebook more straight 
forward.

## Tool sources and bounded chains

`GenAI.Tool.Registry` lets an application expose tools from MCP clients,
in-process harnesses, databases, or other sources without adding those
dependencies to `genai_core`. An adapter implements two callbacks:

```elixir
defmodule MyApp.MCPTools do
  @behaviour GenAI.Tool.Source

  def list_tools(client, context, options) do
    # Return GenAI.Tool values or MCP-shaped maps with name, description, and
    # inputSchema/parameters.
    MyMCPClient.list_tools(client, context, options)
  end

  def call_tool(client, name, arguments, context, options) do
    MyMCPClient.call_tool(client, name, arguments, context, options)
  end
end

{:ok, registry} =
  GenAI.Tool.Registry.new()
  |> GenAI.Tool.Registry.register(:project_mcp, MyApp.MCPTools, client, context)

{:ok, {completion, thread, summary}} =
  GenAI.run_with_tools(thread, registry, context,
    max_iterations: 8,
    max_tool_calls: 32,
    timeout: 15_000
  )
```

Model-facing names are deterministic and namespaced by default, for example
`project_mcp__search`. Unsupported characters become `_`, and a normalized-name
collision returns `{:error, {:tool_name_collision, name}}`. Callers must opt in
to `collision: :keep` or `collision: :replace` to choose another policy.

The chain runner is explicit and does not change `GenAI.run/1-3`. It caps
configured limits at 64 inference iterations, 256 total tool calls, and 120
seconds per call. Source exceptions, exits, timeouts, calls, and results are
normalized through `GenAI.Tool.Call` and `GenAI.Tool.Result`.

### Telemetry and payload safety

Lifecycle events are emitted under these prefixes when the optional
`:telemetry` module is available:

- `[:genai, :tool_source, :register, :start | :stop | :exception]`
- `[:genai, :tool, :execute, :start | :stop | :exception]`
- `[:genai, :tool_chain, :run, :start | :stop | :exception]`

Consumers without `:telemetry` can pass a three-argument function using the
`telemetry:` option. Metadata contains names, IDs, status, bounds, and counts;
tool arguments and results are excluded by default. Set
`include_payloads: true` only where those values are safe to observe.
