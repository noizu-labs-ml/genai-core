defmodule GenAI.Model.Encoder.DefaultProvider do
  
  import GenAI.Records.Directive,
    only: [hyper_param: 1, hyper_param: 2]

  require GenAI.Records.Directive
  
  #**********************************
  # Prepare Requests
  #**********************************

  #---------------------------------
  # headers/5
  #---------------------------------
  @doc "Prepare request headers"
  def headers(module, model, settings, session , context, options)
  def headers(module, model, settings, session , context, options) do
    auth = cond do
      key = settings.model_settings[:api_key] ->  {"Authorization", "Bearer #{key}"}
      key = settings.provider_settings[:api_key] ->  {"Authorization", "Bearer #{key}"}
      key = settings.config_settings[:api_key] ->  {"Authorization", "Bearer #{key}"}
      key = options[:api_key] ->  {"Authorization", "Bearer #{key}"}
    end
    {:ok, {[auth, {"content-type", "application/json"}], session}}
  end
  
  #---------------------------------
  # request_body/7
  #---------------------------------
  @doc "Prepare request body to be passed to inference call."
  def request_body(module, model, messages, tools,  settings, session, context, options)
  def request_body(module, model, messages, tools,  settings, session, context, options) do
      with {:ok, model_name} <- GenAI.ModelProtocol.name(model),
           {:ok, params} <- module.hyper_params(model, settings, session, context, options)  do
        body = %{
                 model: model_name,
                 messages: messages
               }
               |> then(& if tools == [], do: Map.put(&1, :tools, tools), else: &1)
               
        body = apply_hyper_params_and_adjust(module, body, params, model, settings)
        {:ok, {body, session}}
      end
  end
  
  defp apply_hyper_params_and_adjust(module, body, params, model, settings) do
    body_s1 = Enum.reduce(params, body,
      fn
        hyper_param(name: name, as: nil), body ->
          module.with_dynamic_setting(body, name, model, settings.settings)
        hyper_param(name: name, as: as), body ->
          module.with_dynamic_setting_as(body, as, name, model, settings.settings)
      end
    )
    body_s2 = Enum.reduce(params, body_s1,
      fn
        hyper_param(sentinel: nil), body ->
          body
        x = hyper_param(name: name, as: as, sentinel: {m,f,a}), body ->
          if Map.has_key?(body, as || name) do
            if apply(m,f, [x, body_s1, model, settings | a]) do
              body
            else
              Map.delete(body, as || name)
            end
          else
            body
          end
        (x = hyper_param(name: name, as: as, sentinel: sentinel), body) when is_function(sentinel, 4) ->
          if Map.has_key?(body, as || name) do
            if sentinel.(x, body_s1, model, settings) do
              body
            else
              Map.delete(body, as || name)
            end
          else
            body
          end
      end
    )
    body_s3 = Enum.reduce(params, body_s2,
      fn
        hyper_param(adjuster: nil), body ->
          body
        x = hyper_param(name: name, as: as, adjuster: {m,f,a}), body ->
          with true < - Map.has_key?(body, as || name),
               {:ok, update} <- apply(m,f, [x, body_s1, model, settings | a]) do
            Map.put(body, as || name, update)
          else
            _ -> body
          end
        (x = hyper_param(name: name, as: as, adjuster: adjuster), body) when is_function(adjuster, 4) ->
          with true < - Map.has_key?(body, as || name),
               {:ok, update} <- adjuster.(x, body_s1, model, settings) do
            Map.put(body, as || name, update)
          else
            _ -> body
          end
      end
    )
    body_s3
  end
  
  
  def completion_response(module, json, model, settings,  session, context, options)
  def completion_response(module, json, model, _, _, _, _) do
    with  {:ok, provider} <- GenAI.ModelProtocol.provider(model),
          %{
           id: id,
           usage: %{
             prompt_tokens: prompt_tokens,
             total_tokens: total_tokens,
             completion_tokens: completion_tokens
           },
           model: model,
           #created: created,
           choices: choices
         } <- json do
      choices = Enum.map(choices, &choices_from_json(id, &1))
                |> Enum.map(fn {:ok, c} -> c end)
      completion = %GenAI.ChatCompletion{
        id: id,
        provider: provider,
        model: model,
        usage: %GenAI.ChatCompletion.Usage{
          prompt_tokens: prompt_tokens,
          total_tokens: total_tokens,
          completion_tokens: completion_tokens
        },
        choices: choices
      }
      {:ok, completion}
    end
  end
  
  defp choices_from_json(id, json) do
    with %{
           index: index,
           message: message,
           finish_reason: finish_reason,
         } <- json do
      with {:ok, message} <- choice_message_from_json(id, message) do
        choice = %GenAI.ChatCompletion.Choice{
          index: index,
          message: message,
          finish_reason: String.to_atom(finish_reason)
        }
        {:ok, choice}
      end
    end
  end
  
  defp choice_message_from_json(_id, json) do
    case json do
      %{
        role: "assistant",
        content: content,
        tool_calls: nil
      } ->
        msg = %GenAI.Message{
          role: :assistant,
          content: content
        }
        {:ok, msg}
      %{
        role: "assistant",
        content: content,
        tool_calls: tc
      } ->
        x = Enum.map(tc, fn
          (%{function: _} = x) ->
            x
            |> put_in([Access.key(:function), Access.key(:arguments)],Jason.decode!(x.function.arguments, keys: :atoms))
          #|> put_in([Access.key(:function), Access.key(:identifier)], UUID.uuid4())
        end)
        {:ok, %GenAI.Message.ToolCall{role: :assistant, content: content, tool_calls: x}}
      %{
        role: "assistant",
        content: content,
      } ->
        msg = %GenAI.Message{
          role: :assistant,
          content: content
        }
        {:ok, msg}
    end
  end
  
  #**********************************
  # Message and Tool Formatting
  # and Normalization
  #**********************************
  
  #---------------------------------
  # encode_tool
  #---------------------------------
  @doc """
  Format tool for provider/model type.
  """
  def encode_tool(module, tool, model, session, context, options)
  def encode_tool(module, tool, model, session, context, options) do
    with {:ok, protocol} <- module.encoder_protocol(model, session, context, options) do
      protocol.encode(tool, model, session, context, options)
    end
  end
  
  
  
  #---------------------------------
  # encode_message
  #---------------------------------
  @doc """
  Format message for provider/model type.
  """
  def encode_message(module, message, model, session, context, options)
  def encode_message(module, message, model, session, context, options) do
    with {:ok, protocol} <- module.encoder_protocol(model, session, context, options) do
      protocol.encode(message, model, session, context, options)
    end
  end
  
  #---------------------------------
  # normalize_messages
  #---------------------------------
  def normalize_messages(module, messages, model, session, context, options)
  def normalize_messages(_, messages, _, session, _, _) do
    {:ok, {messages, session}}
  end
  
  
  #**********************************
  # Settings
  #**********************************
  
  
  #---------------------------------
  # with_dynamic_setting
  #---------------------------------
  @doc """
  Set setting with dynamic model based logic.
  """
  def with_dynamic_setting(module, body, setting, model, settings, default \\ nil)
  def with_dynamic_setting(_, body, setting, model, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting(body, setting, settings, default)
  end
  
  #---------------------------------
  # with_dynamic_setting_as
  #---------------------------------
  @doc """
  Set setting as_setting with dynamic model based logic.
  """
  def with_dynamic_setting_as(module, body, as_setting, setting, model, settings, default \\ nil)
  def with_dynamic_setting_as(_, body, as_setting, setting, model, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting_as(body, as_setting, setting, settings, default)
  end
  
  #---------------------
  # Settings Config
  #---------------------
  @doc "Obtain list of hyper params supported by given model including mapping and conditional rules/alterations"
  def hyper_params(module, model, settings, session, context, options)
  def hyper_params(module, model, settings, session, context, options) do
    cond do
      (x = options[:hyper_params];
      is_list(x) and x != [] )-> {:ok, x}
      (x = settings.config_settings[:hyper_params];
      is_list(x) and x != []) -> {:ok, x}
      :else ->
        module.default_hyper_params(model, settings, session, context, options)
    end
  end
  
  
  @doc "Obtain list of hyper params supported by given model including mapping and conditional rules/alterations"
  def default_hyper_params(module, model, settings, session, context, options)
  def default_hyper_params(module, model, settings, session, context, options) do
    x = [
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :logprobe),
      hyper_param(name: :top_logprobs),
      hyper_param(name: :logit_bias),
      
      # In the future dynamic_settings or the hyper_param sentinel
      # and adjuster methods may be used to convert max_tokens
      # to max_completions_tokens on thinking models while stripping max_tokens.
      # using max_completion_tokens if set.
      hyper_param(name: :max_tokens),
      hyper_param(name: :max_completion_tokens),
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :completion_choices, as: :n),
      hyper_param(name: :presence_penalty),
      hyper_param(name: :response_format),
      hyper_param(name: :seed),
      hyper_param(name: :stop, type: :list),
      hyper_param(name: :temperature),
      hyper_param(name: :top_p),
      hyper_param(name: :user, type: :string),
      hyper_param(name: :tool_choice, type: :string, sentinel: fn(_, body, _, _) -> body[:tools] && true end),
    ]
    {:ok, x}
  end


end