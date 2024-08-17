
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Ollama R Library

<!-- badges: start -->

[![R-CMD-check](https://github.com/hauselin/ollama-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/hauselin/ollama-r/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The [Ollama R library](https://hauselin.github.io/ollama-r/) is the
easiest way to integrate R with [Ollama](https://ollama.com/), which
lets you run language models locally on your own machine. Main site:
<https://hauselin.github.io/ollama-r/>

To use this R library, ensure the [Ollama](https://ollama.com) app is
installed. Ollama can use GPUs for accelerating LLM inference. See
[Ollama GPU
documentation](https://github.com/ollama/ollama/blob/main/docs/gpu.md)
for more information.

See [Ollama’s Github page](https://github.com/ollama/ollama) for more
information. This library uses the [Ollama REST API (see documentation
for details)](https://github.com/ollama/ollama/blob/main/docs/api.md).

> Note: You should have at least 8 GB of RAM available to run the 7B
> models, 16 GB to run the 13B models, and 32 GB to run the 33B models.

## Ollama R versus Ollama Python/JavaScript

This library has been inspired by the official [Ollama
Python](https://github.com/ollama/ollama-python) and [Ollama
JavaScript](https://github.com/ollama/ollama-js) libraries. If you’re
coming from Python or JavaScript, you should feel right at home.
Alternatively, if you plan to use Ollama with Python or JavaScript,
using this R library will help you understand the Python/JavaScript
libraries as well.

## Installation

1.  Download and install [Ollama](https://ollama.com).

2.  Open/launch the Ollama app to start the local server.

3.  Install either the stable or latest/development version of
    `ollamar`.

Stable version:

``` r
install.packages("ollamar")
```

For the latest/development version with more features/bug fixes, you can
install it from GitHub using the `install_github` function from the
`remotes` library. If it doesn’t work or you don’t have `remotes`
library, please run `install.packages("remotes")` in R or RStudio before
running the code below.

``` r
remotes::install_github("hauselin/ollamar")
```

## Usage

`ollamar` uses the [`httr2` library](https://httr2.r-lib.org/index.html)
to make HTTP requests to the Ollama server, so many functions in this
library returns an `httr2_response` object by default. If the response
object says `Status: 200 OK`, then the request was successful. See
[Notes section](#notes) below for more information.

``` r
library(ollamar)

test_connection()  # test connection to Ollama server
# if you see Ollama local server running, it's working

# generate a response/text based on a prompt; returns an httr2 response by default
resp <- generate("llama3.1", "tell me a 5-word story") 
resp

#' interpret httr2 response object
#' <httr2_response>
#' POST http://127.0.0.1:11434/api/generate  # endpoint
#' Status: 200 OK  # if successful, status code should be 200 OK
#' Content-Type: application/json
#' Body: In memory (414 bytes)

# get just the text from the response object
resp_process(resp, "text") 
# get the text as a tibble dataframe
resp_process(resp, "df") 

# alternatively, specify the output type when calling the function initially
txt <- generate("llama3.1", "tell me a 5-word story", output = "text")

# list available models (models you've pulled/downloaded)
list_models()  
                        name    size parameter_size quantization_level            modified
1               codegemma:7b    5 GB             9B               Q4_0 2024-07-27T23:44:10
2            llama3.1:latest  4.7 GB           8.0B               Q4_0 2024-07-31T07:44:33
```

### Pull/download model

Download a model from the ollama library (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#pull-a-model)).
For the list of models you can pull/download, see [Ollama
library](https://ollama.com/library).

``` r
pull("llama3.1")  # download a model (the equivalent bash code: ollama run llama3.1)
list_models()  # verify you've pulled/downloaded the model
```

### Delete a model

Delete a model and its data (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#delete-a-model)).
You can see what models you’ve downloaded with `list_models()`. To
download a model, specify the name of the model.

``` r
list_models()  # see the models you've pulled/downloaded
delete("all-minilm:latest")  # returns a httr2 response object
```

### Generate a completion

Generate a response for a given prompt (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion)).

``` r
resp <- generate("llama3.1", "Tomorrow is a...")  # return httr2 response object by default
resp

resp_process(resp, "text")  # process the response to return text/vector output

generate("llama3.1", "Tomorrow is a...", output = "text")  # directly return text/vector output
generate("llama3.1", "Tomorrow is a...", stream = TRUE)  # return httr2 response object and stream output
generate("llama3.1", "Tomorrow is a...", output = "df", stream = TRUE)

# image prompt
# use a vision/multi-modal model
generate("benzie/llava-phi-3", "What is in the image?", images = "image.png", output = 'text')
```

### Chat

Generate the next message in a chat (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion)).
See the [Notes section](#notes) for utility/helper functions to help you
format/prepare the messages for the functions/API calls.

``` r
messages <- list(
    list(role = "user", content = "Who is the prime minister of the uk?")
)
resp <- chat("llama3.1", messages)  # default returns httr2 response object
resp  # <httr2_response>
resp_process(resp, "text")  # process the response to return text/vector output

# specify output type when calling the function
chat("llama3.1", messages, output = "text")  # text vector
chat("llama3.1", messages, output = "df")  # data frame/tibble
chat("llama3.1", messages, output = "jsonlist")  # list
chat("llama3.1", messages, output = "raw")  # raw string
chat("llama3.1", messages, stream = TRUE)  # stream output and return httr2 response object

# list of messages
messages <- list(
    list(role = "user", content = "Hello!"),
    list(role = "assistant", content = "Hi! How are you?"),
    list(role = "user", content = "Who is the prime minister of the uk?"),
    list(role = "assistant", content = "Rishi Sunak"),
    list(role = "user", content = "List all the previous messages.")
)
cat(chat("llama3.1", messages, output = "text"))  # print the formatted output

# image prompt
messages <- list(
    list(role = "user", content = "What is in the image?", images = "image.png")
)
# use a vision/multi-modal model
chat("benzie/llava-phi-3", messages, output = "text")
```

#### Streaming responses

``` r
messages <- list(
    list(role = "user", content = "Hello!"),
    list(role = "assistant", content = "Hi! How are you?"),
    list(role = "user", content = "Who is the prime minister of the uk?"),
    list(role = "assistant", content = "Rishi Sunak"),
    list(role = "user", content = "List all the previous messages.")
)

# use "llama3.1" model, provide list of messages, return text/vector output, and stream the output
chat("llama3.1", messages, output = "text", stream = TRUE)
# chat(model = "llama3.1", messages = messages, output = "text", stream = TRUE)  # same as above
```

### Embeddings

Get the vector embedding of some prompt/text (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embeddings)).
By default, the embeddings are normalized to length 1, which means the
following:

- cosine similarity can be computed slightly faster using just a dot
  product
- cosine similarity and Euclidean distance will result in the identical
  rankings

``` r
embed("llama3.1", "Hello, how are you?")

# don't normalize embeddings
embed("llama3.1", "Hello, how are you?", normalize = FALSE)
```

``` r
# get embeddings for similar prompts
e1 <- embed("llama3.1", "Hello, how are you?")
e2 <- embed("llama3.1", "Hi, how are you?")

# compute cosine similarity
sum(e1 * e2)  # not equals to 1
sum(e1 * e1)  # 1 (identical vectors/embeddings)

# non-normalized embeddings
e3 <- embed("llama3.1", "Hello, how are you?", normalize = FALSE)
e4 <- embed("llama3.1", "Hi, how are you?", normalize = FALSE)
```

### Notes

If you don’t have the Ollama app running, you’ll get an error. Make sure
to open the Ollama app before using this library.

``` r
test_connection()
# Ollama local server not running or wrong server.
# Error in `httr2::req_perform()` at ollamar/R/test_connection.R:18:9:
```

#### Parsing `httr2_response` objects with `resp_process()`

`ollamar` uses the [`httr2` library](https://httr2.r-lib.org/index.html)
to make HTTP requests to the Ollama server, so many functions in this
library returns an `httr2_response` object by default.

You can either parse the output with `resp_process()` or use the
`output` parameter in the function to specify the output format.
Generally, the `output` parameter can be one of `"df"`, `"jsonlist"`,
`"raw"`, `"resp"`, or `"text"`.

``` r
resp <- list_models(output = "resp")  # returns a httr2 response object
# <httr2_response>
# GET http://127.0.0.1:11434/api/tags
# Status: 200 OK
# Content-Type: application/json
# Body: In memory (5401 bytes)

# process the httr2 response object with the resp_process() function
resp_process(resp, "df")
# or list_models(output = "df")
resp_process(resp, "jsonlist")  # list
# or list_models(output = "jsonlist")
resp_process(resp, "raw")  # raw string
# or list_models(output = "raw")
resp_process(resp, "resp")  # returns the input httr2 response object
# or list_models() or list_models("resp")
resp_process(resp, "text")  # text vector
# or list_models("text")
```

#### Utility/helper functions to format and prepare messages for the `chat()` function

Internally, messages are represented as a `list` of many distinct `list`
messages. Each list/message object has two elements: `role` (can be
`"user"` or `"assistant"` or `"system"`) and `content` (the message
text). The example below shows how the messages/lists are presented.

``` r
list(  # main list containing all the messages
    list(role = "user", content = "Hello!"),  # first message as a list
    list(role = "assistant", content = "Hi! How are you?"),  # second message as a list
    list(role = "user", content = "Who is the prime minister of the uk?"),  # third message as a list
    list(role = "assistant", content = "Rishi Sunak"),  # fourth message as a list
    list(role = "user", content = "List all the previous messages.")  # fifth message as a list
)
```

To simplify the process of creating and managing messages, `ollamar`
provides utility/helper functions to format and prepare messages for the
`chat()` function.

- `create_message()` creates the first message
- `append_message()` adds a new message to the end of the existing
  messages
- `prepend_message()` adds a new message to the beginning of the
  existing messages
- `insert_message()` inserts a new message at a specific index in the
  existing messages
  - by default, it inserts the message at the -1 (final) position
- `delete_message()` delete a message at a specific index in the
  existing messages
  - positive and negative indices/positions are supported
  - if there are 5 messages, the positions are 1 (-5), 2 (-4), 3 (-3), 4
    (-2), 5 (-1)

``` r
# create first message
messages <- create_message(content = "Hi! How are you? (1ST MESSAGE)", role = "assistant")
# or simply, messages <- create_message("Hi! How are you?", "assistant")
messages[[1]]  # get 1st message

# append (add to the end) a new message to the existing messages
messages <- append_message("I'm good. How are you? (2ND MESSAGE)", "user", messages)
messages[[1]]  # get 1st message
messages[[2]]  # get 2nd message (newly added message)

# prepend (add to the beginning) a new message to the existing messages
messages <- prepend_message("I'm good. How are you? (0TH MESSAGE)", "user", messages)
messages[[1]]  # get 0th message (newly added message)
messages[[2]]  # get 1st message
messages[[3]]  # get 2nd message

# insert a new message at a specific index/position (2nd position in the example below)
# by default, the message is inserted at the end of the existing messages (position -1 is the end/default)
messages <- insert_message("I'm good. How are you? (BETWEEN 0 and 1 MESSAGE)", "user", messages, 2)
messages[[1]]  # get 0th message
messages[[2]]  # get between 0 and 1 message (newly added message)
messages[[3]]  # get 1st message
messages[[4]]  # get 2nd message

# delete a message at a specific index/position (2nd position in the example below)
messages <- delete_message(messages, 2)
```

## Advanced usage

### Parallel requests

For the `generate()` and `chat()` endpoints/functions, you can specify
`output = 'req'` in the function so the functions return `httr2_request`
objects instead of `httr2_response` objects.

``` r
prompt <- "Tell me a 10-word story"
req <- generate("llama3.1", prompt, output = "req")  # returns a httr2_request object
# <httr2_request>
# POST http://127.0.0.1:11434/api/generate
# Headers:
# • content_type: 'application/json'
# • accept: 'application/json'
# • user_agent: 'ollama-r/1.1.1 (aarch64-apple-darwin20) R/4.4.0'
# Body: json encoded data
```

When you have multiple `httr2_request` objects in a list, you can make
parallel requests with the `req_perform_parallel` function from the
`httr2` library. See [`httr2`
documentation](https://httr2.r-lib.org/reference/req_perform_parallel.html)
for details.

``` r
library(httr2)

prompt <- "Tell me a 5-word story"

# create 5 httr2_request objects that generate a response to the same prompt
reqs <- lapply(1:5, function(r) generate("llama3.1", prompt, output = "req"))

# make parallel requests and get response
resps <- req_perform_parallel(reqs)  # list of httr2_request objects

# process the responses
sapply(resps, resp_process, "text")  # get responses as text
# [1] "She found him in Paris."         "She found the key upstairs."    
# [3] "She found her long-lost sister." "She found love on Mars."        
# [5] "She found the diamond ring."    
```

Example sentiment analysis with parallel requests with `generate()`
function

``` r
library(httr2)
library(glue)
library(dplyr)

# text to classify
texts <- c('I love this product', 'I hate this product', 'I am neutral about this product')

# create httr2_request objects for each text, using the same system prompt
reqs <- lapply(texts, function(text) {
  prompt <- glue("Your only task/role is to evaluate the sentiment of product reviews, and your response should be one of the following:'positive', 'negative', or 'other'. Product review: {text}")
  generate("llama3.1", prompt, output = "req")
})

# make parallel requests and get response
resps <- req_perform_parallel(reqs)  # list of httr2_request objects

# process the responses
sapply(resps, resp_process, "text")  # get responses as text
# [1] "Positive"                            "Negative."                          
# [3] "'neutral' translates to... 'other'."
```

Example sentiment analysis with parallel requests with `chat()` function

``` r
library(httr2)
library(dplyr)

# text to classify
texts <- c('I love this product', 'I hate this product', 'I am neutral about this product')

# create system prompt
chat_history <- create_message("Your only task/role is to evaluate the sentiment of product reviews provided by the user. Your response should simply be 'positive', 'negative', or 'other'.", "system")

# create httr2_request objects for each text, using the same system prompt
reqs <- lapply(texts, function(text) {
  messages <- append_message(text, "user", chat_history)
  chat("llama3.1", messages, output = "req")
})

# make parallel requests and get response
resps <- req_perform_parallel(reqs)  # list of httr2_request objects

# process the responses
bind_rows(lapply(resps, resp_process, "df"))  # get responses as dataframes
# # A tibble: 3 × 4
#   model    role      content  created_at                 
#   <chr>    <chr>     <chr>    <chr>                      
# 1 llama3.1 assistant Positive 2024-08-05T17:54:27.758618Z
# 2 llama3.1 assistant negative 2024-08-05T17:54:27.657525Z
# 3 llama3.1 assistant other    2024-08-05T17:54:27.657067Z
```
