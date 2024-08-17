# ollamar (development version)

- `generate()` and `chat()` accept multiple images as prompts/messages.
- Add functions to validate messages for `chat()` function: `validate_message()`, `validate_messages()`.
- Add `encode_images_in_messages()` to encode images in messages for `chat()` function.

# ollamar 1.2.0

- All functions calling API endpoints have `endpoint` parameter.
- All functions calling API endpoints have `...` parameter to pass additional model options to the API.
- All functions calling API endpoints have `host` parameter to specify the host URL. Default is `NULL`, which uses the default Ollama URL.
- Add `req` as an output format for `generate()` and `chat()`.
- Add new functions for calling APIs: `create()`, `show()`, `copy()`, `delete()`, `push()`, `embed()` (supercedes `embeddings()`), `ps()`.
- Add helper functions to manipulate chat/conversation history for `chat()` function (or other APIs like OpenAI): `create_message()`, `append_message()`, `prepend_message()`, `delete_message()`, `insert_message()`.
- Add `ohelp()` function to chat with models in real-time.
- Add helper functions: `model_avail()`, `image_encode_base64()`, `check_option_valid()`, `check_options()`, `search_options()`, `validate_options()`

# ollamar 1.1.1

## Bug fixes

- Fixed invalid URLs. 
- Updated title and description. 

# ollamar 1.0.0

* Initial CRAN submission.

## New features

- Integrate R with Ollama to run language models locally on your own machine. 
- Include `test_connection()` function to test connection to Ollama server.
- Include `list_models()` function to list available models.
- Include `pull()` function to pull a model from Ollama server.
- Include `delete()` function to delete a model from Ollama server.
- Include `chat()` function to chat with a model.
- Include `generate()` function to generate text from a model.
- Include `embeddings()` function to get embeddings from a model.
- Include `resp_process()` function to process `httr2_response` objects.

