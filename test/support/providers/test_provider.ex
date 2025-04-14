defmodule GenAI.Support.TestProvider do
  @moduledoc """
  TestProvider.
  """
  use GenAI.InferenceProviderBehaviour


  def run_inference(thread_context, body, model_name, provider)
  def run_inference(thread_context, _, model_name, provider) do

    choice = %GenAI.ChatCompletion.Choice{
      index: 0,
      message: GenAI.Message.assistant("I'm afraid I can't do that Dave."),
      finish_reason: :finished
    }
    usage = %GenAI.ChatCompletion.Usage{
      prompt_tokens: 200,
      completion_tokens: 20,
      total_tokens: 220
    }
    completion = GenAI.ChatCompletion.new(
      model: model_name,
      provider: provider,
      seed: 1,
      choices: [choice],
      usage: usage
    )
    {:ok, {completion, thread_context}}
  end

  def do_run(thread_context, context, options)
  def do_run(thread_context, context, options) do
    with {:ok, {model, thread_context}} <- GenAI.ThreadProtocol.effective_model(thread_context),
         {:ok, {settings, thread_context}} <- GenAI.ThreadProtocol.effective_settings(thread_context),
         {:ok, {safety_settings, thread_context}} <- GenAI.ThreadProtocol.effective_safety_settings(thread_context),
         {:ok, {model_settings, thread_context}} <- GenAI.ThreadProtocol.effective_model_settings(thread_context, model),
         {:ok, {provider_settings, thread_context}} <- GenAI.ThreadProtocol.effective_provider_settings(thread_context, model),
         {:ok, model_encoder} <- GenAI.ModelProtocol.encoder(model),
         {:ok, model_handle} <- GenAI.ModelProtocol.handle(model),
         {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         {:ok, {messages, thread_context}} <- GenAI.ThreadProtocol.effective_messages(thread_context, model),
         {:ok, {tools, thread_context}} <- GenAI.ThreadProtocol.effective_tools(thread_context, model),
         {:ok, {messages, thread_context}} <- normalize_messages(messages, model, thread_context, context, options) do

      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :api_key, provider_settings[:api_key])
      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :api_key, provider_settings[:api_org])
      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :messages, messages)
      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :tools, tools)
      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :model_settings, model_settings)
      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :safety_settings, safety_settings)

      body = %{
               model: model_handle,
               messages: messages
             }
             |> model_encoder.with_dynamic_setting(:frequency_penalty, model, settings)
             |> model_encoder.with_dynamic_setting(:logprobe, model, settings)
             |> model_encoder.with_dynamic_setting(:top_logprobs, model, settings)
             |> model_encoder.with_dynamic_setting(:logit_bias, model, settings)
             |> model_encoder.with_dynamic_setting(:max_tokens, model, settings)
             |> model_encoder.with_dynamic_setting(:frequency_penalty, model, settings)
             |> model_encoder.with_dynamic_setting_as(:n, :completion_choices, model, settings)
             |> model_encoder.with_dynamic_setting(:presence_penalty, model, settings)
             |> model_encoder.with_dynamic_setting(:response_format, model, settings)
             |> model_encoder.with_dynamic_setting(:seed, model, settings)
             |> model_encoder.with_dynamic_setting(:stop, model, settings)
             |> model_encoder.with_dynamic_setting(:temperature, model, settings)
             |> model_encoder.with_dynamic_setting(:top_p, model, settings)
             |> model_encoder.with_dynamic_setting(:user, model, settings)
             |> then(
                  fn
                    body ->
                      if tools == [] do
                        body
                      else
                        body
                        |> with_setting(:tool_choice, settings)
                        |> Map.put(:tools, tools)
                      end
                  end
                )

      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :body, body)
      run_inference(thread_context, body, model_handle, provider)
    end
  end



end

