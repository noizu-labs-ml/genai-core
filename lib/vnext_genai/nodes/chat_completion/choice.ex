defmodule GenAI.ChatCompletion.Choice do
  defstruct index: nil,
            message: nil,
            logprobs: nil,
            finish_reason: nil

  defp finish_reason(json)
  defp finish_reason(nil), do: nil
  defp finish_reason(json), do: String.to_atom(json)

  def new(options) do
    keys =
      __MODULE__.__info__(:struct)
      |> Enum.map(& &1.field)
      |> MapSet.new()

    options
    |> Enum.to_list()
    |> Keyword.merge(finish_reason: finish_reason(options[:finish_reason]))
    |> Enum.filter(&MapSet.member?(keys, elem(&1, 0)))
    |> __struct__()
  end
end
