defmodule GenAI.InferenceProviderBehaviour do
  @type session :: any
  @type context :: any
  @type options :: any
  @type completion :: any
  @type model :: any
  @type settings :: map()
  @type headers :: list()
  @type url :: String.t()
  @type uri :: url
  @type method :: :get | :post | :put | :delete | :option | :patch
  @type request_body :: any
  @type messages :: list()
  @type tools :: list() | nil

  # ---------------------
  # Core
  # ---------------------
  @doc "Return config_key inference provide application config stored under :genai entry"
  @callback config_key() :: atom

  # @doc "Base url for provider, may be overriden/ignored by encoder"
  # @callback base_url(model, settings, session, context, options) :: {:ok, url} | {:ok, {url, session}} | {:error, term}

  # ---------------------
  # Run
  # ---------------------
  @doc "Build and run inference thread"
  @callback run(session, context, options) :: {:ok, {completion, session}} | {:error, term}

  # ---------------------
  # Run Support
  # ---------------------
  @doc "Prepare request headers"
  @callback headers(model, settings, session, context, options) ::
              {:ok, headers} | {:ok, {headers, session}} | {:error, term}

  @doc "Prepare endpoint and method to make inference call to"
  @callback endpoint(model, settings, session, context, options) ::
              {:ok, {method, uri}} | {:ok, {{method, uri}, session}} | {:error, term}

  @doc "Prepare request body to be passed to inference call."
  @callback request_body(model, messages, tools, settings, session, context, options) ::
              {:ok, headers} | {:ok, {headers, session}} | {:error, term}

  # ---------------------
  # Settings Config
  # ---------------------
  @doc "Obtain map of effective settings: settings, model_settings, provider_settings, config_settings, etc."
  @callback effective_settings(model, session, context, options) ::
              {:ok, {settings, session}} | {:error, term}

  @doc "Obtain list of hyper params supported by given model including mapping and conditional rules/alterations"
  @callback hyper_params(model, session, context, options) ::
              {:ok, {settings, session}} | {:error, term}

  defmacro __using__(options \\ []) do
    quote do
      @provider unquote(options[:provider]) || GenAI.InferenceProvider.DefaultProvider
      @behaviour GenAI.InferenceProviderBehaviour

      import GenAI.InferenceProvider.Helpers
      import GenAI.Helpers

      require GenAI.Helpers

      # ---------------------
      # Core
      # ---------------------
      @doc "Return config_key inference provide application config stored under :genai entry"
      def config_key(),
        do: unquote(options[:config_key])

      # @doc "Base url for provider, may be overriden/ignored by encoder"
      # def base_url(model, settings, session, context, options \\ nil),
      #    do: unquote(options[:base_url])

      # ---------------------
      # Run
      # ---------------------
      @doc "Build and run inference thread"
      def run(session, context, options \\ nil),
        do: @provider.run(__MODULE__, session, context, options)

      # ---------------------
      # Run Support
      # ---------------------
      @doc "Prepare endpoint and method to make inference call to"
      def endpoint(model, settings, session, context, options \\ nil),
        do: @provider.endpoint(__MODULE__, model, settings, session, context, options)

      @doc "Prepare request headers"
      def headers(model, settings, session, context, options \\ nil),
        do: @provider.headers(__MODULE__, model, settings, session, context, options)

      @doc "Prepare request body to be passed to inference call."
      def request_body(model, messages, tools, settings, session, context, options \\ nil),
        do:
          @provider.request_body(
            __MODULE__,
            model,
            messages,
            tools,
            settings,
            session,
            context,
            options
          )

      # ---------------------
      # Settings Config
      # ---------------------
      @doc "Obtain map of effective settings: settings, model_settings, provider_settings, config_settings, etc."
      def effective_settings(model, session, context, options \\ nil),
        do: @provider.effective_settings(__MODULE__, model, session, context, options)

      defoverridable config_key: 0
      # base_url: 4,
      # base_url: 5,
    end
  end
end
