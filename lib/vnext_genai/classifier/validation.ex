defmodule GenAI.Classifier.Validation do
  @moduledoc false

  def get(map, key, default \\ nil),
    do: Map.get(map, key, Map.get(map, Atom.to_string(key), default))

  def fields(map, keys) do
    Map.new(keys, fn key -> {key, get(map, key)} end)
  end

  def string?(value), do: is_binary(value) and String.trim(value) != ""
  def number?(value), do: is_number(value) and value == value
  def probability?(value), do: number?(value) and value >= 0 and value <= 1
  def unique?(values), do: length(Enum.uniq(values)) == length(values)

  def collect(values, function) do
    Enum.reduce_while(values, {:ok, []}, fn value, {:ok, acc} ->
      case function.(value) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, reversed} -> {:ok, Enum.reverse(reversed)}
      error -> error
    end
  end
end
