defmodule GenAI.Document.PDF do
  defstruct [
    content: nil, # {:base64, binary}
    media_type: nil,
  ]
end
