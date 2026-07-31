defmodule GenAI.Dialogue do
  @moduledoc """
  Pure multi-turn slot-filling dialogue stepper.

  Product code supplies a `GenAI.Dialogue.Schema` and optional extract/merge
  functions. No I/O: after `status: :complete`, the host runs side effects
  (e.g. genai_approval scripts) outside this module.
  """

  alias GenAI.Dialogue.Schema

  @type status :: :collecting | :complete | :cancelled

  @typedoc """
  Result of an `extract` callback.

  - `{:cancel}` — user abandoned the dialogue.
  - `{:ok, attrs}` — slots harvested; the agent message stays schema-driven.
  - `{:ok, attrs, reply}` — slots harvested AND the extractor supplied its own
    natural-language reply, which replaces the canned schema question /
    ready message for this turn.
  """
  @type extract_result :: {:cancel} | {:ok, map()} | {:ok, map(), String.t()}

  @typedoc """
  Extract callback. Both arities are supported:

  - `(text, pending_field)` — legacy 2-arity form.
  - `(text, pending_field, draft)` — receives the accumulated draft so an
    LLM-backed extractor can avoid re-asking filled slots.
  """
  @type extract_fun ::
          (String.t(), atom() | nil -> extract_result())
          | (String.t(), atom() | nil, map() -> extract_result())

  @type t :: %__MODULE__{
          status: status(),
          draft: map(),
          schema: Schema.t(),
          pending_field: atom() | nil,
          turns: non_neg_integer(),
          last_agent_message: String.t() | nil,
          extract: extract_fun(),
          ready_message: (map() -> String.t()),
          cancel_message: String.t()
        }

  defstruct status: :collecting,
            draft: %{},
            schema: nil,
            pending_field: nil,
            turns: 0,
            last_agent_message: nil,
            extract: nil,
            ready_message: nil,
            cancel_message: "Okay — cancelled. No changes were made."

  @doc """
  Start a dialogue from the first user utterance.

  Options:
  - `:extract` — `(text, pending_field)` or `(text, pending_field, draft)`
    returning `{:cancel} | {:ok, attrs} | {:ok, attrs, reply}`
  - `:initial_draft` — map pre-filled slots
  - `:ready_message` — `(draft) -> String.t()` when complete
  - `:cancel_message` — string on cancel
  """
  @spec start(Schema.t(), String.t(), keyword()) :: {t(), String.t()}
  def start(%Schema{} = schema, utterance, opts \\ []) when is_binary(utterance) do
    dialogue = %__MODULE__{
      schema: schema,
      draft: Keyword.get(opts, :initial_draft, %{}),
      extract: Keyword.get(opts, :extract, &default_extract/2),
      ready_message: Keyword.get(opts, :ready_message, &default_ready/1),
      cancel_message: Keyword.get(opts, :cancel_message, "Okay — cancelled. No changes were made.")
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
    d = %{d | turns: d.turns + 1}

    case apply_extract(d, text) do
      {:cancel} ->
        msg = d.cancel_message
        d = %{d | status: :cancelled, pending_field: nil, last_agent_message: msg}
        {d, msg}

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

  # Supports both the legacy 2-arity extract and the 3-arity (draft-aware) form.
  defp apply_extract(%__MODULE__{extract: extract} = d, text) when is_function(extract, 3),
    do: extract.(text, d.pending_field, d.draft)

  defp apply_extract(%__MODULE__{extract: extract} = d, text) when is_function(extract, 2),
    do: extract.(text, d.pending_field)

  defp blank_reply(reply) do
    if String.trim(reply) == "", do: nil, else: reply
  end

  def complete?(%__MODULE__{status: :complete}), do: true
  def complete?(_), do: false

  def cancelled?(%__MODULE__{status: :cancelled}), do: true
  def cancelled?(_), do: false

  @doc "Current draft map (atom keys preferred)."
  def draft(%__MODULE__{draft: draft}), do: draft

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

  defp cancel?(text) do
    t = text |> String.trim() |> String.downcase()
    t in ~w(cancel nevermind abort stop quit) or String.starts_with?(t, "cancel ")
  end

  defp default_ready(draft) do
    "Ready: #{inspect(draft)}. Submitting via approval script."
  end
end
