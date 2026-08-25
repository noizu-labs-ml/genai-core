defmodule GenAI.Tool.Call do
  @moduledoc "Normalized tool call used by registries and chain runners."

  @enforce_keys [:name]
  defstruct id: nil, name: nil, arguments: %{}, metadata: %{}

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t(),
          arguments: map(),
          metadata: map()
        }

  @doc "Normalizes GenAI and common provider tool-call shapes."
  @spec normalize(term()) :: {:ok, t()} | {:error, term()}
  def normalize(%__MODULE__{} = call),
    do: normalize_fields(call.id, call.name, call.arguments, call.metadata)

  def normalize(%GenAI.Message.ToolCall{} = call),
    do: normalize_fields(call.id, call.tool_name, call.arguments, %{})

  def normalize(%{function: function} = call) when is_map(function) do
    normalize_fields(value(call, :id), value(function, :name), value(function, :arguments), %{})
  end

  def normalize(%{"function" => function} = call) when is_map(function) do
    normalize_fields(value(call, :id), value(function, :name), value(function, :arguments), %{})
  end

  def normalize(call) when is_map(call) do
    normalize_fields(
      value(call, :id),
      value(call, :name) || value(call, :tool_name),
      value(call, :arguments),
      value(call, :metadata) || %{}
    )
  end

  def normalize(_), do: {:error, :invalid_tool_call}

  defp normalize_fields(id, name, arguments, metadata) when is_binary(name) and name != "" do
    with {:ok, arguments} <- normalize_arguments(arguments) do
      {:ok,
       %__MODULE__{
         id: normalize_id(id),
         name: name,
         arguments: arguments,
         metadata: if(is_map(metadata), do: metadata, else: %{})
       }}
    end
  end

  defp normalize_fields(_, _, _, _), do: {:error, :invalid_tool_name}

  defp normalize_arguments(nil), do: {:ok, %{}}
  defp normalize_arguments(arguments) when is_map(arguments), do: {:ok, arguments}

  defp normalize_arguments(arguments) when is_list(arguments) do
    if Keyword.keyword?(arguments),
      do: {:ok, Map.new(arguments)},
      else: {:error, :invalid_arguments}
  end

  defp normalize_arguments(arguments) when is_binary(arguments) do
    case Jason.decode(arguments) do
      {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
      {:ok, _} -> {:error, :arguments_must_be_an_object}
      {:error, _} -> {:error, :invalid_json_arguments}
    end
  end

  defp normalize_arguments(_), do: {:error, :invalid_arguments}

  defp normalize_id(nil), do: nil
  defp normalize_id(id) when is_binary(id), do: id
  defp normalize_id(id), do: to_string(id)

  defp value(map, key), do: Map.get(map, key) || Map.get(map, Atom.to_string(key))
end
