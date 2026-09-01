defmodule GenAI.StreamHandler.SSETest do
  use ExUnit.Case, async: true
  alias GenAI.StreamHandler.SSE

  describe "SSE Parser" do
    test "single complete frame" do
      {events, rest} = SSE.feed("", "data: hello\n\n")
      assert events == [{:data, "hello"}]
      assert rest == ""
    end

    test "multiple frames in one chunk" do
      {events, rest} = SSE.feed("", "data: one\n\ndata: two\n\n")
      assert events == [{:data, "one"}, {:data, "two"}]
      assert rest == ""
    end

    test "partial frame is buffered until completed" do
      {events, rest} = SSE.feed("", "data: hel")
      assert events == []
      assert rest == "data: hel"

      {events, rest} = SSE.feed(rest, "lo\n\n")
      assert events == [{:data, "hello"}]
      assert rest == ""
    end

    test "frame separator split across chunks" do
      {events, rest} = SSE.feed("", "data: hello\n")
      assert events == []

      {events, rest} = SSE.feed(rest, "\ndata: next\n\n")
      assert events == [{:data, "hello"}, {:data, "next"}]
      assert rest == ""
    end

    test "CRLF separators tolerated" do
      {events, rest} = SSE.feed("", "data: hello\r\n\r\ndata: world\r\n\r\n")
      assert events == [{:data, "hello"}, {:data, "world"}]
      assert rest == ""
    end

    test "CRLF separator split across chunks (CR then LF)" do
      {events, rest} = SSE.feed("", "data: hello\r")
      assert events == []

      {events, rest} = SSE.feed(rest, "\ndata: world\n\n")
      assert events == [{:data, "hello"}, {:data, "world"}]
      assert rest == ""
    end

    test "DONE sentinel" do
      {events, _rest} = SSE.feed("", "data: [DONE]\n\n")
      assert events == [:done]
    end

    test "comment and unknown fields ignored" do
      {events, _rest} = SSE.feed("", ": keep-alive\nevent: message\ndata: payload\n\n")
      assert events == [{:data, "payload"}]
    end

    test "multi-line data joined with newline" do
      {events, _rest} = SSE.feed("", "data: line1\ndata: line2\n\n")
      assert events == [{:data, "line1\nline2"}]
    end

    test "no space after data colon" do
      {events, _rest} = SSE.feed("", "data:{\"a\":1}\n\n")
      assert events == [{:data, "{\"a\":1}"}]
    end
  end
end

defmodule GenAI.StreamHandler.OpenAITest do
  use ExUnit.Case, async: true
  alias GenAI.StreamHandler.OpenAI

  describe "OpenAI Compatible Decoder" do
    test "content delta" do
      assert [{:text, "Hi"}] =
               OpenAI.stream_event(%{choices: [%{index: 0, delta: %{content: "Hi"}}]})
    end

    test "reasoning deltas" do
      assert [{:thinking, "hm"}] =
               OpenAI.stream_event(%{choices: [%{delta: %{reasoning_content: "hm"}}]})

      assert [{:thinking, "hm"}] =
               OpenAI.stream_event(%{choices: [%{delta: %{reasoning: "hm"}}]})
    end

    test "tool call delta" do
      tool_calls = [%{index: 0, id: "call_1", function: %{name: "get_weather", arguments: "{\""}}]
      assert [{:tool_call, ^tool_calls}] = OpenAI.stream_event(%{choices: [%{delta: %{tool_calls: tool_calls}}]})
    end

    test "finish reason normalized" do
      assert [{:finish, :stop}] =
               OpenAI.stream_event(%{choices: [%{delta: %{}, finish_reason: "stop"}]})

      assert [{:finish, :max_tokens}] =
               OpenAI.stream_event(%{choices: [%{delta: %{}, finish_reason: "length"}]})

      assert [{:finish, :tool_call}] =
               OpenAI.stream_event(%{choices: [%{delta: %{}, finish_reason: "tool_calls"}]})
    end

    test "usage chunk (include_usage)" do
      events = OpenAI.stream_event(%{choices: [], usage: %{prompt_tokens: 5, completion_tokens: 7, total_tokens: 12}})
      assert events == [{:usage, %{prompt_tokens: 5, completion_tokens: 7, total_tokens: 12}}]
    end

    test "text and finish in same chunk" do
      events = OpenAI.stream_event(%{choices: [%{delta: %{content: "bye"}, finish_reason: "stop"}]})
      assert events == [{:text, "bye"}, {:finish, :stop}]
    end
  end
