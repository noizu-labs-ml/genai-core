defmodule GenAI.ForkThreadTest do
  use ExUnit.Case, async: true
  alias GenAI.Thread.Fork
  alias GenAI.Pipeline
  alias GenAI.Pipeline.Snapshot
  require GenAI.Records.Directive

  defmodule Encoder do
    def encode_message(message, model, %GenAI.Thread.Session{} = thread, _, _) do
      {:ok, thread} = GenAI.ThreadProtocol.set_artifact(thread, :encoded_by, model.model)
      {:ok, {%{role: message.role, content: message.content, model: model.model}, thread}}
    end

    def normalize_messages(messages, _model, thread, _, _), do: {:ok, {messages, thread}}

    def encode_tool(tool, model, %GenAI.Thread.Session{} = thread, _, _),
      do: {:ok, {%{name: tool.name, model: model.model}, thread}}
  end

  defmodule Provider do
    def run(thread, _context, _options) do
      message = GenAI.Message.assistant("fixture response")

      completion = %GenAI.ChatCompletion{
        choices: [%GenAI.ChatCompletion.Choice{message: message}]
      }

      {:ok, {completion, thread}}
    end
  end

  defp thread(type \\ :session) do
    GenAI.chat(type)
    |> GenAI.with_model(%GenAI.Model{model: "fixture", provider: Provider})
    |> GenAI.with_message(GenAI.Message.user("fixture input"))
  end

  test "forks are thread values and normal public mutations/run preserve scalar return contracts" do
    for type <- [:session, :standard] do
      fork = Pipeline.split(thread(type), 2)
      assert GenAI.ThreadProtocol.impl_for(fork) != nil
      fork = GenAI.with_setting(fork, :temperature, 0)
      fork = GenAI.with_message(fork, GenAI.Message.user("next"))
      assert {:ok, {result, updated}} = GenAI.run(fork, nil, [])
      assert Enum.map(result.outcomes, & &1.path) == [[0], [1]]
      assert Enum.all?(result.outcomes, &match?(%GenAI.ChatCompletion{}, &1.value))

      counts =
        Enum.map(Fork.leaves(updated), fn {_, b} ->
          {:ok, p} = Pipeline.refresh(b.pipeline)
          length(Snapshot.messages(p.thread))
        end)

      assert counts == [2, 2]

      assert {:ok, %Fork.Result{}} = GenAI.run(fork)
      assert {:error, {:unsupported_fork_command, :report}} = GenAI.report(fork, nil)
    end
  end

  test "branch artifacts and typed getters do not pick a first leaf" do
    fork = Pipeline.split(thread(), 2)
    assert {:ok, fork} = GenAI.ThreadProtocol.set_artifact(fork, :fixture, 7)
    assert {:ok, values} = GenAI.ThreadProtocol.get_artifact(fork, :fixture)
    assert Enum.map(values.outcomes, & &1.value) == [7, 7]
    assert {:ok, {models, _}} = GenAI.ThreadProtocol.effective_model(fork, nil, [])
    assert Enum.map(models.outcomes, & &1.path) == [[0], [1]]
  end

  test "pipeline operations retain canonical fork, options and branch-local frames" do
    fork = Pipeline.split(thread(), 2, max_concurrency: 1, timeout: 1000)
    fork = Pipeline.extract(fork, :last_message)
    assert %Fork{} = fork
    assert fork.options[:max_concurrency] == 1
    assert Enum.all?(fork.branches, &(length(&1.pipeline.frames) == 1))
    configured = GenAI.with_setting(fork, :temperature, 0)
    assert Enum.all?(configured.branches, &(length(&1.pipeline.frames) == 1))
    changed = GenAI.with_message(configured, GenAI.Message.user("changed"))
    assert Enum.all?(changed.branches, &(&1.pipeline.frames == []))
    assert {:ok, {_, _}} = GenAI.run(changed, nil, [])
  end

  test "legacy ingress and partial errors retain successful and failed continuations" do
    assert {:ok, fork} = Fork.normalize({:fork, [thread(), thread()]})

    assert {:error, %Fork.Error{} = error} =
             Fork.evaluate(fork, :fixture, fn t, path ->
               if path == [0], do: {:ok, {:kept, t}}, else: raise("fixture failure")
             end)

    assert Enum.map(error.result.outcomes, & &1.status) == [:ok, :error]
    assert hd(error.result.outcomes).value == :kept
    assert Enum.at(error.fork.branches, 1).error == {:branch_exception, RuntimeError}
  end

  test "nested execution uses one global worker budget and stable paths" do
    outer =
      Pipeline.fork(thread(),
        a: fn p -> Pipeline.split(p, 3) end,
        b: fn p -> Pipeline.split(p, 3) end
      )

    {:ok, counter} = Agent.start_link(fn -> {0, 0} end)

    try do
      assert {:ok, {result, updated}} =
               Fork.evaluate(
                 outer,
                 :fixture,
                 fn t, _ ->
                   Agent.update(counter, fn {n, peak} -> {n + 1, max(peak, n + 1)} end)
                   Process.sleep(5)
                   Agent.update(counter, fn {n, peak} -> {n - 1, peak} end)
                   {:ok, {:done, t}}
                 end,
                 max_concurrency: 2
               )

      assert Agent.get(counter, &elem(&1, 1)) <= 2

      assert Enum.map(result.outcomes, & &1.path) == [
               [:a, 0],
               [:a, 1],
               [:a, 2],
               [:b, 0],
               [:b, 1],
               [:b, 2]
             ]

      assert match?(%Fork{}, hd(updated.branches).pipeline)
    after
      Agent.stop(counter)
    end
  end

  test "all reader families use branch models and retain encoder-updated leaf state" do
    left = %GenAI.Model{model: "left", provider: Provider, encoder: Encoder}
    right = %{left | model: "right"}

    fork =
      Pipeline.fork(thread(),
        left: fn p -> Pipeline.transform(p, fn t, _ -> GenAI.with_model(t, left) end) end,
        right: fn p -> Pipeline.transform(p, fn t, _ -> GenAI.with_model(t, right) end) end
      )

    fork =
      fork
      |> GenAI.with_api_key(Provider, "fixture-key")
      |> GenAI.with_api_org(Provider, "fixture-org")
      |> GenAI.with_provider_setting(Provider, :fixture_provider, 3)
      |> GenAI.with_model_setting(left, :fixture_model, 1)
      |> GenAI.with_model_setting(right, :fixture_model, 2)
      |> GenAI.with_safety_setting(:fixture_safety, 4)
      |> GenAI.with_tools([GenAI.Tool.new(name: "fixture_tool")])

    {:ok, fork} =
      GenAI.ThreadProtocol.append_directive(
        fork,
        GenAI.Session.State.Directive.static(
          GenAI.Records.Directive.setting_entry(setting: :fixture_directive),
          9,
          :fixture
        ),
        nil,
        []
      )

    {:ok, {models, fork}} = GenAI.ThreadProtocol.effective_model(fork, nil, [])
    assert Enum.map(models.outcomes, & &1.value.model) == ["left", "right"]

    for operation <- [:effective_settings, :effective_safety_settings] do
      {:ok, {result, _}} = apply(GenAI.ThreadProtocol, operation, [fork, nil, []])
      assert Enum.map(result.outcomes, & &1.path) == [[:left], [:right]]

      if operation == :effective_settings,
        do:
          assert(Enum.map(result.outcomes, &Keyword.get(&1.value, :fixture_directive)) == [9, 9])
    end

    for operation <- [:effective_model_settings, :effective_provider_settings] do
      {:ok, {result, _}} = apply(GenAI.ThreadProtocol, operation, [fork, models, nil, []])
      assert Enum.map(result.outcomes, & &1.path) == [[:left], [:right]]

      if operation == :effective_model_settings,
        do: assert(Enum.map(result.outcomes, &Keyword.get(&1.value, :fixture_model)) == [1, 2])
    end

    {:ok, {messages, fork}} = GenAI.ThreadProtocol.effective_messages(fork, models, nil, [])
    assert Enum.map(messages.outcomes, &hd(&1.value).model) == ["left", "right"]
    {:ok, {tools, fork}} = GenAI.ThreadProtocol.effective_tools(fork, models, nil, [])
    assert Enum.map(tools.outcomes, &hd(&1.value).model) == ["left", "right"]
    {:ok, encoded_by} = GenAI.ThreadProtocol.get_artifact(fork, :encoded_by)
    assert Enum.map(encoded_by.outcomes, & &1.value) == ["left", "right"]
    implementation = GenAI.ThreadProtocol.impl_for(fork)

    missing =
      Enum.reject(GenAI.ThreadProtocol.__protocol__(:functions), fn {name, arity} ->
        function_exported?(implementation, name, arity)
      end)

    assert missing == []
  end

  test "worker timeout and exit preserve successful siblings and terminate workers" do
    fork = Pipeline.split(thread(), 3)
    parent = self()

    {:error, error} =
      Fork.evaluate(
        fork,
        :fixture,
        fn t, path ->
          send(parent, {:worker, path, self()})

          case path do
            [0] ->
              {:ok, {:success, t}}

            [1] ->
              exit(:fixture_exit)

            [2] ->
              Process.sleep(100)
              {:ok, {:late, t}}
          end
        end, max_concurrency: 2, timeout: 10)

    assert Enum.map(error.result.outcomes, & &1.status) == [:ok, :error, :error]
    assert Enum.map(error.result.outcomes, & &1.path) == [[0], [1], [2]]
    assert hd(error.result.outcomes).value == :success
    assert Enum.at(error.result.outcomes, 2).reason == :timeout

    for _ <- 1..3 do
      assert_receive {:worker, _, pid}
      refute Process.alive?(pid)
    end
  end

  test "a returned Fork cannot be hidden inside a scalar pipeline thread" do
    fork = Pipeline.split(thread(), 2)
    {:error, error} = Fork.evaluate(fork, :fixture, fn _t, _ -> {:ok, {:bad, fork}} end)

    assert Enum.map(error.result.outcomes, & &1.reason) == [
             :invalid_branch_thread,
             :invalid_branch_thread
           ]

    {:error, error} = Fork.evaluate(fork, :fixture, fn _t, _ -> {:error, :bad, fork} end)

    assert Enum.map(error.result.outcomes, & &1.reason) == [
             :invalid_branch_thread,
             :invalid_branch_thread
           ]
  end

  test "Standard projection preserves message IDs, chronology and identical-content messages" do
    a = GenAI.Message.user("same")
    b = GenAI.Message.user("same")
    response = GenAI.Message.assistant("done")
    pending = GenAI.Message.user("pending")
    t = thread(:standard) |> GenAI.with_messages([a, b])
    {:ok, {_, t}} = GenAI.run(t, nil, [])
    t = GenAI.Thread.LegacyStateProtocol.apply_message(t, response)

    t =
      case t do
        {:ok, t} -> t
        t -> t
      end

    t = GenAI.with_message(t, pending)
    {:ok, projected} = Snapshot.materialize(t, nil, [])
    ids = Enum.map(Snapshot.messages(projected), & &1.id)
    assert Enum.take(ids, -4) == [a.id, b.id, response.id, pending.id]
    {:ok, projected_again} = Snapshot.materialize(projected, nil, [])
    assert Enum.map(Snapshot.messages(projected_again), & &1.id) == ids
  end

  test "Standard projection rejects conflicting payloads sharing an ID" do
    original = GenAI.Message.user("original")
    conflicting = %{original | content: "different"}
    t = thread(:standard) |> GenAI.with_messages([original, conflicting])
    assert {:error, {:conflicting_message_id, id}} = Pipeline.new(t)
    assert id == original.id

    replay = thread(:standard) |> GenAI.with_messages([original, original])
    assert {:ok, pipeline} = Pipeline.new(replay)
    assert Enum.count(Snapshot.messages(pipeline.thread), &(&1.id == original.id)) == 1
  end
end
