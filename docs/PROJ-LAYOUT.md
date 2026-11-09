# Project Layout

`genai_core` — Elixir library providing a graph-based generative-AI toolkit: dialogue/session
management, inference-provider abstraction, streaming, media jobs, and tool chaining.
Two API generations live side by side: `Genai` (legacy) and `VnextGenai` (current).

```text
genai-core/
├── lib/                        # Source → [layout/lib.md](layout/lib.md)
│   ├── genai/                  #   Legacy API (dialogue, graph, providers)
│   ├── genai.ex                #   Legacy top-level module
│   ├── vnext_genai/            #   Current API (graph, thread, nodes, media, pipeline, classifier)
│   └── (no top-level vnext_genai.ex — see vnext_genai/ modules)
├── config/                     # Mix config
│   ├── config.exs              #   Base config (loaded before deps)
│   ├── dev.exs                 #   Dev overrides
│   └── test.exs                #   Test overrides
├── test/                       # ExUnit suites
│   ├── classifier_test.exs     #   Classifier router/validation suites
│   ├── pipeline_test.exs       #   Pipeline extraction/transform suites
│   ├── inference_extractor_test.exs #   Inference-assisted extraction
│   ├── fork_thread_test.exs    #   Fork thread dispatch suites
│   ├── fork_tool_chain_test.exs #   Fork-isolated tool chains
│   ├── genai/                  #   Legacy API tests
│   ├── vnext_genai/            #   Current API tests (graph, session, mermaid)
│   ├── providers/              #   Provider integration tests
│   ├── stream_handler/         #   SSE/stream handler tests
│   ├── support/                #   Test helpers + custom asserts
│   └── *_test.exs              #   Top-level suites (tools, media, dialogue)
├── priv/media/                 # Tracked test fixtures (provider_test image)
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md / PROJ-LAYOUT.summary.md
│   ├── PROJ-ARCH.md / PROJ-ARCH.summary.md
│   ├── PROJ-SCHEMA.md / PROJ-SCHEMA.summary.md
│   ├── THREAT-MODEL.md / THREAT-MODEL.summary.md
│   ├── classifier-pipelines.md #   Classifier + pipeline usage guide
│   └── layout/
├── .github/workflows/elixir.yml  # CI — mix format/check, credo, test matrix (develop + stage)
├── .tool-versions              # asdf: erlang 28.4, elixir 1.19.5-otp-28, nodejs 20
├── .formatter.exs              # mix format rules
├── .gitignore
├── CHANGELOG.md                # Release history (0.3.x → 0.4.0-unreleased)
├── CONTRIBUTING.md             # Contribution guide
├── BOOK.md                     # Long-form design/book notes
├── TODO.md                     # Open work items
├── AGENT.md / AGENTS.md / CLAUDE.md  # Agent guidance for this repo
├── LICENSE
├── mix.exs                     # Project definition (app :genai_core, v0.4.0)
├── mix.lock
└── README.md                   # Start here
```

Not tracked (gitignored, do not document further): `_build/`, `deps/`, `doc/` (ExDoc
output), `*.tar` release archives, `cover/`, `.claude/worktrees/`.

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `.tool-versions` | Ensure asdf-installed Erlang/Elixir match before building |
| `config/dev.exs` | Local dev overrides; add provider API keys via env, never commit |
