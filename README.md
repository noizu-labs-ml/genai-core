# Contributing
<!-- 〚📁:9b5636f2-d88a-5eeb-a2dc-77be1fe92423〛 genai-core README :: Entry point for the genai_core library: classifiers, pipelines, fork threads, tool sources. -->
Please feel free to submit an feature request/issues/clarification items you ahve under Issues! ^_^.

-----

GenAI Core Library
====

`genai_core` is the foundation package of the Noizu GenAI family (alongside
`genai`, `genai_approval`, and `ex_llama`): the protocols, threads, classifiers,
pipelines, and tool infrastructure shared by Noizu Elixir AI applications.

The current architecture lives under `lib/vnext_genai/` (the "VNext"
branch-by-abstraction layer). The modules it exposes are `GenAI.*`, and the
older `lib/genai/` structures (graph, inference provider, model metadata,
dialogue) remain as the legacy compatibility layer. New providers, settings,
and capabilities merge in through extender protocols — thread, model, encoder,
message/content, tool, and stream handler — without touching call sites, while
the `GenAI` entry module stays a stable surface for chat, streaming,
classification, media generation, and tool-chain execution.

Hosted providers (OpenAI, Anthropic, Gemini) are supported directly; local
model support is provided by the `ex_llama` sibling package, which builds on
`genai_core`.

## Installation

```elixir
def deps do
  [
    {:genai_core, "~> 0.4.0"}
  ]
end
```

## Classifiers and conversation pipelines

`GenAI.classify/2` supports typed choice, boolean and score decisions through
explicit classifier adapters. `GenAI.Pipeline` adds extraction, inference-assisted
preparation, transformations, result insertion, and isolated fork/join processing
with a global concurrency budget across nested branches.

See the [classifier pipeline guide](docs/classifier-pipelines.md) for standalone
and inline classification, agent postprocessing, evaluation forks and adapter
contracts. The existing `GenAI.run/1-3` and tool-chain behavior is preserved.

Forks are `GenAI.Thread.Fork` thread values: normal message/model/settings APIs,
inference, streaming and tool chains dispatch to isolated leaves. Results carry
ordered full branch paths, and partial failures retain successful siblings.

## Threads: standard and session

`GenAI.chat/2` opens a thread. `:default` and `:standard` create a
`GenAI.Thread.Standard` — a linear conversation thread holding messages,
settings, and model constraints in a compact state struct. `:session` creates a
`GenAI.Thread.Session`, the advanced VNext thread: sessions track directives
and a graph of nodes/links, carry runtime state, and surface optimization and
grid-search loops through `GenAI.execute/4` / `GenAI.report/3`.

Both thread types share the same builder and dispatch API — `GenAI.with_model/2`,
`GenAI.with_message/2-3`, `GenAI.with_setting/2-3`, `GenAI.run/1-3`, and friends —
routed through `GenAI.ThreadProtocol`, so code written against one thread type
works against the other.

## Streaming

`GenAI.stream/3` runs inference in streaming mode; interstitial (dynamic)
messages go to the thread's stream handler. Handlers implement
`GenAI.StreamHandler.Behaviour` (begin stream, event handling, finish
normalization) and can be overridden per thread with
`GenAI.with_stream_handler/3`. Built-in handlers decode provider SSE with a
pure incremental `feed/2` step — Anthropic and OpenAI normalization is built in
(`GenAI.StreamHandler.SSE` accumulates the final `GenAI.ChatCompletion` as
events arrive).

## Prompt cache usage

Since 0.3.5, `GenAI.ChatCompletion.Usage` carries `cache_read_input_tokens` /
`cache_creation_input_tokens`. OpenAI-compatible responses map
`usage.prompt_tokens_details.cached_tokens` to the read field, and the Anthropic
and OpenAI stream handlers pass cache usage through to accumulated completions.
Caching is requested per content part via the optional `cache_control` field on
`GenAI.Message.Content.TextContent` (consumed by the genai Anthropic encoder).

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

## Media generation (ADR-016)

`GenAI.generate_media/2` routes a `GenAI.Media.Request` to a provider that
declares support for its (input, output) modality and runs its
`generate_media/2`. Modalities cover text -> image/speech/music/sfx/video and
speech -> text (transcription). Sync providers return
`{:ok, %{data: binary, mime: String.t(), meta: map}}`; long-running providers
(music/video) return `{:ok, %GenAI.Media.Job{}}` for submit -> poll ->
download.

Providers register through an explicit modality registry — `config :genai,
:media_providers`, listing modules that implement `supported_modalities/0` — so
`GenAI.Media.Router` never hardcodes capabilities. Free-form chat/vision (image
input -> text generation) is not this path; it rides the normal chat/thread run
via the encoder protocol.

## Graphs and Mermaid

Session threads model advanced flows as graphs of nodes and links
(`GenAI.Graph.Node`, `GenAI.Graph.Link`) with a matching protocol for rendering
a graph as a Mermaid diagram (`GenAI.Graph.MermaidProtocol`), useful for inspecting
execution plans of optimization and grid-search loops.
