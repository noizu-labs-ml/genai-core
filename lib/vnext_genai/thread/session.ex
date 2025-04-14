defmodule GenAI.Thread.Session do
  @moduledoc """
  More advanced VNext Thread Implementation
  """
  @vsn 1.0
  require GenAI.Records.Link
  require GenAI.Records.Session
  alias GenAI.Records.Session, as: Node
  alias GenAI.Session.Runtime
  alias GenAI.Session.State


  defstruct [
    state: nil,
    root: nil,
    runtime: nil,
    vsn: @vsn
  ]

  def new(options \\ nil)
  def new(options) do
    %__MODULE__{
      state: GenAI.Session.State.new(options[:state]),
      root:  %GenAI.Graph.Root{graph: GenAI.VNext.Graph.new(options[:graph])},
      runtime: GenAI.Session.Runtime.new(options[:runtime]),
      vsn: @vsn
    }
  end

  #-------------------------------------------
  # GenAI.ThreadProtocol
  #---------------------------------------------
  defimpl GenAI.ThreadProtocol do
    require Logger

    defp append_node(thread_context, node, options \\ nil)
    defp append_node(thread_context, node, options) do
      update_in(thread_context, [Access.key(:root), Access.key(:graph)], & GenAI.VNext.Graph.attach_node(&1, node, options))
    end

    #-------------------------------------
    # with_model/2
    #-------------------------------------
    @doc """
    Specify a specific model or model picker.

      This function allows you to define the model to be used for inference.
    You can either provide a specific model, like `Model.smartest()`, or a model picker function that dynamically selects
    the best model based on the context and available providers.

      Examples:
    * `Model.smartest()` - This will select the "smartest" available model at inference time, based on factors
      like performance and capabilities.
    * `Model.cheapest(params: :best_effort)` - This will select the cheapest available model that can handle the
      given parameters and context size.
    * `CustomProvider.custom_model` - This allows you to use a custom model from a user-defined provider.
    """
    def with_model(thread_context, model) do
      if GenAI.Graph.Node.is_node?(model, GenAI.Model) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(model)
        append_node(thread_context, n)
      else
        raise ArgumentError,
              message: "Model must be a GenAI.Model node, got #{inspect(model)}"
      end
    end

    #-------------------------------------
    #
    #-------------------------------------

    def with_tool(thread_context, tool) do
      if GenAI.Graph.Node.is_node?(tool, GenAI.Tool) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(tool)
        append_node(thread_context, n)
      else
        raise ArgumentError,
              message: "Tool must be a GenAI.Tool node, got #{inspect(tool)}"
      end
    end

    #-------------------------------------
    #
    #-------------------------------------
    def with_tools(context, tools) do
      Enum.reduce(tools, context, fn(tool, context) ->
        with_tool(context, tool)
      end)
    end

    #-------------------------------------
    #
    #-------------------------------------

    @doc """
    Specify an API key for a provider.
    """
    def with_api_key(thread_context, provider, api_key) do
      n = GenAI.Setting.ProviderSetting.new(
        provider: provider,
        setting: :api_key,
        value: api_key
      )
      append_node(thread_context, n)
    end

    #-------------------------------------
    #
    #-------------------------------------

    @doc """
    Specify an API org for a provider.
    """
    def with_api_org(thread_context, provider, api_org) do
      n = GenAI.Setting.ProviderSetting.new(
        provider: provider,
        setting: :api_org,
        value: api_org
      )
      append_node(thread_context, n)
    end

    #-------------------------------------
    #
    #-------------------------------------

    @doc """
    Set a hyperparameter option.

      Some options are model-specific. The value can be a literal or a picker function that dynamically determines
    the best value based on the context and model.

      Examples:
    * `Parameter.required(name, value)` - This sets a required parameter with the specified name and value.
    * `Gemini.best_temperature_for(:chain_of_thought)` - This uses a picker function to determine the best temperature
       for the Gemini provider when using the "chain of thought" prompting technique.
    """
    def with_setting(thread_context, setting, value) do
      n = GenAI.Setting.new(
        setting: setting,
        value: value
      )
      append_node(thread_context, n)
    end

    #-------------------------------------
    #
    #-------------------------------------
    def with_setting(thread_context, setting) do
      if GenAI.Graph.Node.is_node?(setting, GenAI.Setting) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(setting)
        append_node(thread_context, n)
      else
        raise ArgumentError,
              message: "Setting must be a GenAI.Setting node, got #{inspect(setting)}"
      end
    end

    #-------------------------------------
    #
    #-------------------------------------
    def with_settings(thread_context, settings) do
      Enum.reduce(settings, thread_context,
        fn
          ({setting, value}, thread_context) -> with_setting(thread_context, setting, value)
          (value, thread_context) when is_struct(value) -> with_setting(thread_context, value)
        end
      )
    end

    #-------------------------------------
    #
    #-------------------------------------
    def with_safety_setting(thread_context, category, threshold) do
      n = GenAI.Setting.SafetySetting.new(
        category: category,
        threshold: threshold
      )
      append_node(thread_context, n)
    end

    #-------------------------------------
    #
    #-------------------------------------
    def with_safety_setting(thread_context, safety_setting) do
      if GenAI.Graph.Node.is_node?(safety_setting, GenAI.Setting) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(safety_setting)
        append_node(thread_context, n)
      else
        raise ArgumentError,
              message: "SafetySetting must be a GenAI.Setting node, got #{inspect(safety_setting)}"
      end
    end

    #-------------------------------------
    #
    #-------------------------------------
    def with_safety_settings(context, safety_settings) do
      Enum.reduce(safety_settings, context,
        fn
          ({category, threshold}, context) -> with_safety_setting(context, category, threshold)
          (safety_setting, context) when is_struct(safety_setting) -> with_safety_setting(context, safety_setting)
        end
      )
    end

    #-------------------------------------
    #
    #-------------------------------------

    def with_provider_setting(thread_context, provider, setting, value) do
      node = GenAI.Setting.ProviderSetting.new(
        [
          provider: provider,
          setting: setting,
          value: value
        ]
      )
      append_node(thread_context, node)
    end

    def with_provider_setting(thread_context, setting_node) do
      if GenAI.Graph.Node.is_node?(setting_node, GenAI.Setting) do
        append_node(thread_context, setting_node)
      else
        raise ArgumentError,
              message: "Setting must be a GenAI.Setting node, got #{inspect(setting_node)}"
      end
    end


    def with_model_setting(thread_context, model, setting, value) do
      node = GenAI.Setting.ModelSetting.new(
        [
          model: model,
          setting: setting,
          value: value
        ]
      )
      append_node(thread_context, node)
    end

    def with_model_setting(thread_context, setting_node) do
      if GenAI.Graph.Node.is_node?(setting_node, GenAI.Setting) do
        append_node(thread_context, setting_node)
      else
        raise ArgumentError,
              message: "Setting must be a GenAI.Setting node, got #{inspect(setting_node)}"
      end
    end


    @doc """
    Add a message to the conversation.
    """
    def with_message(thread_context, message, options \\ nil)
    def with_message(thread_context, message, _) do
      if GenAI.Graph.Node.is_node?(message, GenAI.Message) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(message)
        append_node(thread_context, n)
      else
        raise ArgumentError,
              message: "Message must be a GenAI.Message node, got #{inspect(message)}"
      end
    end

    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    Add a list of messages to the conversation.
    """
    def with_messages(context, messages, options)
    def with_messages(context, messages, options) do
      Enum.reduce(messages, context, fn(message, context) ->
        with_message(context, message, options)
      end)
    end

    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    specify/override default stream handler
    """
    def with_stream_handler(thread_context, handler, options \\ nil)
    def with_stream_handler(thread_context, handler, _) do
      node = GenAI.Setting.new(
        [
          setting: :stream_handler,
          value: handler
        ]
      )
      append_node(thread_context, node)
    end

    #-------------------------------------
    #
    #-------------------------------------
    @doc """
    Run inference.

      This function performs the following steps:
    * Picks the appropriate model and hyperparameters based on the provided context and settings.
    * Performs any necessary pre-processing, such as RAG (Retrieval-Augmented Generation) or message consolidation.
    * Runs inference on the selected model with the prepared input.
    * Returns the inference result.
    """
    def execute(thread_context, command, context, options \\ nil)
    def execute(session, :run = command, context, options) do
      context = context || Noizu.Context.system()

      # Runtime
      session = session.runtime
                |> Runtime.command(command, context, options)
                |> apply_runtime(session)
      # State
      session = session.state
                |> GenAI.Session.State.initialize(session.runtime, context, options)
                |> apply_state(session)

      # Setup Monitor
      session = with {:ok, {state, runtime}} <-
                       GenAI.Session.State.monitor(
                         session.state,
                         session.runtime,
                         context,
                         options
                       ) do
        %{session| state: state, runtime: runtime}
      end

      scope = starting_scope(session.root, nil, nil, session)

      with Node.process_end(update: update) <-
             GenAI.Thread.SessionProtocol.process_node(
               session.root, scope, context, options
             ),
           {:ok, session} <- merge_scope(update, session) do

        process_response = [:get_model, :get_provider, :call_provider_execute]
        # Get effective model
        # Get effective provider
        # Call provider execute
        {:ok, {process_response, session}}
      end
    end


    def apply_runtime({:ok, runtime}, session) do
      %{session| runtime: runtime}
    end
    def apply_state({:ok, state}, session) do
      %{session| state: state}
    end
    def apply_root({:ok, root}, session) do
      %{session| root: root}
    end

    def merge_scope(Node.scope(session_state: state, session_root: root, session_runtime: runtime), session) do
       {:ok,  %{session| state: state, runtime: runtime, root: root}}
    end

    def starting_scope(graph_node, graph_link, graph_container, session) do
      Node.scope(
        graph_node: graph_node,
        graph_link: graph_link,
        graph_container: graph_container,
        session_state: session.state,
        session_root: session.root,
        session_runtime: session.runtime
      )
    end



      #  #-------------------------------------
      #  #
      #  #-------------------------------------
      #  @doc """
      #  Execute a command, such as run prompt fine tuner, dynamic prompt etc.
      #  # Options
      #  - report: return a report of the command execution (entire effective conversation with extended timing/loop details.
      #  - thread: return full thread along with most recent reply, useful for investigating exact dynamic messages generated in flow
      #  """
      #  def execute(session, command, context, options) do
      #    context = context || Noizu.Context.system()
      #    with {:ok, runtime} <-
      #           # Set Runtime Mode
      #           GenAI.Session.Runtime.command(session.runtime, command, context, options),
      #         {:ok, session_state} <-
      #           # Refresh state (clear any ephemeral values, etc. for rerun as specified by runtime object
      #           # set seeds, clear monitor cache, etc.
      #           GenAI.Session.State.initialize(session.state, runtime, context, options),
      #         {:ok, {session_state, runtime}} <-
      #           # Setup telemetry agents, etc.
      #           GenAI.Session.State.monitor(session_state, runtime, context, options) do
      #      with x <- GenAI.Session.NodeProtocol.process_node(
      #        session.graph,
      #        Node.scope(
      #          graph_node: session.graph,
      #          graph_link: nil,
      #          graph_container: nil,
      #          session_state: session_state,
      #          session_runtime: runtime
      #        ),
      #        context,
      #        options) do
      #        # TODO apply updates, return completion (if any) and session and generated report from monitor agent
      #        {:ok, :pending2}
      #      end
      #    end

      # Spawn Monitor Agent
      # Register Callbacks to Monitor Agent
      # Process session
      # Strip runtime flags from execute
      # Get metrics from monitor

      def effective_model(thread_context)
      def effective_model(_), do: {:error, :nyi}

      def effective_settings(thread_context)
      def effective_settings(_), do: {:error, :nyi}

      def effective_safety_settings(thread_context)
      def effective_safety_settings(_), do: {:error, :nyi}

      def effective_model_settings(thread_context, model)
      def effective_model_settings(_,_), do: {:error, :nyi}

      def effective_provider_settings(thread_context, model)
      def effective_provider_settings(_,_), do: {:error, :nyi}

      def effective_messages(thread_context, model)
      def effective_messages(_,_), do: {:error, :nyi}

      def effective_tools(thread_context, model)
      def effective_tools(_,_), do: {:error, :nyi}

      def set_artifact(thread_context, artifact, value)
      def set_artifact(_,_,_), do: {:error, :nyi}

      def get_artifact(thread_context, artifact)
      def get_artifact(_,_), do: {:error, :nyi}




    end

  end