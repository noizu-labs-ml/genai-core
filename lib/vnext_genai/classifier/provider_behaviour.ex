defmodule GenAI.Classifier.ProviderBehaviour do
  @moduledoc """
  Additive classifier adapter contract. Existing chat providers need no changes.
  Capabilities declare supported `types` and `modalities`; optional `max_choices`
  and `max_questions` restrict request size. This contract has no chat fallback.
  """
  @callback classify(GenAI.Classifier.Request.t(), keyword()) ::
              {:ok, GenAI.Classifier.Result.t() | map()} | {:error, term()}
  @callback classifier_capabilities() :: map()
  @optional_callbacks classifier_capabilities: 0
end
