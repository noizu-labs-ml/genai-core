# Document.ContentBlock
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/document/content_block.ex)

A reusable content block for document representation. Acts as a container for document content segments.

## Purpose
Provides a structured container for grouping related content within documents. Content blocks allow for organizing document parts with associated metadata.

## Key Components
- Content array for storing document segments
- Metadata field for additional information
- Version tracking for compatibility

## Implementation
- Simple structure with content collection
- Supports creation from keyword lists
- Filters fields to ensure valid structure
- Maintains version information for future compatibility

## Related
- [text.ex.elif.md](text.ex.elif.md) - Text document implementation
- [pdf.ex.elif.md](pdf.ex.elif.md) - PDF document implementation
- [../document_content.ex.elif.md](../document_content.ex.elif.md) - Document content implementation