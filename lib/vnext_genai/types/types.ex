defmodule VNextGenAI.Types do
  @moduledoc """
  VNextGenAI Types
  """

  @typedoc """
  Element Handle
  """
  @type handle :: term

  @typedoc """
  Element Name.
  """
  @type name :: term

  @typedoc """
  Element Description.
  """
  @type description :: term

  @typedoc """
  Element Finger Print.
  """
  @type finger_print :: term

  @typedoc """
  Error details
  """
  @type details :: tuple | atom | bitstring()

  @typedoc """
  Success Response
  """
  @type ok(r) :: {:ok, r}
  @typedoc """
  Error Response
  """
  @type error(e) :: {:error, e}

  @typedoc """
  Call outcome tuple.
  """
  @type result(r, e) :: ok(r) | error(e)
end
