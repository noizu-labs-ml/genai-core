defprotocol GenAI.ThreadProtocol do
  @doc """
  Specify a specific model or model picker.

  This function allows you to define the model to be used for inference. You can either provide a specific model, like `Model.smartest()`, or a model picker function that dynamically selects the best model based on the context and available providers.

  Examples:
  * `Model.smartest()` - This will select the "smartest" available model at inference time, based on factors like performance and capabilities.
  * `Model.cheapest(params: :best_effort)` - This will select the cheapest available model that can handle the given parameters and context size.
  * `CustomProvider.custom_model` - This allows you to use a custom model from a user-defined provider.
  """
  def with_model(context, model)

  def with_tool(context, tool)
  def with_tools(context, tools)

  @doc """
  Specify an API key for a provider.
  """
  def with_api_key(context, provider, api_key)

  @doc """
  Specify an API org for a provider.
  """
  def with_api_org(context, provider, api_org)

  @doc """
  Set a hyperparameter option.

  Some options are model-specific. The value can be a literal or a picker function that dynamically determines the best value based on the context and model.

  Examples:
  * `Parameter.required(name, value)` - This sets a required parameter with the specified name and value.
  * `Gemini.best_temperature_for(:chain_of_thought)` - This uses a picker function to determine the best temperature for the Gemini provider when using the "chain of thought" prompting technique.
  """
  def with_setting(context, setting, value)
  def with_setting(context, setting_object)

  def with_settings(context, settings)

  def with_safety_setting(context, safety_setting, threshold)
  def with_safety_setting(context, safety_setting_object)

  def with_safety_settings(context, entries)

  def with_provider_setting(context, provider, setting, value)
  def with_provider_setting(context, node)

  def with_provider_settings(context, entries)
  def with_provider_settings(context, provider, entries)

  def with_model_setting(context, model, setting, value)
  def with_model_setting(context, node)

  def with_model_settings(context, model, entries)
  def with_model_settings(context, entries)

  @doc """
  Add a message to the conversation.
  """
  def with_message(context, message, options)

  @doc """
  Add a list of messages to the conversation.
  """
  def with_messages(context, messages, options)

  def with_stream_handler(context, handler, options \\ nil)

  def execute(session, command, context, options \\ nil)

  #  @doc """
  #  Start inference using a streaming handler.
  #
  #  If the selected model does not support streaming, the handler will be called with the final inference result.
  #  """
  #  def stream(thread_context, context)
  #
  #  @doc """
  #  Run inference.
  #
  #  This function performs the following steps:
  #  * Picks the appropriate model and hyperparameters based on the provided context and settings.
  #  * Performs any necessary pre-processing, such as RAG (Retrieval-Augmented Generation) or message consolidation.
  #  * Runs inference on the selected model with the prepared input.
  #  * Returns the inference result.
  #  """
  #  def run(context)

  def effective_model(thread_context, context, options)
  def effective_settings(thread_context, context, options)
  def effective_safety_settings(thread_context, context, options)
  def effective_model_settings(thread_context, model, context, options)
  def effective_provider_settings(thread_context, model, context, options)
  def effective_messages(thread_context, model, context, options)
  def effective_tools(thread_context, model, context, options)

  def append_directive(thread_context, directive, context, options)

  def set_artifact(thread_context, artifact, value)
  def get_artifact(thread_context, artifact)
end
