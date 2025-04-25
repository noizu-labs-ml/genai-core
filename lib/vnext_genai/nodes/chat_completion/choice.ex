
defmodule GenAI.ChatCompletion.Choice do
  defstruct [
    index: nil,
    message: nil,
    finish_reason: nil,
  ]
  
  defp finish_reason(json)
  defp finish_reason(nil), do: nil
  defp finish_reason(json), do: String.to_atom(json)
  
  def new(options) do
    %__MODULE__{
      index: options[:index],
      message: options[:message],
      finish_reason: finish_reason(options[:finish_reason])
    }
  end

end
