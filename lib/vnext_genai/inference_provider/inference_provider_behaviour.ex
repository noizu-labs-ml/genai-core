defmodule GenAI.InferenceProviderBehaviour do
  @callback run(thread_context :: any, context :: any, options :: any) :: {:ok, {completion :: any, thread_context :: any}} | {:error, term}
  @callback normalize_messages(messages :: any, model :: any, thread_context :: any, context :: any, options :: any) :: {:ok, {any, any}} | {:error, any}

  # @callback models(options :: any) :: {:ok, models :: any} | {:error, term}

  defmacro __using__(options \\ []) do
    quote do
      @provider (unquote(options[:provider]) || GenAI.InferenceProvider.DefaultProvider)
      @behaviour GenAI.InferenceProviderBehaviour

      import GenAI.InferenceProvider.Helpers
      import GenAI.Helpers

      require GenAI.Helpers

      def run(thread_context, context, options \\ nil), do: @provider.run(__MODULE__, thread_context, context, options)
      def normalize_messages(messages, model, thread_context, context, options), do: @provider.normalize_messages(__MODULE__, messages, model, thread_context, context, options)
    end
  end
end
