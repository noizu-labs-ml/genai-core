defmodule GenAI.Session.State.DirectiveBehaviour do
  @moduledoc false
  
  @callback apply_directive(directive :: any, thread :: any, context :: any, options :: any) :: {:ok, any} | {:error, any}
  
end