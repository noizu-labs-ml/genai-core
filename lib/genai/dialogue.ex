defmodule GenAI.Dialogue do
  @moduledoc """
  Pure multi-turn slot-filling dialogue stepper.

  Product code supplies a `GenAI.Dialogue.Schema` and optional extract/merge
  functions. No I/O: after `status: :complete`, the host runs side effects
  (e.g. genai_approval scripts) outside this module.
  """

  alias GenAI.Dialogue.Schema

  @type status :: :collecting | :complete | :cancelled

  @type t :: %__MODULE__{
          status: status(),
          draft: map(),
          schema: Schema.t(),
          pending_field: atom() | nil,
          turns: non_neg_integer(),
          last_agent_message: String.t() | nil,
          extract: (String.t(), atom() | nil -> {:cancel} | {:ok, map()}),
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
  - `:extract` — `(text, pending_field) -> {:cancel} | {:ok, attrs_map}`
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

    case d.extract.(text, d.pending_field) do
      {:cancel} ->
        msg = d.cancel_message
        d = %{d | status: :cancelled, pending_field: nil, last_agent_message: msg}
        {d, msg}

      {:ok, attrs} when is_map(attrs) ->
        draft = merge_draft(d.draft, attrs)
        advance(%{d | draft: draft})
    end
  end

  def complete?(%__MODULE__{status: :complete}), do: true
  def complete?(_), do: false

  def cancelled?(%__MODULE__{status: :cancelled}), do: true
  def cancelled?(_), do: false

  @doc "Current draft map (atom keys preferred)."
  def draft(%__MODULE__{draft: draft}), do: draft

  defp advance(%__MODULE__{} = d) do
    case Schema.next_question(d.schema, d.draft) do
      nil ->
        msg = d.ready_message.(d.draft)
        d = %{d | status: :complete, pending_field: nil, last_agent_message: msg}
        {d, msg}

      {field, question} ->
        d = %{d | status: :collecting, pending_field: field, last_agent_message: question}
        {d, question}
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
