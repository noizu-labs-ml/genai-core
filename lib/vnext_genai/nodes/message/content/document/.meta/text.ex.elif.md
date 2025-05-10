# Document.Text
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/document/text.ex)

Text document representation for AI model input. Enables passing plain text documents to models.

## Purpose
Provides a simple container for text-based document content. This allows AI systems to process structured text documents as distinct from regular message content.

## Key Components
- Content field for storing the document text
- Metadata field for additional information
- Version tracking for compatibility

## Implementation
- Simple structure optimized for text content
- Supports creation from keyword lists
- Filters fields to ensure valid structure
- Designed for compatibility with document-aware AI models

## Related
- [content_block.ex.elif.md](content_block.ex.elif.md) - Content block implementation
- [pdf.ex.elif.md](pdf.ex.elif.md) - PDF document implementation
- [../document_content.ex.elif.md](../document_content.ex.elif.md) - Document content implementation