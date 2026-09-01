defmodule GenAI.ToolRegistryTest do
  use ExUnit.Case, async: true

  alias GenAI.Tool.{Call, Registry, Result}

  defmodule Source do
    @behaviour GenAI.Tool.Source

    @impl true
    def list_tools({_pid, tools}, _context, _options), do: {:ok, tools}

    @impl true
    def call_tool({pid, _tools}, name, arguments, context, _options) do
      send(pid, {:called, name, arguments, context})
      {:ok, %{name: name, arguments: arguments}}
    end
  end

  defmodule SlowSource do
    @behaviour GenAI.Tool.Source

    @impl true
    def list_tools(_, _, _), do: {:ok, [%{name: "slow", parameters: %{}}]}

    @impl true
    def call_tool(_, _, _, _, _) do
      Process.sleep(100)
      {:ok, :late}
    end
  end

  defp descriptors do
    [
      %{
        "name" => "weather.get",
        "description" => "Current weather",
        "inputSchema" => %{"type" => "object"}
      },
      %{name: "clock", description: "Current time", parameters: %{type: "object"}}
    ]
  end

  test "registers MCP-shaped descriptors with deterministic names and ordering" do
    assert {:ok, registry} =
             Registry.register(Registry.new(), :city_data, Source, {self(), descriptors()})

    assert Registry.names(registry) == ["city_data__clock", "city_data__weather_get"]

    assert Enum.map(Registry.tools(registry), & &1.name) == [
             "city_data__clock",
             "city_data__weather_get"
           ]
  end

  test "reports sanitization and cross-source collisions deterministically" do
    tools = [%{name: "a.b", parameters: %{}}, %{name: "a b", parameters: %{}}]

    assert {:error, {:tool_name_collision, "source__a_b"}} =
             Registry.register(Registry.new(), :source, Source, {self(), tools})

    assert {:ok, registry} =
             Registry.register(
               Registry.new(),
               :first,
               Source,
               {self(), [%{name: "same", parameters: %{}}]},
               nil,
               namespace: false
             )

    assert {:error, {:tool_name_collision, "same"}} =
             Registry.register(
               registry,
               :second,
               Source,
               {self(), [%{name: "same", parameters: %{}}]},
               nil,
               namespace: false
             )
  end

  test "collision overrides are explicit and deterministic" do
    first = {self(), [%{name: "same", description: "first", parameters: %{}}]}
    second = {self(), [%{name: "same", description: "second", parameters: %{}}]}

    assert {:ok, registry} =
             Registry.register(Registry.new(), :first, Source, first, nil, namespace: false)

    assert {:error, {:invalid_collision_policy, :surprise}} =
             Registry.register(registry, :second, Source, second, nil,
               namespace: false,
               collision: :surprise
             )

    assert {:ok, kept} =
             Registry.register(registry, :second, Source, second, nil,
               namespace: false,
               collision: :keep
             )

    assert hd(Registry.tools(kept)).description == "first"

    assert {:ok, replaced} =
             Registry.register(registry, :second, Source, second, nil,
               namespace: false,
               collision: :replace
             )

    assert hd(Registry.tools(replaced)).description == "second"
  end

  test "normalizes JSON calls and source results" do
    assert {:ok, registry} =
             Registry.register(Registry.new(), :local, Source, {self(), descriptors()})

    call = %{
      "id" => "call-1",
      "function" => %{"name" => "local__clock", "arguments" => ~s({"zone":"UTC"})}
    }

    assert {:ok, %Result{status: :ok, call_id: "call-1", source: "local"} = result} =
             Registry.execute(registry, call, :ctx)

    assert result.content.arguments == %{"zone" => "UTC"}
    assert_received {:called, "clock", %{"zone" => "UTC"}, :ctx}
  end

  test "rejects malformed calls and unknown tools without invoking a source" do
    assert {:error, :arguments_must_be_an_object} =
             Call.normalize(%{name: "tool", arguments: "[]"})

    assert {:error, {:unknown_tool, "missing"}} =
             Registry.execute(Registry.new(), %{name: "missing", arguments: %{}})
  end

  test "enforces a bounded timeout and terminates the source task" do
    assert {:ok, registry} = Registry.register(Registry.new(), :remote, SlowSource, nil)

    assert {:error, %Result{status: :error, error: :timeout}} =
             Registry.execute(registry, %{name: "remote__slow", arguments: %{}}, nil, timeout: 1)
  end

  test "telemetry excludes payloads by default and includes them only by opt in" do
    owner = self()

    sink = fn event, measurements, metadata ->
      send(owner, {:event, event, measurements, metadata})
    end

    assert {:ok, registry} =
             Registry.register(Registry.new(), :local, Source, {self(), descriptors()}, nil,
               telemetry: sink
             )

    assert_received {:event, [:genai, :tool_source, :register, :start], _, %{source: "local"}}

    assert {:ok, _} =
             Registry.execute(
               registry,
               %{id: "1", name: "local__clock", arguments: %{secret: "x"}},
               nil,
               telemetry: sink
             )

    assert_received {:event, [:genai, :tool, :execute, :start], _, metadata}
    refute Map.has_key?(metadata, :arguments)
    refute Map.has_key?(metadata, :result)

    assert {:ok, _} =
             Registry.execute(
               registry,
               %{id: "2", name: "local__clock", arguments: %{visible: true}},
               nil,
               telemetry: sink,
               include_payloads: true
             )

    assert_received {:event, [:genai, :tool, :execute, :start], _, metadata}
    assert metadata.arguments == %{visible: true}
  end
