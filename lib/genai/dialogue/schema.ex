defmodule GenAI.Dialogue.Schema do
  @moduledoc """
  Product-agnostic field schema for multi-turn slot-filling dialogues.

  Fields are declared once; the dialogue stepper asks for missing required
  (and optional-to-ask) slots until the draft is complete.
  """

  @type field :: %{
          required(:name) => atom(),
          required(:question) => String.t(),
          optional(:required) => boolean()
        }

  @type t :: %__MODULE__{
          fields: [field()],
          ask_optional: [atom()]
        }

  defstruct fields: [], ask_optional: []

  @doc """
  Build a schema from a list of field maps.

  Each field: `%{name: :title, question: "…", required: true | false}`.
  """
  @spec new([field()], keyword()) :: t()
  def new(fields, opts \\ []) when is_list(fields) do
    normalized =
      Enum.map(fields, fn f ->
        name = Map.fetch!(f, :name)
        question = Map.fetch!(f, :question)
        required = Map.get(f, :required, false)
        %{name: name, question: question, required: required}
      end)

    %__MODULE__{
      fields: normalized,
      ask_optional: Keyword.get(opts, :ask_optional, [])
    }
  end

  @doc "Ordered list of field names still blank under required + ask_optional policy."
  @spec missing(t(), map()) :: [atom()]
  def missing(%__MODULE__{} = schema, draft) when is_map(draft) do
    required_names =
      schema.fields
      |> Enum.filter(& &1.required)
      |> Enum.map(& &1.name)

    (required_names ++ schema.ask_optional)
    |> Enum.uniq()
    |> Enum.filter(fn name -> blank?(Map.get(draft, name) || Map.get(draft, Atom.to_string(name))) end)
  end

  @doc "True when no required/ask_optional fields are blank."
  @spec complete?(t(), map()) :: boolean()
  def complete?(%__MODULE__{} = schema, draft), do: missing(schema, draft) == []

  @doc "Next `{field, question}` or nil when complete."
  @spec next_question(t(), map()) :: {atom(), String.t()} | nil
  def next_question(%__MODULE__{} = schema, draft) do
    case missing(schema, draft) do
      [name | _] ->
        field = Enum.find(schema.fields, &(&1.name == name))
        question = if field, do: field.question, else: "Please provide #{name}."
        {name, question}

      [] ->
        nil
    end
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(v) when is_binary(v), do: String.trim(v) == ""
  defp blank?(_), do: false
end
