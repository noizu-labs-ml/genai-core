defmodule GenAI.DialogueTest do
  use ExUnit.Case, async: true

  alias GenAI.Dialogue
  alias GenAI.Dialogue.Schema

  defp create_schema do
    Schema.new(
      [
        %{name: :organization, question: "Which organization?", required: true},
        %{name: :title, question: "What title?", required: true},
        %{name: :priority, question: "Priority?", required: false}
      ],
      ask_optional: []
    )
  end

  test "missing required field → asks next question" do
    schema = create_schema()

    extract = fn text, pending ->
      cond do
        String.downcase(String.trim(text)) == "cancel" -> {:cancel}
        pending == :organization -> {:ok, %{organization: String.trim(text)}}
        pending == :title -> {:ok, %{title: String.trim(text)}}
        true -> {:ok, %{}}
      end
    end

    {d, msg} = Dialogue.start(schema, "hello", extract: extract)
    assert d.status == :collecting
    assert d.pending_field in [:organization, :title]
    assert is_binary(msg)
  end

  test "multi-turn complete then cancel is no-op" do
    schema = create_schema()

    extract = fn text, pending ->
      t = String.trim(text)

      cond do
        String.downcase(t) == "cancel" ->
          {:cancel}

        pending == :organization or (is_nil(pending) and t == "acme") ->
          {:ok, %{organization: "acme"}}

        pending == :title or t == "fix login" ->
          {:ok, %{title: "fix login", organization: "acme"}}

        true ->
          {:ok, %{pending => t}}
      end
    end

    {d, _} = Dialogue.start(schema, "acme", extract: extract, initial_draft: %{})

    d =
      if Dialogue.complete?(d) do
        d
      else
        {d, _} = Dialogue.turn(d, "fix login")
        d
      end

    # ensure both fields filled
    d =
      if Dialogue.complete?(d) do
        d
      else
        {d2, _} =
          case d.pending_field do
            :title -> Dialogue.turn(d, "fix login")
            :organization -> Dialogue.turn(d, "acme")
            _ -> {d, ""}
          end

        if Dialogue.complete?(d2), do: d2, else: elem(Dialogue.turn(d2, "fix login"), 0)
      end

    assert Dialogue.complete?(d)
    assert d.draft[:organization] == "acme" or d.draft[:title] == "fix login"

    {d2, msg} = Dialogue.turn(d, "cancel")
    assert Dialogue.complete?(d2)
    refute Dialogue.cancelled?(d2)
    assert is_binary(msg)
  end

  test "cancel mid-dialogue" do
    schema = create_schema()
    {d, _} = Dialogue.start(schema, "start")
    {d, msg} = Dialogue.turn(d, "cancel")
    assert Dialogue.cancelled?(d)
    assert msg =~ "cancelled"
    refute Dialogue.complete?(d)
  end

  test "ApprovalScript embeds tool and args" do
    src =
      GenAI.Dialogue.ApprovalScript.single_tool("plans", "Item.Create", %{
        "organization" => "acme",
        "title" => "t1"
      })

    assert src =~ "Item.Create"
    assert src =~ "acme"
    assert src =~ "t1"
    assert src =~ ~s(endpoint "plans")
  end

  # ── tool loop ────────────────────────────────────────────────────────────────

  defp loop_extract(steps) do
    # Scripted extractor: pops scripted responses; a {:tool_result, _, _}
    # re-entry consumes the next step.
    {:ok, agent} = Agent.start_link(fn -> steps end)

    fn input, _pending, _draft ->
      Agent.get_and_update(agent, fn
        [next | rest] -> {next, rest}
        [] -> {{:ok, %{}, "out of script"}, []}
      end)
    end
  end

  defp executor(log) do
    fn call, _draft ->
      send(log, {:tool, call})
      {:cont, %{"answer" => 42}}
    end
  end

  test "tool_call executes and the loop continues to a final answer" do
    schema = create_schema()
    log = self()

    extract =
      loop_extract([
        {:tool_call, %{"tool" => "search"}, "Searching."},
        {:tool_call, %{"tool" => "fetch"}, "Fetching."},
        {:ok, %{}, "Done: 42."}
      ])

    {d, msg} =
      Dialogue.start(schema, "look it up",
        extract: extract,
        tool_executor: executor(log)
      )

    assert msg == "Done: 42."

    assert [%{call: %{"tool" => "search"}}, %{call: %{"tool" => "fetch"}}] =
             Dialogue.tool_trace(d)

    assert_received {:tool, %{"tool" => "search"}}
    assert_received {:tool, %{"tool" => "fetch"}}
  end

  test "tool result reaches the extractor as a {:tool_result, call, result} input" do
    schema = create_schema()

    extract = fn input, _pending, _draft ->
      case input do
        {:tool_result, _call, %{"answer" => 42}} -> {:ok, %{title: "answer-42"}}
        _input -> {:tool_call, %{"tool" => "ask"}, "Checking."}
      end
    end

    executor = fn _call, _draft -> {:cont, %{"answer" => 42}} end

    {d, _msg} =
      Dialogue.start(schema, "what is it", extract: extract, tool_executor: executor)

    assert Dialogue.draft(d)[:title] == "answer-42"
  end

  test "executor halt ends the loop with the halt reply" do
    schema = create_schema()

    extract =
      loop_extract([
        {:tool_call, %{"tool" => "deploy"}, "Deploying."},
        {:ok, %{}, "unreachable"}
      ])

    executor = fn _call, _draft -> {:halt, "Needs your approval first."} end

    {d, msg} =
      Dialogue.start(schema, "deploy", extract: extract, tool_executor: executor)

    assert msg == "Needs your approval first."
    assert [%{outcome: {:halt, "Needs your approval first."}}] = Dialogue.tool_trace(d)
  end

  test "max_tool_iterations stops the loop" do
    schema = create_schema()
    log = self()

    # Every response is another tool_call — the script never ends.
    extract = fn _input, _p, _d -> {:tool_call, %{"tool" => "loop"}, "Again."} end

    {d, msg} =
      Dialogue.start(schema, "go",
        extract: extract,
        tool_executor: executor(log),
        max_tool_iterations: 3
      )

    assert msg == "I reached the tool-use limit for this turn (3)."
    assert length(Dialogue.tool_trace(d)) == 3
  end

  test "per-step timeout halts a hung executor" do
    schema = create_schema()

    extract =
      loop_extract([
        {:tool_call, %{"tool" => "slow"}, "Working."},
        {:ok, %{}, "unused"}
      ])

    executor = fn _call, _draft ->
      Process.sleep(5_000)
      {:cont, %{}}
    end

    {d, msg} =
      Dialogue.start(schema, "go",
        extract: extract,
        tool_executor: executor,
        tool_step_timeout: 50
      )

    assert msg =~ "timed out"
    assert [%{outcome: {:halt, halt}}] = Dialogue.tool_trace(d)
    assert halt =~ "timed out"
  end

  test "crashing executor halts instead of crashing the turn" do
    schema = create_schema()

    extract =
      loop_extract([
        {:tool_call, %{"tool" => "boom"}, "Trying."},
        {:ok, %{}, "unused"}
      ])

    executor = fn _call, _draft -> raise "boom" end

    {_d, msg} = Dialogue.start(schema, "go", extract: extract, tool_executor: executor)
    assert msg =~ "Tool call failed"
  end

  test "tool_call without an executor degrades to the model's reply" do
    schema = create_schema()

    extract = fn _input, _p, _d -> {:tool_call, %{"tool" => "x"}, "Cannot run tools."} end

    {d, msg} = Dialogue.start(schema, "go", extract: extract)
    assert msg == "Cannot run tools."
    assert Dialogue.tool_trace(d) == []
  end

  test "legacy slot path is unchanged alongside loop config" do
    schema = create_schema()

    extract = fn "acme", nil, _draft -> {:ok, %{organization: "acme"}} end

    executor = fn _c, _d -> flunk("executor must not run without a tool_call") end

    {d, msg} =
      Dialogue.start(schema, "acme", extract: extract, tool_executor: executor)

    assert d.pending_field == :title
    assert Dialogue.draft(d)[:organization] == "acme"
    assert is_binary(msg)
    assert Dialogue.tool_trace(d) == []
  end
end
