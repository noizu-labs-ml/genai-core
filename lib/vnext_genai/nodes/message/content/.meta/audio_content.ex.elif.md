# Message.Content.AudioContent
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/message/content/audio_content.ex)

Audio content representation for messages. Handles various audio formats and sources for inclusion in GenAI messages.

## Purpose
Enables audio content to be included in message exchanges with AI models. This allows for voice messages, audio transcription, and audio-based interactions.

## Key Components
- Source and resource fields for audio content referencing
- Transcript field for text representation of audio
- Type field for audio format identification
- Length field for duration information
- Base64 encoding support for binary transfer

## Implementation
- Supports multiple sources (file, URI, base64, upload)
- Handles different audio formats (wav, mp3)
- Provides automatic type detection from file extension
- Implements ContentProtocol for standardized access

## Related
- [text_content.ex.elif.md](text_content.ex.elif.md) - Text content implementation
- [image_content.ex.elif.md](image_content.ex.elif.md) - Image content implementation
- [content_protocol.ex.elif.md](content_protocol.ex.elif.md) - Content protocol definition