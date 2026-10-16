defmodule GenAI.PipelineTest do
  use ExUnit.Case, async: true
  alias GenAI.Pipeline
  alias GenAI.Pipeline.Snapshot

  defmodule ClassifierFixture do
    @behaviour GenAI.Classifier.ProviderBehaviour
    def classify(request, options) do
      if options[:observer], do: send(options[:observer], {:classified, request})

      {:ok,
       %{
         answers:
           Enum.map(request.questions, fn q ->
             case q.type do
               :boolean -> %{question_id: q.id, type: :boolean, value: true}
               :choice -> %{question_id: q.id, type: :choice, index: 1}
             end
           end)
       }}
    end
  end

  defp thread(type \\ :session) do
    GenAI.chat(type)
    |> GenAI.with_message(GenAI.Message.system("system"))
    |> GenAI.with_message(GenAI.Message.user("first"))
    |> GenAI.with_message(GenAI.Message.assistant("response"))
    |> GenAI.with_message(GenAI.Message.user("pending last"))
  end

  test "neutral extraction includes pending messages and repeated projection is idempotent" do
    for type <- [:session, :standard] do
      {:ok, pipeline} = Pipeline.new(thread(type))
      {:ok, extracted} = Pipeline.extract(pipeline, :last_message)
      assert hd(extracted.frames).value == "pending last"

      {:ok, extracted} =
        Pipeline.extract(extracted, {:literal, [%{id: "q", type: :boolean}]}, kind: :criteria)

      assert Enum.map(Snapshot.messages(extracted.thread), & &1.content) == [
               "system",
               "first",
               "response",
               "pending last"
             ]

      assert Enum.map(extracted.frames, & &1.kind) == [:criteria, :payload]
      assert Enum.uniq(Enum.map(extracted.frames, & &1.revision)) |> length() == 1
    end
  end

  test "last assistant and prompt+response select raw content" do
    {:ok, p} = Pipeline.extract(thread(), :last_response)
    assert hd(p.frames).value == "response"
    {:ok, p} = Pipeline.extract(p, :prompt_last_response, prompt: "grade this")
    assert hd(p.frames).value == %{prompt: "grade this", response: "response"}
  end

  test "safe selectors support explicit JSON paths, grep, XML, YAML blocks and missing paths" do
    assert {:ok, 2} = GenAI.Pipeline.Selector.select(~s({"a":[1,2]}), {:json, ["a", 1]})

    assert {:error, :not_found} =
             GenAI.Pipeline.Selector.select(~s({"a":[1,2]}), {:json, ["a", 4]})

    assert {:ok, [["one"], ["one"]]} =
             GenAI.Pipeline.Selector.select("one two one", {:grep, ~r/one/})

    assert {:ok, ["hello"]} =
             GenAI.Pipeline.Selector.select(
               "<root><value>hello</value></root>",
               {:xml, "//value/text()"}
             )

    assert {:ok, ["a: 1"]} =
             GenAI.Pipeline.Selector.select("```yaml\na: 1\n```", {:yaml_blocks, "yaml"})

    assert {:error, :unsupported_selector} =
             GenAI.Pipeline.Selector.select("hello", {:shell, "cat"})
  end

  test "aggregation traverses forward or backward, serializes text/json/yaml and reports missing" do
    {:ok, p} = Pipeline.aggregate(thread(), :content, role: :user)
    assert hd(p.frames).value == ["first", "pending last"]

    {:ok, p} =
      Pipeline.aggregate(thread(), :content, role: :user, direction: :backward, format: :json)

    assert Jason.decode!(hd(p.frames).value) == ["pending last", "first"]
    {:ok, p} = Pipeline.aggregate(thread(), :content, role: :user, format: :yaml)
    assert hd(p.frames).value =~ "pending last"

    assert {:error, :invalid_direction} =
             Pipeline.aggregate(thread(), :content, direction: :sideways)
  end

  test "trusted callbacks receive thread messages and options, errors remain tagged" do
    {:ok, p} =
      Pipeline.extract(
        thread(),
        {:callback, fn messages, opts -> {length(messages), opts[:value]} end},
        value: 42
      )

    assert hd(p.frames).value == {4, 42}

    assert {:error, {:callback_exception, RuntimeError}} =
             Pipeline.extract(thread(), {:inference, fn _, _ -> raise "failed" end})
  end

  test "aggregate serialization failures remain tagged without retaining the tool payload" do
    source =
      GenAI.with_message(
        thread(),
        GenAI.Message.ToolResponse.new(
          tool_call_id: "fixture-call",
          tool_name: "fixture",
          tool_response: %{private: fn -> "private-payload" end}
        )
      )

    for format <- [:json, :yaml, :text] do
      assert {:error, {:aggregate_serialization, reason}} =
               Pipeline.aggregate(source, :content, role: :tool, format: format)

      assert is_atom(reason)

      assert {:error, {:aggregate_serialization, ^reason}} =
               source
               |> Pipeline.aggregate(:content, role: :tool, format: format)
               |> Pipeline.append_result()
               |> Pipeline.next_turn()
    end
  end

  test "transform changes continuing thread and invalidates frames; manual stale frames rejected" do
    {:ok, p} = Pipeline.extract(thread(), :last_message)

    {:ok, transformed} =
      Pipeline.transform(p, fn thread, _ ->
        GenAI.with_message(thread, GenAI.Message.system("memory"))
      end)

    assert transformed.frames == []
    assert List.last(Snapshot.messages(transformed.thread)).content == "memory"
    stale = %{transformed | frames: p.frames}
    assert {:error, :stale_frame} = Pipeline.append_result(stale)
    assert {:error, :empty_stack} = Pipeline.append_result(transformed)
  end

  test "append result correlates tool exchange and optional final JSON without inference" do
    {:ok, p} = Pipeline.extract(thread(), {:literal, %{value: "safe"}})
    {:ok, appended} = Pipeline.append_result(p, final: :json)
    {:ok, appended} = Pipeline.refresh(appended)
    messages = Snapshot.messages(appended.thread)
    [call, response, final] = Enum.take(messages, -3)
    assert %GenAI.Message.ToolUsage{role: :assistant, tool_calls: [tool]} = call

    assert %GenAI.Message.ToolResponse{tool_call_id: id, tool_response: %{value: "safe"}} =
             response

    assert tool.id == id
    assert %GenAI.Message{role: :assistant} = final
    assert Jason.decode!(final.content) == %{"value" => "safe"}
    assert appended.frames == []
  end

  test "fork state, artifacts and frames are isolated, and append joins deltas in stable order" do
    {:fork, branches} =
      Pipeline.fork(thread(),
        a: fn p ->
          {:ok, p} =
            Pipeline.transform(p, fn t, _ ->
              GenAI.with_message(t, GenAI.Message.assistant("A"))
            end)

          %{p | artifacts: %{memory: "a"}}
        end,
        b: fn p ->
          {:ok, p} =
            Pipeline.transform(p, fn t, _ ->
              GenAI.with_message(t, GenAI.Message.assistant("B"))
            end)

          %{p | artifacts: %{memory: "b"}}
        end
      )

    assert Enum.map(branches, & &1.id) == [:a, :b]
    assert Enum.map(branches, & &1.pipeline.artifacts.memory) == ["a", "b"]
    assert {:error, :explicit_join_mode_required} = Pipeline.join({:fork, branches})
    {:ok, joined} = Pipeline.join({:fork, branches}, mode: :append)
    {:ok, joined} = Pipeline.refresh(joined)

    assert Enum.map(Snapshot.messages(joined.thread), & &1.content) == [
             "system",
             "first",
             "response",
             "pending last",
             "A",
             "B"
           ]

    {:ok, selected} = Pipeline.join({:fork, branches}, mode: :select, branch: :b)
    assert selected.artifacts.memory == "b"

    assert {:error, :unknown_branch} =
             Pipeline.join({:fork, branches}, mode: :select, branch: :unknown)
  end

  test "agent postprocess reduces independently extracted memory and mood to one appended result" do
    {:fork, branches} =
      Pipeline.fork(thread(),
        memory: &Pipeline.extract(&1, {:literal, %{memory: "remember"}}),
        mood: &Pipeline.extract(&1, {:literal, %{interest: 0.9}})
      )

    {:ok, joined} =
      Pipeline.join({:fork, branches},
        mode: :reduce,
        reducer: fn branches -> Map.new(branches, &{&1.id, hd(&1.pipeline.frames).value}) end
      )

    assert hd(joined.frames).value == %{memory: %{memory: "remember"}, mood: %{interest: 0.9}}
    {:ok, joined} = Pipeline.append_result(joined, final: :json)
    {:ok, joined} = Pipeline.refresh(joined)
    assert length(Snapshot.messages(joined.thread)) == 7
  end

  test "NextTurn broadcasts exactly one invocation per copy and preserves returned thread" do
    parent = self()

    run = fn t, _, _ ->
      send(parent, :called)

      completion = %GenAI.ChatCompletion{
        choices: [%GenAI.ChatCompletion.Choice{message: GenAI.Message.assistant("new")}]
      }

      {:ok, {completion, t}}
    end

    {:fork, branches} =
      thread() |> Pipeline.split(3) |> Pipeline.next_turn(run: run, max_concurrency: 2)

    for _ <- 1..3, do: assert_receive(:called)
    refute_receive(:called)
    assert Enum.map(branches, & &1.id) == [0, 1, 2]

    for branch <- branches do
      {:ok, p} = Pipeline.refresh(branch.pipeline)

      assert Enum.map(Snapshot.messages(p.thread), & &1.content) == [
               "system",
               "first",
               "response",
               "pending last",
               "new"
             ]
    end
  end

  test "NextTurn respects provider-appended assistant messages" do
    run = fn t, _, _ ->
      message = GenAI.Message.assistant("new")

      completion = %GenAI.ChatCompletion{
        choices: [%GenAI.ChatCompletion.Choice{message: message}]
      }

      {:ok, {completion, GenAI.with_message(t, message)}}
    end

    {:ok, p} = Pipeline.next_turn(thread(), run: run)
    {:ok, p} = Pipeline.refresh(p)
    assert length(Snapshot.messages(p.thread)) == 5
  end

  test "fork catches branch exceptions and times out workers without losing identity or partial successes" do
    {:fork, branches} =
      Pipeline.fork(
        thread(),
        [ok: fn p -> p end, bad: fn _ -> raise "bad" end, slow: fn _ -> Process.sleep(100) end],
        timeout: 5
      )

    assert Enum.map(branches, & &1.id) == [:ok, :bad, :slow]
    assert hd(branches).error == nil
    assert Enum.at(branches, 1).error == {:callback_exception, RuntimeError}
    assert Enum.at(branches, 2).error == {:branch_exit, :timeout}

    assert {:error, {:branch_failures, ^branches}} =
             Pipeline.join({:fork, branches}, mode: :append)

    assert {:error, :invalid_parallel_limits} = Pipeline.split(thread(), 2, max_concurrency: 0)
    assert {:error, :invalid_split_count} = Pipeline.split(thread(), 65)
  end

  test "nested forks require explicit collapse and incompatible transformed histories cannot append" do
    nested = Pipeline.fork(thread(), a: &Pipeline.split(&1, 2))
    assert {:error, :nested_join_required} = Pipeline.join(nested, mode: :append)

    {:fork, branches} =
      Pipeline.fork(thread(),
        a: fn p -> p end,
        b: fn p ->
          Pipeline.transform(p, fn _, _ ->
            GenAI.chat(:session) |> GenAI.with_message(GenAI.Message.user("different"))
          end)
        end
      )

    assert {:error, :incompatible_branch_prefix} = Pipeline.join({:fork, branches}, mode: :append)
  end

  test "errors flow through ordinary pipeline pipes" do
    assert {:error, :unsupported_selector} =
             thread()
             |> Pipeline.extract(:shell)
             |> Pipeline.append_result()
             |> Pipeline.next_turn()
  end

  test "one callback may bind payload and criteria together" do
    {:ok, p} =
      Pipeline.extract(
        thread(),
        {:callback, fn _, _ -> %{payload: "text", criteria: [%{id: "q", type: :boolean}]} end},
        kind: :both
      )

    assert Enum.map(p.frames, &{&1.kind, &1.value}) == [
             criteria: [%{id: "q", type: :boolean}],
             payload: "text"
           ]
  end

  test "NextTurn may produce the same content on successive turns" do
    run = fn t, _, _ ->
      {:ok,
       {%GenAI.ChatCompletion{
          choices: [%GenAI.ChatCompletion.Choice{message: GenAI.Message.assistant("response")}]
        }, t}}
    end

    {:ok, p} = thread() |> Pipeline.next_turn(run: run) |> Pipeline.next_turn(run: run)
    {:ok, p} = Pipeline.refresh(p)

    assert Enum.map(Snapshot.messages(p.thread), & &1.content) == [
             "system",
             "first",
             "response",
             "pending last",
             "response",
             "response"
           ]
  end

  test "projection preserves model/settings and ordinary provider run after extracting" do
    model = GenAI.Support.TestProvider.Models.model_one()
    source = thread() |> GenAI.with_model(model) |> GenAI.with_setting(:temperature, 0.5)
    {:ok, p} = Pipeline.extract(source, :last_message)

    assert {:ok, {actual_model, _}} =
             GenAI.ThreadProtocol.effective_model(p.thread, p.context, [])

    assert actual_model.model == model.model
    assert actual_model.provider == model.provider
    assert actual_model.encoder == model.encoder
    assert {:ok, {settings, _}} = GenAI.ThreadProtocol.effective_settings(p.thread, p.context, [])
    assert settings[:temperature] == 0.5
    assert {:ok, {%GenAI.ChatCompletion{}, returned}} = GenAI.run(p.thread, p.context, [])
    {:ok, projected} = Pipeline.new(returned)

    assert Enum.map(Snapshot.messages(projected.thread), & &1.content) == [
             "system",
             "first",
             "response",
             "pending last"
           ]
  end

  test "projection rejects arbitrary graph callbacks instead of invoking them" do
    source = GenAI.chat(:session)

    graph =
      GenAI.VNext.Graph.attach_node(source.root.graph, GenAI.ChatCompletion.new(choices: []))

    source = %{source | root: %{source.root | graph: graph}}
    assert {:error, :unsafe_projection_node} = Pipeline.new(source)
  end

  test "projection of an already-run graph preserves response chronology before pending input" do
    source =
      GenAI.chat(:session)
      |> GenAI.with_model(GenAI.Support.TestProvider.Models.model_one())
      |> GenAI.with_message(GenAI.Message.user("A"))
      |> GenAI.with_message(GenAI.Message.assistant("B"))

    {:ok, {completion, returned}} = GenAI.run(source, Noizu.Context.system(), [])
    message = hd(completion.choices).message

    returned =
      returned |> GenAI.with_message(message) |> GenAI.with_message(GenAI.Message.user("C"))

    {:ok, p} = Pipeline.extract(returned, :last_message)
    {:ok, p} = Pipeline.extract(p, :last_response)
    assert Enum.map(Snapshot.messages(p.thread), & &1.content) == ["A", "B", message.content, "C"]
    assert {:ok, {%GenAI.ChatCompletion{}, _}} = GenAI.run(p.thread, p.context, [])
  end

  test "singleton NextTurn catches exceptions and kills timed out inference" do
    assert {:error, {:callback_exception, RuntimeError}} =
             Pipeline.next_turn(thread(), run: fn _, _, _ -> raise "failed" end)

    assert {:error, :timeout} =
             Pipeline.next_turn(thread(), timeout: 5, run: fn _, _, _ -> Process.sleep(100) end)
  end

  test "non-JSON keys are rejected before representing a result" do
    {:ok, p} = Pipeline.extract(thread(), {:literal, %{{1, 2} => "unsafe"}})
    assert {:error, :non_serializable_result} = Pipeline.append_result(p, final: :json)
  end

  test "inline classification consumes typed frames and validates the concrete result" do
    {:ok, p} =
      thread()
      |> Pipeline.extract(:last_response)
      |> Pipeline.extract({:literal, [%{id: "safe", type: :boolean}]}, kind: :criteria)
      |> Pipeline.classify(provider: ClassifierFixture, observer: self())

    assert [%GenAI.Pipeline.Frame{kind: :result, value: result}] = p.frames
    assert [answer] = result.answers
    assert answer.value == true
    assert_receive {:classified, %{input: "response", questions: [%{id: "safe"}]}}

    assert {:error, {:unsupported_classifier, GenAI.Support.TestProvider}} =
             thread()
             |> Pipeline.extract(:last_response)
             |> Pipeline.classify(
               questions: [%{id: "safe", type: :boolean}],
               provider: GenAI.Support.TestProvider
             )
  end

  test "evaluation joins support index-only classifier answers and forward grading instructions" do
    {:fork, branches} = Pipeline.split(thread(), 2)

    {:ok, selected} =
      Pipeline.join({:fork, branches},
        mode: :select,
        selector:
          {:classifier,
           [provider: ClassifierFixture, observer: self(), instructions: "Prefer careful answers"]}
      )

    assert selected == Enum.at(branches, 1).pipeline
    assert_receive {:classified, %{questions: [%{instructions: "Prefer careful answers"}]}}
  end

  test "literal fork thread tuples broadcast into stable branches" do
    run = fn t, _, _ ->
      {:ok,
       {%GenAI.ChatCompletion{
          choices: [
            %GenAI.ChatCompletion.Choice{message: GenAI.Message.assistant("literal fork")}
          ]
        }, t}}
    end

    {:fork, branches} = Pipeline.next_turn({:fork, [thread(), thread()]}, run: run)
    assert Enum.map(branches, & &1.id) == [0, 1]
    assert Enum.all?(branches, &is_nil(&1.error))
  end

  test "append join rejects reused message identity across branches, but keeps distinct identical content" do
    message = GenAI.Message.assistant("same")

    forks =
      Pipeline.fork(thread(),
        a: fn p -> Pipeline.transform(p, fn t, _ -> GenAI.with_message(t, message) end) end,
        b: fn p -> Pipeline.transform(p, fn t, _ -> GenAI.with_message(t, message) end) end
      )

    id = message.id
    assert {:error, {:duplicate_message_id, ^id, [:a, :b]}} = Pipeline.join(forks, mode: :append)

    distinct =
      Pipeline.fork(thread(),
        a: fn p ->
          Pipeline.transform(p, fn t, _ ->
            GenAI.with_message(t, GenAI.Message.assistant("same"))
          end)
        end,
        b: fn p ->
          Pipeline.transform(p, fn t, _ ->
            GenAI.with_message(t, GenAI.Message.assistant("same"))
          end)
        end
      )

    {:ok, joined} = Pipeline.join(distinct, mode: :append)
    {:ok, joined} = Pipeline.refresh(joined)

    assert Enum.take(Enum.map(Snapshot.messages(joined.thread), & &1.content), -2) == [
             "same",
             "same"
           ]
  end

  test "XML selection rejects document type declarations before entity expansion" do
    content = ~s(<!DOCTYPE root [<!ENTITY payload "secret">]><root>&payload;</root>)

    assert {:error, reason} = GenAI.Pipeline.Selector.select(content, {:xml, "/root/text()"})
    assert reason in [{:callback_exception, SweetXml.DTDError}, {:callback_exit, :exit}]
  end

  test "all conversation operations broadcast to isolated fork branches" do
    {:fork, classified} =
      thread()
      |> Pipeline.split(2)
      |> Pipeline.extract(:last_response)
      |> Pipeline.extract({:literal, [%{id: "safe", type: :boolean}]}, kind: :criteria)
      |> Pipeline.classify(provider: ClassifierFixture)

    assert Enum.map(classified, & &1.id) == [0, 1]

    for branch <- classified do
      assert [%GenAI.Pipeline.Frame{kind: :result}] = branch.pipeline.frames
      assert branch.error == nil
    end

    {:fork, represented} = Pipeline.append_result({:fork, classified}, final: :json)

    {:fork, transformed} =
      Pipeline.transform({:fork, represented}, fn t, _ ->
        GenAI.with_message(t, GenAI.Message.user("follow-up"))
      end)

    {:fork, aggregated} = Pipeline.aggregate({:fork, transformed}, :content, role: :user)

    for branch <- aggregated do
      assert hd(branch.pipeline.frames).value == ["first", "pending last", "follow-up"]
      assert branch.error == nil
    end
  end

  test "fork broadcasting preserves nested identities and branch failures" do
    nested = Pipeline.fork(thread(), outer: &Pipeline.split(&1, 2))
    {:fork, [outer]} = Pipeline.extract(nested, :last_message)
    assert outer.id == :outer
    {:fork, inner} = outer.pipeline
    assert Enum.map(inner, & &1.id) == [0, 1]
    assert Enum.all?(inner, &(hd(&1.pipeline.frames).value == "pending last"))
    failed = Pipeline.fork(thread(), ok: fn p -> p end, bad: fn _ -> {:error, :failed} end)
    {:fork, branches} = Pipeline.extract(failed, :last_message)
    assert Enum.map(branches, & &1.error) == [nil, :failed]
    assert hd(hd(branches).pipeline.frames).value == "pending last"
  end

  test "nested NextTurn uses one global leaf concurrency budget and preserves failure paths" do
    {:ok, counter} = Agent.start_link(fn -> %{active: 0, peak: 0, calls: 0} end)

    run = fn t, _, _ ->
      Agent.update(counter, fn c ->
        %{c | active: c.active + 1, calls: c.calls + 1, peak: max(c.peak, c.active + 1)}
      end)

      Process.sleep(15)
      Agent.update(counter, &%{&1 | active: &1.active - 1})

      {:ok,
       {%GenAI.ChatCompletion{
          choices: [%GenAI.ChatCompletion.Choice{message: GenAI.Message.assistant("leaf")}]
        }, t}}
    end

    nested = Pipeline.fork(thread(), left: &Pipeline.split(&1, 3), right: &Pipeline.split(&1, 3))
    {:fork, branches} = Pipeline.next_turn(nested, run: run, max_concurrency: 2)
    assert %{active: 0, peak: peak, calls: 6} = Agent.get(counter, & &1)
    assert peak in 1..2
    assert Enum.map(branches, & &1.id) == [:left, :right]

    for outer <- branches do
      {:fork, inner} = outer.pipeline
      assert Enum.map(inner, & &1.id) == [0, 1, 2]
      assert Enum.map(inner, & &1.path) == [[outer.id, 0], [outer.id, 1], [outer.id, 2]]
      assert Enum.all?(inner, &is_nil(&1.error))
    end

    {:fork, failed} =
      Pipeline.next_turn(nested, run: fn _, _, _ -> {:error, :rejected} end, max_concurrency: 2)

    for outer <- failed do
      {:fork, inner} = outer.pipeline
      assert Enum.map(inner, & &1.error) == [:rejected, :rejected, :rejected]
      assert Enum.map(inner, & &1.path) == [[outer.id, 0], [outer.id, 1], [outer.id, 2]]
    end

    Agent.stop(counter)
  end
end
