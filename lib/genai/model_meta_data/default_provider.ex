defmodule GenAI.ModelMetadata.DefaultProvider do
  # <REMOVED UUID HERE> get :: auto-generated pointer for public function get
  def get(scope, model, options \\ nil)

  def get(scope, model, _) do
    {:ok,
     %GenAI.Model{
       provider: scope,
       model: model,
       details: %GenAI.ModelDetails{}
     }}
  end
end
