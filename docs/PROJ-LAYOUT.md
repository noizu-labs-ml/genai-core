# Project Layout

`genai_core` — Elixir library providing a graph-based generative-AI toolkit: dialogue/session
management, inference-provider abstraction, streaming, media jobs, and tool chaining.
Two API generations live side by side: `Genai` (legacy) and `VnextGenai` (current).

```text
genai-core/
├── lib/                        # Source → [layout/lib.md](layout/lib.md)
│   ├── genai/                  #   Legacy API (dialogue, graph, providers)
│   ├── genai.ex                #   Legacy top-level module
│   ├── vnext_genai/            #   Current API (graph, thread, nodes, media)
│   └── vnext_genai.ex          #   Current top-level module
├── config/                     # Mix config
│   ├── config.exs              #   Base config (loaded before deps)
│   ├── dev.exs                 #   Dev overrides
│   └── test.exs                #   Test overrides
├── test/                       # ExUnit suites
│   ├── genai/                  #   Legacy API tests
│   ├── vnext_genai/            #   Current API tests (graph, session, mermaid)
│   ├── providers/              #   Provider integration tests
│   ├── stream_handler/         #   SSE/stream handler tests
│   ├── support/                #   Test helpers + custom asserts
│   └── *_test.exs              #   Top-level suites (tools, media, dialogue)
├── docs/                       # Documentation
│   ├── PROJ-LAYOUT.md
│   ├── PROJ-LAYOUT.summary.md
│   └── layout/
├── .github/workflows/elixir.yml  # CI — mix format/check, credo, test matrix
├── .tool-versions              # asdf: erlang 28.4, elixir 1.19.5-otp-28, nodejs 20
├── .formatter.exs              # mix format rules
├── .gitignore
├── CHANGELOG.md                # Release history (0.3.x)
├── CONTRIBUTING.md             # Contribution guide
├── BOOK.md                     # Long-form design/book notes
├── TODO.md                     # Open work items
├── AGENT.md / AGENTS.md / CLAUDE.md  # Agent guidance for this repo
├── LICENSE
├── mix.exs                     # Project definition (app :genai_core, v0.3.4)
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
