defmodule GenAI.ClassifierTest do
  use ExUnit.Case, async: true

  alias GenAI.Classifier.{Question, Request, Result}
  alias GenAI.Classifier.Result.Answer

  defmodule Fixture do
    @behaviour GenAI.Classifier.ProviderBehaviour
    def classifier_capabilities,
      do: %{
        types: [:choice, :boolean, :score],
        modalities: [:text],
        max_choices: 5,
        max_questions: 4
      }

    def classify(request, options) do
      send(options[:test_pid] || self(), {:classified, request, options})
      {:ok, %{answers: Enum.map(request.questions, &answer/1)}}
    end

    defp answer(%{type: :boolean, id: id}),
      do: %{question_id: id, value: false, distribution: [0.8, 0.2]}

    defp answer(%{type: :choice, id: id}),
      do: %{
        question_id: id,
        index: 1,
        distribution: [0.25, 0.75],
        selected_probability: 0.75,
        provider_confidence: 0.9,
        confidence_metadata: %{meaning: :calibration}
      }

    defp answer(%{type: :score, id: id}),
      do: %{question_id: id, expected_score: 1.6, distribution: [0.4, 0.6]}
  end

  defmodule LegacyChat do
    def run(_, _, _), do: {:error, :not_called}
  end

  defmodule InvalidProvider do
    def classify(_, options), do: Keyword.fetch!(options, :response)
  end

  defmodule Limited do
    def classifier_capabilities, do: %{types: [:boolean], modalities: [:text], max_questions: 1}
    def classify(_, _), do: raise("must reject before invoking")
  end

  defmodule Raises do
    def classify(_, _), do: raise("payload should not appear in router error")
  end

  defmodule ThrowsCapabilities do
    def classifier_capabilities, do: throw(%{private: "must not appear"})
    def classify(_, _), do: raise("must reject before invoking")
  end

  defmodule ExitsCapabilities do
    def classifier_capabilities, do: exit(%{private: "must not appear"})
    def classify(_, _), do: raise("must reject before invoking")
  end

  defp choice_request(options \\ []) do
    %Request{
      input: "candidate",
      provider: Fixture,
      options: options,
      questions: [%Question{id: "pick", choices: ["a", "b"]}]
    }
  end

  defp score_question do
    %Question{
      id: "grade",
      type: :score,
      rubric: [%{id: "low", label: "Low", score: 1}, %{id: "high", label: "High", score: 2}]
    }
  end

  defp result_for(answer) do
    {:ok, request} = Request.normalize(choice_request())
    Result.normalize(%{answers: [Map.put(answer, :question_id, "pick")]}, request)
  end

  test "normalizes string keys and preserves ordered criteria and question IDs" do
    assert {:ok, request} =
             Request.normalize(%{
               "input" => "payload",
               "questions" => [%{"id" => "pick-123", "type" => "choice", "choices" => ["z", "a"]}]
             })

    assert [%Question{id: "pick-123", type: :choice, choices: [%{id: "z"}, %{id: "a"}]}] =
             request.questions
  end

  test "returns typed standalone decisions without mixing probability and confidence" do
    assert {:ok, %Result{answers: [answer], provider: Fixture}} = GenAI.classify(choice_request())

    assert %Answer{
             question_id: "pick",
             index: 1,
             distribution: [0.25, 0.75],
             selected_probability: 0.75,
             provider_confidence: 0.9
           } = answer

    assert answer.expected_score == nil
    assert answer.grade == nil
    assert_receive {:classified, %Request{}, _}
  end

  test "supports standard model references and a provider selected from the model" do
    model = %GenAI.Model{provider: Fixture, model: "fixture-decision"}

    assert {:ok, %Result{model: ^model}} =
             GenAI.classify(%{choice_request() | provider: nil, model: model})
  end

  test "explicit provider/model options override request and merge provider options" do
    original = %GenAI.Model{provider: LegacyChat, model: "chat"}
    override = %GenAI.Model{provider: Fixture, model: "decision"}

    assert {:ok, %Result{model: ^override}} =
             GenAI.classify(%{choice_request(seed: 1) | provider: LegacyChat, model: original},
               provider: Fixture,
               model: override,
               seed: 2
             )

    assert_receive {:classified, %Request{model: ^override}, [seed: 2]}
  end

  test "keeps absent optional fields absent for boolean inference" do
    assert {:ok, %Result{answers: [answer]}} =
             GenAI.classify(%{
               choice_request()
               | questions: [%Question{id: "yes", type: :boolean}]
             })

    assert answer.value == false
    assert answer.selected_probability == nil
    assert answer.provider_confidence == nil
  end

  test "expected ordinal score does not fabricate a chosen grade" do
    assert {:ok, %Result{answers: [answer]}} =
             GenAI.classify(%{choice_request() | questions: [score_question()]})

    assert answer.expected_score == 1.6
    assert answer.grade == nil
    assert answer.index == nil
  end

  test "validates a chosen grade separately from expected score" do
    {:ok, request} = Request.normalize(%{choice_request() | questions: [score_question()]})

    assert {:ok, %Result{answers: [%Answer{grade: "high", index: 1, expected_score: 1.6}]}} =
             Result.normalize(
               %{answers: [%{question_id: "grade", grade: "high", expected_score: 1.6}]},
               request
             )
  end

  test "rejects malformed request inputs and duplicate question IDs" do
    assert {:error, {:invalid_classifier_request, :shape}} = GenAI.classify("payload")

    assert {:error, {:invalid_classifier_request, :input}} =
             GenAI.classify(%{choice_request() | input: nil})

    assert {:error, {:invalid_classifier_request, :duplicate_question_ids}} =
             GenAI.classify(%{
               choice_request()
               | questions: choice_request().questions ++ choice_request().questions
             })

    assert {:error, {:invalid_question, :id}} =
             GenAI.classify(%{
               choice_request()
               | questions: [%Question{id: :atom_id, choices: ["a", "b"]}]
             })
  end

  test "rejects duplicate choice IDs and unordered score rubrics" do
    assert {:error, {:invalid_question, :duplicate_choice_ids}} =
             GenAI.classify(%{
               choice_request()
               | questions: [%Question{id: "pick", choices: ["a", "a"]}]
             })

    question = score_question()

    assert {:error, {:invalid_question, :duplicate_or_unordered_rubric}} =
             GenAI.classify(%{
               choice_request()
               | questions: [%{question | rubric: Enum.reverse(question.rubric)}]
             })
  end

  test "does not fall back to chat for an unsupported classifier" do
    assert {:error, {:unsupported_classifier, LegacyChat}} =
             GenAI.classify(choice_request(), provider: LegacyChat)
  end

  test "rejects unsupported modality/type and request limits before inference" do
    assert {:error, {:unsupported_classifier_modality, :image}} =
             GenAI.classify(%{choice_request() | modality: :image})

    assert {:error, :unsupported_classifier_question_type} =
             GenAI.classify(choice_request(), provider: Limited)

    boolean = %Question{id: "first", type: :boolean}

    assert {:error, {:classifier_limit, :max_questions}} =
             GenAI.classify(%{choice_request() | questions: [boolean, %{boolean | id: "second"}]},
               provider: Limited
             )

    assert {:error, {:classifier_limit, :max_choices}} =
             GenAI.classify(%{
               choice_request()
               | questions: [%Question{id: "many", choices: ["1", "2", "3", "4", "5", "6"]}]
             })
  end

  test "rejects missing, extra or duplicate provider answers" do
    for answers <- [
          [],
          [%{question_id: "other", index: 0}],
          [%{question_id: "pick", index: 0}, %{question_id: "pick", index: 1}]
        ] do
      assert {:error, {:invalid_classifier_result, :answers_or_metadata}} =
               GenAI.classify(choice_request(),
                 provider: InvalidProvider,
                 response: {:ok, %{answers: answers}}
               )
    end
  end

  test "rejects invalid distribution size, values and normalization" do
    for distribution <- [[1.0], [-0.1, 1.1], [0.2, 0.2], ["0.5", 0.5], %{a: 0.5, b: 0.5}] do
      assert {:error, {:invalid_classifier_answer, "pick", :distribution}} =
               result_for(%{index: 0, distribution: distribution})
    end
  end

  test "rejects out-of-range and contradictory selected criteria" do
    for index <- [-1, 2, 0.5] do
      assert {:error, {:invalid_classifier_answer, "pick", :choice_index}} =
               result_for(%{index: index})
    end

    assert {:error, {:invalid_classifier_answer, "pick", :inconsistent_selection}} =
             result_for(%{index: 0, choice_id: "b"})

    assert {:error, {:invalid_classifier_answer, "pick", :unknown_choice}} =
             result_for(%{choice_id: "absent"})
  end

  test "rejects selected probability inconsistent with the ordered distribution" do
    assert {:error, {:invalid_classifier_answer, "pick", :inconsistent_selected_probability}} =
             result_for(%{index: 1, distribution: [0.25, 0.75], selected_probability: 0.9})
  end

  test "normalizes a string-keyed answer without converting external IDs to atoms" do
    {:ok, request} = Request.normalize(choice_request())

    assert {:ok, %Result{answers: [%Answer{question_id: "pick", type: :choice, index: 0}]}} =
             Result.normalize(
               %{
                 "answers" => [%{"question_id" => "pick", "type" => "choice", "choice_id" => "a"}]
               },
               request
             )
  end

  test "rejects invalid boolean decisions and out-of-scale expected scores" do
    {:ok, boolean_request} =
      Request.normalize(%{choice_request() | questions: [%Question{id: "bool", type: :boolean}]})

    assert {:error, {:invalid_classifier_answer, "bool", :boolean_selection}} =
             Result.normalize(
               %{answers: [%{question_id: "bool", value: "false"}]},
               boolean_request
             )

    {:ok, score_request} = Request.normalize(%{choice_request() | questions: [score_question()]})

    for value <- [0, 3, "1.5"] do
      assert {:error, {:invalid_classifier_answer, "grade", :expected_score}} =
               Result.normalize(
                 %{answers: [%{question_id: "grade", expected_score: value}]},
                 score_request
               )
    end
  end

  test "rejects an expected score that disagrees with the rubric distribution" do
    {:ok, request} = Request.normalize(%{choice_request() | questions: [score_question()]})

    assert {:error, {:invalid_classifier_answer, "grade", :inconsistent_expected_score}} =
             Result.normalize(
               %{answers: [%{question_id: "grade", expected_score: 2, distribution: [1.0, 0.0]}]},
               request
             )
  end

  test "orders returned answers by request question IDs" do
    second = %Question{id: "second", choices: ["a", "b"]}
    request = %{choice_request() | questions: choice_request().questions ++ [second]}

    assert {:ok, %Result{answers: [%Answer{question_id: "pick"}, %Answer{question_id: "second"}]}} =
             GenAI.classify(request,
               provider: InvalidProvider,
               response:
                 {:ok,
                  %{
                    answers: [
                      %{question_id: "second", index: 0},
                      %{question_id: "pick", index: 1}
                    ]
                  }}
             )
  end

  test "normalizes provider failures and exceptions without returning exception text" do
    assert {:error, :offline} =
             GenAI.classify(choice_request(),
               provider: InvalidProvider,
               response: {:error, :offline}
             )

    assert {:error, {:invalid_classifier_response, InvalidProvider}} =
             GenAI.classify(choice_request(), provider: InvalidProvider, response: :wrong)

    assert {:error, {:classifier_exception, Raises, RuntimeError}} =
             GenAI.classify(choice_request(), provider: Raises)
  end

  test "normalizes capability callback throws without retaining the thrown payload" do
    assert {:error, {:invalid_classifier_capabilities, ThrowsCapabilities}} =
             GenAI.classify(choice_request(), provider: ThrowsCapabilities)
  end

  test "normalizes capability callback exits without retaining the exit reason" do
    assert {:error, {:invalid_classifier_capabilities, ExitsCapabilities}} =
             GenAI.classify(choice_request(), provider: ExitsCapabilities)
  end

  test "rejects invalid call options" do
    assert {:error, {:invalid_classifier_options, :shape}} = GenAI.classify(choice_request(), %{})

    assert {:error, {:invalid_classifier_options, :shape}} =
             GenAI.classify(choice_request(), [:bad])
  end
end

defmodule GenAI.ClassifierDefaultsTest do
  use ExUnit.Case, async: false
  alias GenAI.Classifier.{Request, Question, Result}

  setup do
    previous = Application.fetch_env(:genai, :classifier)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:genai, :classifier, value)
        :error -> Application.delete_env(:genai, :classifier)
      end
    end)

    :ok
  end

  test "uses explicit configured classifier defaults" do
    model = %GenAI.Model{model: "configured", provider: GenAI.ClassifierTest.Fixture}
    Application.put_env(:genai, :classifier, model: model)
    request = %Request{input: "payload", questions: [%Question{id: "pick", choices: ["a", "b"]}]}

    assert {:ok, %Result{model: ^model, provider: GenAI.ClassifierTest.Fixture}} =
             GenAI.classify(request)
  end

  test "rejects malformed classifier defaults instead of failing in dispatch" do
    Application.put_env(:genai, :classifier, %{provider: GenAI.ClassifierTest.Fixture})
    request = %Request{input: "payload", questions: [%Question{id: "pick", choices: ["a", "b"]}]}
    assert {:error, {:invalid_classifier_defaults, :shape}} = GenAI.classify(request)
  end
end
