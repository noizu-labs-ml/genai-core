# InferenceProvider.DefaultProvider

## Overview
The `GenAI.InferenceProvider.DefaultProvider` module provides default implementations for inference provider functionality. It handles making API calls to LLM providers, managing settings, and processing responses. This module serves as the foundation for specific provider implementations.

## Key Functions

### Chat Completion
- `run/4`, `do_run/4`: Run inference and return completion response with updated session
- `chat/7`, `do_chat/7`: Low-level inference that prepares provider-specific API requests
- `chat/4`, `do_chat/4`: Legacy chat completion function 

### Request Preparation
- `endpoint/6`, `do_endpoint/6`: Prepare the endpoint and method for the inference call
- `headers/2`: Build headers for API requests based on configuration
- `headers/6`, `do_headers/6`: Prepare request headers for inference calls
- `request_body/8`, `do_request_body/8`: Prepare the request body for inference calls

### Settings Configuration
- `effective_settings/5`, `do_effective_settings/5`: Obtain effective settings combining model, provider, and configuration settings
- `standardize_model/3`: Standardize different model formats to a consistent structure

## Workflow
1. When a chat completion is requested, the `run` function is called
2. The function retrieves the effective model, encoder, settings, tools, and messages
3. It builds the request body, headers, and endpoint
4. It makes the API call to the provider
5. It processes the response using the model encoder
6. It returns the processed response along with the updated session

## Usage
This provider is used as a foundation for specific LLM provider implementations. It provides common functionality like:
- Building API requests
- Managing settings across different levels (model, provider, etc.)
- Processing responses
- Handling errors

Provider-specific implementations can override any function to customize behavior while leveraging the default implementations for common functionality.