# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Records.Node do
  @moduledoc """
  Records used by for preparing/processing nodes.
  """

  require Record

  @typedoc """
  Indicate node to process next.
  """
  @type process_next :: record(:process_next, session: any)
  Record.defrecord(:process_next, session: nil)

  @typedoc """
  Indicate no further nodes to process.
  """
  @type process_end :: record(:process_end, session: any)
  Record.defrecord(:process_end, session: nil)

  @typedoc """
  Yield processing for.
  """
  @type process_yield :: record(:process_yield, session: any)
  Record.defrecord(:process_yield, session: nil)

  @typedoc """
  Processing error
  """
  @type process_error :: record(:process_error, session: any)
  Record.defrecord(:process_error, session: nil)

end