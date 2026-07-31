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
end
