# Message.Content.Document
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/document_content.ex)

Document content wrapper for messages. Provides a container for document-based content in conversations.

## Purpose
Creates a structured representation of document-based content for AI conversations. This allows for attaching documents with metadata to messages.

## Key Components
- Title field for document identification
- Citation field for source reference
- Cache control for reuse management
- Context for additional information
- Document field for actual document content

## Implementation
- Simple wrapper structure for document content
- Supports creation from keyword lists
- Maintains metadata alongside document content
- Designed for compatibility with document-aware AI models

## Related
- [document/text.ex.elif.md](document/text.ex.elif.md) - Text document implementation
- [document/pdf.ex.elif.md](document/pdf.ex.elif.md) - PDF document implementation
- [content_protocol.ex.elif.md](content_protocol.ex.elif.md) - Content protocol definition