# Document.PDF
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/document/pdf.ex)

PDF document representation for AI model input. Enables passing PDF content to models that support document understanding.

## Purpose
Provides a structured container for PDF document content in a format that can be sent to AI models. This allows AI systems to process and reference PDF content in conversations.

## Key Components
- Content field storing base64-encoded PDF data
- Media type for content format identification
- Metadata field for additional information
- Version tracking for compatibility

## Implementation
- Simple structure with encoded content storage
- Supports creation from keyword lists
- Filters fields to ensure valid structure
- Designed for compatibility with document-aware AI models

## Related
- [content_block.ex.elif.md](content_block.ex.elif.md) - Content block implementation
- [text.ex.elif.md](text.ex.elif.md) - Text document implementation
- [../document_content.ex.elif.md](../document_content.ex.elif.md) - Document content implementation