end

defmodule GenAI.ToolChainTest do
  use ExUnit.Case, async: true

  alias GenAI.Tool.Registry

  defmodule Source do
    @behaviour GenAI.Tool.Source
    def list_tools(_pid, _, _), do: {:ok, [%{name: "lookup", parameters: %{}}]}

    def call_tool(pid, "lookup", arguments, _, _) do
      send(pid, {:lookup, arguments})
      {:ok, %{answer: 42}}
    end
  end

  test "runs inference, executes calls, appends responses, and returns a summary" do
    owner = self()
    {:ok, registry} = Registry.register(Registry.new(), :facts, Source, owner)

    run = fn thread, _context, _options ->
      invocation = Process.get(:chain_invocation, 0)
      Process.put(:chain_invocation, invocation + 1)

      if invocation == 0 do
        call = %GenAI.Message.ToolCall{
          id: "call-42",
          tool_name: "facts__lookup",
          arguments: %{"question" => "life"}
        }

        usage = GenAI.Message.ToolUsage.new(role: :assistant, content: nil, tool_calls: [call])
        {:ok, {completion(usage, :tool_call), thread}}
      else
        assert Enum.any?(thread.graph.nodes, &match?(%GenAI.Message.ToolResponse{}, &1))
        {:ok, {completion(GenAI.Message.assistant("done"), :stop), thread}}
      end
    end

    assert {:ok, {completion, thread, summary}} =
             GenAI.run_with_tools(GenAI.chat(), registry, :ctx, run: run)

    assert hd(completion.choices).message.content == "done"
    assert summary.iterations == 2
    assert summary.tool_calls == 1
    assert summary.tool_errors == 0
    assert summary.stop_reason == :complete
    assert Enum.any?(thread.graph.nodes, &match?(%GenAI.Message.ToolUsage{}, &1))
    assert_received {:lookup, %{"question" => "life"}}
  end

  test "stops before an additional inference when the iteration bound is reached" do
    {:ok, registry} = Registry.register(Registry.new(), :facts, Source, self())

    run = fn thread, _, _ ->
      call = %GenAI.Message.ToolCall{id: "repeat", tool_name: "facts__lookup", arguments: %{}}
      usage = GenAI.Message.ToolUsage.new(role: :assistant, tool_calls: [call])
      {:ok, {completion(usage, :tool_call), thread}}
    end

    assert {:error, {:chain_limit, :max_iterations, summary}} =
             GenAI.ToolChain.run(GenAI.chat(), registry, nil, run: run, max_iterations: 1)

    assert summary.iterations == 1
    assert summary.tool_calls == 1
  end

  test "enforces the total tool-call bound before execution" do
    {:ok, registry} = Registry.register(Registry.new(), :facts, Source, self())

    run = fn thread, _, _ ->
      calls =
        for id <- 1..2 do
          %GenAI.Message.ToolCall{id: to_string(id), tool_name: "facts__lookup", arguments: %{}}
        end

      usage = GenAI.Message.ToolUsage.new(role: :assistant, tool_calls: calls)
      {:ok, {completion(usage, :tool_call), thread}}
    end

    assert {:error, {:chain_limit, :max_tool_calls, summary}} =
             GenAI.ToolChain.run(GenAI.chat(), registry, nil, run: run, max_tool_calls: 1)

    assert summary.tool_calls == 0
    refute_received {:lookup, _}
  end

  defp completion(message, finish_reason) do
    choice = %GenAI.ChatCompletion.Choice{
      index: 0,
      message: message,
      finish_reason: finish_reason
    }

    GenAI.ChatCompletion.new(choices: [choice])
  end
end
