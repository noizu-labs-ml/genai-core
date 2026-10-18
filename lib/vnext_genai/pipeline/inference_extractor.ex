defmodule GenAI.Pipeline.InferenceExtractor do
  @moduledoc """
  Isolated chat inference that produces a validated extraction envelope.

  The existing conversation and chat model are copied into a temporary turn.
  A model override affects only that temporary turn. The model must return one
  assistant JSON object or one named extraction tool call. Returned inference
  threads are discarded, so extraction never changes the continuing history.
  """
  alias GenAI.Classifier.{Question, Validation}
  alias GenAI.Pipeline
  alias GenAI.Tool.Call

  @tool_name "genai_extract"

  @doc "Infer a payload, validated criteria, or both; runner options are explicit test seams."
  @spec run(Pipeline.t(), String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def run(pipeline, prompt, options \\ [])

  def run(%Pipeline{} = pipeline, prompt, options) when is_binary(prompt) and is_list(options) do
    with true <- Keyword.keyword?(options) and String.trim(prompt) != "",
         kind = Keyword.get(options, :kind, :payload),
         true <- kind in [:payload, :criteria, :both],
         {:ok, temporary, tool_name} <- prepare(pipeline, prompt, kind, options),
         {:ok, {completion, _discarded_thread}} <- Pipeline.run_inference(temporary, options),
         {:ok, envelope} <- envelope(completion, tool_name),
         {:ok, value} <- validate_envelope(envelope, kind) do
      {:ok, value}
    else
      false -> {:error, :invalid_inference_extraction_options}
      {:error, _} = error -> error
      _ -> {:error, :invalid_inference_extraction_response}
    end
  rescue
    exception -> {:error, {:inference_extraction_exception, exception.__struct__}}
  catch
    kind, _reason -> {:error, {:inference_extraction_exception, kind}}
  end

  def run(_, _, _), do: {:error, :invalid_inference_extraction_options}

  defp prepare(pipeline, prompt, kind, options) do
    model = Keyword.get(options, :model)
    thread = if is_nil(model), do: pipeline.thread, else: GenAI.with_model(pipeline.thread, model)

    with {:ok, tool} <- extraction_tool(kind, options),
         {:ok, {resolved, _}} <- resolve_model(thread, pipeline.context, options),
         true <- match?(%GenAI.Model{}, resolved) do
      thread = if is_nil(tool), do: thread, else: GenAI.with_tool(thread, tool)
      schema = schema(kind)

      instructions =
        prompt <>
          "\n\nReturn exactly one JSON object conforming to this schema, or invoke the extraction tool with that object. No Markdown or prose:\n" <>
          Jason.encode!(schema)

      thread = GenAI.with_message(thread, GenAI.Message.user(instructions))
      {:ok, %{pipeline | thread: thread}, if(tool, do: tool.name, else: nil)}
    else
      false -> {:error, :missing_extraction_model}
      {:error, _} = error -> error
      _ -> {:error, :missing_extraction_model}
    end
  end

  # Materialize the override in a private copy before effective_model/3; pending
  # configuration nodes otherwise leave the old model visible to model lookup.
  defp resolve_model(thread, context, options) do
    with {:ok, thread} <- GenAI.Pipeline.Snapshot.materialize(thread, context, options) do
      GenAI.ThreadProtocol.effective_model(thread, context, options)
    end
  rescue
    _ -> {:error, :missing_extraction_model}
  end

  defp extraction_tool(kind, options) do
    case Keyword.get(options, :tool, :default) do
      false ->
        {:ok, nil}

      :default ->
        {:ok,
         GenAI.Tool.new(
           name: @tool_name,
           description: "Return the requested structured extraction",
           parameters: schema(kind)
         )}

      %GenAI.Tool{name: name} = tool when is_binary(name) and name != "" ->
        {:ok, tool}

      _ ->
        {:error, :invalid_extraction_tool}
    end
  end

  defp schema(kind) do
    required =
      case kind do
        :payload -> ["payload"]
        :criteria -> ["criteria"]
        :both -> ["payload", "criteria"]
      end

    properties = %{
      "payload" => %{},
      "criteria" => %{
        "type" => "array",
        "minItems" => 1,
        "items" => %{
          "type" => "object",
          "required" => ["id", "type"],
          "properties" => %{
            "id" => %{"type" => "string"},
            "type" => %{"enum" => ["choice", "boolean", "score"]},
            "instructions" => %{"type" => "string"},
            "choices" => %{"type" => "array"},
            "rubric" => %{"type" => "array"},
            "metadata" => %{"type" => "object"}
          }
        }
      }
    }

    %{
      "type" => "object",
      "required" => required,
      "properties" => Map.take(properties, required),
      "additionalProperties" => false
    }
  end

  defp envelope(%GenAI.ChatCompletion{choices: [%{message: message}]}, tool_name),
    do: message_envelope(message, tool_name)

  defp envelope(_, _), do: {:error, :invalid_extraction_completion}

  defp message_envelope(%GenAI.Message.ToolUsage{tool_calls: [call]}, tool_name)
       when is_binary(tool_name) do
    with {:ok, call} <- Call.normalize(call),
         true <- call.name == tool_name and Validation.string?(call.id) do
      {:ok, call.arguments}
    else
      false -> {:error, :uncorrelated_extraction_tool_call}
      {:error, _} = error -> error
    end
  end

  defp message_envelope(%GenAI.Message{role: :assistant, content: content}, _)
       when is_binary(content), do: decode_envelope(content)

  defp message_envelope(_, _), do: {:error, :missing_structured_extraction}

  defp decode_envelope(content) do
    case Jason.decode(content) do
      {:ok, value} when is_map(value) -> {:ok, value}
      _ -> {:error, :invalid_extraction_json}
    end
  end

  defp validate_envelope(envelope, kind) when is_map(envelope) do
    required =
      case kind do
        :payload -> ["payload"]
        :criteria -> ["criteria"]
        :both -> ["payload", "criteria"]
      end

    # Accept only these fixed atom keys from local fixtures; external JSON keys
    # remain strings and never cause atom creation.
    normalized =
      Map.new(envelope, fn
        {key, value} when key in [:payload, :criteria] -> {Atom.to_string(key), value}
        entry -> entry
      end)

    if Enum.sort(Map.keys(normalized)) == Enum.sort(required) and
         (kind == :criteria or not is_nil(normalized["payload"])) do
      value(kind, normalized)
    else
      {:error, :invalid_extraction_envelope}
    end
  end

  defp validate_envelope(_, _), do: {:error, :invalid_extraction_envelope}

  defp value(:payload, envelope), do: {:ok, envelope["payload"]}
  defp value(:criteria, envelope), do: criteria(envelope["criteria"])

  defp value(:both, envelope) do
    with {:ok, criteria} <- criteria(envelope["criteria"]) do
      {:ok, %{payload: envelope["payload"], criteria: criteria}}
    end
  end

  defp criteria(values) when is_list(values) and values != [] do
    with {:ok, questions} <- Validation.collect(values, &Question.normalize/1),
         true <- Validation.unique?(Enum.map(questions, & &1.id)) do
      {:ok, questions}
    else
      false -> {:error, :duplicate_extraction_question_ids}
      {:error, reason} -> {:error, {:invalid_extraction_criteria, reason}}
    end
  end

  defp criteria(_), do: {:error, :invalid_extraction_criteria}
end
