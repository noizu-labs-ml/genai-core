defprotocol GenAI.ToolProtocol do
  @moduledoc """
  Tool naming protocol.

  `name/1` resolves the identifier a tool value is presented under — the
  model-facing name a provider sees in the tool schema and echoes back in
  tool-call responses. Implement it on custom tool values to control that
  name; tools surfaced through `GenAI.Tool.Registry` get deterministic,
  source-namespaced names (for example `project_mcp__search`) layered on
  top. Dispatched when threads bind tool values (e.g. legacy state
  handling) and implemented by the standard tool structs under
  `GenAI.Tool`.
  """

  # <REMOVED UUID HERE> name :: auto-generated pointer for public function name
  def name(model)
end
