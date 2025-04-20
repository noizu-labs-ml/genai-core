defmodule GenAI.Session.State.Entry do
  @moduledoc """
  State Entry
  """
  @vsn 1.0
  
  defstruct [
    value: nil,
    vsn: @vsn
  ]
end