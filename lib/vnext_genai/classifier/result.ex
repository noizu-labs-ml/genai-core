defmodule GenAI.Classifier.Result do
  @moduledoc """
  Typed classifier answers. Missing provider fields stay nil. An ordered
  distribution, selected probability, and provider confidence retain separate
  meanings; expected score does not imply a chosen grade.

  When both a score distribution and expected score are supplied, their
  weighted mean must agree within `1.0e-6 * max(1, abs(mean))`.
  """
  defmodule Answer do
    @moduledoc "A typed answer correlated to a request question by its string ID."
    defstruct question_id: nil,
              type: nil,
              value: nil,
              index: nil,
              choice_id: nil,
              distribution: nil,
              selected_probability: nil,
              provider_confidence: nil,
              confidence_metadata: %{},
              expected_score: nil,
              grade: nil,
              metadata: %{}

    @type t :: %__MODULE__{
            question_id: String.t(),
            type: :choice | :boolean | :score,
            value: term(),
            index: non_neg_integer() | nil,
            choice_id: String.t() | nil,
            distribution: [number()] | nil,
            selected_probability: number() | nil,
            provider_confidence: term(),
            confidence_metadata: map(),
            expected_score: number() | nil,
            grade: String.t() | nil,
            metadata: map()
          }
  end

  defstruct answers: [], model: nil, provider: nil, usage: nil, duration: nil, metadata: %{}

  @type t :: %__MODULE__{
          answers: [Answer.t()],
          model: term(),
          provider: module() | nil,
          usage: term(),
          duration: non_neg_integer() | nil,
          metadata: map()
        }

  alias GenAI.Classifier.{Question, Request, Validation}
  alias GenAI.Classifier.Validation, as: V

  @doc "Validate provider answers against request IDs, ordered criteria and probability shapes."
  @spec normalize(term(), Request.t()) :: {:ok, t()} | {:error, term()}
  def normalize(map, %Request{} = request) when is_map(map) do
    answers = V.get(map, :answers)
    metadata = V.get(map, :metadata, %{})
    duration = V.get(map, :duration)

    with true <- is_list(answers) and Enum.all?(answers, &is_map/1),
         ids = Enum.map(answers, &V.get(&1, :question_id)),
         true <-
           V.unique?(ids) and Enum.sort(ids) == Enum.sort(Enum.map(request.questions, & &1.id)),
         true <-
           is_map(metadata) and (is_nil(duration) or (is_integer(duration) and duration >= 0)),
         by_id = Map.new(answers, &{V.get(&1, :question_id), &1}),
         {:ok, normalized} <-
           V.collect(request.questions, fn question ->
             normalize_answer(by_id[question.id], question)
           end) do
      {:ok,
       %__MODULE__{
         answers: normalized,
         model: V.get(map, :model, request.model),
         provider: V.get(map, :provider, request.provider),
         usage: V.get(map, :usage),
         duration: duration,
         metadata: metadata
       }}
    else
      false -> {:error, {:invalid_classifier_result, :answers_or_metadata}}
      error -> error
    end
  end

  def normalize(_, _), do: {:error, {:invalid_classifier_result, :shape}}

  defp normalize_answer(map, question) do
    answer = struct(Answer, V.fields(map, Map.keys(Map.from_struct(%Answer{}))))

    answer = %{
      answer
      | type: normalized_type(answer.type || question.type),
        metadata: answer.metadata || %{},
        confidence_metadata: answer.confidence_metadata || %{}
    }

    with true <- answer.type == question.type,
         true <- is_map(answer.metadata) and is_map(answer.confidence_metadata),
         {:ok, answer} <- selection(answer, question),
         :ok <- probabilities(answer, question),
         :ok <- score(answer, question) do
      {:ok, answer}
    else
      false -> {:error, {:invalid_classifier_answer, question.id, :type_or_metadata}}
      {:error, reason} -> {:error, {:invalid_classifier_answer, question.id, reason}}
    end
  end

  defp normalized_type(type) when type in [:choice, "choice"], do: :choice
  defp normalized_type(type) when type in [:boolean, "boolean"], do: :boolean
  defp normalized_type(type) when type in [:score, "score"], do: :score
  defp normalized_type(_), do: nil

  defp selection(%{value: value, index: index, choice_id: choice_id} = answer, %{type: :boolean}) do
    expected_index = if value == true, do: 1, else: 0
    expected_id = if value == true, do: "true", else: "false"

    if is_boolean(value) and index in [nil, expected_index] and choice_id in [nil, expected_id] and
         is_nil(answer.grade), do: {:ok, answer}, else: {:error, :boolean_selection}
  end

  defp selection(answer, question) do
    entries = Question.entries(question)

    identifier =
      answer.choice_id || if(question.type == :score, do: answer.grade, else: answer.value)

    matching =
      if is_nil(identifier),
        do: [],
        else:
          Enum.with_index(entries)
          |> Enum.filter(fn {entry, _} ->
            entry.id == identifier or (is_nil(answer.choice_id) and entry.label == identifier)
          end)

    inferred =
      case matching do
        [{_, index}] -> index
        _ -> nil
      end

    index = if is_nil(answer.index), do: inferred, else: answer.index

    cond do
      not is_nil(identifier) and is_nil(inferred) ->
        {:error, :unknown_choice}

      not is_nil(answer.index) and
          (not is_integer(answer.index) or answer.index < 0 or answer.index >= length(entries)) ->
        {:error, :choice_index}

      not is_nil(inferred) and inferred != index ->
        {:error, :inconsistent_selection}

      question.type == :choice and is_nil(index) ->
        {:error, :missing_selection}

      question.type == :score and is_nil(index) and is_nil(answer.expected_score) ->
        {:error, :missing_score}

      true ->
        validate_selected_entry(answer, question, entries, index)
    end
  end

  defp validate_selected_entry(answer, _question, _entries, nil), do: {:ok, answer}

  defp validate_selected_entry(answer, question, entries, index) do
    entry = Enum.at(entries, index)

    valid_value =
      case question.type do
        :choice ->
          answer.value in [nil, entry.id, entry.label]

        :score ->
          answer.value in [nil, entry.score] and answer.grade in [nil, entry.id, entry.label]
      end

    if valid_value and answer.choice_id in [nil, entry.id] do
      {:ok, %{answer | index: index}}
    else
      {:error, :inconsistent_selection}
    end
  end

  defp probabilities(answer, question) do
    distribution = answer.distribution
    selected = answer.selected_probability
    index = if question.type == :boolean, do: if(answer.value, do: 1, else: 0), else: answer.index

    cond do
      not is_nil(distribution) and
          not valid_distribution?(distribution, length(Question.entries(question))) ->
        {:error, :distribution}

      not is_nil(selected) and not V.probability?(selected) ->
        {:error, :selected_probability}

      not is_nil(selected) and is_nil(index) ->
        {:error, :selected_probability_without_selection}

      not is_nil(selected) and not is_nil(distribution) and
          abs(selected - Enum.at(distribution, index)) > 1.0e-6 ->
        {:error, :inconsistent_selected_probability}

      true ->
        :ok
    end
  end

  defp valid_distribution?(distribution, count) when is_list(distribution) do
    length(distribution) == count and Enum.all?(distribution, &V.probability?/1) and
      abs(Enum.sum(distribution) - 1) <= 1.0e-6
  end

  defp valid_distribution?(_, _), do: false

  defp score(answer, %{type: :score, rubric: rubric}) do
    scores = Enum.map(rubric, & &1.score)
    expected = answer.expected_score

    cond do
      is_nil(expected) ->
        :ok

      not Validation.number?(expected) or expected < Enum.min(scores) or
          expected > Enum.max(scores) ->
        {:error, :expected_score}

      not is_nil(answer.distribution) ->
        mean = Enum.zip_with(scores, answer.distribution, &(&1 * &2)) |> Enum.sum()

        if abs(expected - mean) <= 1.0e-6 * max(1, abs(mean)),
          do: :ok,
          else: {:error, :inconsistent_expected_score}

      true ->
        :ok
    end
  end

  defp score(%{expected_score: nil, grade: nil}, _), do: :ok
  defp score(_, _), do: {:error, :unexpected_score_fields}
end
