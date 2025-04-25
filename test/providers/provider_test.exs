defmodule GenAI.Providers.ProviderTest do
  use ExUnit.Case,
    async: false

  @moduletag provider: :test_provider
  @moduletag :providers

  def priv() do
    List.to_string(:code.priv_dir(:genai_core))
  end

  describe "Validate TestProvider" do
    @tag :pri0
    test "Acceptance Test" do
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread =
        GenAI.chat(:standard)
        |> GenAI.with_model(model)
        |> GenAI.with_api_key(GenAI.Support.TestProvider, "foobar")
        |> GenAI.with_api_org(GenAI.Support.TestProvider, "bop-org")
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_provider_setting(GenAI.Support.TestProvider, :quirk_mode, true)
        |> GenAI.with_model_setting(model, :apple, :go)
        |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
        |> GenAI.with_message(GenAI.Message.system("System Prompt"))
        |> GenAI.with_messages([
          GenAI.Message.user("Hello"),
          GenAI.Message.assistant("Hello User")
        ])
        |> GenAI.with_message(
          GenAI.Message.user([
            GenAI.Message.Content.TextContent.new("Is this a zebra?"),
            GenAI.Message.Content.ImageContent.new(priv() <> "/media/kitten.jpeg")
          ])
        )
        |> GenAI.with_tool(GenAI.Test.Support.Common.random_fact_tool())

      {:ok, {completion, thread}} = GenAI.run(thread, context)

      response = List.first(completion.choices)
      assert response.message.content == "I'm afraid I can't do that Dave."
      assert completion.provider == GenAI.Support.TestProvider
      assert completion.model == "one"
      [_, user_message | _] = thread.state.artifacts[:messages]
      assert user_message.content == "Hello"
      assert user_message.role == :user

      model_settings = thread.state.artifacts[:model_settings]
      assert model_settings[:apple] == :go

      safety_settings =
        thread.state.artifacts[:safety_settings]
        |> Enum.into(%{})

      assert safety_settings["HARM_CATEGORY_DANGEROUS_CONTENT"] == "BLOCK_ANY"

      body = thread.state.artifacts[:body]
      assert body.temperature == 0.7
    end

    @tag :pri0
    test "Acceptance Test - alt encoder" do
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_two()

      thread =
        GenAI.chat(:standard)
        |> GenAI.with_model(model)
        |> GenAI.with_api_key(GenAI.Support.TestProvider, "foobar")
        |> GenAI.with_api_org(GenAI.Support.TestProvider, "bop-org")
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_provider_setting(GenAI.Support.TestProvider, :quirk_mode, true)
        |> GenAI.with_model_setting(model, :apple, :go)
        |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
        |> GenAI.with_message(GenAI.Message.system("System Prompt"))
        |> GenAI.with_messages([
          GenAI.Message.user("Hello"),
          GenAI.Message.assistant("Hello User")
        ])
        |> GenAI.with_message(
          GenAI.Message.user([
            GenAI.Message.Content.TextContent.new("Is this a zebra?"),
            GenAI.Message.Content.ImageContent.new(priv() <> "/media/kitten.jpeg")
          ])
        )
        |> GenAI.with_tool(GenAI.Test.Support.Common.random_fact_tool())

      {:ok, {completion, thread}} = GenAI.run(thread, context)

      response = List.first(completion.choices)
      assert response.message.content == "I'm afraid I can't do that Dave."
      assert completion.provider == GenAI.Support.TestProvider
      assert completion.model == "two"
      [_, user_message | _] = thread.state.artifacts[:messages]
      assert user_message.content == "Hello"
      assert user_message.role == :mike

      model_settings = thread.state.artifacts[:model_settings]
      assert model_settings[:apple] == :go

      safety_settings =
        thread.state.artifacts[:safety_settings]
        |> Enum.into(%{})

      assert safety_settings["HARM_CATEGORY_DANGEROUS_CONTENT"] == "BLOCK_ANY"

      body = thread.state.artifacts[:body]
      assert body.temperature == 0.7
    end

    @tag :pri1
    test "Acceptance Test - VNext" do
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(model)
        |> GenAI.with_api_key(GenAI.Support.TestProvider, "foobar")
        |> GenAI.with_api_org(GenAI.Support.TestProvider, "bop-org")
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_provider_setting(GenAI.Support.TestProvider, :quirk_mode, true)
        |> GenAI.with_model_setting(model, :apple, :go)
        |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
        |> GenAI.with_message(GenAI.Message.system("System Prompt"))
        |> GenAI.with_messages([
          GenAI.Message.user("Hello"),
          GenAI.Message.assistant("Hello User")
        ])
        |> GenAI.with_message(
          GenAI.Message.user([
            GenAI.Message.Content.TextContent.new("Is this a zebra?"),
            GenAI.Message.Content.ImageContent.new(priv() <> "/media/kitten.jpeg")
          ])
        )
        |> GenAI.with_tool(GenAI.Test.Support.Common.random_fact_tool())

      {:ok, {completion, thread}} = GenAI.run(thread, context)
      response = List.first(completion.choices)
      assert response.message.content == "I'm afraid I can't do that Dave."
      assert completion.provider == GenAI.Support.TestProvider
      assert completion.model == "one"
      [_, user_message | _] = thread.state.artifacts[:messages]
      assert user_message.content == "Hello"
      assert user_message.role == :user

      model_settings = thread.state.artifacts[:model_settings]
      assert model_settings[:apple] == :go

      safety_settings =
        thread.state.artifacts[:safety_settings]
        |> Enum.into(%{})

      assert safety_settings["HARM_CATEGORY_DANGEROUS_CONTENT"] == "BLOCK_ANY"

      body = thread.state.artifacts[:body]
      assert body.temperature == 0.7
    end

    @tag :pri1
    test "Acceptance Test - VNext - use provider" do
      context = Noizu.Context.system()
      options = []
      model = GenAI.Support.TestProvider2.Models.model_one()

      Mimic.expect(Finch, :request, fn _, _, _ ->
        {:ok,
         %Finch.Response{
           status: 200,
           body:
             "{\n  \"id\": \"chatcmpl-93OJTB9hxpGLsin0QnJjYiZmdJjUR\",\n  \"object\": \"chat.completion\",\n  \"created\": 1710595471,\n  \"model\": \"one\",\n  \"choices\": [\n    {\n      \"index\": 0,\n      \"message\": {\n        \"role\": \"assistant\",\n        \"content\": \"I'm afraid I can't do that Dave.\"\n      },\n      \"logprobs\": null,\n      \"finish_reason\": \"stop\"\n    }\n  ],\n  \"usage\": {\n    \"prompt_tokens\": 10,\n    \"completion_tokens\": 9,\n    \"total_tokens\": 19\n  },\n  \"system_fingerprint\": \"fp_4f2ebda25a\"\n}\n",
           headers: [],
           trailers: []
         }}
      end)

      thread =
        GenAI.chat(:session)
        |> GenAI.with_model(model)
        |> GenAI.with_api_key(GenAI.Support.TestProvider2, "foobar")
        |> GenAI.with_api_org(GenAI.Support.TestProvider2, "bop-org")
        |> GenAI.with_setting(:temperature, 0.7)
        |> GenAI.with_provider_setting(GenAI.Support.TestProvider, :quirk_mode, true)
        |> GenAI.with_model_setting(model, :apple, :go)
        |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
        |> GenAI.with_message(GenAI.Message.system("System Prompt"))
        |> GenAI.with_messages([
          GenAI.Message.user("Hello"),
          GenAI.Message.assistant("Hello User")
        ])
        |> GenAI.with_message(
          GenAI.Message.user([
            GenAI.Message.Content.TextContent.new("Is this a zebra?"),
            GenAI.Message.Content.ImageContent.new(priv() <> "/media/kitten.jpeg")
          ])
        )
        |> GenAI.with_tool(GenAI.Test.Support.Common.random_fact_tool())

      {:ok, {completion, thread}} = GenAI.run(thread, context)

      response = List.first(completion.choices)
      assert response.message.content == "I'm afraid I can't do that Dave."
      assert completion.provider == GenAI.Support.TestProvider2
      assert completion.model == "one"

      {:ok, {model, thread}} = GenAI.ThreadProtocol.effective_model(thread, context, options)

      {:ok, {messages, thread}} =
        GenAI.ThreadProtocol.effective_messages(thread, model, context, options)

      [_, user_message | _] = messages
      assert user_message.content == "Hello"
      assert user_message.role == :user

      {:ok, {model_settings, thread}} =
        GenAI.ThreadProtocol.effective_model_settings(thread, model, context, options)

      assert model_settings[:apple] == :go

      {:ok, {safety_settings, _}} =
        GenAI.ThreadProtocol.effective_safety_settings(thread, context, options)

      safety_settings =
        safety_settings
        |> Enum.into(%{})

      assert safety_settings["HARM_CATEGORY_DANGEROUS_CONTENT"] == "BLOCK_ANY"
    end
  end
end
