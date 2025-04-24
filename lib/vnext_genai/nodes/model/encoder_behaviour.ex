defmodule GenAI.Model.EncoderBehaviour do

  @doc """
  Format tool for provider/model type.
  """
  @callback encode_tool(tool :: any, thread_context  :: any, context :: any, options :: any) :: {:ok, {tool :: any, thread_context :: any}} | {:error, term}

  @doc """
  Format message for provider/model type.
  """
  @callback encode_message(message :: any, thread_context  :: any, context :: any, options :: any) :: {:ok, {message :: any, thread_context :: any}} | {:error, term}

  @callback normalize_messages(messages :: any, model :: any, thread_context :: any, context :: any, options :: any) :: {:ok, {any, any}} | {:error, any}

  @doc """
  Set setting with dynamic model based logic.
  """
  @callback with_dynamic_setting(body :: term, setting :: term, model :: term, settings :: term) :: term
  @callback with_dynamic_setting(body :: term, setting :: term, model :: term, settings :: term, default :: term) :: term

  @doc """
  Set setting as_setting with dynamic model based logic.
  """
  @callback with_dynamic_setting_as(body :: term, as_setting  :: term, setting  :: term,  model  :: term, settings  :: term)  :: term
  @callback with_dynamic_setting_as(body :: term, as_setting  :: term, setting  :: term,  model  :: term, settings  :: term, default  :: term)  :: term

end