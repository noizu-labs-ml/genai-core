defmodule GenAI.Pipeline.Frame do
  @moduledoc "A branch-local extraction value bound to a thread revision."
  @enforce_keys [:kind, :value, :revision]
  defstruct [:kind, :value, :revision, :source, metadata: %{}]

  @type t :: %__MODULE__{
          kind: :payload | :criteria | :result,
          value: term(),
          revision: binary(),
          source: term(),
          metadata: map()
        }
end
