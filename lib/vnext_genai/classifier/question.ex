defmodule GenAI.Classifier.Question do
  @moduledoc """
  A decision with a stable string ID and ordered criteria.

  Choice entries are strings or `%{id: string, label: string}` maps. Score
  rubrics are ordered `%{id: string, label: string, score: number}` maps.
  Boolean distributions use the fixed order `[false, true]`.
  """
  defstruct id: nil, type: :choice, instructions: nil, choices: [], rubric: [], metadata: %{}

  @type t :: %__MODULE__{
          id: String.t(),
          type: :choice | :boolean | :score,
          instructions: String.t() | nil,
          choices: list(),
          rubric: list(),
          metadata: map()
        }

  alias GenAI.Classifier.Validation, as: V

  @doc "Normalize a question without creating atoms from external identifiers."
  @spec normalize(term()) :: {:ok, t()} | {:error, term()}
  def normalize(map) when is_map(map) do
    question = %__MODULE__{
      id: V.get(map, :id),
      type: normalize_type(V.get(map, :type, :choice)),
      instructions: V.get(map, :instructions),
      choices: V.get(map, :choices, []),
      rubric: V.get(map, :rubric, []),
      metadata: V.get(map, :metadata, %{})
    }

    cond do
      not V.string?(question.id) ->
        {:error, {:invalid_question, :id}}

      question.type not in [:choice, :boolean, :score] ->
        {:error, {:invalid_question, :type}}

      not is_nil(question.instructions) and not is_binary(question.instructions) ->
        {:error, {:invalid_question, :instructions}}

      not is_map(question.metadata) ->
        {:error, {:invalid_question, :metadata}}

      true ->
        normalize_criteria(question)
    end
  end

  def normalize(_), do: {:error, {:invalid_question, :shape}}

  @doc "Return the ordered decision entries; booleans always use false then true."
  @spec entries(t()) :: list()
  def entries(%__MODULE__{type: :choice, choices: choices}), do: choices
  def entries(%__MODULE__{type: :score, rubric: rubric}), do: rubric

  def entries(%__MODULE__{type: :boolean}),
    do: [%{id: "false", label: "false"}, %{id: "true", label: "true"}]

  defp normalize_type(value) when value in [:choice, "choice"], do: :choice
  defp normalize_type(value) when value in [:boolean, "boolean"], do: :boolean

  defp normalize_type(value)
       when value in [:score, "score", :grade, "grade", :ordinal_score, "ordinal_score"],
       do: :score

  defp normalize_type(_), do: nil

  defp normalize_criteria(%{type: :boolean, choices: [], rubric: []} = question),
    do: {:ok, question}

  defp normalize_criteria(%{type: :choice, choices: choices, rubric: []} = question)
       when is_list(choices) and length(choices) >= 2 do
    with {:ok, entries} <- V.collect(choices, &normalize_choice/1),
         true <- V.unique?(Enum.map(entries, & &1.id)) do
      {:ok, %{question | choices: entries}}
    else
      false -> {:error, {:invalid_question, :duplicate_choice_ids}}
      error -> error
    end
  end

  defp normalize_criteria(%{type: :score, choices: [], rubric: rubric} = question)
       when is_list(rubric) and length(rubric) >= 2 do
    with {:ok, entries} <- V.collect(rubric, &normalize_grade/1),
         true <- V.unique?(Enum.map(entries, & &1.id)),
         scores = Enum.map(entries, & &1.score),
         true <- V.unique?(scores) and scores == Enum.sort(scores) do
      {:ok, %{question | rubric: entries}}
    else
      false -> {:error, {:invalid_question, :duplicate_or_unordered_rubric}}
      error -> error
    end
  end

  defp normalize_criteria(_), do: {:error, {:invalid_question, :criteria}}

  defp normalize_choice(value) when is_binary(value),
    do: normalize_choice(%{id: value, label: value})

  defp normalize_choice(map) when is_map(map) do
    id = V.get(map, :id)
    label = V.get(map, :label, id)

    if V.string?(id) and V.string?(label),
      do: {:ok, %{id: id, label: label}},
      else: {:error, {:invalid_question, :choice}}
  end

  defp normalize_choice(_), do: {:error, {:invalid_question, :choice}}

  defp normalize_grade(map) when is_map(map) do
    with {:ok, entry} <- normalize_choice(map),
         score = V.get(map, :score),
         true <- V.number?(score) do
      {:ok, Map.put(entry, :score, score)}
    else
      false -> {:error, {:invalid_question, :grade_score}}
      error -> error
    end
  end

  defp normalize_grade(_), do: {:error, {:invalid_question, :grade}}
end
