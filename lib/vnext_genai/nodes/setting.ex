defmodule GenAI.Setting do
  @moduledoc """
  A module representing a setting node in a graph structure.
  This module defines the structure and behavior of a setting node,
  including its identifier, setting, and value.
  """
  @vsn 1.0
  
  #import GenAI.Records.Session, only: [scope: 1, scope: 2]
  #require GenAI.Records.Session
  
  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  #@derive GenAI.Thread.SessionProtocol
  defnodestruct(setting: nil, value: nil)
  defnodetype(setting: term, value: term)
  
#  def process_node_directives(graph_node, scope = scope(session_state: state), context, options) do
#    directive = %GenAI.Session.State.Directive{stub: :setting}
#    with {:ok, state} <- GenAI.Session.State.add_directive(state, directive, context, options) do
#      {:ok, scope(scope, session_state: state)}
#    end
#  end

end