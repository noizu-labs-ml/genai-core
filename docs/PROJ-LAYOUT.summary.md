# Project Layout (Summary)

`genai_core` — Elixir graph-based generative-AI toolkit. Dual API: `Genai` (legacy) + `VnextGenai` (current).

```text
genai-core/
├── lib/                  # Source → layout/lib.md (genai/ legacy, vnext_genai/ current)
├── config/               # config.exs, dev.exs, test.exs
├── test/                 # ExUnit: genai/, vnext_genai/, providers/, stream_handler/, support/
├── docs/                 # PROJ-LAYOUT.md + layout/
├── .github/workflows/    # elixir.yml CI
├── .tool-versions        # erlang 28.4, elixir 1.19.5-otp-28, nodejs 20
├── .formatter.exs
├── mix.exs               # app :genai_core, v0.3.4
├── mix.lock
├── CHANGELOG.md / CONTRIBUTING.md / LICENSE / README.md
├── BOOK.md / TODO.md
└── AGENT.md / AGENTS.md / CLAUDE.md
```

Gitignored (not documented): `_build/`, `deps/`, `doc/`, `*.tar`, `cover/`, `.claude/worktrees/`.
