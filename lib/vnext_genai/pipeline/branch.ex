defmodule GenAI.Pipeline.Branch do
  @moduledoc """
  Stable branch identity, common ancestor, isolated continuation, and failure.
  `pipeline` is a scalar Pipeline or a nested `GenAI.Thread.Fork`; `path` lists
  enclosing branch IDs from the root. Thread/model state never crosses leaves.
  """
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
