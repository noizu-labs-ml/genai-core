defmodule GenAI.Message.Content.Document do
  defstruct [
    title: nil,
    citation: nil,
    cache_control: nil,
    context: nil,
    document: nil
  ]
end

#content.type document
#content.cache_control.type
#content.citation
#content.context
#content.title
#role
#
#pdf
#content.source.data
#content.source.media_type application/pdf
#content.source.type base64
#
#
#text
#  content.source.data
#  content.source.type text
#  content.source.media_type text/plain
#
#content_block
#content.source.type content
#content.source.content:  string | array[content]
#
#URLPDFSource
#content.source.type: url
#content.source.url: string