defmodule GenAI.Session.State.Directive do
  @moduledoc """
  Directive that is applied to build effective state.
  """
  @vsn 1.0
  
  defstruct [
    source: nil,
    entries: [],
    fingerprint: nil,
    vsn: @vsn
  ]
  
  #----------------------
  # apply_directive
  #----------------------
  def apply_directive(directive, session, context, options)
  def apply_directive(directive, session, context, options) do
    updated_state = directive.entries
                    |> Enum.reduce(
                         session.state,
                         &apply_directive_entry(&1, &2, context, options)
                       )
    {:ok, %{session| state: updated_state}}
  end
  
  defp apply_directive_entry({entry, value}, state, context, options) do
    update_in(state, GenAI.Session.State.entry_path(entry), &GenAI.Session.StateEntry.update_entry(&1, value, context, options))
  end
  
  
  #----------------------
  # expired?/1
  #----------------------
  def expired?(directive)
  def expired?(_), do: false
  
  #----------------------
  # fingerprint/1
  #----------------------
  def fingerprint(directive)
  def fingerprint(directive),
      do: {:ok, directive.fingerprint}
  

      
      
      
end