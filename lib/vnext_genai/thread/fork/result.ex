defmodule GenAI.Thread.Fork.Outcome do
  @moduledoc "One leaf outcome. Paths are ordered branch IDs from root to leaf."
  defstruct [:id, :value, :reason, path: [], status: :ok]
end

defmodule GenAI.Thread.Fork.Result do
  @moduledoc "Ordered path-keyed results; values retain each leaf API's exact result type."
  defstruct [:operation, outcomes: []]

  def fetch(%__MODULE__{outcomes: outcomes}, path) do
    case Enum.find(outcomes, &(&1.path == path)) do
      %{status: :ok, value: value} -> {:ok, value}
      %{reason: reason} -> {:error, reason}
      nil -> {:error, :unknown_branch_path}
    end
  end
end

defmodule GenAI.Thread.Fork.Error do
  @moduledoc "Partial failure retaining every branch's updated state and outcome."
  defstruct [:operation, :fork, :result]
end

defimpl Inspect, for: GenAI.Thread.Fork.Result do
  def inspect(value, _opts),
    do: "#GenAI.Thread.Fork.Result<#{value.operation}, #{length(value.outcomes)} outcomes>"
end

defimpl Inspect, for: GenAI.Thread.Fork.Error do
  def inspect(value, _opts), do: "#GenAI.Thread.Fork.Error<#{value.operation}>"
end
