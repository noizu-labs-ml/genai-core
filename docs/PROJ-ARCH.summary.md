# Project Architecture (Summary)

Pure Elixir genai library — no own infrastructure; consumed by Noizu Elixir AI apps.

- **Pattern**: branch by abstraction — `Genai` (legacy) + `VnextGenai` (current, all new work); legacy shims keep old callers alive.
- **Layers**: ThreadProtocol API → Session (immutable state + directive replay) → Graph (nodes/links, NodeBehaviour) → Providers (InferenceProvider + StreamHandler behaviours, SSE parsing) ; separate media router.
- **Classifiers**: `GenAI.classify/2` — typed choice/boolean/score decisions via explicit `Classifier.ProviderBehaviour` adapters; capability-checked, no implicit chat fallback.
- **Pipelines**: `GenAI.Pipeline` — immutable extraction/transform flows, branch-local frames, selectors (JSON-path/XPath/regex, no shell); fork/join over `GenAI.Thread.Fork` trees (≤64 uniquely-id branches, isolated leaves, joins require `:reduce`/`:select`/`:append`); extraction turns are discarded.
- **Media**: explicit modality registry (`config :genai, :media_providers`); providers declare `supported_modalities/0`; router never hardcodes capabilities (ADR-016 D4).
- **Streaming**: pure incremental SSE `feed/2`; Anthropic/OpenAI normalization behind `StreamHandler.Behaviour`; prompt-cache usage fields flow through to accumulated completions.
- **Models**: metadata-driven pickers (`smartest`/`cheapest`) resolve at inference time.
- **Stack**: Elixir 1.19/OTP 28, Finch, Jason, ymlr/yaml_elixir, SweetXml, Floki, noizu_labs_core; ExUnit CI.
- **Siblings**: `ai/genai`, `ai/genai-approval`, `ai/ex_llama`; coupling map in trl-infra `docs/SUBS.md`.
