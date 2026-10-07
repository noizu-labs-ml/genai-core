defprotocol GenAI.Thread.LegacyStateProtocol do
  # <REMOVED UUID HERE> apply_model :: auto-generated pointer for public function apply_model
  def apply_model(thread_context, model)
  # <REMOVED UUID HERE> apply_setting :: auto-generated pointer for public function apply_setting
  def apply_setting(thread_context, node)
  # <REMOVED UUID HERE> apply_provider_setting :: auto-generated pointer for public function apply_provider_setting
  def apply_provider_setting(thread_context, node)
  # <REMOVED UUID HERE> apply_safety_setting :: auto-generated pointer for public function apply_safety_setting
  def apply_safety_setting(thread_context, node)
  # <REMOVED UUID HERE> apply_model_setting :: auto-generated pointer for public function apply_model_setting
  def apply_model_setting(thread_context, node)
  # <REMOVED UUID HERE> apply_tool :: auto-generated pointer for public function apply_tool
  def apply_tool(thread_context, tool)
  # <REMOVED UUID HERE> apply_message :: auto-generated pointer for public function apply_message
  def apply_message(thread_context, message)

  # <REMOVED UUID HERE> set_artifact :: auto-generated pointer for public function set_artifact
  def set_artifact(thread_context, artifact, value)
  # <REMOVED UUID HERE> get_artifact :: auto-generated pointer for public function get_artifact
  def get_artifact(thread_context, artifact)

  # <REMOVED UUID HERE> effective_model :: auto-generated pointer for public function effective_model
  def effective_model(thread_context, context, options)
  # <REMOVED UUID HERE> effective_settings :: auto-generated pointer for public function effective_settings
  def effective_settings(thread_context, context, options)
  # <REMOVED UUID HERE> effective_safety_settings :: auto-generated pointer for public function effective_safety_settings
  def effective_safety_settings(thread_context, context, options)
  # <REMOVED UUID HERE> effective_model_settings :: auto-generated pointer for public function effective_model_settings
  def effective_model_settings(thread_context, model, context, options)
  # <REMOVED UUID HERE> effective_provider_settings :: auto-generated pointer for public function effective_provider_settings
  def effective_provider_settings(thread_context, model, context, options)
  # <REMOVED UUID HERE> effective_messages :: auto-generated pointer for public function effective_messages
  def effective_messages(thread_context, model, context, options)
  # <REMOVED UUID HERE> effective_tools :: auto-generated pointer for public function effective_tools
  def effective_tools(thread_context, model, context, options)
end
