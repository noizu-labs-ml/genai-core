defmodule GenAITest do
  # import GenAI.Test.Support.Common
  use ExUnit.Case, async: false
  use Mimic
  doctest GenAI
  doctest GenAI.Helpers

  describe "Streaming Support" do

    defp stream_while_expectation do
      Mimic.expect(Finch, :stream_while, fn _req, _name, acc, cb, _opts ->
        {:cont, acc} = cb.({:status, 200}, acc)
        {:cont, acc} = cb.({:headers, []}, acc)

        {:cont, acc} =
          cb.({:data, ~S(data: {"choices":[{"index":0,"delta":{"role":"assistant","content":"Hi"}}]}) <> "\n\n"}, acc)

        {:cont, acc} =
          cb.({:data, ~S(data: {"choices":[{"index":0,"delta":{"content":" there"}}]}) <> "\n\n"}, acc)

        {:cont, acc} =
          cb.(
            {:data,
             ~S(data: {"choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":2,"total_tokens":12}}) <>
               "\n\n"},
            acc
          )

        {:cont, acc} = cb.({:data, "data: [DONE]\n\n"}, acc)
        {:ok, acc}
      end)
    end

    test "Default Streaming Policy - Session" do
      stream_while_expectation()
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(model)
        |> GenAI.with_setting(:temperature, 0.5)
        |> GenAI.with_message(GenAI.Message.system("System Prompt"))
        |> GenAI.with_message(GenAI.Message.user("Hello"))
      {:ok, {acc, _}} = GenAI.stream(thread, context)
      assert acc.__struct__ == GenAI.StreamHandler.Default.Accumulator
      assert acc.status == 200
      assert acc.completed
    end

    test "Default Streaming Policy - Legacy" do
      stream_while_expectation()
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread =
        GenAI.chat(:standard)
        |> GenAI.with_model(model)
        |> GenAI.with_setting(:temperature, 0.5)
        |> GenAI.with_message(GenAI.Message.system("System Prompt"))
        |> GenAI.with_message(GenAI.Message.user("Hello"))
        #|> GenAI.with_stream_handler(GenAI.StreamHandler.Console)
      {:ok, {acc, _}} = GenAI.stream(thread, context)
      assert acc.__struct__ == GenAI.StreamHandler.Default.Accumulator
      assert acc.status == 200
      assert acc.completed
    end

    test "Default Streaming Policy - Decodes Text, Usage, and Completion" do
      stream_while_expectation()
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread =
        GenAI.chat(:standard)
        |> GenAI.with_model(model)
        |> GenAI.with_setting(:temperature, 0.5)
        |> GenAI.with_message(GenAI.Message.user("Hello"))

      {:ok, {acc, _}} = GenAI.stream(thread, context)
      assert acc.text == "Hi there"
      assert acc.finish == :stop
      assert acc.usage == %{prompt_tokens: 10, completion_tokens: 2, total_tokens: 12}

      completion = acc.completion
      assert %GenAI.ChatCompletion{} = completion
      [choice] = completion.choices
      assert choice.message.content == "Hi there"
      assert choice.finish_reason == :stop
      assert completion.usage == %GenAI.ChatCompletion.Usage{
               prompt_tokens: 10,
               completion_tokens: 2,
               total_tokens: 12
             }
    end

    test "Streaming Policy - Accumulate Handler Forwards Events to Sink" do
      self = self()

      Mimic.expect(Finch, :stream_while, fn _req, _name, acc, cb, _opts ->
        {:cont, acc} = cb.({:status, 200}, acc)

        {:cont, acc} =
          cb.({:data, ~S(data: {"choices":[{"index":0,"delta":{"content":"To"}}]}) <> "\n\n"}, acc)

        {:cont, acc} =
          cb.({:data, ~S(data: {"choices":[{"index":0,"delta":{"content":"ken"}}]}) <> "\n\n"}, acc)

        {:cont, acc} = cb.({:data, "data: [DONE]\n\n"}, acc)
        {:ok, acc}
      end)

      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread =
        GenAI.chat(:standard)
        |> GenAI.with_model(model)
        |> GenAI.with_message(GenAI.Message.user("Hello"))
        |> GenAI.with_stream_handler(%GenAI.StreamHandler.Accumulate{sink: self})

      {:ok, {acc, _}} = GenAI.stream(thread, context)
      assert acc.__struct__ == GenAI.StreamHandler.Default.Accumulator
      assert acc.text == "Token"

      assert_received {:genai, {:text, "To"}}
      assert_received {:genai, {:text, "ken"}}
    end

  end





end
