Change Log
==============

# Unreleased
- Added dependency-neutral tool source registration for MCP clients, harnesses,
  and other external data/tool providers.
- Added an opt-in bounded tool-chain runner without changing `GenAI.run/1-3`.
- Added normalized tool calls/results and payload-safe lifecycle telemetry.

# 0.0.1 - Initial Release
- Initial Text Only Generation.

# 0.0.2 - Local Model Support
- Local LLama support added for pulling in gguf models for inference.

# 0.0.3 - Vision Support and Internal Structure Update 
Warning - This update may break existing code.

- Added Vision support for OpenAI, Gemini, and Anthropic. 
- Updated internal structure to allow for more advanced use cases such as prompt loops/fitness checks,
added support for how to handel local models, etc.

# 0.2.0 - Refactor
- Directed Graph Session to allow future advanced feature.
- Streamline how providers are added with use macros.
