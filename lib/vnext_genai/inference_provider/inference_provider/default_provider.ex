defmodule GenAI.InferenceProvider.DefaultProvider do
  @moduledoc """
  Inference Provider Default Provider.
  """
  
  alias GenAI.ThreadProtocol
  import GenAI.InferenceProvider.Helpers

  
  
  
  #*************************
  # run/4
  #*************************
  @doc """
  Run inference and return completion response and updated session
  """
  def run(module, session, context, options \\ nil) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_run, 3) do
      module.do_run(session, context, options)
    else
      do_run(module, session, context, options)
    end
  end

  def do_run(module, session, context, options \\ nil) do
    with {:ok, {model, session}} <- ThreadProtocol.effective_model(session, context, options),
         {:ok, model_encoder} <- ModelProtocol.encoder(model),
         {:ok, {effective, session}} <- module.effective_settings(session, model, context, options),
         {:ok, {tools, session}} <- ThreadProtocol.effective_tools(session, model, context, options),
         {:ok, {messages, session}} <- ThreadProtocol.effective_messages(session, model, context, options) do
      
      # Build Request
      with {:ok, {req_body, session}} <- module.request_body(model, messages, tools,  effective, session, context, options),
           {:ok, {req_headers, session}} <- module.headers(model, effective, session, context, options),
           {:ok, {{req_method, req_endpoint}, session}} <- module.endpoint(model, effective, session, context, options) do
        with {:ok, %Finch.Response{status: 200, body: response_body}}
             <- api_call(req_method, req_endpoint, req_headers, req_body),
             {:ok, json} <- Jason.decode(response_body, keys: :atoms),
             {:ok, response} <- model_encoder.completion_response(json, model, effective,  session, context, options),
             response <- put_in(response, [Access.key(:seed)], req_body[:random_seed]) do
          {:ok, {response, session}}
        end
      end
      
    end
  end
  
  
  
  #*************************
  # Run Support
  #*************************
  
  #----------------------
  # endpoint/6
  #----------------------
  @doc "Prepare endpoint and method to make inference call to"
  def endpoint(module, model, settings, session, context, options \\ nil)
  def endpoint(module, model, settings, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_endpoint, 5) do
      module.do_endpoint(model, settings, session, context, options)
    else
      do_endpoint(module, model, settings, session, context, options)
    end
  end
  
  def do_endpoint(module, model, settings, session, context, options) do
    with {:ok, model_encoder} <- ModelProtocol.encoder(model) do
      model_encoder.endpoint(model, settings, session, context, options)
    end
  end
  
  #----------------------
  # headers/6
  #----------------------
  @doc "Prepare request headers"
  def headers(module, model, settings, session, context, options \\ nil)
  def headers(module, model, settings, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_headers, 5) do
      module.do_headers(model, settings, session, context, options)
    else
      do_headers(module, model, settings, session, context, options)
    end
  end
  
  def do_headers(module, model, settings, session, context, options)
  def do_headers(_, model, settings, session, context, options) do
    with {:ok, model_encoder} <- ModelProtocol.encoder(model) do
      model_encoder.header(model, settings, session, context, options)
    end
  end
  
  
  #----------------------
  # request_body/8
  #----------------------
  @doc "Prepare request body to be passed to inference call."
  def request_body(module, model, messages, tools,  settings, session, context, options \\ nil)
  def request_body(module, model, messages, tools,  settings, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_request_body, 7) do
      module.do_request_body(model, messages, tools,  settings, session, context, options)
    else
      do_request_body(module, model, messages, tools,  settings, session, context, options)
    end
  end
  
  def do_request_body(module, model, messages, tools,  settings, session, context, options)
  def do_request_body(module, model, messages, tools,  settings, session, context, options) do
    with {:ok, model_encoder} <- ModelProtocol.encoder(model) do
      model_encoder.request_body(model, messages, tools,  settings, session, context, options)
    end
  end
  
  
  #**************************
  # Settings Config
  #*************************
  
  #----------------------
  # effective_settings/5
  #----------------------
  @doc "Obtain map of effective settings: settings, model_settings, provider_settings, config_settings, etc."
  def effective_settings(module, model, session, context, options \\ nil)
  def effective_settings(module, model, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_effective_settings, 4) do
      module.do_effective_settings(model, session, context, options)
    else
      do_effective_settings(module, model, session, context, options)
    end
  end
  
  def do_effective_settings(module, model, session, context, options)
  def do_effective_settings(module, model, session, _, _) do
    with {:ok, {settings, session}} <- GenAI.ThreadProtocol.effective_settings(session),
         {:ok, {safety_settings, session}} <- GenAI.ThreadProtocol.effective_safety_settings(session),
         {:ok, {model_settings, session}} <- GenAI.ThreadProtocol.effective_model_settings(session, model),
         {:ok, {provider_settings, session}} <- GenAI.ThreadProtocol.effective_provider_settings(session, model) do
      
      x = %{
        config_settings: Application.get_env(:genai, module.config_key(), []),
        settings: settings,
        model_settings: model_settings,
        provider_settings: provider_settings,
        safety_settings: safety_settings,
      }
      {:ok, {x, session}}
    end
  end
  
  
  
end