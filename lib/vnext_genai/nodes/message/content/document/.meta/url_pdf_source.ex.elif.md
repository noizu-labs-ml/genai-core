# Document.Link
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/document/url_pdf_source.ex)

Link-based document reference for remote content. Enables referencing documents by URL rather than embedding content.

## Purpose
Provides a lightweight way to reference external document content via URL. This allows AI systems to access documents without requiring full content transmission.

## Key Components
- URL field for document location reference
- Metadata field for additional information
- Version tracking for compatibility

## Implementation
- Simple structure with URL reference
- Supports creation from keyword lists
- Filters fields to ensure valid structure
- Enables referencing remote documents in conversations

## Related
- [pdf.ex.elif.md](pdf.ex.elif.md) - PDF document implementation
- [text.ex.elif.md](text.ex.elif.md) - Text document implementation
- [../document_content.ex.elif.md](../document_content.ex.elif.md) - Document content implementation