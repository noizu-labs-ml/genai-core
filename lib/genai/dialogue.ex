defmodule GenAI.Dialogue do
  @moduledoc """
  Pure multi-turn slot-filling dialogue stepper, with an optional multi-step
  tool loop.

  Product code supplies a `GenAI.Dialogue.Schema` and optional extract/merge
  functions. No I/O in the default path: after `status: :complete`, the host
  runs side effects (e.g. genai_approval scripts) outside this module.

  ## Tool loop (opt-in)

  When the host configures a `:tool_executor`, an extractor may answer a turn
  with `{:tool_call, call, reply}`. The stepper then iterates:

    1. executor invoked with the call (guarded by a per-step timeout)
    2. `{:cont, result}` — the result is fed back to the extractor as a
       `{:tool_result, call, result}` input and the model continues
    3. `{:halt, reply}` — the loop ends; `reply` becomes the agent message
    4. until the extractor produces a slot/final answer or
       `:max_tool_iterations` (default #{@max_tool_iterations_default}) is hit

  The trace of executed calls is kept in `:tool_trace` for host visibility.
  Without a `:tool_executor` a `{:tool_call, ...}` degrades to the model's
  reply — the slot API and existing extract contracts are unchanged.
  """

  alias GenAI.Dialogue.Schema

  @max_tool_iterations_default 5
  @tool_step_timeout_default 30_000

  @type status :: :collecting | :complete | :cancelled

  @typedoc """
  A model-issued tool call (host-shaped: typically
  `%{"endpoint_id" => ..., "tool" => ..., "args" => %{...}}`).
  """
  @type tool_call :: map()

  @typedoc """
  First argument of an `extract` callback: the user's utterance, or — on a
  tool-loop re-entry — the structured result of the just-executed call.
  """
  @type extract_input :: String.t() | {:tool_result, tool_call(), term()}

  @typedoc """
  Result of an `extract` callback.

  - `{:cancel}` — user abandoned the dialogue.
  - `{:ok, attrs}` — slots harvested; the agent message stays schema-driven.
  - `{:ok, attrs, reply}` — slots harvested AND the extractor supplied its own
    natural-language reply, which replaces the canned schema question /
    ready message for this turn.
  - `{:tool_call, call, reply}` — the model wants a tool executed before it
    can answer. Requires a `:tool_executor`; the `reply` is spoken while the
    call runs and is the fallback message when no executor is configured.
  """
  @type extract_result ::
          {:cancel}
          | {:ok, map()}
          | {:ok, map(), String.t()}
          | {:tool_call, tool_call(), String.t()}

  @typedoc """
  Extract callback. Both arities are supported:

  - `(input, pending_field)` — legacy 2-arity form.
  - `(input, pending_field, draft)` — receives the accumulated draft so an
    LLM-backed extractor can avoid re-asking filled slots.

  `input` is an `extract_input`: the user utterance, or a
  `{:tool_result, call, result}` tuple on a tool-loop re-entry.
  """
  @type extract_fun ::
          (extract_input(), atom() | nil -> extract_result())
          | (extract_input(), atom() | nil, map() -> extract_result())

  @typedoc """
  Tool executor: executes one model-issued call and decides whether the loop
  continues.

  - `{:cont, result}` — feed `result` back to the extractor and continue.
  - `{:halt, reply}` — stop the loop; `reply` is the agent's message.
  """
  @type tool_executor :: (tool_call(), map() -> {:cont, term()} | {:halt, String.t()})

  @type t :: %__MODULE__{
          status: status(),
          draft: map(),
          schema: Schema.t(),
          pending_field: atom() | nil,
          turns: non_neg_integer(),
          last_agent_message: String.t() | nil,
          extract: extract_fun(),
          ready_message: (map() -> String.t()),
          cancel_message: String.t(),
          tool_executor: tool_executor() | nil,
          max_tool_iterations: pos_integer(),
          tool_step_timeout: pos_integer(),
          tool_trace: [map()]
        }

  defstruct status: :collecting,
            draft: %{},
            schema: nil,
            pending_field: nil,
            turns: 0,
            last_agent_message: nil,
            extract: nil,
            ready_message: nil,
            cancel_message: "Okay — cancelled. No changes were made.",
            tool_executor: nil,
            max_tool_iterations: @max_tool_iterations_default,
            tool_step_timeout: @tool_step_timeout_default,
            tool_trace: []

  @doc """
  Start a dialogue from the first user utterance.

  Options:
  - `:extract` — `(input, pending_field)` or `(input, pending_field, draft)`
    returning `{:cancel} | {:ok, attrs} | {:ok, attrs, reply} |
    {:tool_call, call, reply}`
  - `:initial_draft` — map pre-filled slots
  - `:ready_message` — `(draft) -> String.t()` when complete
  - `:cancel_message` — string on cancel
  - `:tool_executor` — `tool_executor/0` callback; opt-in to the tool loop
  - `:max_tool_iterations` — loop budget per user turn
    (default #{@max_tool_iterations_default})
  - `:tool_step_timeout` — per-call executor timeout in ms
    (default #{@tool_step_timeout_default})
  """
  @spec start(Schema.t(), String.t(), keyword()) :: {t(), String.t()}
  def start(%Schema{} = schema, utterance, opts \\ []) when is_binary(utterance) do
    dialogue = %__MODULE__{
      schema: schema,
      draft: Keyword.get(opts, :initial_draft, %{}),
      extract: Keyword.get(opts, :extract, &default_extract/2),
      ready_message: Keyword.get(opts, :ready_message, &default_ready/1),
      cancel_message:
        Keyword.get(opts, :cancel_message, "Okay — cancelled. No changes were made."),
      tool_executor: Keyword.get(opts, :tool_executor),
      max_tool_iterations: Keyword.get(opts, :max_tool_iterations, @max_tool_iterations_default),
      tool_step_timeout: Keyword.get(opts, :tool_step_timeout, @tool_step_timeout_default)
    }

    turn(dialogue, utterance)
  end

  @doc "Process one user turn. Returns `{dialogue, agent_message}`."
  @spec turn(t(), String.t()) :: {t(), String.t()}
  def turn(%__MODULE__{status: :cancelled} = d, _text) do
    {d, d.cancel_message}
  end

  def turn(%__MODULE__{status: :complete} = d, _text) do
    {d, d.last_agent_message || "Draft is already complete."}
  end

  def turn(%__MODULE__{} = d, text) when is_binary(text) do
    d = %{d | turns: d.turns + 1, tool_trace: []}
    tool_loop(d, text, 0)
  end

  # The loop: extract → optional tool execution → re-extract → …
  defp tool_loop(d, input, iteration) do
    case apply_extract(d, input) do
      {:cancel} ->
        msg = d.cancel_message
        d = %{d | status: :cancelled, pending_field: nil, last_agent_message: msg}
        {d, msg}

      {:tool_call, call, reply} when is_map(call) and is_binary(reply) ->
        handle_tool_call(d, call, reply, iteration)

      {:ok, attrs, reply} when is_map(attrs) and is_binary(reply) ->
        draft = merge_draft(d.draft, attrs)
        advance(%{d | draft: draft}, blank_reply(reply))

      {:ok, attrs, _reply} when is_map(attrs) ->
        draft = merge_draft(d.draft, attrs)
        advance(%{d | draft: draft})

      {:ok, attrs} when is_map(attrs) ->
        draft = merge_draft(d.draft, attrs)
        advance(%{d | draft: draft})
    end
  end

  defp handle_tool_call(%__MODULE__{tool_executor: nil} = d, _call, reply, _iteration) do
    # No executor configured — degrade gracefully to the model's own reply.
    advance(%{d | pending_field: nil}, blank_reply(reply))
  end

  defp handle_tool_call(%__MODULE__{max_tool_iterations: max} = d, _call, _reply, iteration)
       when iteration >= max do
    # The declined call is not recorded — tool_trace holds EXECUTED calls only.
    msg = "I reached the tool-use limit for this turn (#{max})."
    advance(%{d | pending_field: nil}, msg)
  end

  defp handle_tool_call(d, call, _reply, iteration) do
    case run_tool(d, call) do
      {:cont, result} ->
        d = %{
          d
          | tool_trace:
              d.tool_trace ++ [%{call: call, outcome: {:ok, result}, iteration: iteration + 1}]
        }

        tool_loop(d, {:tool_result, call, result}, iteration + 1)

      {:halt, halt} ->
        d = %{
          d
          | tool_trace:
              d.tool_trace ++ [%{call: call, outcome: {:halt, halt}, iteration: iteration + 1}]
        }

        advance(%{d | pending_field: nil}, halt)
    end
  end

  # Executor execution is the one impure corner of the stepper: a detached
  # process + explicit timeout so a hung tool can never wedge the dialogue.
  defp run_tool(
         %__MODULE__{tool_executor: executor, tool_step_timeout: timeout, draft: draft},
         call
       ) do
    me = self()
    ref = make_ref()

    pid =
      spawn(fn ->
        send(me, {ref, safely_exec(executor, call, draft)})
      end)

    receive do
      {^ref, outcome} -> outcome
    after
      timeout ->
        Process.exit(pid, :kill)
        {:halt, "Tool call timed out after #{timeout}ms."}
    end
  end

  defp safely_exec(executor, call, draft) do
    case executor.(call, draft) do
      {:cont, _result} = outcome -> outcome
      {:halt, reply} when is_binary(reply) -> {:halt, reply}
      # Malformed executor return — halt honestly rather than loop forever.
      other -> {:halt, "Tool executor returned an invalid outcome: #{inspect(other)}"}
    end
  rescue
    e -> {:halt, "Tool call failed: #{Exception.message(e)}"}
  catch
    kind, reason -> {:halt, "Tool call failed (#{kind})."}
  end

  # Supports both the legacy 2-arity extract and the 3-arity (draft-aware) form.
  defp apply_extract(%__MODULE__{extract: extract} = d, input) when is_function(extract, 3),
    do: extract.(input, d.pending_field, d.draft)

  defp apply_extract(%__MODULE__{extract: extract} = d, input) when is_function(extract, 2),
    do: extract.(input, d.pending_field)

  defp blank_reply(reply) do
    if String.trim(reply) == "", do: nil, else: reply
  end

  def complete?(%__MODULE__{status: :complete}), do: true
  def complete?(_), do: false

  def cancelled?(%__MODULE__{status: :cancelled}), do: true
  def cancelled?(_), do: false

  @doc "Current draft map (atom keys preferred)."
  def draft(%__MODULE__{draft: draft}), do: draft

  @doc "Tool calls executed during the most recent user turn (oldest first)."
  def tool_trace(%__MODULE__{tool_trace: trace}), do: trace

  # `override_reply`, when non-nil, replaces the canned schema question /
  # ready message as the agent's utterance for this turn. Slot structure is
  # still schema-driven — only the *source of the message* changes.
  defp advance(dialogue, override_reply \\ nil)

  defp advance(%__MODULE__{} = d, override_reply) do
    case Schema.next_question(d.schema, d.draft) do
      nil ->
        msg = override_reply || d.ready_message.(d.draft)
        d = %{d | status: :complete, pending_field: nil, last_agent_message: msg}
        {d, msg}

      {field, question} ->
        msg = override_reply || question
        d = %{d | status: :collecting, pending_field: field, last_agent_message: msg}
        {d, msg}
    end
  end

  defp merge_draft(draft, attrs) do
    Enum.reduce(attrs, draft, fn {k, v}, acc ->
      key =
        cond do
          is_atom(k) ->
            k

          is_binary(k) ->
            try do
              String.to_existing_atom(k)
            rescue
              ArgumentError -> String.to_atom(k)
            end

          true ->
            k
        end

      cond do
        is_nil(v) -> acc
        is_binary(v) and String.trim(v) == "" -> acc
        true -> Map.put(acc, key, if(is_binary(v), do: String.trim(v), else: v))
      end
    end)
  end

  defp default_extract(text, nil) do
    if cancel?(text), do: {:cancel}, else: {:ok, %{}}
  end

  defp default_extract(text, pending_field) when is_atom(pending_field) do
    cond do
      cancel?(text) -> {:cancel}
      true -> {:ok, %{pending_field => String.trim(text)}}
    end
  end

  defp cancel?(text) when is_binary(text) do
    t = text |> String.trim() |> String.downcase()
    t in ~w(cancel nevermind abort stop quit) or String.starts_with?(t, "cancel ")
  end

  defp cancel?(_), do: false

  defp default_ready(draft) do
    "Ready: #{inspect(draft)}. Submitting via approval script."
  end
end