end

defmodule GenAI.StreamHandler.AnthropicTest do
  use ExUnit.Case, async: true
  alias GenAI.StreamHandler.Anthropic

  describe "Anthropic Decoder" do
    test "message_start yields input usage" do
      events = Anthropic.stream_event(%{type: "message_start", message: %{usage: %{input_tokens: 25, output_tokens: 1}}})
      assert events == [{:usage, %{prompt_tokens: 25, completion_tokens: 1, total_tokens: nil}}]
    end

    test "text delta" do
      assert [{:text, "Hel"}] =
               Anthropic.stream_event(%{type: "content_block_delta", index: 0, delta: %{type: "text_delta", text: "Hel"}})
    end

    test "thinking delta" do
      assert [{:thinking, "so"}] =
               Anthropic.stream_event(%{type: "content_block_delta", index: 0, delta: %{type: "thinking_delta", thinking: "so"}})
    end

    test "tool use block start and json delta" do
      assert [{:tool_call, %{index: 1, id: "toolu_1", name: "get_weather"}}] =
               Anthropic.stream_event(%{type: "content_block_start", index: 1, content_block: %{type: "tool_use", id: "toolu_1", name: "get_weather"}})

      assert [{:tool_call, %{index: 1, partial_json: "{\"loc"}}] =
               Anthropic.stream_event(%{type: "content_block_delta", index: 1, delta: %{type: "input_json_delta", partial_json: "{\"loc"}})
    end

    test "message_delta yields finish and output usage" do
      events = Anthropic.stream_event(%{type: "message_delta", delta: %{stop_reason: "end_turn"}, usage: %{output_tokens: 40}})
      assert events == [{:finish, :stop}, {:usage, %{prompt_tokens: nil, completion_tokens: 40, total_tokens: nil}}]
    end

    test "ping ignored" do
      assert [] == Anthropic.stream_event(%{type: "ping"})
    end
  end
end

defmodule GenAI.StreamHandler.DefaultTest do
  use ExUnit.Case, async: true
  alias GenAI.StreamHandler.Default

  describe "Default Handler Accumulation" do
    test "decodes OpenAI compatible stream into completion" do
      {:ok, {{state, cb}, _}} =
        Default.begin_stream(
          Default,
          :session,
          nil,
          stream_decoder: GenAI.StreamHandler.OpenAI,
          stream_model: "test-model",
          stream_provider: :test_provider
        )

      {:cont, state} = cb.({:status, 200}, state)
      {:cont, state} = cb.({:data, ~S(data: {"choices":[{"index":0,"delta":{"content":"Hi"}}]}) <> "\n\n"}, state)
      {:cont, state} = cb.({:data, ~S(data: {"choices":[{"index":0,"delta":{"content":"!"}}]}) <> "\n\n"}, state)
      {:cont, state} = cb.({:data, "data: [DONE]\n\n"}, state)

      assert state.completed
      assert state.text == "Hi!"
      assert state.completion.choices |> hd() |> Map.get(:message) |> Map.get(:content) == "Hi!"
      assert state.completion.model == "test-model"
      assert state.completion.provider == :test_provider
    end

    test "forwards events to sink fun" do
      test = self()

      {:ok, {{state, cb}, _}} =
        Default.begin_stream(
          Default,
          :session,
          nil,
          stream_decoder: GenAI.StreamHandler.OpenAI,
          stream_sink: fn event -> send(test, {:forwarded, event}) end
        )

      {:cont, state} = cb.({:data, ~S(data: {"choices":[{"index":0,"delta":{"content":"x"}}]}) <> "\n\n"}, state)
      assert_received {:forwarded, {:text, "x"}}
      assert state.text == "x"
    end

    test "raw accumulation when no decoder" do
      {:ok, {{state, cb}, _}} = Default.begin_stream(Default, :session, nil, nil)
      {:cont, state} = cb.({:data, "not sse\n\n"}, state)
      assert state.buffer == "not sse\n\n"
      assert is_nil(state.completion)
    end
  end
end
