defmodule GenAI.Tool.Result do
  @moduledoc "Normalized outcome of a tool execution."

  @enforce_keys [:call_id, :name, :status]
  defstruct call_id: nil,
            name: nil,
            source: nil,
            status: nil,
            content: nil,
            error: nil,
            duration: 0,
            metadata: %{}

  @type t :: %__MODULE__{
          call_id: String.t() | nil,
          name: String.t(),
          source: String.t() | nil,
          status: :ok | :error,
          content: term(),
          error: term(),
          duration: non_neg_integer(),
          metadata: map()
        }

  @doc "Converts a result to the existing provider-neutral tool response message."
  @spec to_message(t()) :: GenAI.Message.ToolResponse.t()
  def to_message(%__MODULE__{} = result) do
    response =
      case result.status do
        :ok -> result.content
        :error -> %{error: inspect(result.error)}
      end

    GenAI.Message.ToolResponse.new(
      tool_name: result.name,
      tool_call_id: result.call_id,
      tool_response: response
    )
  end
end
