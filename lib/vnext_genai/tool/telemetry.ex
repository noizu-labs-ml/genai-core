defmodule GenAI.Tool.Telemetry do
  @moduledoc false

  @prefix [:genai]

  def emit(event, measurements, metadata, options) do
    metadata = maybe_include_payloads(metadata, options)

    if function = options[:telemetry] do
      safely(fn -> function.(@prefix ++ event, measurements, metadata) end)
    end

    if Code.ensure_loaded?(:telemetry) do
      safely(fn -> apply(:telemetry, :execute, [@prefix ++ event, measurements, metadata]) end)
    end

    :ok
  end

  def metadata(metadata, payload, options) do
    if options[:include_payloads], do: Map.merge(metadata, payload), else: metadata
  end

  defp maybe_include_payloads(metadata, _options), do: metadata

  defp safely(function) do
    function.()
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end
end
