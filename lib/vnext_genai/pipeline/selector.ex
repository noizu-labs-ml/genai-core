defmodule GenAI.Pipeline.Selector do
  @moduledoc """
  Provider-neutral selectors. JSON paths are explicit key/index lists; XML uses
  XPath with SweetXml; grep uses Regex. No selector executes a shell command.
  Callback/MFA and inference hooks are trusted application code, not serializable
  model instructions. An inference hook receives raw messages and its options.
  """
  def extract(messages, selector, options \\ [])
  def extract(messages, :last_message, options), do: last(messages, Keyword.get(options, :role))
  def extract(messages, :last_response, _options), do: last(messages, :assistant)

  def extract(messages, :prompt_last_response, options) do
    with {:ok, response} <- last(messages, :assistant) do
      {:ok, %{prompt: Keyword.get(options, :prompt, ""), response: response}}
    end
  end

  def extract(messages, {:literal, value}, _options) when is_list(messages), do: {:ok, value}

  def extract(messages, {:callback, callback}, options) when is_function(callback, 2),
    do: invoke(fn -> callback.(messages, options) end)

  def extract(messages, {:mfa, module, function, arguments}, options)
      when is_atom(module) and is_atom(function) and is_list(arguments),
      do: invoke(fn -> apply(module, function, [messages, options | arguments]) end)

  def extract(messages, {:inference, callback}, options) when is_function(callback, 2),
    do: invoke(fn -> callback.(messages, options) end)

  def extract(messages, {:last, selector}, options) do
    with {:ok, content} <- last(messages, Keyword.get(options, :role)),
         do: select(content, selector)
  end

  def extract(messages, {:aggregate, selector}, options) do
    direction = Keyword.get(options, :direction, :forward)

    if direction in [:forward, :backward] do
      messages = if direction == :backward, do: Enum.reverse(messages), else: messages

      messages =
        Enum.filter(messages, &(is_nil(options[:role]) or role(&1) == options[:role]))

      Enum.reduce_while(messages, {:ok, []}, fn message, {:ok, values} ->
        case select(content(message), selector) do
          {:ok, value} ->
            {:cont, {:ok, values ++ [value]}}

          {:error, :not_found} ->
            if options[:missing] == :error,
              do: {:halt, {:error, :not_found}},
              else: {:cont, {:ok, values}}

          error ->
            {:halt, error}
        end
      end)
      |> format(Keyword.get(options, :format, :list))
    else
      {:error, :invalid_direction}
    end
  end

  def extract(_, _, _), do: {:error, :unsupported_selector}

  def select(content, :content), do: {:ok, content}

  def select(content, {:json, path}) when is_list(path) do
    with {:ok, value} <- decode_json(content), do: json_path(value, path)
  end

  def select(content, {:grep, %Regex{} = regex}) when is_binary(content) do
    case Regex.scan(regex, content) do
      [] -> {:error, :not_found}
      matches -> {:ok, matches}
    end
  end

  def select(content, {:xml, xpath}) when is_binary(content) and is_binary(xpath) do
    if Code.ensure_loaded?(SweetXml) and Code.ensure_loaded?(SweetXpath) do
      invoke(fn ->
        parsed = apply(SweetXml, :parse, [content, [dtd: :none]])

        spec =
          struct(SweetXpath,
            path: String.to_charlist(xpath),
            is_list: true,
            cast_to: :string
          )

        values = apply(SweetXml, :xpath, [parsed, spec])

        if values == [], do: {:error, :not_found}, else: {:ok, values}
      end)
    else
      {:error, :xml_selector_unavailable}
    end
  end

  def select(content, {:yaml_blocks, language})
      when is_binary(content) and language in ["yaml", "yml"] do
    regex = Regex.compile!("```" <> language <> "\\s*\\n([\\s\\S]*?)\\n```")
    blocks = for [_, block] <- Regex.scan(regex, content), do: block
    if blocks == [], do: {:error, :not_found}, else: {:ok, blocks}
  end

  def select(_, _), do: {:error, :unsupported_selector}

  def content(%GenAI.Message.ToolResponse{tool_response: value}), do: value
  def content(%{content: content}), do: content
  def content(other), do: other

  defp last(messages, role) do
    case messages |> Enum.reverse() |> Enum.find(&(is_nil(role) or role(&1) == role)) do
      nil -> {:error, :no_message}
      message -> {:ok, content(message)}
    end
  end

  defp role(%GenAI.Message.ToolResponse{}), do: :tool
  defp role(%{role: role}), do: role
  defp role(_), do: nil
  defp decode_json(content) when is_binary(content), do: Jason.decode(content)
  defp decode_json(content) when is_map(content) or is_list(content), do: {:ok, content}
  defp decode_json(_), do: {:error, :invalid_json}
  defp json_path(value, []), do: {:ok, value}

  defp json_path(value, [key | path]) when is_map(value) and (is_binary(key) or is_atom(key)) do
    case Map.fetch(value, key) do
      {:ok, value} -> json_path(value, path)
      :error -> {:error, :not_found}
    end
  end

  defp json_path(value, [index | path])
       when is_list(value) and is_integer(index) and index >= 0 do
    case Enum.fetch(value, index) do
      {:ok, value} -> json_path(value, path)
      :error -> {:error, :not_found}
    end
  end

  defp json_path(_, _), do: {:error, :not_found}
  defp format({:ok, values}, :list), do: {:ok, values}
  defp format({:ok, values}, :json), do: Jason.encode(values)
  defp format({:ok, values}, :yaml), do: {:ok, Ymlr.document!(values)}
  defp format({:ok, values}, :text), do: {:ok, Enum.map_join(values, "\n", &render/1)}
  defp format({:error, _} = error, _), do: error
  defp format(_, _), do: {:error, :unsupported_format}
  defp render(value) when is_binary(value), do: value
  defp render(value), do: Jason.encode!(value)

  @doc false
  def invoke(callback) do
    case callback.() do
      {:ok, _} = result -> result
      {:error, _} = error -> error
      value -> {:ok, value}
    end
  rescue
    exception -> {:error, {:callback_exception, exception.__struct__}}
  catch
    kind, _reason -> {:error, {:callback_exit, kind}}
  end
end
