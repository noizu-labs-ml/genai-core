defmodule VNextGenAI.Graph.Link do
  @vsn 1.0
  @moduledoc """
  Represent a link between two nodes in a graph.
  """

  alias VNextGenAI.Graph.NodeProtocol
  alias VNextGenAI.Records, as: R
  alias VNextGenAI.Types, as: T

  require VNextGenAI.Records.Link
  require VNextGenAI.Types.Graph

  @type t :: %__MODULE__{
          # Identifier
          id: G.graph_id(),
          handle: T.handle(),

          # Name / Description
          name: T.name(),
          description: T.description(),

          # Link Details
          type: T.Graph.link_type(),
          label: T.Graph.link_label(),
          # @todo specifier like count, trait, direction, etc. o(5)-->1 etc. for uml.

          # Link Endpoints
          source: R.Link.connector(),
          target: R.Link.connector(),

          # Meta
          meta: nil,
          vsn: float()
        }

  defstruct [
    # Identifier
    id: nil,
    handle: nil,

    # Name / Description
    name: nil,
    description: nil,

    # Link Details
    type: nil,
    label: nil,

    # Link Endpoints
    source: nil,
    target: nil,

    # Meta
    meta: nil,
    vsn: @vsn
  ]

  @doc """
  Create a new link.

  # Examples

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      iex> node2_id = UUID.uuid5(:oid, "node-2")
      iex> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, name: "Hello")
      %VNextGenAI.Graph.Link{
        handle: nil,
        name: "Hello",
        description: nil,
        source: R.Link.connector(node: ^node1_id, socket: :default, external: false),
        target: R.Link.connector(node: ^node2_id, socket: :default, external: false),
        vsn: 1.0
      } = l

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      iex> node2_id = UUID.uuid5(:oid, "node-2")
      iex> l = VNextGenAI.Graph.Link.new(R.Link.connector(node: node1_id, socket: :default, external: false), node2_id, handle: :andy)
      %VNextGenAI.Graph.Link{
        handle: :andy,
        source: R.Link.connector(node: ^node1_id, socket: :default, external: false),
        target: R.Link.connector(node: ^node2_id, socket: :default, external: false),
        vsn: 1.0
      } = l

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      iex> l = VNextGenAI.Graph.Link.new(R.Link.connector(node: node1_id, socket: :default, external: false), nil, description: "A Node")
      %VNextGenAI.Graph.Link{
        description: "A Node",
        source: R.Link.connector(node: ^node1_id, socket: :default, external: false),
        target: R.Link.connector(node: nil, socket: :default, external: true),
        vsn: 1.0
      } = l

    # from node struct (requires protocol impl)
  """
  @spec new(term, term, term) :: __MODULE__.t()
  def new(source, target, options \\ nil)

  def new(source, target, options) do
    id = options[:id] || UUID.uuid4()
    source = to_connector(source)
    target = to_connector(target)
    type = if Keyword.has_key?(options || [], :type), do: options[:type], else: :link

    %VNextGenAI.Graph.Link{
      id: id,
      handle: options[:handle],
      name: options[:name],
      description: options[:description],
      type: type,
      label: options[:label],
      source: source,
      target: target,
      vsn: @vsn
    }
  end

  # =============================================================================
  # Link Protocol
  # =============================================================================

  # -------------------------
  # id/1
  # -------------------------

  @doc """
  Obtain the id of a graph link.

  # Examples

  ## when set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, handle: :foo, name: "A", description: "B")
      ...> VNextGenAI.Graph.Link.id(l)
      {:ok, l.id}

  ## when not set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, handle: :foo, name: "A", description: "B") |> put_in([Access.key(:id)], nil)
      ...> VNextGenAI.Graph.Link.id(l)
      {:error, {:id, :is_nil}}

  """
  @spec id(graph_link :: T.Graph.graph_link()) :: T.result(T.Graph.graph_link_id(), T.details())
  def id(graph_link)
  def id(%__MODULE__{id: nil}), do: {:error, {:id, :is_nil}}
  def id(%__MODULE__{id: id}), do: {:ok, id}

  # -------------------------
  # handle/1
  # -------------------------

  @doc """
  Obtain the handle of a graph link.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, handle: :foo)
      ...> VNextGenAI.Graph.Link.handle(l)
      {:ok, :foo}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.handle(l)
      {:error, {:handle, :is_nil}}

  """
  @spec handle(graph_link :: T.Graph.graph_link()) :: T.result(T.handle(), T.details())
  def handle(graph_link)
  def handle(%__MODULE__{handle: nil}), do: {:error, {:handle, :is_nil}}
  def handle(%__MODULE__{handle: handle}), do: {:ok, handle}

  # -------------------------
  # handle/2
  # -------------------------

  @doc """
  Obtain the handle of a graph link, or return a default value if the handle is nil.

  # Examples

  ## When Set

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, handle: :foo)
      ...> VNextGenAI.Graph.Link.handle(l, :default)
      {:ok, :foo}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.handle(l, :default)
      {:ok, :default}

  """
  @spec handle(graph_link :: T.Graph.graph_link(), default :: T.handle()) ::
          T.result(T.handle(), T.details())
  def handle(graph_link, default)
  def handle(%__MODULE__{handle: nil}, default), do: {:ok, default}
  def handle(%__MODULE__{handle: handle}, _), do: {:ok, handle}

  # -------------------------
  # name/1
  # -------------------------

  @doc """
  Obtain the name of a graph link.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, name: "A")
      ...> VNextGenAI.Graph.Link.name(l)
      {:ok, "A"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.name(l)
      {:error, {:name, :is_nil}}

  """
  @spec name(graph_link :: T.Graph.graph_link()) :: T.result(T.name(), T.details())
  def name(graph_link)
  def name(%__MODULE__{name: nil}), do: {:error, {:name, :is_nil}}
  def name(%__MODULE__{name: name}), do: {:ok, name}

  # -------------------------
  # name/2
  # -------------------------

  @doc """
  Obtain the name of a graph link, or return a default value if the name is nil.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, name: "A")
      ...> VNextGenAI.Graph.Link.name(l, "default")
      {:ok, "A"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.name(l, "default")
      {:ok, "default"}

  """
  @spec name(graph_link :: T.Graph.graph_link(), default :: T.name()) ::
          T.result(T.name(), T.details())
  def name(graph_link, default)
  def name(%__MODULE__{name: nil}, default), do: {:ok, default}
  def name(%__MODULE__{name: name}, _), do: {:ok, name}

  # -------------------------
  # description/1
  # -------------------------

  @doc """
  Obtain the description of a graph link.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, description: "B")
      ...> VNextGenAI.Graph.Link.description(l)
      {:ok, "B"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.description(l)
      {:error, {:description, :is_nil}}

  """
  @spec description(graph_link :: T.Graph.graph_link()) :: T.result(T.description(), T.details())
  def description(graph_link)
  def description(%__MODULE__{description: nil}), do: {:error, {:description, :is_nil}}
  def description(%__MODULE__{description: description}), do: {:ok, description}

  # -------------------------
  # description/2
  # -------------------------

  @doc """
  Obtain the description of a graph link, or return a default value if the description is nil.

  # Examples

  ## When Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, description: "B")
      ...> VNextGenAI.Graph.Link.description(l, "default")
      {:ok, "B"}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.description(l, "default")
      {:ok, "default"}

  """
  @spec description(graph_link :: T.Graph.graph_link(), default :: T.description()) ::
          T.result(T.description(), T.details())
  def description(graph_link, default)
  def description(%__MODULE__{description: nil}, default), do: {:ok, default}
  def description(%__MODULE__{description: description}, _), do: {:ok, description}

  # -------------------------
  # type/1
  # -------------------------
  @doc """
  Obtain the type of a graph link.

  ## Examples

  ### When Set
        iex> node1_id = UUID.uuid5(:oid, "node-1")
        ...> node2_id = UUID.uuid5(:oid, "node-2")
        ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, type: :link_type)
        ...> VNextGenAI.Graph.Link.type(l)
        {:ok, :link_type}

  ### When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, type: nil)
      ...> VNextGenAI.Graph.Link.type(l)
      {:error, {:type, :is_nil}}

  """
  @spec type(__MODULE__.t()) :: T.result(T.Graph.link_type(), T.details())
  def type(graph_link)
  def type(%__MODULE__{type: nil}), do: {:error, {:type, :is_nil}}
  def type(%__MODULE__{type: type}), do: {:ok, type}

  # -------------------------
  # type/2
  # -------------------------
  @doc """
  Obtain the type of a graph link, or return a default value if the type is nil.

  ## Examples

  ### When Set
        iex> node1_id = UUID.uuid5(:oid, "node-1")
        ...> node2_id = UUID.uuid5(:oid, "node-2")
        ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, type: :link_type)
        ...> VNextGenAI.Graph.Link.type(l, :default)
        {:ok, :link_type}

  ### When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, type: nil)
      ...> VNextGenAI.Graph.Link.type(l, :default)
      {:ok, :default}
  """
  @spec type(__MODULE__.t(), default :: any) :: T.result(T.Graph.link_type(), T.details())
  def type(graph_link, default)
  def type(%__MODULE__{type: nil}, default), do: {:ok, default}
  def type(%__MODULE__{type: type}, _), do: {:ok, type}

  # -------------------------
  # label/1
  # -------------------------
  @doc """
  Obtain the label of a graph link.

  ## Examples

  ### When Set
        iex> node1_id = UUID.uuid5(:oid, "node-1")
        ...> node2_id = UUID.uuid5(:oid, "node-2")
        ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, label: :some_label)
        ...> VNextGenAI.Graph.Link.label(l)
        {:ok, :some_label}

  ### When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.label(l)
      {:error, {:label, :is_nil}}

  """
  @spec label(__MODULE__.t()) :: T.result(T.Graph.link_label(), T.details())
  def label(graph_link)
  def label(%__MODULE__{label: nil}), do: {:error, {:label, :is_nil}}
  def label(%__MODULE__{label: label}), do: {:ok, label}

  # -------------------------
  # label/2
  # -------------------------
  @doc """
  Obtain the label of a graph link, or return a default value if the label is nil.

  ## Examples

  ### When Set
        iex> node1_id = UUID.uuid5(:oid, "node-1")
        ...> node2_id = UUID.uuid5(:oid, "node-2")
        ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id, label: :my_label)
        ...> VNextGenAI.Graph.Link.label(l, :default)
        {:ok, :my_label}

  ### When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> VNextGenAI.Graph.Link.label(l, :default)
      {:ok, :default}
  """
  @spec label(__MODULE__.t(), default :: any) :: T.result(T.Graph.link_label(), T.details())
  def label(graph_link, default)
  def label(%__MODULE__{label: nil}, default), do: {:ok, default}
  def label(%__MODULE__{label: label}, _), do: {:ok, label}

  # -------------------------
  # with_id/1
  # -------------------------

  @doc """
  Ensure the graph link has an id, generating one if necessary.

  # Examples
  ## When Already Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> {:ok, l2} = VNextGenAI.Graph.Link.with_id(l)
      ...> %{was_nil: is_nil(l.id), is_nil: is_nil(l2.id), id_change: l.id != l2.id}
      %{was_nil: false, is_nil: false, id_change: false}

  ## When Not Set
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id) |> put_in([Access.key(:id)], nil)
      ...> {:ok, l2} = VNextGenAI.Graph.Link.with_id(l)
      ...> %{was_nil: is_nil(l.id), is_nil: is_nil(l2.id), id_change: l.id != l2.id}
      %{was_nil: true, is_nil: false, id_change: true}

  """
  @spec with_id(graph_link :: T.Graph.graph_link()) :: T.result(T.Graph.graph_link(), T.details())
  def with_id(graph_link) do
    graph_link
    |> with_id!()
    |> then(&{:ok, &1})
  end

  @spec with_id!(__MODULE__.t()) :: __MODULE__.t()
  def with_id!(graph_link) do
    cond do
      graph_link.id == nil ->
        put_in(graph_link, [Access.key(:id)], UUID.uuid4())

      graph_link.id == :auto ->
        put_in(graph_link, [Access.key(:id)], UUID.uuid4())

      :else ->
        graph_link
    end
  end

  # -------------------------
  # source_connector/1
  # -------------------------

  @doc """
  Obtain the source connector of a graph link.

  # Examples

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> {:ok, sut} = VNextGenAI.Graph.Link.source_connector(l)
      ...> sut
      R.Link.connector(external: false) = sut

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> l = VNextGenAI.Graph.Link.new(nil, node1_id)
      ...> {:ok, sut} = VNextGenAI.Graph.Link.source_connector(l)
      ...> sut
      R.Link.connector(external: true) = sut

  """
  @spec source_connector(graph_link :: T.Graph.graph_link()) ::
          T.result(R.Link.connector(), T.details())
  def source_connector(%__MODULE__{source: nil}), do: {:error, {:source, :is_nil}}
  def source_connector(%__MODULE__{source: connector}), do: {:ok, connector}

  # -------------------------
  # target_connector/1
  # -------------------------

  @doc """
  Obtain the target connector of a graph link.

  # Examples

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> {:ok, sut} = VNextGenAI.Graph.Link.target_connector(l)
      ...> sut
      R.Link.connector(node: ^node2_id) = sut

      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, nil)
      ...> {:ok, sut} = VNextGenAI.Graph.Link.target_connector(l)
      ...> sut
      R.Link.connector(external: true) = sut
  """
  @spec target_connector(graph_link :: T.Graph.graph_link()) ::
          T.result(R.Link.connector(), T.details())
  def target_connector(%__MODULE__{target: nil}), do: {:error, {:target, :is_nil}}
  def target_connector(%__MODULE__{target: connector}), do: {:ok, connector}

  # -------------------------
  # putnew_target/2
  # -------------------------

  @doc """
  Set the target connector of a graph link, if it is not already set.

  # Examples

  ## When Not Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, nil)
      ...> |> VNextGenAI.Graph.Link.putnew_target(node2_id)
      %VNextGenAI.Graph.Link{target: R.Link.connector(node: ^node2_id, external: false)} = l

  ## When Not Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, nil)
      ...> |> VNextGenAI.Graph.Link.putnew_target(R.Link.connector(node: node2_id, socket: :foo, external: false))
      %VNextGenAI.Graph.Link{target: R.Link.connector(node: ^node2_id, external: false)} = l

  ## When Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> VNextGenAI.Graph.Link.putnew_target(node3_id)
      %VNextGenAI.Graph.Link{target: R.Link.connector(node: ^node2_id, external: false)} = l

  ## When Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> VNextGenAI.Graph.Link.putnew_target(R.Link.connector(node: node3_id, socket: :foo, external: false))
      %VNextGenAI.Graph.Link{target: R.Link.connector(node: ^node2_id, external: false)} = l

  """
  @spec putnew_target(graph_link :: T.Graph.graph_link(), target :: term) :: T.Graph.graph_link()
  def putnew_target(
        graph_link,
        R.Link.connector(
          node: connector_node,
          socket: connector_socket,
          external: connector_external
        )
      ) do
    x = graph_link.target || R.Link.connector(node: nil, socket: nil, external: false)

    if is_nil(R.Link.connector(x, :node)) do
      %__MODULE__{
        graph_link
        | target:
            R.Link.connector(
              x,
              node: connector_node,
              socket: connector_socket,
              external: connector_external
            )
      }
    else
      graph_link
    end
  end

  def putnew_target(graph_link, target) when T.Graph.is_node_id(target) do
    x = graph_link.target || R.Link.connector(node: nil, socket: nil, external: nil)

    if is_nil(R.Link.connector(x, :node)) do
      %__MODULE__{
        graph_link
        | target:
            R.Link.connector(
              x,
              node: R.Link.connector(x, :node) || target,
              socket: R.Link.connector(x, :socket) || :default,
              # wip
              external: false
            )
      }
    else
      graph_link
    end
  end

  def putnew_target(graph_link, target) when is_struct(target) do
    {:ok, connector_id} = NodeProtocol.id(target)
    x = graph_link.target || R.Link.connector(node: nil, socket: nil, external: false)

    if is_nil(R.Link.connector(x, :node)) do
      %__MODULE__{
        graph_link
        | target:
            R.Link.connector(
              x,
              node: R.Link.connector(x, :node) || connector_id,
              socket: R.Link.connector(x, :socket) || :default,
              # wip
              external: false
            )
      }
    else
      graph_link
    end
  end

  # -------------------------
  # putnew_source/2
  # -------------------------

  @doc """
  Set the source connector of a graph link, if it is not already set.

  # Examples

  ## When Not Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(nil, node2_id)
      ...> |> VNextGenAI.Graph.Link.putnew_source(node1_id)
      %VNextGenAI.Graph.Link{source: R.Link.connector(node: ^node1_id, external: false)} = l

  ## When Not Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> l = VNextGenAI.Graph.Link.new(nil, node2_id)
      ...> |> VNextGenAI.Graph.Link.putnew_source(R.Link.connector(node: node1_id, socket: :foo, external: false))
      %VNextGenAI.Graph.Link{source: R.Link.connector(node: ^node1_id, socket: :foo, external: false)} = l

  ## When Set. By ID
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> VNextGenAI.Graph.Link.putnew_source(node3_id)
      %VNextGenAI.Graph.Link{source: R.Link.connector(node: ^node1_id, external: false)} = l

  ## When Set. By Connector
      iex> node1_id = UUID.uuid5(:oid, "node-1")
      ...> node2_id = UUID.uuid5(:oid, "node-2")
      ...> node3_id = UUID.uuid5(:oid, "node-3")
      ...> l = VNextGenAI.Graph.Link.new(node1_id, node2_id)
      ...> |> VNextGenAI.Graph.Link.putnew_source(R.Link.connector(node: node3_id, socket: :foo, external: false))
      %VNextGenAI.Graph.Link{source: R.Link.connector(node: ^node1_id, external: false)} = l

  """
  @spec putnew_source(graph_link :: T.Graph.graph_link(), source :: term) :: T.Graph.graph_link()
  def putnew_source(
        graph_link,
        R.Link.connector(
          node: connector_node,
          socket: connector_socket,
          external: connector_external
        )
      ) do
    x = graph_link.source || R.Link.connector(node: nil, socket: nil, external: false)

    if is_nil(R.Link.connector(x, :node)) do
      %__MODULE__{
        graph_link
        | source:
            R.Link.connector(
              x,
              node: connector_node,
              socket: connector_socket,
              external: connector_external
            )
      }
    else
      graph_link
    end
  end

  def putnew_source(graph_link, source) when T.Graph.is_node_id(source) do
    x = graph_link.source || R.Link.connector(node: nil, socket: nil, external: false)

    if is_nil(R.Link.connector(x, :node)) do
      %__MODULE__{
        graph_link
        | source:
            R.Link.connector(
              x,
              node: R.Link.connector(x, :node) || source,
              socket: R.Link.connector(x, :socket) || :default,
              # wip
              external: false
            )
      }
    else
      graph_link
    end
  end

  def putnew_source(graph_link, source) when is_struct(source) do
    {:ok, connector_id} = NodeProtocol.id(source)
    x = graph_link.source || R.Link.connector(node: nil, socket: nil, external: false)

    if is_nil(R.Link.connector(x, :node)) do
      %__MODULE__{
        graph_link
        | source:
            R.Link.connector(
              x,
              node: R.Link.connector(x, :node) || connector_id,
              socket: R.Link.connector(x, :socket) || :default,
              # wip
              external: false
            )
      }
    else
      graph_link
    end
  end

  # =============================================================================
  # Internal
  # =============================================================================

  defp to_connector(value = R.Link.connector()), do: value
  defp to_connector(nil), do: R.Link.connector(node: nil, socket: :default, external: true)

  defp to_connector(value) when T.Graph.is_node_id(value),
    do: R.Link.connector(node: value, socket: :default, external: false)

  defp to_connector(value) do
    {:ok, x} = NodeProtocol.id(value)
    R.Link.connector(node: x, socket: :default, external: false)
  end
end
