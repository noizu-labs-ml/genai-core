defmodule GenAI.Model.EncoderBehaviour do
  @type session :: any
  @type context :: any
  @type options :: any
  @type completion :: any
  @type model :: any
  @type settings :: map()
  @type headers :: list()
  @type url :: String.t()
  @type uri ::  url
  @type method :: :get | :post | :put | :delete | :option | :patch
  @type request_body :: any
  @type messages :: list()
  @type tools :: list() | nil
  
  #**********************************
  # Prepare Requests
  #**********************************
  @doc """
  Prepare request headers
  """
  @callback headers(model, settings, session, context, options) :: {:ok, headers} | {:ok, {headers, session}} | {:error, term}
  
  @doc """
  Prepare endpoint and method to make inference call to
  """
  @callback endpoint(model, settings, session, context, options) :: {:ok, {method,uri}} | {:ok, {{method,uri}, session}} | {:error, term}
  
  @doc """
  Prepare request body to be passed to inference call.
  """
  @callback request_body(model, messages, tools, settings, session, context, options) :: {:ok, headers} | {:ok, {headers, session}} | {:error, term}
  
  #**********************************
  # Message and Tool Formatting and Normalization
  #**********************************
  
  #---------------------------------
  #
  #---------------------------------
  @doc """
  Format tool for provider/model type.
  """
  @callback encode_tool(tool :: any, thread_context  :: any, context :: any, options :: any) :: {:ok, {tool :: any, thread_context :: any}} | {:error, term}
  
  #---------------------------------
  #
  #---------------------------------
  @doc """
  Format message for provider/model type.
  """
  @callback encode_message(message :: any, thread_context  :: any, context :: any, options :: any) :: {:ok, {message :: any, thread_context :: any}} | {:error, term}
  
  #---------------------------------
  #
  #---------------------------------
  @callback normalize_messages(messages :: any, model :: any, thread_context :: any, context :: any, options :: any) :: {:ok, {any, any}} | {:error, any}
  
  
  #**********************************
  # Settings
  #**********************************
  
  
  #---------------------------------
  #
  #---------------------------------
  @doc """
  Set setting with dynamic model based logic.
  """
  @callback with_dynamic_setting(body :: term, setting :: term, model :: term, settings :: term) :: term
  @callback with_dynamic_setting(body :: term, setting :: term, model :: term, settings :: term, default :: term) :: term
  
  #---------------------------------
  #
  #---------------------------------
  @doc """
  Set setting as_setting with dynamic model based logic.
  """
  @callback with_dynamic_setting_as(body :: term, as_setting  :: term, setting  :: term,  model  :: term, settings  :: term)  :: term
  @callback with_dynamic_setting_as(body :: term, as_setting  :: term, setting  :: term,  model  :: term, settings  :: term, default  :: term)  :: term
  
  #---------------------------------
  #
  #---------------------------------
  @doc """
  Obtain list of hyper params supported by given model including mapping and conditional rules/alterations
  """
  @callback hyper_params(model, session, context, options) :: {:ok, {settings, session}} | {:error, term}
  
end