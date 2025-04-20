defmodule GenAI.Session.State.Directive do
  @moduledoc """
  Directive that is applied to build effective state.
  """
  @vsn 1.0
  
  defstruct [
    stub: nil,
    vsn: @vsn
  ]
end