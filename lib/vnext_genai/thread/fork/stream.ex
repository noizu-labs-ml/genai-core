defmodule GenAI.Thread.Fork.Stream do
  @moduledoc false
  # The real leaf provider owns preparation, encoding and finalization. Carry
  # identity in options, never replace/persist its configured handler directive.
  def execute(thread, context, options, path) do
    GenAI.ThreadProtocol.execute(
      thread,
      :stream,
      context,
      Keyword.put(options || [], :fork_path, path)
    )
  end

  def sink(nil, _path), do: nil
  def sink(sink, nil), do: sink

  def sink(pid, path) when is_pid(pid),
    do: fn event -> send(pid, {:genai, {:branch, path, event}}) end

  def sink(callback, path) when is_function(callback, 1),
    do: fn event -> callback.({:branch, path, event}) end

  def sink(sink, _path), do: sink
end
