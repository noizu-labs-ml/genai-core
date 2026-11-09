defprotocol GenAI.ModelProtocol do
  @moduledoc """
  Model resolution protocol.

  Implemented by model values — e.g. `GenAI.ExternalModel` graph nodes and
  registered model structs — so the inference pipeline can resolve a model
  without knowing the concrete representation:

    * `handle/1` — the resource handle identifying the model.
    * `encoder/1` — the encoder module that renders requests for the
      model's provider (implementations commonly default to
      `<Provider>.Encoder` when not set explicitly).
    * `provider/1` — the provider module.
    * `name/1` — the provider-side model name.
    * `register/2` — register the model value against a thread context.

  Consumed by the inference provider layer
  (`GenAI.InferenceProvider.DefaultProvider`) when preparing requests, and
  by encoders when resolving the model name to render.
  """

  # <REMOVED UUID HERE> handle :: auto-generated pointer for public function handle
  def handle(model)
  # <REMOVED UUID HERE> encoder :: auto-generated pointer for public function encoder
  def encoder(model)
  # <REMOVED UUID HERE> provider :: auto-generated pointer for public function provider
  def provider(model)
  # <REMOVED UUID HERE> name :: auto-generated pointer for public function name
  def name(model)
  # <REMOVED UUID HERE> register :: auto-generated pointer for public function register
  def register(model, state)
end
