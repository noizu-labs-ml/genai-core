defmodule GenAI.Classifier.Router do
  @moduledoc """
  Explicit classifier dispatch with validated request/result boundaries.

  Model/provider precedence is call options, request, then
  `config :genai, :classifier, model: model, provider: adapter`. If no adapter is
  specified, the selected GenAI.Model's provider is used only when it exports
  classify/2. Ordinary chat and generative judging are never implicit fallbacks.
  """
  alias GenAI.Classifier.{Question, Request, Result}

  @doc "Resolve a classifier, validate capabilities and execute one decision request."
  @spec classify(term(), keyword()) :: {:ok, Result.t()} | {:error, term()}
  def classify(request, options \\ [])

  def classify(request, options) when is_list(options) do
    if Keyword.keyword?(options) do
      with {:ok, request} <- Request.normalize(request),
           {:ok, request} <- resolve(request, options),
           :ok <- supported(request),
           {:ok, result} <- invoke(request, options),
           {:ok, normalized} <- Result.normalize(result, request) do
        {:ok,
         %{normalized | model: normalized.model || request.model, provider: request.provider}}
      end
    else
      {:error, {:invalid_classifier_options, :shape}}
    end
  end

  def classify(_, _), do: {:error, {:invalid_classifier_options, :shape}}

  defp resolve(request, options) do
    defaults = Application.get_env(:genai, :classifier, [])

    if Keyword.keyword?(defaults) do
      model = Keyword.get(options, :model) || request.model || defaults[:model]

      provider =
        Keyword.get(options, :provider) || request.provider || defaults[:provider] ||
          model_provider(model)

      with {:ok, request} <- Request.normalize(%{request | model: model, provider: provider}),
           true <-
             is_atom(provider) and not is_nil(provider) and Code.ensure_loaded?(provider) and
               function_exported?(provider, :classify, 2) do
        {:ok, request}
      else
        false -> {:error, {:unsupported_classifier, provider}}
        error -> error
      end
    else
      {:error, {:invalid_classifier_defaults, :shape}}
    end
  end

  defp model_provider(%GenAI.Model{provider: provider}), do: provider
  defp model_provider(_), do: nil

  defp supported(request) do
    provider = request.provider

    if function_exported?(provider, :classifier_capabilities, 0) do
      capabilities(provider.classifier_capabilities(), request)
    else
      capabilities(%{types: [:boolean, :choice, :score], modalities: [:text]}, request)
    end
  rescue
    _ -> {:error, {:invalid_classifier_capabilities, request.provider}}
  catch
    _, _ -> {:error, {:invalid_classifier_capabilities, request.provider}}
  end

  defp capabilities(capabilities, request) when is_map(capabilities) do
    types = Map.get(capabilities, :types, [])
    modalities = Map.get(capabilities, :modalities, [])
    max_choices = Map.get(capabilities, :max_choices)
    max_questions = Map.get(capabilities, :max_questions)

    cond do
      not is_list(types) or not is_list(modalities) or not valid_limit?(max_choices) or
          not valid_limit?(max_questions) ->
        {:error, {:invalid_classifier_capabilities, request.provider}}

      request.modality not in modalities ->
        {:error, {:unsupported_classifier_modality, request.modality}}

      Enum.any?(request.questions, &(&1.type not in types)) ->
        {:error, :unsupported_classifier_question_type}

      not is_nil(max_choices) and
          Enum.any?(request.questions, &(length(Question.entries(&1)) > max_choices)) ->
        {:error, {:classifier_limit, :max_choices}}

      not is_nil(max_questions) and length(request.questions) > max_questions ->
        {:error, {:classifier_limit, :max_questions}}

      true ->
        :ok
    end
  end

  defp capabilities(_, request),
    do: {:error, {:invalid_classifier_capabilities, request.provider}}

  defp valid_limit?(nil), do: true
  defp valid_limit?(value), do: is_integer(value) and value > 0

  defp invoke(request, options) do
    provider_options = Keyword.merge(request.options, Keyword.drop(options, [:provider, :model]))

    case request.provider.classify(request, provider_options) do
      {:ok, result} -> {:ok, result}
      {:error, _} = error -> error
      _ -> {:error, {:invalid_classifier_response, request.provider}}
    end
  rescue
    exception -> {:error, {:classifier_exception, request.provider, exception.__struct__}}
  catch
    kind, _reason -> {:error, {:classifier_exception, request.provider, kind}}
  end
end
