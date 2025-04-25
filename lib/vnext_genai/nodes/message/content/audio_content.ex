defmodule GenAI.Message.Content.AudioContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct source: nil,
            type: nil,
            transcript: "AUDIO TRANSCRIPT NOT AVAILABLE",
            length: nil,
            resource: nil,
            options: nil,
            vsn: @vsn

  @doc """
  Get image type based on file extension.
  """
  def image_type(resource) when is_bitstring(resource) do
    cond do
      String.ends_with?(resource, ".wave") -> :wav
      String.ends_with?(resource, ".mp3") -> :mp3
      true -> throw("Unsupported image type: #{resource}")
    end
  end

  @doc """
  Get image resolution.
  """
  def audio_length(_), do: :auto

  @doc """
  Base64 encode image content.
  """
  def base64(image, options \\ nil)

  def base64(image, _) do
    binary = File.read!(image.resource)
    {:ok, Base.encode64(binary)}
  end

  @doc """
  Prepare new image message content item.
  """
  def new(resource, options \\ nil)

  def new(resource, options) when is_bitstring(resource) do
    File.exists?(resource) || throw("Resource not found: #{resource}")

    %__MODULE__{
      type: image_type(resource),
      length: audio_length(resource),
      resource: resource,
      options: options
    }
  end

  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end
end