defmodule GenAI.Support.TestProvider.EncoderOne do
  @moduledoc """
  TestProvider Encoder
  """
  @behaviour GenAI.Model.EncoderBehaviour

  def encode_tool(tool = %GenAI.Tool{}, thread_context) do
    encoded = %{
      type: :function,
      function: %{
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      }
    }

    {:ok, {encoded, thread_context}}
  end

  def encode_message(message, thread_context)
  def encode_message(message = %GenAI.Message{}, thread_context) do
    encoded = %{role: message.role, content: message.content}
    {:ok, {encoded, thread_context}}
  end
  def encode_message(message = %GenAI.Message.ToolResponse{}, thread_context) do
    encoded = %{
      role: :tool,
      tool_call_id: message.tool_call_id,
      content: Jason.encode!(message.tool_response)
    }
    {:ok, {encoded, thread_context}}
  end
  def encode_message(message = %GenAI.Message.ToolCall{}, thread_context) do
    tool_calls = Enum.map(message.tool_calls,
      fn(tc) ->
        update_in(tc, [Access.key(:function), Access.key(:arguments)], & &1 && Jason.encode!(&1))
      end
    )

    encoded = %{
      role: message.role,
      content: message.content,
      tool_calls: tool_calls
    }
    {:ok, {encoded, thread_context}}
  end


  def normalize_messages(messages, model, thread_context, context, options)
  def normalize_messages(messages, _, thread_context, _, _) do
    {:ok, {messages, thread_context}}
  end

  def with_dynamic_setting(body, setting, model, settings, default \\ nil)
  def with_dynamic_setting(body, setting, model, settings, default) do
    with_dynamic_setting_as(body, setting, setting, model, settings, default)
  end

  def with_dynamic_setting_as(body, as_setting, setting, model, settings, default \\ nil)
  def with_dynamic_setting_as(body, as_setting, setting, _, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting_as(body, as_setting, setting, settings, default)
  end

end

defmodule GenAI.Support.TestProvider.EncoderTwo do
  @moduledoc """
  TestProvider Encoder Two
  """
  @behaviour GenAI.Model.EncoderBehaviour

  def encode_tool(tool = %GenAI.Tool{}, thread_context) do
    encoded = %{
      type: :function,
      function: %{
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      }
    }

    {:ok, {encoded, thread_context}}
  end

  def encode_message(message, thread_context)
  def encode_message(message = %GenAI.Message{}, thread_context) do
    role_map = %{
      user: :mike,
      assistant: :agent,
      system: :system
    }
    role = role_map[message.role]
    encoded = %{role: role, content: message.content}
    {:ok, {encoded, thread_context}}
  end
  def encode_message(message = %GenAI.Message.ToolResponse{}, thread_context) do
    encoded = %{
      role: :tool,
      tool_call_id: message.tool_call_id,
      content: Jason.encode!(message.tool_response)
    }
    {:ok, {encoded, thread_context}}
  end
  def encode_message(message = %GenAI.Message.ToolCall{}, thread_context) do
    tool_calls = Enum.map(message.tool_calls,
      fn(tc) ->
        update_in(tc, [Access.key(:function), Access.key(:arguments)], & &1 && Jason.encode!(&1))
      end
    )

    encoded = %{
      role: message.role,
      content: message.content,
      tool_calls: tool_calls
    }
    {:ok, {encoded, thread_context}}
  end


  def normalize_messages(messages, model, thread_context, context, options)
  def normalize_messages(messages, _, thread_context, _, _) do
    {:ok, {messages, thread_context}}
  end

  def with_dynamic_setting(body, setting, model, settings, default \\ nil)
  def with_dynamic_setting(body, setting, model, settings, default) do
    with_dynamic_setting_as(body, setting, setting, model, settings, default)
  end

  def with_dynamic_setting_as(body, as_setting, setting, model, settings, default \\ nil)
  def with_dynamic_setting_as(body, as_setting, setting, _, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting_as(body, as_setting, setting, settings, default)
  end

end

defmodule GenAI.Support.TestProvider.Models do
  @moduledoc """
  TestProvider Models
  """
  def model_one() do
    GenAI.Model.new(
      provider: GenAI.Support.TestProvider,
      encoder: GenAI.Support.TestProvider.EncoderOne,
      model: "one"
    )
  end

  def model_two() do
    GenAI.Model.new(
      provider: GenAI.Support.TestProvider,
      encoder: GenAI.Support.TestProvider.EncoderTwo,
      model: "two"
    )
  end

end