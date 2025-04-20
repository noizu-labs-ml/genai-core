defmodule GenAI.Session.State.SettingEntry do
  @moduledoc """
  A entry (built by directives) in a session state struct.
  """
  @vsn 1.0
  
  defstruct [
    name: nil,
    effective: nil,
    selectors: [],
    constraints: [],
    references: [],
    impacts: [],
    updated_on: nil,
    vsn: @vsn
  ]
end