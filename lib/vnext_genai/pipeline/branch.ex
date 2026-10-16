defmodule GenAI.Pipeline.Branch do
  @moduledoc "Stable branch identity, its common ancestor, isolated pipeline, and outcome."
  @enforce_keys [:id, :base, :pipeline]
  defstruct [:id, :base, :pipeline, error: nil, path: []]

  @type t :: %__MODULE__{
          id: term(),
          base: term(),
          pipeline: term(),
          error: term(),
          path: [term()]
        }
end
