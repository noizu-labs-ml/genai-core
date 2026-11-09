Change Log
==============

# Unreleased

- 2026-10-26: doc sweep 2026-10-26 — refreshed PROJ-LAYOUT/ARCH/SCHEMA + THREAT-MODEL (classifiers, pipelines, fork threads, prompt-cache usage fields; version 0.4.0; new threat entries T-009); doc-pointer seed (10 markers) landed via PR #20 into `develop`.

# 0.4.1 - Security Dependency Bumps

Published to hex as `genai_core` 0.4.1 on 2026-11-10.

- 2026-11-10: Dependency vulnerability sweep (`mix deps.audit` + `mix hex.audit`) — mint 1.7.1 → 1.11.0 (17 advisories, fix floor 1.9.0: CONTINUATION flood, PUSH_PROMISE growth, Content-Length parsing, CRLF injection and related HTTP/2/1 DoS and smuggling issues), hpax 1.0.3 → 1.1.0 (EEF-CVE-2026-58226 / GHSA-jj2p-32j7-whj2, unbounded HPACK integer decoding DoS), ymlr 5.1.4 → 5.1.6 (EEF-CVE-2026-65636 / GHSA-p8qx-7cp9-v6c9, YAML injection via newlines in document comments); added `mix_audit` as a dev dependency for ongoing audits. All minor/patch movement; full test suite green (109 doctests, 192 tests).

# 0.4.0 - Typed Classifiers, Conversation Pipelines, Fork Threads

Published to hex as `genai_core` 0.4.0 on 2026-10-18 (release ladder PRs #17/#18).

- 2026-10-17: First-class fork pipelines as threads (PR #16) — full thread API dispatch, bounded nested execution, branch-keyed results, isolated streaming/tool chains per leaf; merged → `develop` on 2026-10-17.
- 2026-10-16: Typed classifiers and conversation pipelines (PR #15) — typed choice/boolean/score decisions via explicit classifier adapters, required JSON/YAML serializers, safe aggregate serialization errors, guarded classifier capability callbacks, scoped develop CI (Core 0.4.0); merged → `develop` on 2026-10-17.

# 0.3.5 - Prompt Caching Usage
- Added `cache_read_input_tokens` / `cache_creation_input_tokens` to `GenAI.ChatCompletion.Usage`.
- OpenAI-compatible responses map `usage.prompt_tokens_details.cached_tokens` to `cache_read_input_tokens`.
- Anthropic/OpenAI stream handlers pass cache usage through to accumulated completions.
- Added optional `cache_control` field to `GenAI.Message.Content.TextContent` (consumed by the genai Anthropic encoder).
- Added dependency-neutral tool source registration for MCP clients, harnesses,
  and other external data/tool providers.
- Added an opt-in bounded tool-chain runner without changing `GenAI.run/1-3`.
- Added normalized tool calls/results and payload-safe lifecycle telemetry.

# 0.0.1 - Initial Release
- Initial Text Only Generation.

# 0.0.2 - Local Model Support
- Local LLama support added for pulling in gguf models for inference.

# 0.0.3 - Vision Support and Internal Structure Update 
Warning - This update may break existing code.

- Added Vision support for OpenAI, Gemini, and Anthropic. 
- Updated internal structure to allow for more advanced use cases such as prompt loops/fitness checks,
added support for how to handel local models, etc.

# 0.2.0 - Refactor
- Directed Graph Session to allow future advanced feature.
- Streamline how providers are added with use macros.
