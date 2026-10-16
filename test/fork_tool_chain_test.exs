defmodule GenAI.ForkToolChainTest do
  use ExUnit.Case, async: true

  alias GenAI.Pipeline.Snapshot
  alias GenAI.Thread.Fork
  alias GenAI.Tool.Registry

  defmodule Source do
    @behaviour GenAI.Tool.Source
    def list_tools(_, _, _), do: {:ok, [%{name: "lookup", parameters: %{type: "object"}}]}

    def call_tool(owner, "lookup", arguments, _, _) do
      send(owner, {:tool_called, arguments})
      {:ok, arguments}
    end
  end

  defp thread(label) do
    GenAI.chat(:session) |> GenAI.with_message(GenAI.Message.user(label))
  end

  defp messages(thread) do
    {:ok, snapshot} = Snapshot.materialize(thread, nil, [])
    Snapshot.messages(snapshot)
  end

  defp completion(message, finish \\ :stop) do
    GenAI.ChatCompletion.new(
      choices: [%GenAI.ChatCompletion.Choice{index: 0, message: message, finish_reason: finish}]
    )
  end

  defp tool_run(thread, _, _) do
    history = messages(thread)
    label = Enum.find(history, &(&1.role == :user)).content

    if Enum.any?(history, &match?(%GenAI.Message.ToolResponse{}, &1)) do
      {:ok, {completion(GenAI.Message.assistant("done-" <> label)), thread}}
    else
      call = %GenAI.Message.ToolCall{
        id: "call-" <> label,
        tool_name: "facts__lookup",
        arguments: %{"branch" => label}
      }

      message = GenAI.Message.ToolUsage.new(role: :assistant, tool_calls: [call])
      {:ok, {completion(message, :tool_call), thread}}
    end
  end

  defp registry do
    {:ok, registry} = Registry.register(Registry.new(), :facts, Source, self())
    registry
  end

  test "nested tool chains preserve ordered paths and independent continuation histories" do
    fork =
      GenAI.Pipeline.fork(thread("root"),
        direct: fn pipeline -> %{pipeline | thread: thread("direct")} end,
        nested: fn _ -> GenAI.Pipeline.split(thread("nested"), 2) end
      )

    assert {:ok, {%Fork.Result{} = result, %Fork{} = updated}} =
             GenAI.run_with_tools(fork, registry(), nil, run: &tool_run/3, max_concurrency: 2)

    assert Enum.map(result.outcomes, & &1.path) == [[:direct], [:nested, 0], [:nested, 1]]

    for outcome <- result.outcomes do
      assert outcome.status == :ok
      assert outcome.value.summary.iterations == 2
      assert outcome.value.summary.tool_calls == 1
      assert outcome.value.summary.stop_reason == :complete
    end

    assert {:ok, {inspection, _}} =
             Fork.evaluate(updated, :inspect, fn thread, _ ->
               {:ok, {messages(thread), thread}}
             end)

    for outcome <- inspection.outcomes do
      assert Enum.count(outcome.value, &match?(%GenAI.Message.ToolUsage{}, &1)) == 1
      assert Enum.count(outcome.value, &match?(%GenAI.Message.ToolResponse{}, &1)) == 1
    end

    assert_receive {:tool_called, %{"branch" => "direct"}}
    assert_receive {:tool_called, %{"branch" => "nested"}}
    assert_receive {:tool_called, %{"branch" => "nested"}}
  end

  test "failed fork leaves retain tool responses while successful sibling outcomes survive" do
    fork =
      GenAI.Pipeline.fork(thread("initial"),
        complete: fn pipeline -> %{pipeline | thread: thread("complete")} end,
        limited: fn pipeline -> %{pipeline | thread: thread("limited")} end
      )

    run = fn thread, _, _ ->
      if Enum.find(messages(thread), &(&1.role == :user)).content == "complete",
        do: {:ok, {completion(GenAI.Message.assistant("finished")), thread}},
        else: tool_run(thread, nil, [])
    end

    assert {:error, %Fork.Error{fork: updated, result: result}} =
             GenAI.run_with_tools(fork, registry(), nil, run: run, max_iterations: 1)

    assert [%{status: :ok}, %{status: :error, reason: {:chain_limit, :max_iterations, summary}}] =
             result.outcomes

    assert summary.tool_calls == 1

    # Inspect branch continuations directly; an execution error must not erase
    # the already completed tool interaction on the failed leaf.
    failed = Enum.find(updated.branches, &(&1.id == :limited))

    assert Enum.count(
             messages(failed.pipeline.thread),
             &match?(%GenAI.Message.ToolResponse{}, &1)
           ) == 1

    assert_receive {:tool_called, %{"branch" => "limited"}}
  end

  test "legacy fork tuples are normalized at the tool chain entry point" do
    run = fn thread, _, _ -> {:ok, {completion(GenAI.Message.assistant("done")), thread}} end

    assert {:ok, {%Fork.Result{} = result, %Fork{}}} =
             GenAI.run_with_tools({:fork, [thread("a"), thread("b")]}, registry(), nil, run: run)

    assert Enum.map(result.outcomes, & &1.path) == [[0], [1]]
  end

  test "invalid completion retains the provider's updated leaf continuation" do
    fork = GenAI.Pipeline.split(thread("initial"), 1)

    run = fn thread, _, _ ->
      {:ok,
       {:invalid_completion, GenAI.with_message(thread, GenAI.Message.assistant("progress"))}}
    end

    assert {:error, %Fork.Error{fork: updated, result: result}} =
             GenAI.run_with_tools(fork, registry(), nil, run: run)

    assert [%{status: :error, reason: :invalid_chat_completion}] = result.outcomes
    assert Enum.any?(messages(hd(updated.branches).pipeline.thread), &(&1.content == "progress"))
  end

  test "inference exceptions after a tool iteration preserve completed tool interactions" do
    fork = GenAI.Pipeline.split(thread("initial"), 1)

    for fail <- [fn -> raise "fixture failure" end, fn -> throw(:fixture_failure) end] do
      run = fn thread, _, _ ->
        if Enum.any?(messages(thread), &match?(%GenAI.Message.ToolResponse{}, &1)),
          do: fail.(),
          else: tool_run(thread, nil, [])
      end

      assert {:error, %Fork.Error{fork: updated, result: result}} =
               GenAI.run_with_tools(fork, registry(), nil, run: run)

      assert [%{status: :error, reason: {:chain_exception, _}}] = result.outcomes
      history = messages(hd(updated.branches).pipeline.thread)
      assert Enum.count(history, &match?(%GenAI.Message.ToolResponse{}, &1)) == 1
    end
  end

  test "scalar success and limit errors keep their original public shapes" do
    assert {:ok, {%GenAI.ChatCompletion{}, _thread, summary}} =
             GenAI.run_with_tools(thread("scalar"), registry(), nil, run: &tool_run/3)

    assert summary.iterations == 2

    assert {:error, {:chain_limit, :max_iterations, _}} =
             GenAI.run_with_tools(thread("limited"), registry(), nil,
               run: &tool_run/3,
               max_iterations: 1
             )
  end
end
