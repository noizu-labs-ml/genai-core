# Threat Model (Summary)

Library, not a service — no ingress/infra/stores. Jewels: provider API keys in session state; prompt/message content (PII).

Boundaries: consumer app ↔ library (trusted config, untrusted content) · library ↔ providers (credentialed TLS egress) · config ↔ runtime (media registry).

Register: 9 entries (T-001…T-009).
- High: T-001 keys in inspectable state (partial) · T-003 prompt injection via message/tool-result content (consumer responsibility)
- Medium: T-002 poisoned egress URL settings · T-005 SSRF via `{:uri, path}` content sources · T-006 hex supply chain (mitigated: lockfile, optional deps)
- Low: T-004 unbounded SSE frame buffering · T-007 Logger key leakage (partial) · T-008 tool registry runs configured modules (accepted) · T-009 pipeline/fork result values leak extracted content if logged (open)

Structural mitigations: pipeline selectors are data-only (no shell); fork trees bounded at 64 uniquely-id branches with isolated leaves; extraction turns discarded.

Residual: consumers must own state-logging hygiene, content provenance, and result-logging hygiene — audit checklist when embedding.
