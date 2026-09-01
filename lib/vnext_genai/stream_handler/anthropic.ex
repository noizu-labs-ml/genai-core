defmodule GenAI.StreamHandler.Anthropic do
  @moduledoc """
  Decoder for Anthropic Messages API SSE streams (`stream: true`).

  `stream_event/1` converts a decoded Anthropic event json map into a list of
  normalized stream events:

    - `{:text, binary}`     — `content_block_delta` / `text_delta`
    - `{:thinking, binary}` — `content_block_delta` / `thinking_delta`
    - `{:tool_call, map}`   — `content_block_start` tool_use (id/name) and
      `content_block_delta` / `input_json_delta` (partial json), tagged with
      the block index
    - `{:usage, map}`       — normalized usage; `message_start` carries input
      tokens, `message_delta` the final output tokens
    - `{:finish, atom}`     — normalized stop reason from `message_delta`

  `ping` and unknown event types decode to `[]`.
  """

  # ⟦𓂔𓎟𓋹𓈖𓍲⟧ stream_event :: Convert a decoded Anthropic stream event into normalized stream events.
  def stream_event(json) do
    case json[:type] do
      "message_start" ->
        usage_event(json[:message] && json[:message][:usage])

      "content_block_start" ->
        block_start_event(json[:index], json[:content_block])

      "content_block_delta" ->
        delta_event(json[:index], json[:delta])

      "message_delta" ->
        finish_event(json[:delta] && json[:delta][:stop_reason]) ++
          usage_event(json[:usage])

      _ ->
        []
    end
  end

  # ⟦𓇑𓏏𓈅𓎖𓍎⟧ block_start_event :: Announce a tool_use block (id + name) when one starts.
  defp block_start_event(index, %{type: "tool_use"} = block) do
    [{:tool_call, %{index: index, id: block[:id], name: block[:name]}}]
  end

  defp block_start_event(_, _), do: []

  # ⟦𓃒𓏎𓉐𓇋𓍯⟧ delta_event :: Convert content block deltas.
  defp delta_event(_index, %{type: "text_delta"} = delta),
    do: [{:text, delta[:text]}]

  defp delta_event(_index, %{type: "thinking_delta"} = delta),
    do: [{:thinking, delta[:thinking]}]

  defp delta_event(index, %{type: "input_json_delta"} = delta),
    do: [{:tool_call, %{index: index, partial_json: delta[:partial_json]}}]

  defp delta_event(_, _), do: []

  # ⟦𓉪𓏌𓎛𓄤𓍧⟧ finish_event :: Normalize the Anthropic stop reason.
  defp finish_event(nil), do: []

  defp finish_event(reason), do: [{:finish, GenAI.StreamHandler.normalize_finish(reason)}]

  # ⟦𓊃𓍇𓏤𓎁𓆉⟧ usage_event :: Normalize usage (input_tokens / output_tokens → prompt/completion).
  defp usage_event(nil), do: []

  defp usage_event(usage) do
    [
      {:usage,
       %{
         prompt_tokens: usage[:input_tokens],
         completion_tokens: usage[:output_tokens],
         total_tokens: usage[:total_tokens]
       }}
    ]
  end
end
