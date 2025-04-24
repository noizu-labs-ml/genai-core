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

      thread = GenAI.chat(:standard)
               |> GenAI.with_model(model)
               |> GenAI.with_api_key(GenAI.Support.TestProvider, "foobar")
               |> GenAI.with_api_org(GenAI.Support.TestProvider, "bop-org")
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_provider_setting(GenAI.Support.TestProvider, :quirk_mode, true)
               |> GenAI.with_model_setting(model, :apple, :go)
               |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
               |> GenAI.with_message(GenAI.Message.system("System Prompt"))
               |> GenAI.with_messages([GenAI.Message.user("Hello"), GenAI.Message.assistant("Hello User")])
               |> GenAI.with_message(
                    GenAI.Message.user(
                      [
                        GenAI.Message.Content.TextContent.new("Is this a zebra?"),
                        GenAI.Message.Content.ImageContent.new(priv() <> "/media/kitten.jpeg")
                      ]
                    )
                  )
               |> GenAI.with_tool(GenAI.Test.Support.Common.random_fact_tool())

      {:ok, {completion, thread}} = GenAI.run(thread, context)

      response = List.first(completion.choices)
      assert response.message.content == "I'm afraid I can't do that Dave."
      assert completion.provider == GenAI.Support.TestProvider
      assert completion.model == "one"
      [_,user_message|_] = thread.state.artifacts[:messages]
      assert user_message.content == "Hello"
      assert user_message.role == :user

      model_settings = thread.state.artifacts[:model_settings]
      assert model_settings[:apple] == :go

      safety_settings = thread.state.artifacts[:safety_settings]
      assert safety_settings["HARM_CATEGORY_DANGEROUS_CONTENT"] == "BLOCK_ANY"

      body = thread.state.artifacts[:body]
      assert body.temperature == 0.7
    end

    @tag :pri0
    test "Acceptance Test - alt encoder" do

      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_two()

      thread = GenAI.chat(:standard)
               |> GenAI.with_model(model)
               |> GenAI.with_api_key(GenAI.Support.TestProvider, "foobar")
               |> GenAI.with_api_org(GenAI.Support.TestProvider, "bop-org")
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_provider_setting(GenAI.Support.TestProvider, :quirk_mode, true)
               |> GenAI.with_model_setting(model, :apple, :go)
               |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
               |> GenAI.with_message(GenAI.Message.system("System Prompt"))
               |> GenAI.with_messages([GenAI.Message.user("Hello"), GenAI.Message.assistant("Hello User")])
               |> GenAI.with_message(
                    GenAI.Message.user(
                      [
                        GenAI.Message.Content.TextContent.new("Is this a zebra?"),
                        GenAI.Message.Content.ImageContent.new(priv() <> "/media/kitten.jpeg")
                      ]
                    )
                  )
               |> GenAI.with_tool(GenAI.Test.Support.Common.random_fact_tool())

      {:ok, {completion, thread}} = GenAI.run(thread, context)

      response = List.first(completion.choices)
      assert response.message.content == "I'm afraid I can't do that Dave."
      assert completion.provider == GenAI.Support.TestProvider
      assert completion.model == "two"
      [_,user_message|_] = thread.state.artifacts[:messages]
      assert user_message.content == "Hello"
      assert user_message.role == :mike

      model_settings = thread.state.artifacts[:model_settings]
      assert model_settings[:apple] == :go

      safety_settings = thread.state.artifacts[:safety_settings]
      assert safety_settings["HARM_CATEGORY_DANGEROUS_CONTENT"] == "BLOCK_ANY"

      body = thread.state.artifacts[:body]
      assert body.temperature == 0.7
    end
    
    
    @tag :pri1
    test "Acceptance Test - VNext" do
      
      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()
      
      thread = GenAI.chat(:session)
               |> GenAI.with_model(model)
               |> GenAI.with_api_key(GenAI.Support.TestProvider, "foobar")
               |> GenAI.with_api_org(GenAI.Support.TestProvider, "bop-org")
               |> GenAI.with_setting(:temperature, 0.7)
               |> GenAI.with_provider_setting(GenAI.Support.TestProvider, :quirk_mode, true)
               |> GenAI.with_model_setting(model, :apple, :go)
               |> GenAI.with_safety_setting("HARM_CATEGORY_DANGEROUS_CONTENT", "BLOCK_ANY")
               |> GenAI.with_message(GenAI.Message.system("System Prompt"))
               |> GenAI.with_messages([GenAI.Message.user("Hello"), GenAI.Message.assistant("Hello User")])
               |> GenAI.with_message(
                    GenAI.Message.user(
                      [
                        GenAI.Message.Content.TextContent.new("Is this a zebra?"),
                        GenAI.Message.Content.ImageContent.new(priv() <> "/media/kitten.jpeg")
                      ]
                    )
                  )
               |> GenAI.with_tool(GenAI.Test.Support.Common.random_fact_tool())
      
      {:ok, {completion, thread}} = GenAI.run(thread, context)
      response = List.first(completion.choices)
      assert response.message.content == "I'm afraid I can't do that Dave."
      assert completion.provider == GenAI.Support.TestProvider
      assert completion.model == "one"
      [_,user_message|_] = thread.state.artifacts[:messages]
      assert user_message.content == "Hello"
      assert user_message.role == :user
      
      model_settings = thread.state.artifacts[:model_settings]
      assert model_settings[:apple] == :go
      
      safety_settings = thread.state.artifacts[:safety_settings]
      assert safety_settings["HARM_CATEGORY_DANGEROUS_CONTENT"] == "BLOCK_ANY"
      
      body = thread.state.artifacts[:body]
      assert body.temperature == 0.7
    end
    
  end
end