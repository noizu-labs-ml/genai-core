# AGENT.md — genai-core

Guidance for **Codex**, **Grok**, **Cursor**, and other `AGENTS.md` / `AGENT.md` tools.

Claude Code loads [CLAUDE.md](./CLAUDE.md). Same policy; this file is the harness-shaped sibling (numbered MUST first, markdown headings). If both this file and a parent `AGENTS.md` load, **this file wins on conflict**.

## MUST (every turn)

1. **Identity**: core LLM client package of the Noizu genai family (with `ai/genai`, `ai/genai-approval`, `ai/ex_llama`); marketed at elixirgenai.dev; consumed by most Noizu Elixir AI apps. Monorepo coupling map: trl-infra `docs/SUBS.md`.
2. **Trinity Protocol REQUIRED**: each response = Orientation → Friction → Response. Full text: monorepo `protocols/the-trinity-protocol.md`.
3. **No shell in main thread** — delegate to taskers; summarize, never dump raw output.
## Worktrees — Canonical Convention (REQUIRED)

All work happens on git worktrees, created from **this repo's own `.git`** — never work directly on a shared checkout of `develop`/`main`.

- **Placement (fixed):** every worktree lives inside this repo's checkout at **`.claude/worktrees/<name>/`** — never siblings (`<repo>.worktrees/`), never ad-hoc paths. Matches Claude Code's native worktree tooling, so harness-created and manual worktrees coexist.
- **Naming:** `<name>` = branch name with `/` → `-` (branch `feature/vfs-wave1` → `.claude/worktrees/feature-vfs-wave1`).
- **Creation** — from this repo's own `.git`, based on `develop` (never `main`):
  ```bash
  git -C <this-repo> worktree add .claude/worktrees/<name> -b <branch> develop
  ```
- **Hygiene:** `.claude/worktrees/` is gitignored in this repo; never commit its contents. One worktree per task; remove it when the work lands (`git worktree remove .claude/worktrees/<name>` — keep the branch).
- **Addressing:** `git -C <this-repo>/.claude/worktrees/<name> …`; verify branch + clean index before any git write; no `git stash`.
- **Elixir projects:** the MAIN checkout owns `deps/` + `_build/`; each worktree symlinks `deps` (and `_build` where needed) to the canonical checkout by **absolute path** — no per-worktree re-fetch/recompile.
- **Legacy placements** (`.worktrees/`, `.wt/`, `<repo>.worktrees/` siblings, `staging/`) are grandfathered — do not create new ones; migrate opportunistically. `staging/` remains local-only experiments (never pushed/submoduled).
- **Branch & PR policy unchanged:** worktree branches fork from `develop`; PRs target `develop`; `main` is CI/CD-only (automation merges only).


5. **Hex discipline**: published package — version bump + changelog before publish; see monorepo CLAUDE.md for OSS licensing rule (MIT/Apache/BSD-class only).
6. Node.js: 23.3.0 (if needed for assets)
7. **PRs target `develop`.** Never merge or push `main` (CI/CD-only release path).

## Project Overview

GenAI Core is an Elixir library that provides base protocols and structures for generative AI functionality. It uses a "Branch by Abstraction" pattern with vnext structures to isolate core functionality and make extensibility more straightforward.

## Common Development Commands

### Build and Dependencies
```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Clean build artifacts
mix clean
```

### Testing
```bash
# Run all tests
mix test

# Run specific test file
mix test test/path/to/test_file.exs

# Run tests with specific tag (e.g., :session)
mix test --only session

# Run tests with coverage
mix test --cover
```

### Code Quality
```bash
# Format code
mix format

# Run static analysis (Dialyzer) - if configured
mix dialyzer

# Generate documentation
mix docs
```

## Architecture Overview

### Directory Structure

The codebase follows a dual-structure approach with legacy and vnext implementations:

- **`lib/genai/`** - Legacy implementation structures
  - `graph/` - Graph-related functionality
  - `inference_provider/` - Provider abstractions
  - `model_meta_data/` - Model metadata handling

- **`lib/vnext_genai/`** - Next generation structures (primary focus)
  - `error/` - Error handling (e.g., RequestError)
  - `graph/` - Graph implementations with Mermaid protocol support
  - `inference_provider/` - Provider interfaces
  - `nodes/` - Various node types:
    - `chat_completion/` - Chat completion nodes
    - `message/` - Message handling with content and tool usage
    - `setting/` - Model, provider, and safety settings
    - `tool/` - Tool definitions and schemas
  - `records/` - Core record types (Directive, Node, Link)
  - `thread/` - Thread management:
    - `session/` - Session handling with state management
    - `state/` - State and directive handling

### Key Protocols and Behaviors

- **ThreadProtocol** - Main protocol for thread operations
- **DirectiveBehaviour** - Behavior for implementing directives
- **NodeProtocol** - Protocol for graph nodes
- **MermaidProtocol** - Protocol for generating Mermaid diagrams

### Core Concepts

1. **Sessions** (`GenAI.Thread.Session`) - Manage conversation state, directives, and runtime
2. **Directives** - Commands that modify session state
3. **Graph Structure** - Nodes and links forming computation graphs
4. **State Management** - Immutable state with structured access paths

### Testing Approach

- Tests use ExUnit with async capability
- Module tags for organization (e.g., `@moduletag :session`)
- Test fixtures defined within test modules
- Custom assertions in `test/support/custom_asserts.ex`

## Key Dependencies

- **noizu_labs_core** - Core utility library
- **jason** - JSON parsing
- **floki** - HTML parsing
- **finch** - HTTP client
- **ex_doc** - Documentation generation (dev only)
- **dialyxir** - Static analysis (dev only)

## Development Environment

Required versions (from .tool-versions):
- Erlang: 26.2.5.6
- Elixir: 1.16.3-otp-26

## Branch & PR Policy

- Submodules sit on **`develop`** — keep your checkout on `develop`.
- All PRs target **`develop`** (feature/bug/task branches fork from `develop`).
- **`main` is CI/CD-only**: CI/CD automation performs all merges into `main` (release path). Never merge to or push `main` by hand.
