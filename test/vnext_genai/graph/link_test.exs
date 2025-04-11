defmodule VNextGenAI.Graph.LinkTest do
  # import VNextGenAI.Test.Support.Common
  use ExUnit.Case,
    async: true

  alias VNextGenAI.Records, as: R

  require Logger
  require VNextGenAI.Records.Link

  doctest VNextGenAI.Graph.Link
end
