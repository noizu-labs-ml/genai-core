defmodule GenAI.Graph.NodeProtocol.DefaultProvider do
  @moduledoc """
  Default provider for GenAI.Graph.NodeProtocol.
  Uses function_exported? to invoke the passed module's implementation if any for calls.
  """

  alias GenAI.Graph.Link
  alias GenAI.Types.Graph, as: G
  alias GenAI.Records, as: R
  alias GenAI.Types, as: T

  require GenAI.Records.Link


  # -------------------------
  # new/2
  # -------------------------
  @spec new(module, any) :: struct
  def new(module, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_new, 1) do
      module.do_new(options)
    else
      do_new(module, options)
    end
  end

  @spec do_new(module, any) :: any
  def do_new(module, nil) do
    options = [
      id: UUID.uuid4(),
      inbound_links: %{},
      outbound_links: %{}
    ]
    module.__struct__(options)
  end
  def do_new(module, options) do
    core = [
      id: options[:id] || UUID.uuid4(),
      inbound_links: options[:inbound_links] || %{},
      outbound_links: options[:outbound_links] || %{}
    ]
    options = Keyword.merge(Enum.to_list(options), core)
    module.__struct__(options)
  end


  # -------------------------
  # id/1
  # -------------------------
  @spec id(G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def id(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_id, 1) do
      module.do_id(graph_node)
    else
      do_id(graph_node)
    end
  end

  @spec do_id(G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def do_id(graph_node)
  def do_id(%{id: nil}), do: {:error, {:id, :is_nil}}
  def do_id(%{id: id}), do: {:ok, id}

  # -------------------------
  # handle/1
  # -------------------------
  @spec handle(G.graph_node()) :: T.result(T.handle(), T.details())
  def handle(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_handle, 1) do
      module.do_handle(graph_node)
    else
      do_handle(graph_node)
    end
  end

  @spec do_handle(G.graph_node()) :: T.result(T.handle(), T.details())
  def do_handle(graph_node)
  def do_handle(%{handle: nil}), do: {:error, {:handle, :is_nil}}
  def do_handle(%{handle: handle}), do: {:ok, handle}

  # -------------------------
  # handle/2
  # -------------------------
  @spec handle(G.graph_node(), T.handle()) :: T.result(T.handle(), T.details())
  def handle(graph_node = %{__struct__: module}, default) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_handle, 2) do
      module.do_handle(graph_node, default)
    else
      do_handle(graph_node, default)
    end
  end

  @spec do_handle(G.graph_node(), T.handle()) :: T.result(T.handle(), T.details())
  def do_handle(graph_node, default)
  def do_handle(%{handle: nil}, default), do: {:ok, default}
  def do_handle(%{handle: handle}, _), do: {:ok, handle}

  # -------------------------
  # name/1
  # -------------------------
  @spec name(G.graph_node()) :: T.result(T.name(), T.details())
  def name(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_name, 1) do
      module.do_name(graph_node)
    else
      do_name(graph_node)
    end
  end

  @spec do_name(G.graph_node()) :: T.result(T.name(), T.details())
  def do_name(graph_node)
  def do_name(%{name: nil}), do: {:error, {:name, :is_nil}}
  def do_name(%{name: name}), do: {:ok, name}

  # -------------------------
  # name/2
  # -------------------------
  @spec name(G.graph_node(), T.name()) :: T.result(T.name(), T.details())
  def name(graph_node = %{__struct__: module}, default) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_name, 2) do
      module.do_name(graph_node, default)
    else
      do_name(graph_node, default)
    end
  end

  @spec do_name(G.graph_node(), T.name()) :: T.result(T.name(), T.details())
  def do_name(graph_node, default)
  def do_name(%{name: nil}, default), do: {:ok, default}
  def do_name(%{name: name}, _), do: {:ok, name}

  # -------------------------
  # description/1
  # -------------------------
  @spec description(G.graph_node()) :: T.result(T.description(), T.details())
  def description(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_description, 1) do
      module.do_description(graph_node)
    else
      do_description(graph_node)
    end
  end

  @spec do_description(G.graph_node()) :: T.result(T.description(), T.details())
  def do_description(graph_node)
  def do_description(%{description: nil}), do: {:error, {:description, :is_nil}}
  def do_description(%{description: description}), do: {:ok, description}

  # -------------------------
  # description/2
  # -------------------------
  @spec description(G.graph_node(), T.description()) :: T.result(T.description(), T.details())
  def description(graph_node = %{__struct__: module}, default) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_description, 2) do
      module.do_description(graph_node, default)
    else
      do_description(graph_node, default)
    end
  end

  @spec do_description(G.graph_node(), T.description()) :: T.result(T.description(), T.details())
  def do_description(graph_node, default)
  def do_description(%{description: nil}, default), do: {:ok, default}
  def do_description(%{description: description}, _), do: {:ok, description}

  # -------------------------
  # with_id/2
  # -------------------------
  @spec with_id(G.graph_node()) :: T.result(G.graph_node(), T.details())
  def with_id(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_with_id, 1) do
      module.do_with_id(graph_node)
    else
      do_with_id(graph_node)
    end
  end

  @spec do_with_id(G.graph_node()) :: T.result(G.graph_node(), T.details())
  def do_with_id(graph_node) do
    graph_node
    |> do_with_id!()
    |> then(&{:ok, &1})
  end

  @spec do_with_id!(G.graph_node()) :: G.graph_node()
  def do_with_id!(graph_node) do
    cond do
      graph_node.id == nil ->
        put_in(graph_node, [Access.key(:id)], UUID.uuid4())

      graph_node.id == :auto ->
        put_in(graph_node, [Access.key(:id)], UUID.uuid4())

      :else ->
        graph_node
    end
  end

  # -------------------------
  # register_link/5
  # -------------------------
  @spec register_link(G.graph_node(), G.graph(), G.graph_link(), map) ::
          T.result(G.graph_node(), T.details())
  def register_link(graph_node = %{__struct__: module}, graph, link, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_register_link, 4) do
      module.do_register_link(graph_node, graph, link, options)
    else
      do_register_link(graph_node, graph, link, options)
    end
  end

  @spec do_register_link(G.graph_node(), G.graph(), G.graph_link(), map) ::
          T.result(G.graph_node(), T.details())
  def do_register_link(graph_node, graph, link, options)

  def do_register_link(graph_node, _, link, _) do
    with {:ok, link_id} <- Link.id(link),
         {:ok, source} <- Link.source_connector(link),
         {:ok, target} <- Link.target_connector(link) do
      # 1. For Source Node
      graph_node =
        if R.Link.connector(source, :node) == graph_node.id do
          update_in(
            graph_node,
            [Access.key(:outbound_links), R.Link.connector(source, :socket)],
            &Enum.uniq([link_id | &1 || []])
          )
        else
          graph_node
        end

      # 2. For Target Node
      graph_node =
        if R.Link.connector(target, :node) == graph_node.id do
          update_in(
            graph_node,
            [Access.key(:inbound_links), R.Link.connector(target, :socket)],
            &Enum.uniq([link_id | &1 || []])
          )
        else
          graph_node
        end

      {:ok, graph_node}
    end
  end

  # -------------------------
  # outbound_links/4
  # -------------------------
  @spec outbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def outbound_links(graph_node = %{__struct__: module}, graph, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_outbound_links, 3) do
      module.do_outbound_links(graph_node, graph, options)
    else
      do_outbound_links(graph_node, graph, options)
    end
  end

  @spec do_outbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def do_outbound_links(graph_node, graph, options) do
    if options[:expand] do
      links =
        graph_node.outbound_links
        |> Enum.map(fn {socket, link_ids} ->
          links =
            Enum.map(
              link_ids,
              fn link_id ->
                {:ok, link} = GenAI.VNext.Graph.link(graph, link_id)
                link
              end
            )

          {socket, links}
        end)
        |> Map.new()

      {:ok, links}
    else
      {:ok, graph_node.outbound_links}
    end
  end

  # -------------------------
  # inbound_links/4
  # -------------------------
  @spec inbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def inbound_links(graph_node = %{__struct__: module}, graph, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_inbound_links, 3) do
      module.do_inbound_links(graph_node, graph, options)
    else
      do_inbound_links(graph_node, graph, options)
    end
  end

  @spec do_inbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def do_inbound_links(graph_node, graph, options) do
    if options[:expand] do
      links =
        graph_node.inbound_links
        |> Enum.map(fn {socket, link_ids} ->
          links =
            Enum.map(
              link_ids,
              fn link_id ->
                {:ok, link} = GenAI.VNext.Graph.link(graph, link_id)
                link
              end
            )

          {socket, links}
        end)
        |> Map.new()

      {:ok, links}
    else
      {:ok, graph_node.inbound_links}
    end
  end
end
