defmodule GenAI.Classifier.Request do
  @moduledoc """
  Provider-neutral classifier input. `model` accepts the existing GenAI.Model
  reference; `provider` optionally selects a classifier adapter independently
  of the model's chat provider. No chat model is selected implicitly.
  """
  defstruct input: nil,
            questions: [],
            model: nil,
            provider: nil,
            modality: :text,
            metadata: %{},
            options: []

  @type t :: %__MODULE__{
          input: term(),
          questions: [GenAI.Classifier.Question.t()],
          model: term(),
          provider: module() | nil,
          modality: atom(),
          metadata: map(),
          options: keyword()
        }

  alias GenAI.Classifier.{Question, Validation}

  @doc "Normalize and validate a request; IDs stay strings and criteria keep their order."
  @spec normalize(term()) :: {:ok, t()} | {:error, term()}
  def normalize(map) when is_map(map) do
    request = %__MODULE__{
      input: Validation.get(map, :input),
      questions: Validation.get(map, :questions, []),
      model: Validation.get(map, :model),
      provider: Validation.get(map, :provider),
      modality: Validation.get(map, :modality, :text),
      metadata: Validation.get(map, :metadata, %{}),
      options: Validation.get(map, :options, [])
    }

    with :ok <- validate(request),
         {:ok, questions} <- Validation.collect(request.questions, &Question.normalize/1),
         true <- Validation.unique?(Enum.map(questions, & &1.id)) do
      {:ok, %{request | questions: questions}}
    else
      false -> {:error, {:invalid_classifier_request, :duplicate_question_ids}}
      error -> error
    end
  end

  def normalize(_), do: {:error, {:invalid_classifier_request, :shape}}

  defp validate(request) do
    cond do
      is_nil(request.input) ->
        {:error, {:invalid_classifier_request, :input}}

      not is_list(request.questions) or request.questions == [] ->
        {:error, {:invalid_classifier_request, :questions}}

      not is_nil(request.model) and not match?(%GenAI.Model{}, request.model) ->
        {:error, {:invalid_classifier_request, :model}}

      not is_nil(request.provider) and
          (not is_atom(request.provider) or request.provider in [true, false]) ->
        {:error, {:invalid_classifier_request, :provider}}

      request.modality not in [:text, :image, :audio, :video] ->
        {:error, {:invalid_classifier_request, :modality}}

      not is_map(request.metadata) ->
        {:error, {:invalid_classifier_request, :metadata}}

      not Keyword.keyword?(request.options) ->
        {:error, {:invalid_classifier_request, :options}}

      true ->
        :ok
    end
  end
end
