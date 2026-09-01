defmodule GenAI.Tool.Source do
  @moduledoc """
  Dependency-neutral contract for a source of callable tools.

  A source may be an MCP client, an in-process harness, a database facade, or
  any other adapter. `genai_core` deliberately does not know how the source is
  transported or authenticated.
  """

  @type source :: term()
  @type context :: term()
  @type options :: keyword()
  @type tool_descriptor :: GenAI.Tool.t() | map() | keyword()

  @callback list_tools(source(), context(), options()) ::
              {:ok, [tool_descriptor()]} | {:error, term()}

  @callback call_tool(source(), String.t(), map(), context(), options()) ::
              {:ok, term()} | {:error, term()}
end
