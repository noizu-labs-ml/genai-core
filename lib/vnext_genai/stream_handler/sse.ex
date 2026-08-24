defmodule GenAI.StreamHandler.SSE do
  @moduledoc """
  Server-Sent Events (SSE) parser for streaming inference responses.

  Pure and incremental: feed it raw chunk data as it arrives off the wire and
  it returns parsed events plus any trailing partial frame to carry forward
  into the next `feed/2` call.

  Events:

    - `{:data, payload}` — a completed `data:` frame (payload verbatim, `\\n`
      joined when a frame carries multiple `data:` lines)
    - `:done` — the `[DONE]` sentinel used by OpenAI compatible providers

  Comment lines (`:` prefixed) and non-`data` fields are ignored per the SSE
  spec. Handles `\\n\\n` and `\\r\\n\\r\\n` frame separators, including
  separators split across chunk boundaries.
  """

  # ⟦𓊖𓉶𓋿𓍚𓎝⟧ feed :: Incrementally parse SSE frames from the wire.
  def feed(buffer \\ "", chunk \\ "")

  def feed(buffer, chunk) do
    buffer = (buffer || "") <> (chunk || "")
    {frames, rest} = split_frames(buffer)
    {Enum.flat_map(frames, &parse_frame/1), rest}
  end

  # ⟦𓄿𓂉𓈖𓂀𓍁⟧ split_frames :: Split buffer on blank-line separators, keeping any trailing partial frame.
  defp split_frames(buffer) do
    normalized =
      buffer
      |> String.replace("\r\n", "\n")
      |> String.replace("\r", "\n")

    do_split_frames(normalized, [])
  end

  defp do_split_frames(buffer, acc) do
    case :binary.match(buffer, "\n\n") do
      :nomatch ->
        {Enum.reverse(acc), buffer}

      {at, _} ->
        frame = :binary.part(buffer, 0, at)
        rest = :binary.part(buffer, at + 2, byte_size(buffer) - at - 2)
        do_split_frames(rest, [frame | acc])
    end
  end

  # ⟦𓋴𓂧𓎼𓈋𓆑⟧ parse_frame :: Extract data payload (or [DONE]) from a single frame.
  defp parse_frame(frame) do
    data_lines =
      frame
      |> String.split("\n", trim: true)
      |> Enum.flat_map(&parse_line/1)

    case data_lines do
      [] ->
        []

      _ ->
        payload = Enum.join(data_lines, "\n")

        if payload == "[DONE]" do
          [:done]
        else
          [{:data, payload}]
        end
    end
  end

  defp parse_line(":" <> _), do: []
  defp parse_line("data:" <> rest), do: [String.trim_leading(rest, " ")]
  defp parse_line(_), do: []
end
