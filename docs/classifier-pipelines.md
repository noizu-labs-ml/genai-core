# Classifier pipelines

`GenAI.classify/2` sends a provider-neutral request to an explicit classifier.
The classifier default is separate from the chat default. The core preserves
the distinction between a selected choice, selected probability, provider
confidence, expected score, and discrete grade. Models remain standard
`GenAI.Model` references. Model-specific tokenization and transports belong in
adapters, outside Core. This delivery executes text; contracts can identify
other modalities for adapters to reject or support explicitly.

Conversation processing is opt-in through `GenAI.Pipeline`. Existing
`GenAI.run/1` and `run/3` continue to run one inference. Tool chains retain their
existing behavior. Pipeline operations return `{:ok, pipeline}` or tagged errors;
forks return `{:fork, [%GenAI.Pipeline.Branch{}]}`. Errors pass through subsequent
operations. The original thread remains immutable.

## Extraction and classification

```elixir
alias GenAI.Pipeline
alias GenAI.Classifier.Question

thread
|> Pipeline.extract(:last_response)
|> Pipeline.extract({:literal, [
  %Question{id: "quality", type: :score, instructions: "Rate response quality",
    rubric: [%{id: "poor", label: "Poor", score: 0},
             %{id: "good", label: "Good", score: 1}]}
]}, kind: :criteria)
|> Pipeline.classify(provider: MyClassifier, model: classifier_model)
|> Pipeline.append_result(final: :json)
```

Every extraction pushes a typed frame (`:payload`, `:criteria`, or `:result`).
Classification consumes the latest payload and criteria frames, leaving other
stack entries intact, and pushes a typed result. A single callback can return
`%{payload: value, criteria: questions}` with `kind: :both`. Call-level questions
override an extracted criteria frame. A transform replaces the continuing
thread and clears old frames. Frames from a different thread revision are
rejected instead of silently grading stale content.

Selectors include `:last_message` (optional `role:`), `:last_response`, and
`:prompt_last_response` (`prompt:` plus the last assistant response).
`{:last, {:json, ["key", 0]}}` selects JSON keys and nonnegative array indices;
paths are explicit lists, not a full JSONPath language. `{:last, {:xml, xpath}}`
uses SweetXml XPath string lists. `{:grep, regex}` returns regex captures.
`{:yaml_blocks, "yaml"}` or `"yml"` returns fenced block text without parsing it.
No selector runs shell commands or XSLT code.

`{:inference, prompt}` performs concrete structured extraction on a temporary
conversation using its existing chat model or an explicit `model:` override.
It accepts validated JSON or the named extraction tool's arguments, and binds
payload, criteria, or both according to `kind:`. The inference conversation and
its answer are discarded; the continuing conversation changes only through an
explicit transform, next turn, or result insertion.

`{:callback, fun}`, `{:mfa, module, function, args}`, and `{:inference, fun}`
receive provider-neutral chronological messages and options. Callback and
inference functions take two arguments. MFA receives `[messages, options | args]`.
These hooks are trusted application code and are not serializable model
instructions. Callback hooks remain available for application-specific inference
or extraction alongside the concrete structured extractor.

`Pipeline.aggregate(selector, direction: :forward | :backward, role: role,
format: :list | :text | :json | :yaml)` walks messages and collects results.
Missing selections are skipped by default; `missing: :error` fails instead.
Tool responses expose their raw response payload. Thread projection applies
pending graph messages and configuration without provider encoding or inference;
unknown custom graph nodes are rejected to prevent executing arbitrary callbacks.
The optional XML selector loads SweetXml only when invoked and rejects DTDs,
including external entity fetches.

`append_result` records an assistant tool call and a matching tool response with
the same call ID. `final: :text` or `:json` additionally inserts a deterministic
assistant rendering; it does not perform inference. The extracted value lives
in the tool response, preserving the ordinary tool exchange. `name:` controls
the synthetic tool name. Values must be JSON-compatible; structs are converted
recursively and atoms become strings. Model references render only their name
and provider identity; executable model configuration is excluded.

## Agent postprocessing

```elixir
thread
|> Pipeline.fork([
  memory: &Pipeline.extract(&1, {:inference, memory_extractor}),
  mood: &Pipeline.extract(&1, {:inference, mood_extractor}),
  critique: &Pipeline.extract(&1, {:inference, critique_extractor})
])
|> Pipeline.join(mode: :reduce, reducer: fn branches ->
  Map.new(branches, &{&1.id, hd(&1.pipeline.frames).value})
end)
|> Pipeline.append_result(final: :json)
```

Branch identity and order come from the supplied named branch list. Each branch
owns its thread, frames and artifacts; immutable base history is shared.
Fork callbacks run with bounded concurrency (default 4, maximum 64), and task
timeout (default 30 seconds, maximum 300 seconds). Timed-out tasks are killed;
their branch IDs and failure diagnostics remain in the fork with successful
branches. All extraction, aggregation, transformation, classification and result
insertion operations broadcast across forks using one global leaf concurrency
budget, preserving nested branch identities and failures. `Branch.path` records
the identity of each enclosing branch for diagnostics. Joins reject failed branches. Nested forks require their own explicit
join before the parent can converge. Arbitrary callback side effects cannot be
rolled back by canceling a task; callbacks should use immutable results.

## Evaluation forks

```elixir
thread
|> Pipeline.split(3)
|> Pipeline.next_turn(max_concurrency: 3)
|> Pipeline.join(mode: :select,
  selector: {:classifier, [provider: MyClassifier, model: judge_model]})
```

`split/3` creates independent copies identified by `0..count-1` (maximum 64).
`next_turn/2` accepts a pipeline or fork, runs one inference per branch, and
appends the first assistant choice exactly once, including when the provider
already appended it. Multiple completion choices are retained in the completion
artifact, while the first choice continues the thread. A supplied `run:` callback
has signature `(thread, context, run_options) -> {:ok, {completion, thread}}`.
Ordinary `run/1`'s completion-only shape is not the callback contract.

All joins require an explicit mode:

- `:reduce` calls `reducer:` with branches and pushes the reduced value onto the
  common ancestor's stack, ready for `append_result`.
- `:select` uses `branch:` or `selector:` to continue one complete branch.
  A classifier selector asks a choice question with branch IDs as option IDs.
- `:append` appends each branch's messages after the common prefix in stable
  branch order, without duplicating that prefix. Reused message IDs across
  deltas fail with a tagged diagnostic naming the source branches. Branch settings and artifacts
  are not implicitly merged; reduce them explicitly when needed.

Each branch must retain the common message prefix. History replacement or
compaction may happen in a branch, but requires selection or an explicit
reconciliation before an append/reduce join. Classifier selection accepts only
a valid returned branch ID. No external strings are converted to atoms.

Deterministic tests cover pending messages in both thread representations,
stack binding/staleness, selectors, aggregation, transformations, tool exchange,
isolated branches, task failures and timeouts, explicit joins and postprocessing.
Provider live tests belong in adapters and are separate from these core tests.
