defmodule GenAI.Tool do
  @moduledoc """
  Represents a function that can be called by the model.
  """
  @vsn 1.0

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  #@derive GenAI.Thread.SessionProtocol
  defnodestruct(parameters: nil)
  defnodetype(parameters: term)

  @doc """
  Extract function from json.
  """
  def from_json(json_string) when is_bitstring(json_string) do
    with {:ok, json} <- Jason.decode(json_string) do
      do_from_json(json)
    end
  end

  @doc """
  Extract function from yaml.
  """
  def from_yaml(yaml_string) when is_bitstring(yaml_string) do
    with {:ok, json} <- YamlElixir.read_from_string(yaml_string) do
      do_from_json(json)
    end
  end

  defp do_from_json(%{"type" => "function", "function" => json}) do
    do_from_json(json)
  end
  defp do_from_json(%{"name" => _} = json) do
      # parameters is json a standard object json schema entry so use it to build a map of parameters one implemented.
      parameters = with {:ok, x} <- json["parameters"] && GenAI.Tool.Schema.Type.from_json(json["parameters"]) do
        x
      end
    {:ok,
      %GenAI.Tool{
        name: json["name"],
        description: json["description"],
        parameters: parameters
      }
    }
  end

  defimpl GenAI.ToolProtocol do
    def name(subject), do: {:ok, subject.name}
  end
end

