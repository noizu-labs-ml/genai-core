# Project Layout (Summary)

`genai_core` — Elixir graph-based generative-AI toolkit. Dual API: `Genai` (legacy) + `VnextGenai` (current).

```text
genai-core/
├── lib/                  # Source → layout/lib.md (genai/ legacy; vnext_genai/ current incl. classifier/, pipeline/, thread/fork/)
├── config/               # config.exs, dev.exs, test.exs
├── test/                 # ExUnit: classifier, pipeline, fork suites + genai/, vnext_genai/, providers/, stream_handler/, support/
├── priv/media/           # Tracked test fixtures
├── docs/                 # PROJ-{LAYOUT,ARCH,SCHEMA}.md + THREAT-MODEL.md (+ summaries), classifier-pipelines.md, layout/
├── .github/workflows/    # elixir.yml CI (develop + stage)
├── .tool-versions        # erlang 28.4, elixir 1.19.5-otp-28, nodejs 20
├── .formatter.exs
├── mix.exs               # app :genai_core, v0.4.0
├── mix.lock
├── CHANGELOG.md / CONTRIBUTING.md / LICENSE / README.md
├── BOOK.md / TODO.md
└── AGENT.md / AGENTS.md / CLAUDE.md
```

Gitignored (not documented): `_build/`, `deps/`, `doc/`, `*.tar`, `cover/`, `.claude/worktrees/`.
