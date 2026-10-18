defmodule GenAI.Pipeline.InferenceExtractorTest do
  use ExUnit.Case, async: true

  alias GenAI.Classifier.Question
  alias GenAI.Pipeline
  alias GenAI.Pipeline.{InferenceExtractor, Snapshot}

  defmodule FixtureProvider do
    use GenAI.InferenceProviderBehaviour

    def do_run(thread, context, options) do
      {:ok, {model, thread}} = GenAI.ThreadProtocol.effective_model(thread, context, options)

      send(
        options[:test_pid],
        {:extractor_provider, model.model, Snapshot.messages(thread), thread.state.tools}
      )

      message = options[:message] || GenAI.Message.assistant("{\"payload\":\"extracted\"}")
      choices = options[:choices] || [%GenAI.ChatCompletion.Choice{index: 0, message: message}]

      completion = %GenAI.ChatCompletion{
        model: model.model,
        provider: __MODULE__,
        choices: choices
      }

      {:ok, {completion, GenAI.with_message(thread, GenAI.Message.assistant("temporary only"))}}
    end
  end

  defmodule FixtureClassifier do
    @behaviour GenAI.Classifier.ProviderBehaviour
    def classify(request, _options) do
      {:ok, %{answers: Enum.map(request.questions, &%{question_id: &1.id, index: 1})}}
    end
  end

  defp pipeline do
    model = %GenAI.Model{model: "default-chat", provider: FixtureProvider}

    thread =
      GenAI.chat(:session)
      |> GenAI.with_model(model)
      |> GenAI.with_message(GenAI.Message.user("first"))
      |> GenAI.with_message(GenAI.Message.assistant("second"))
      |> GenAI.with_message(GenAI.Message.user("latest pending"))

    {:ok, pipeline} = Pipeline.new(thread)
    pipeline
  end

  defp options(message \\ nil), do: [run_options: [test_pid: self(), message: message]]
  defp json(value), do: GenAI.Message.assistant(Jason.encode!(value))

  test "uses the real GenAI provider path and current chat model with chronological context" do
    pipeline = pipeline()

    assert {:ok, "extracted"} =
             InferenceExtractor.run(pipeline, "Extract the final request", options())

    assert_receive {:extractor_provider, "default-chat", messages, tools}
    assert Enum.map(Enum.take(messages, 3), & &1.content) == ["first", "second", "latest pending"]
    assert List.last(messages).content =~ "Extract the final request"
    assert Map.has_key?(tools, "genai_extract")

    assert Enum.map(Snapshot.messages(pipeline.thread), & &1.content) == [
             "first",
             "second",
             "latest pending"
           ]

    assert pipeline.frames == []
  end

  test "overrides the extraction model while preserving the continuing thread model" do
    pipeline = pipeline()
    override = %GenAI.Model{model: "extract-only", provider: FixtureProvider}

    assert {:ok, "extracted"} =
             InferenceExtractor.run(pipeline, "Extract", Keyword.put(options(), :model, override))

    assert_receive {:extractor_provider, "extract-only", _, _}

    assert {:ok, {%GenAI.Model{model: "default-chat"}, _}} =
             GenAI.ThreadProtocol.effective_model(pipeline.thread, pipeline.context, [])
  end

  test "extracts validated dynamic payload and criteria without classifier inference" do
    envelope = %{
      payload: %{text: "candidate"},
      criteria: [%{id: "pick", type: "choice", choices: ["a", "b"]}]
    }

    assert {:ok,
            %{payload: %{"text" => "candidate"}, criteria: [%Question{id: "pick", type: :choice}]}} =
             InferenceExtractor.run(
               pipeline(),
               "Prepare decision",
               Keyword.put(options(json(envelope)), :kind, :both)
             )
  end

  test "accepts one correlated named extraction tool call" do
    call = %GenAI.Message.ToolCall{
      id: "call-extract",
      tool_name: "genai_extract",
      arguments: "{\"payload\":{\"text\":\"candidate\"}}"
    }

    message = GenAI.Message.ToolUsage.new(role: :assistant, tool_calls: [call])

    assert {:ok, %{"text" => "candidate"}} =
             InferenceExtractor.run(pipeline(), "Extract", options(message))
  end

  test "supports criteria-only output and a caller-supplied extraction tool" do
    tool = GenAI.Tool.new(name: "custom_extract", parameters: %{"type" => "object"})

    call = %GenAI.Tool.Call{
      id: "custom-call",
      name: "custom_extract",
      arguments: %{criteria: [%{id: "yes", type: :boolean}]}
    }

    message = GenAI.Message.ToolUsage.new(role: :assistant, tool_calls: [call])
    opts = options(message) |> Keyword.put(:kind, :criteria) |> Keyword.put(:tool, tool)

    assert {:ok, [%Question{id: "yes", type: :boolean}]} =
             InferenceExtractor.run(pipeline(), "Extract criteria", opts)
  end

  test "rejects absent, malformed and non-object JSON rather than treating prose as payload" do
    for content <- [
          "unstructured text",
          "[]",
          "{}",
          "{\"payload\":null}",
          "```json\n{\"payload\":\"x\"}\n```",
          "{\"payload\":\"x\",\"unexpected\":1}"
        ] do
      assert {:error, _} =
               InferenceExtractor.run(
                 pipeline(),
                 "Extract",
                 options(GenAI.Message.assistant(content))
               )
    end
  end

  test "rejects malformed dynamic criteria and duplicate question IDs" do
    for criteria <- [
          [],
          [%{id: "pick", type: "choice", choices: ["only"]}],
          [%{id: "same", type: "boolean"}, %{id: "same", type: "boolean"}],
          [%{id: 42, type: "boolean"}]
        ] do
      assert {:error, _} =
               InferenceExtractor.run(
                 pipeline(),
                 "Extract",
                 Keyword.put(options(json(%{criteria: criteria})), :kind, :criteria)
               )
    end
  end

  test "rejects mismatched or missing extraction tool correlation" do
    for call <- [
          %GenAI.Tool.Call{id: "id", name: "other", arguments: %{payload: "x"}},
          %GenAI.Tool.Call{id: nil, name: "genai_extract", arguments: %{payload: "x"}}
        ] do
      message = GenAI.Message.ToolUsage.new(role: :assistant, tool_calls: [call])

      assert {:error, :uncorrelated_extraction_tool_call} =
               InferenceExtractor.run(pipeline(), "Extract", options(message))
    end
  end

  test "rejects ambiguous completions and invalid prompts/kinds" do
    message = json(%{payload: "x"})

    choices = [
      %GenAI.ChatCompletion.Choice{message: message},
      %GenAI.ChatCompletion.Choice{message: message}
    ]

    assert {:error, :invalid_extraction_completion} =
             InferenceExtractor.run(pipeline(), "Extract",
               run_options: [test_pid: self(), choices: choices]
             )

    assert {:error, :invalid_inference_extraction_options} =
             InferenceExtractor.run(pipeline(), " ", options())

    assert {:error, :invalid_inference_extraction_options} =
             InferenceExtractor.run(pipeline(), "Extract", kind: :unknown)
  end

  test "supports explicit JSON-only execution and runner seam without changing history" do
    pipeline = pipeline()

    runner = fn thread, _, _ ->
      {:ok,
       {%GenAI.ChatCompletion{
          choices: [%GenAI.ChatCompletion.Choice{message: json(%{payload: false})}]
        }, thread}}
    end

    assert {:ok, false} = InferenceExtractor.run(pipeline, "Extract", tool: false, run: runner)
    assert length(Snapshot.messages(pipeline.thread)) == 3
  end

  test "feeds inference-extracted payload and criteria into the classifier pipeline" do
    envelope = %{
      payload: "candidate",
      criteria: [%{id: "pick", type: "choice", choices: ["a", "b"]}]
    }

    opts = options(json(envelope)) |> Keyword.put(:kind, :both)
    assert {:ok, extracted} = Pipeline.extract(pipeline(), {:inference, "Prepare decision"}, opts)
    assert length(extracted.frames) == 2
    assert {:ok, classified} = Pipeline.classify(extracted, provider: FixtureClassifier)

    assert [
             %GenAI.Pipeline.Frame{
               kind: :result,
               value: %GenAI.Classifier.Result{answers: [answer]}
             }
           ] = classified.frames

    assert answer.question_id == "pick"
    assert answer.index == 1
    assert length(Snapshot.messages(classified.thread)) == 3
  end

  test "rejects missing model instead of silently selecting a classifier or other chat model" do
    {:ok, pipeline} =
      Pipeline.new(GenAI.chat(:session) |> GenAI.with_message(GenAI.Message.user("message")))

    assert {:error, :missing_extraction_model} =
             InferenceExtractor.run(pipeline, "Extract", options())
  end
end
