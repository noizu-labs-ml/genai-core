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
  @type message :: any
  @type messages :: list()
  @type method :: :get | :post | :put | :delete | :option | :patch
  @type request_body :: any
  @type tool :: any()
  @type tools :: list() | nil
  
  #**********************************
  # Prepare Requests
  #**********************************
  
  #---------------------------------
  # headers
  #---------------------------------
  @doc """
  Prepare request headers
  """
  @callback headers(model, settings, session, context, options) :: {:ok, headers} | {:ok, {headers, session}} | {:error, term}
  
  #---------------------------------
  #
  #---------------------------------
  @doc """
  Prepare endpoint and method to make inference call to
  """
  @callback endpoint(model, settings, session, context, options) :: {:ok, {method,uri}} | {:ok, {{method,uri}, session}} | {:error, term}
  
  #---------------------------------
  # endpoint
  #---------------------------------
  @doc """
  Prepare request body to be passed to inference call.
  """
  @callback request_body(model, messages, tools, settings, session, context, options) :: {:ok, headers} | {:ok, {headers, session}} | {:error, term}
  
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
  @callback encode_tool(tool, model, session, context, options) :: {:ok, {tool, session}} | {:error, term}
  
  #---------------------------------
  # encode_message
  #---------------------------------
  @doc """
  Format message for provider/model type.
  """
  @callback encode_message(message, session, context, options) :: {:ok, {message, session}} | {:error, term}
  
  #---------------------------------
  # normalize_messages
  #---------------------------------
  @callback normalize_messages(messages, model, session, context, options) :: {:ok, {any, any}} | {:error, any}
  
  
  #**********************************
  # Settings
  #**********************************
  
  
  #---------------------------------
  # with_dynamic_setting
  #---------------------------------
  @doc """
  Set setting with dynamic model based logic.
  """
  @callback with_dynamic_setting(body :: term, setting :: term, model :: term, settings :: term) :: term
  @callback with_dynamic_setting(body :: term, setting :: term, model :: term, settings :: term, default :: term) :: term
  
  #---------------------------------
  # with_dynamic_setting_as
  #---------------------------------
  @doc """
  Set setting as_setting with dynamic model based logic.
  """
  @callback with_dynamic_setting_as(body :: term, as_setting  :: term, setting  :: term,  model  :: term, settings  :: term)  :: term
  @callback with_dynamic_setting_as(body :: term, as_setting  :: term, setting  :: term,  model  :: term, settings  :: term, default  :: term)  :: term
  
  #---------------------------------
  # hyper_params
  #---------------------------------
  @doc """
  Obtain list of hyper params supported by given model including mapping and conditional rules/alterations
  """
  @callback hyper_params(model, session, context, options) :: {:ok, {settings, session}} | {:error, term}
  
  #=============================================================================
  #=============================================================================
  # USING MACRO
  #=============================================================================
  #=============================================================================
  defmacro __using__(options \\ []) do
    quote do
      @provider (unquote(options[:provider]) || GenAI.Model.Encoder.DefaultProvider)
      @behaviour GenAI.Model.EncoderBehaviour
      
      import GenAI.InferenceProvider.Helpers
      import GenAI.Helpers
      
      require GenAI.Helpers
      
      
      #**********************************
      # Prepare Requests
      #**********************************
      
      #---------------------------------
      # endpoint/5
      #---------------------------------
      @doc "Prepare endpoint and method to make inference call to"
      def endpoint(model, settings, session, context, options),
          do: @provider.endpoint(__MODULE__, model, settings, session, context, options)
      
      #---------------------------------
      # headers/5
      #---------------------------------
      @doc "Prepare request headers"
      def headers(model, settings, session , context, options),
          do: @provider.headers(__MODULE__, model, settings, session, context, options)
      
      #---------------------------------
      # request_body/7
      #---------------------------------
      @doc "Prepare request body to be passed to inference call."
      def request_body(model, messages, tools,  settings, session, context, options),
          do: @provider.request_body(__MODULE__, model, messages, tools, settings, session, context, options)
      
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
      def encode_tool(tool, model, session, context, options),
          do: @provider.request_body(__MODULE__, tool, model, session, context, options)
      
      
      
      #---------------------------------
      # encode_message
      #---------------------------------
      @doc """
      Format message for provider/model type.
      """
      def encode_message(message, session, context, options),
          do: @provider.encode_message(__MODULE__, message, session, context, options)
      
      #---------------------------------
      # normalize_messages
      #---------------------------------
      def normalize_messages(messages, model, session, context, options),
          do: @provider.normalize_messages(__MODULE__, messages, model, session, context, options)
      
      
      #**********************************
      # Settings
      #**********************************
      
      
      #---------------------------------
      # with_dynamic_setting
      #---------------------------------
      @doc """
      Set setting with dynamic model based logic.
      """
      def with_dynamic_setting(body, setting, model, settings),
          do: @provider.with_dynamic_setting(__MODULE__, body, setting, model, settings)
      def with_dynamic_setting(body, setting, model, settings, default),
          do: @provider.with_dynamic_setting(__MODULE__, body, setting, model, settings, default)
      
      #---------------------------------
      # with_dynamic_setting_as
      #---------------------------------
      @doc """
      Set setting as_setting with dynamic model based logic.
      """
      def with_dynamic_setting_as(body, as_setting , setting ,  model , settings),
          do: @provider.with_dynamic_setting_as(__MODULE__, body, as_setting , setting ,  model , settings)
      def with_dynamic_setting_as(body, as_setting , setting ,  model , settings , default),
          do: @provider.with_dynamic_setting_as(__MODULE__, body, as_setting , setting ,  model , settings , default)
      
      
      
      #---------------------
      # Settings Config
      #---------------------
      @doc "Obtain list of hyper params supported by given model including mapping and conditional rules/alterations"
      def hyper_params(model, settings, session, context, options),
          do: @provider.hyper_params(__MODULE__, model, settings, session, context, options)
      
      defoverridable [
        hyper_params: 4,
        hyper_params: 5,
      ]
    end
  end

end