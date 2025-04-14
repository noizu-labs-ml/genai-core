defmodule GenAI.InferenceProvider.DefaultProvider do
  @moduledoc """
  Inference Provider Default Provider.
  """


  @doc """
  Run inference and return response and updated thread_context
  """
  def run(module, thread_context, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_run, 3) do
      module.do_run(thread_context, context, options)
    else
      do_run(module, thread_context, context, options)
    end
  end

  def do_run(module, _, _, _) do
    raise GenAI.RequestError,
          message: "Inference provider #{inspect(module)} does not implement the do_run/1 function"
  end

  def normalize_messages(module, messages, model, thread_context, context, options)
  def normalize_messages(module, messages, model, thread_context, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_normalize_messages, 5) do
      module.do_normalize_messages(messages, model, thread_context, context, options)
    else
      do_normalize_messages(module, messages, model, thread_context, context, options)
    end
  end

  def do_normalize_messages(_, messages, model, thread_context, context, options) do
    with {:ok, encoder} <- GenAI.ModelProtocol.encoder(model) do
      encoder.normalize_messages(messages, model, thread_context, context, options)
    end
  end

end