defmodule GenAI.StreamHandler.OpenAI do
  @moduledoc """
  Decoder for OpenAI compatible `chat.completion.chunk` SSE streams —
  OpenAI, Groq, Mistral, DeepSeek, XAI, Zai, Cerebras, LiteLLM, Ollama, …

  `stream_event/1` converts a decoded chunk json map into a list of
  normalized stream events:

    - `{:text, binary}`   — content delta
    - `{:thinking, binary}` — reasoning delta (`reasoning_content` / `reasoning`)
    - `{:tool_call, map}` — tool call delta (raw provider shape)
    - `{:usage, map}`     — normalized usage, when the provider emits it
      (OpenAI requires `stream_options: %{include_usage: true}`)
    - `{:finish, atom}`   — normalized stop reason
  """

  # ⟦𓇓𓅱𓃭𓎛𓆄⟧ stream_event :: Convert a decoded chat.completion.chunk into normalized stream events.
  def stream_event(json) do
    choice = json[:choices] && List.first(json[:choices])

    delta_events(choice && choice[:delta])
    |> Kernel.++(finish_event(choice && choice[:finish_reason]))
    |> Kernel.++(usage_event(json[:usage] || (json[:x_groq] && json[:x_groq][:usage])))
  end

  # ⟦𓃠𓈖𓉔𓍦𓏏⟧ delta_events :: Extract text/thinking/tool-call deltas.
  defp delta_events(nil), do: []

  defp delta_events(delta) do
    text_event(delta[:content]) ++
      thinking_event(delta[:reasoning_content] || delta[:reasoning]) ++
      tool_call_event(delta[:tool_calls])
  end

  defp text_event(s) when is_binary(s) and s != "", do: [{:text, s}]
  defp text_event(_), do: []

  defp thinking_event(s) when is_binary(s) and s != "", do: [{:thinking, s}]
  defp thinking_event(_), do: []

  defp tool_call_event(tool_calls) when is_list(tool_calls) and tool_calls != [],
    do: [{:tool_call, tool_calls}]

  defp tool_call_event(_), do: []

  # ⟦𓉬𓎡𓇣𓏌𓍿⟧ finish_event :: Normalize the provider stop reason.
  defp finish_event(nil), do: []
  defp finish_event(reason), do: [{:finish, GenAI.StreamHandler.normalize_finish(reason)}]

  # ⟦𓍄𓊝𓂰𓎦𓇋⟧ usage_event :: Normalize usage when present (often only on the final chunk).
  defp usage_event(nil), do: []

  defp usage_event(usage) do
    [
      {:usage,
       %{
         prompt_tokens: usage[:prompt_tokens],
         completion_tokens: usage[:completion_tokens],
         total_tokens: usage[:total_tokens]
       }}
    ]
  end
end
