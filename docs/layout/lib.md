# lib/ — Detailed Layout

Two API generations coexist ("branch by abstraction"):

- `genai/` — legacy structures (kept for compatibility)
- `vnext_genai/` — current primary focus

```text
lib/
├── genai.ex                        # Legacy top-level convenience module
├── genai/                          # LEGACY API
│   ├── dialogue.ex                 #   Dialogue behaviour + schema/approval scripts
│   ├── dialogue/
│   │   ├── approval_script.ex      #     Scripted approval flows
│   │   └── schema.ex               #     Dialogue schema definitions
│   ├── graph/                      #   Legacy graph types
│   │   └── legacy.node_protocol.ex #     NodeProtocol compat shim
│   ├── inference_provider/         #   Legacy provider abstraction
│   │   └── model/                  #     Model defs (OpenAI, Anthropic, Gemini…)
│   └── model_meta_data/
│       ├── default_provider.ex     #     Default provider mapping
│       └── provider_behavior.ex    #     Metadata lookup behaviour
│
└── vnext_genai/                    # CURRENT API (primary focus)
        ├── config.ex               #   Library runtime config
        ├── helpers.ex              #   Shared helper functions
        ├── tool_chain.ex           #   Tool-chaining orchestration
        ├── classifier/             #   Typed classification
        │   ├── provider_behaviour.ex #  Adapter contract (classify/2 + capabilities)
        │   ├── question.ex         #     Decision: choice | boolean | score
        │   ├── request.ex          #     Provider-neutral classifier input
        │   ├── result.ex           #     Typed answers + distributions
        │   ├── router.ex           #     Explicit dispatch + validation
        │   └── validation.ex       #     Shared normalization helpers
        ├── error/
        │   └── request_error.ex    #     Typed request errors
        ├── graph/                  #   Computation graphs
        │   ├── graph.ex            #     Graph types + operations
        │   ├── exceptions.ex
        │   ├── link.ex             #     Node links/edges
        │   ├── root.ex             #     Graph root entrypoint
        │   ├── node/               #     Node implementations
        │   └── mermaid_protocol/   #     Mermaid diagram rendering of graphs
        ├── inference_provider/     #   Provider interfaces
        │   └── inference_provider/
        │       └── inference_provider_behaviour.ex
        ├── media/                  #   Media generation
        │   ├── job.ex              #     Media job tracking
        │   ├── request.ex          #     Media requests
        │   └── router.ex           #     Provider routing for media
        ├── nodes/                  #   Graph node types
        │   ├── chat_completion(.ex|/)  # Chat completion nodes
        │   ├── inspect.ex          #     Debug/inspection node
        │   ├── mermaid_protocol.ex #     Mermaid rendering for nodes
        │   ├── message(.ex|/)      #     Messages: content, tool usage
        │   ├── model(.ex|/)        #     Model reference nodes
        │   ├── setting(.ex|/)      #     Model/provider/safety settings
        │   └── tool(.ex|/)         #     Tool definitions + schemas
        ├── pipeline.ex             #   Conversation pipelines (immutable, branch-local)
        ├── pipeline/               #   Pipeline internals
        │   ├── branch.ex           #     Branch identity + isolation
        │   ├── frame.ex            #     Branch-local extracted values
        │   ├── inference_extractor.ex #  Isolated inference-assisted extraction
        │   ├── selector.ex         #     JSON-path / XPath / regex selectors
        │   └── snapshot.ex         #     Thread materialization + revisions
        ├── records/                #   Core records
        │   ├── directive.ex        #     Directive record
        │   ├── link.ex             #     Link record
        │   ├── node.ex             #     Node record
        │   └── session.ex.deprecated  #  Deprecated session record (kept for ref)
        ├── stream_handler/         #   Streaming responses
        │   ├── anthropic.ex        #     Anthropic SSE handler
        │   ├── open_ai.ex          #     OpenAI SSE handler
        │   ├── sse.ex              #     Generic SSE parsing
        │   └── behaviour.ex        #     Handler behaviour
        ├── thread/                 #   Conversation threads
        │   ├── fork.ex             #     Immutable fork trees (branch dispatch)
        │   ├── fork/               #     Fork results + streaming
        │   │   ├── result.ex       #       Leaf outcomes (ordered paths)
        │   │   └── stream.ex       #       Fork stream helpers
        │   ├── session(.ex|/)      #     Sessions: state + directives + runtime
        │   ├── state(.ex|/)        #     Immutable state, structured access
        │   ├── standard.ex         #     Standard thread impl (ThreadProtocol)
        │   ├── thread_protocol.ex  #     Main thread protocol
        │   └── *.legacy_state_protocol.ex  #  Legacy state compat shims
        ├── tool/
        │   ├── call.ex             #     Tool invocation records
        │   └── registry.ex         #     Tool registry
        └── types/                  #   Shared type specs
```

Key protocols/behaviours: `ThreadProtocol`, `NodeProtocol`, `MermaidProtocol`,
`DirectiveBehaviour`, `InferenceProvider` behaviour, `StreamHandler` behaviour,
`Classifier.ProviderBehaviour`.
