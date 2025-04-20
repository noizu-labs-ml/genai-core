defmodule GenAI.Graph.Root do
  @vsn 1.0
  @moduledoc """
  The root data structure that contains nested graphs, nodes and other structures.
  """
  alias GenAI.Records.Link, as: L
  require GenAI.Records.Link
  require GenAI.Types.Graph

  defstruct [
    graph: nil, # Entry Point
    lookup_table: %{by_element: %{}, by_handle: %{}}, # uuid => element_lookup, handle => {:resolver, %{paths => element_entry}} | element_entry
    last_node: nil, # id of last inserted node
    last_link: nil, # id of last inserted link
  ]

  @doc """
  Retrieve a element_lookup entry by element id.
  """
  def element_entry(%__MODULE__{} = this, id) do
    if entry = this.lookup_table.by_element[id] do
      {:ok, entry}
    else
      {:error, {:element, :not_found}}
    end
  end

  @doc """
  Retrieve an element_lookup entry by handle and optional base node
  """
  def handle_entry(%__MODULE__{} = this, handle, base \\ nil) do
    if global_entry = this.lookup_table.by_handle[L.graph_handle(scope: :global, name: handle)] do
      element_entry(this, global_entry)
    else
      standard_entry = this.lookup_table.by_handle[L.graph_handle(scope: :standard, name: handle)]
      local_entries = this.lookup_table.by_handle[L.graph_handle(scope: :local, name: handle)] || []

      with {:ok, L.element_lookup(path: path)} <- element_entry(this, base) do
        {_, entry}  = local_entries
                      |> Enum.reduce(
                           {0, standard_entry},
                           fn
                             {entry_path, entry_element}, b = {b_depth, _} ->
                               e_depth = length(entry_path)
                               cond do
                                 e_depth > b_depth && List.starts_with?(path, entry_path) -> {e_depth, entry_element}
                                 :else -> b
                               end
                           end
                         )
        if entry do
          element_entry(this, entry)
        else
          {:error, {:element, :not_found}}
        end
      else
        _ -> standard_entry && element_entry(this, standard_entry) || {:error, {:element, :not_found}}
      end
    end
  end

  @doc """
  Retrieve a nested element by id from graph
  """
  def element(%__MODULE__{} = this, id) do
    with {:ok, L.element_lookup(path: [_|path])} <- element_entry(this, id) do
      get_nested_element(this.graph, path)
    end
  end

  @doc """
  Retrieve a nested element by handle from graph
  """
  def element_by_handle(%__MODULE__{} = this, handle, base \\ nil) do
    with {:ok, L.element_lookup(path: [_|path])} <- handle_entry(this, handle, base)  do
      get_nested_element(this.graph, path)
    end
  end


  @doc """
  extract nested entry by path from source element.
  """
  def get_nested_element(source, path)
  def get_nested_element(nil, _) do
    {:error, {:element, :not_found}}
  end
  def get_nested_element(element, []) do
    {:ok, element}
  end
  def get_nested_element(element, [h|t]) do
    with {:ok, nested} <- element.__struct__.node(element, h) do
      get_nested_element(nested, t)
    end
  end


  @doc """
  Merge element lookup entries
  """
  def merge_lookup_table_entries(%__MODULE__{} = this, entries) do
    update_in(this, [Access.key(:lookup_table), Access.key(:by_element)], & Enum.into(entries, &1 || %{}))
  end

  @doc """
  Merge list of {handle, element or path to element} entries into lookup table.
  """
  def merge_handles(%__MODULE__{} = this, handles) when is_list(handles) do
    Enum.reduce(handles, this, & merge_handle(&2, &1))
  end

  @doc """
  Merge a single graph handle entry into lookup table.
  """
  def merge_handle(this, {handle = L.graph_handle(scope: :global), element}) do
    put_in(this, [Access.key(:lookup_table), Access.key(:by_handle), handle], element)
  end
  def merge_handle(this, {handle = L.graph_handle(scope: :standard), element}) do
    put_in(this, [Access.key(:lookup_table), Access.key(:by_handle), handle], element)
  end
  def merge_handle(this, {handle = L.graph_handle(scope: :local), elements}) do
    elements = is_list(elements) && elements || [elements]
    update_in(this, [Access.key(:lookup_table), Access.key(:by_handle), handle], & elements ++ (&1 || []))
  end


end

#
#defimpl GenAI.Thread.SessionProtocol, for: GenAI.Graph.Root do
#  require GenAI.Records.Session
#  alias GenAI.Records.Session, as: Node
#
#  def process_node(subject, scope, context, options) do
#    subject = subject
#              |> GenAI.Graph.Root.merge_lookup_table_entries(GenAI.Graph.NodeProtocol.build_node_lookup(subject.graph, []))
#              |> GenAI.Graph.Root.merge_handles(GenAI.Graph.NodeProtocol.build_handle_lookup(subject.graph, []))
#
#    updated_scope = Node.scope(
#      scope,
#      graph_node: subject.graph,
#      graph_link: nil,
#      graph_container: subject,
#      session_root: subject
#    )
#    GenAI.Thread.SessionProtocol.process_node(subject.graph, updated_scope, context, options)
#  end
#end
