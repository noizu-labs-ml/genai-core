defmodule VNextGenAI.Records.Link do
  @moduledoc """
  Records related to graph links.
  """

  alias VNextGenAI.Graph.Types, as: G

  require Record
  Record.defrecord(:connector, node: nil, socket: nil, external: false)

  @typedoc """
  Record representing a link connector (target, and socket).

  ## Note
  Socket is used for elements with special input output links like grid search to indicate appropriate link to use per state.
  """
  @type connector :: record(:connector, node: G.graph_node_id(), socket: term, external: atom)
end
