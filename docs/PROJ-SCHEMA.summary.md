# Project Schema (Summary)

No relational store. Data model = Elixir structs + Erlang records + wire contracts.

| Kind | Core types |
|------|-----------|
| Thread/session state | `GenAI.Thread.State` (model/tools/settings/messages), `GenAI.Session.State` (directives, thread, monitors, artifacts) |
| Graph | `GenAI.Graph`, `Root`, `Link` |
| Messages | `Content.*`: Text(+`cache_control`), Image, Audio, Thinking, RedactedThinking, ToolUse, ToolResult, Document(+Text/Pdf/UrlPdfSource) |
| Completion results | `Choice`, `Usage` (+`cache_read_input_tokens`/`cache_creation_input_tokens`) |
| Classifiers | `Classifier.{Question, Request, Result}` — typed choice/boolean/score answers with distributions |
| Pipelines/forks | `Pipeline` (+`Branch`, `Frame`), `Thread.Fork` tree, `Fork.Result` leaf outcomes with ordered paths |
| Tool schema | `Schema.Type.*` JSON-Schema builders (Bool/Number/Object/Enum/Integer/Null/String) |
| Model metadata | `Details.*` (limits, pricing, capabilities, benchmarks) |
| Tools | Registry(+Entry), `Tool.Result`, ToolChain state |
| Records | `process_next/end/yield/error` signals; `graph_handle`, `element_context`; directive support entries |
| Config | Mix env-config split; `GenAI.Config` global/per-process |
| Wire | SSE `{:data, payload}` / `:done`; Anthropic/OpenAI handlers via `StreamHandler.Behaviour` |

```mermaid
graph LR
    Session --> Thread --> Messages & Tools
    Session --> Directives
    Pipeline --> Fork --> Branch --> Frame
    Classifier.Request --> Classifier.Result
    Graph --> Nodes --> SSE
    Tools --> ToolChain
```
