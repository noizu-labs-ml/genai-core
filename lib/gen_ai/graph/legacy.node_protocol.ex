
defprotocol GenAI.Legacy.NodeProtocol do
  def apply(node, state)
end

defimpl GenAI.Legacy.NodeProtocol, for: [GenAI.Graph.Node] do
  def apply(node, state)
  def apply(_, state) do
    {:ok, state}
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Graph.ToolNode do
  def apply(node, state)
  def apply(node, state) do
    GenAI.Thread.StateProtocol.with_tool(state, node.content)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Graph.SettingNode do
  def apply(node, state)
  def apply(node, state) do
    GenAI.Thread.StateProtocol.with_setting(state, node.setting, node.value)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Graph.ProviderSettingNode do
  def apply(node, state)
  def apply(node, state) do
    GenAI.Thread.StateProtocol.with_provider_setting(state, node.provider, node.setting, node.value)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: [GenAI.Graph.ModelNode] do
  def apply(node, state)
  def apply(%GenAI.Graph.ModelNode{content: model_or_selector}, state) do
    cond do
      GenAI.ModelProtocol.protocol_supported?(model_or_selector) ->
        with {:ok, {registered_model, state}} <- GenAI.ModelProtocol.register(model_or_selector, state) do
          GenAI.Thread.StateProtocol.with_model(state, registered_model)
        else
          x = {:error, _} -> x
          x -> {:error, {:unexpected, x}}
        end
      :else ->
        GenAI.Thread.StateProtocol.with_model(state, model_or_selector)
    end
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Graph.MessageNode do
  def apply(node, state)
  def apply(node, state) do
    GenAI.Thread.StateProtocol.with_message(state, node.content)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Graph do
  def apply(this, state) do
    Enum.reduce(this.nodes, {:ok, state},
      fn
        _, state = {:error, _} -> state
        node, {:ok, state} ->
          GenAI.Legacy.NodeProtocol.apply(node, state)
      end
    )
  end
end