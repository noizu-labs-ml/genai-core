defmodule GenAI.Dialogue.ApprovalScript do
  @moduledoc """
  Build a minimal genai_approval script that performs a single tool call.

  Product adapters pass endpoint alias, tool name, and finalized string-keyed args.
  """

  @doc """
  Render script source for one step: `call(endpoint, tool, args...)`.

  Args values must be binaries, numbers, or booleans (embedded as literals).
  """
  @spec single_tool(String.t(), String.t(), map(), keyword()) :: String.t()
  def single_tool(endpoint, tool, args, opts \\ [])
      when is_binary(endpoint) and is_binary(tool) and is_map(args) do
    step_title = Keyword.get(opts, :step_title, "Execute #{tool}")
    result_var = Keyword.get(opts, :result_var, "result")
    transport = Keyword.get(opts, :transport, "local")

    call_args =
      args
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> "#{k}=#{encode_lit(v)}" end)
      |> Enum.join(", ")

    output_bindings =
      Keyword.get(opts, :outputs, [{"id", "#{result_var}.id"}, {"title", "#{result_var}.title"}])
      |> Enum.map(fn {name, expr} -> "      #{name} = #{expr}" end)
      |> Enum.join("\n")

    """
    {{#endpoint "#{endpoint}"}}
      transport = "#{transport}"
    {{/endpoint}}

    {{#vars}}
      #{result_var} : object?
    {{/vars}}

    {{#step "#{step_title}"}}
      {{assign #{result_var} = call("#{endpoint}", "#{tool}", #{call_args})}}
    {{/step}}

    {{#outputs}}
    #{output_bindings}
    {{/outputs}}
    """
  end

  defp encode_lit(v) when is_binary(v) do
    escaped =
      v
      |> String.replace("\\", "\\\\")
      |> String.replace("\"", "\\\"")

    "\"#{escaped}\""
  end

  defp encode_lit(v) when is_integer(v) or is_float(v), do: to_string(v)
  defp encode_lit(true), do: "true"
  defp encode_lit(false), do: "false"
  defp encode_lit(v), do: encode_lit(inspect(v))
end
