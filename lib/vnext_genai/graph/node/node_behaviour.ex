# ===============================================================================
# Copyright (c) 2024, Noizu Labs, Inc.
# ===============================================================================
defmodule VNextGenAI.Graph.NodeBehaviour do
  @moduledoc """
  Behaviour Graph Node Elements must adhere to.
  """
  alias VNextGenAI.Graph.Types, as: G
  alias VNextGenAI.Types, as: T

  # ==================================
  # Behaviour
  # ==================================
  @callback id(graph_node :: term) :: {:ok, G.node_id()} | {:error, any}
  @callback handle(graph_node :: term) :: {:ok, G.node_handle()} | {:error, any}
  @callback handle(graph_node :: term, default :: any) :: {:ok, G.node_handle()} | {:error, any}
  @callback name(graph_node :: term) :: {:ok, String.t()} | {:error, any}
  @callback name(graph_node :: term, default :: any) :: {:ok, String.t()} | {:error, any}
  @callback description(graph_node :: term) :: {:ok, String.t()} | {:error, any}
  @callback description(graph_node :: term, default :: any) :: {:ok, String.t()} | {:error, any}

  # ==================================
  # Support Macros
  # ==================================
  @doc """
  Define the type of a node with default fields included.

  ## Example

  ```elixir
  defnodetype [
     internal: boolean,
  ]
  ```

  """
  defmacro defnodetype(types) do
    types = Macro.expand_once(types, __CALLER__)

    members =
      quote do
        [
          {:id, T.node_id()},
          {:handle, T.node_handle()},
          {:name, T.name()},
          {:description, T.description()},
          unquote_splicing(types),
          {:inbound_links, T.link_map()},
          {:outbound_links, T.link_map()},
          {:finger_print, T.finger_print()},
          {:meta, nil | map() | keyword()},
          {:vsn, float}
        ]
      end

    quote do
      @type t :: %__MODULE__{
              unquote_splicing(members)
            }
    end
  end

  @doc """
  Define the struct of a node with default fields included.

  ## Example
  ```elixir
    defnodestruct [
        value: nil,
    ]
  ```
  """
  defmacro defnodestruct(values) do
    quote do
      @vsn Module.get_attribute(__MODULE__, :vsn, 1.0)
      Kernel.defstruct(
        [
          id: nil,
          handle: nil,
          name: nil,
          description: nil
        ] ++
          (unquote(values) || []) ++
          [
            # edge ids grouped by outlet
            outbound_links: %{},
            # edge ids grouped by outlet
            inbound_links: %{},
            finger_print: nil,
            meta: nil,
            vsn: @vsn
          ]
      )
    end

    # end of quote
  end

  # ==================================
  # Using Macro
  # ==================================
  defmacro __using__(opts \\ nil) do
    quote do
      @provider unquote(opts[:provider]) || VNextGenAI.Graph.NodeProtocol.DefaultProvider
      require VNextGenAI.Graph.NodeBehaviour
      import VNextGenAI.Graph.NodeBehaviour, only: [defnodestruct: 1, defnodetype: 1]
      import VNextGenAI.Graph.NodeProtocol.DefaultProvider
      @behaviour VNextGenAI.Graph.NodeBehaviour

      @defimpl VNextGenAI.Graph.NodeBehaviour
      defdelegate id(graph), to: @provider, as: :do_id
      @defimpl VNextGenAI.Graph.NodeBehaviour
      defdelegate handle(graph), to: @provider, as: :do_handle
      @defimpl VNextGenAI.Graph.NodeBehaviour
      defdelegate handle(graph, default), to: @provider, as: :do_handle
      @defimpl VNextGenAI.Graph.NodeBehaviour
      defdelegate name(graph), to: @provider, as: :do_name
      @defimpl VNextGenAI.Graph.NodeBehaviour
      defdelegate name(graph, default), to: @provider, as: :do_name
      @defimpl VNextGenAI.Graph.NodeBehaviour
      defdelegate description(graph), to: @provider, as: :do_description
      @defimpl VNextGenAI.Graph.NodeBehaviour
      defdelegate description(graph, default), to: @provider, as: :do_description
    end
  end
end
