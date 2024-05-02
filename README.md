
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Ollama R Library

<!-- badges: start -->

[![R-CMD-check](https://github.com/hauselin/ollama-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/hauselin/ollama-r/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The [Ollama R library](https://hauselin.github.io/ollama-r/) provides
the easiest way to integrate R with [Ollama](https://ollama.com/), which
lets you run language models locally on your own machine. Main site:
<https://hauselin.github.io/ollama-r/>

> Note: You should have at least 8 GB of RAM available to run the 7B
> models, 16 GB to run the 13B models, and 32 GB to run the 33B models.

See [Ollama’s Github page](https://github.com/ollama/ollama) for more
information. See also the [Ollama API documentation and
endpoints](https://github.com/ollama/ollama/blob/main/docs/api.md). For
Ollama Python, see
[ollama-python](https://github.com/ollama/ollama-python). You’ll need to
have the [Ollama](https://ollama.com/) app installed on your computer to
use this library.

## Installation

1.  You should have the Ollama app installed on your computer. Download
    it from [Ollama](https://ollama.com/).

2.  Open/launch the Ollama app to start the local server. You can then
    run your language models locally, on your own machine/computer.

3.  Install the development version of `ollamar` R library like so:

``` r
devtools::install_github("hauselin/ollamar")
```

If it doesn’t work or you don’t have `devtools` installed, please run
`install.packages("devtools")` in R or RStudio first.

## Usage

``` r
library(ollamar)

test_connection()  # test connection to Ollama server; returns a httr2 response object
# Ollama local server running
# <httr2_response>

list_models()  # list available models (models you've pulled/downloaded)
   name                     size    parameter_size quantization_level modified           
   <chr>                    <chr>   <chr>          <chr>              <chr>              
 1 llama3:latest            4.7 GB  8B             Q4_0               2024-05-01T21:01:00
 2 mistral-openorca:latest  4.1 GB  7B             Q4_0               2024-04-25T16:45:00
```

### Notes

Optional/advanced parameters (see [API
docs](https://github.com/ollama/ollama/blob/main/docs/api.md)) such as
`temperature` are not yet implemented as of now but will be implemented
in future versions.

If you don’t have the Ollama app running, you’ll get an error. Make sure
to open the Ollama app before using this library.

``` r
test_connection()
# Ollama local server not running or wrong server.
# Error in `httr2::req_perform()` at ollamar/R/test_connection.R:18:9:
```

If a function in the library returns an `httr2_response` object, you can
parse the output with `resp_process()`. `ollamar` uses the [`httr2`
library](https://httr2.r-lib.org/index.html) to make HTTP requests to
the Ollama server.

``` r
resp <- list_models(output = "resp")  # returns a httr2 response object
# <httr2_response>
# GET http://127.0.0.1:11434/api/tags
# Status: 200 OK
# Content-Type: application/json
# Body: In memory (5401 bytes)

# process the httr2 response object with the resp_process() function
resp_process(resp, "df")
resp_process(resp, "jsonlist")  # list
resp_process(resp, "raw")  # raw string
resp_process(resp, "resp")  # returns the input httr2 response object
resp_process(resp, "text")  # text vector
```

### Pull/download model

Download a model from the ollama library (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#pull-a-model)).
For the list of models you can pull/download, see [Ollama
library](https://ollama.com/library).

``` r
pull("llama3")  # pull/download llama3 model
pull("mistral-openorca")  # pull/download mistral-openorca model
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

### Chat

Generate the next message in a chat (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion)).

``` r
messages <- list(
    list(role = "user", content = "Who is the prime minister of the uk?")
)
resp <- chat("llama3", messages)  # default returns httr2 response object
resp  # <httr2_response>
chat("llama3", messages, "df")  # data frame/tibble
chat("llama3", messages, "raw")  # raw string
chat("llama3", messages, "jsonlist")  # list
chat("llama3", messages, "text")  # text vector

messages <- list(
    list(role = "user", content = "Hello!"),
    list(role = "assistant", content = "Hi! How are you?"),
    list(role = "user", content = "Who is the prime minister of the uk?"),
    list(role = "assistant", content = "Rishi Sunak"),
    list(role = "user", content = "List all the previous messages.")
)
chat("llama3", messages, "text")
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

# use "llama3" model, provide list of messages, return text/vector output, and stream the output
chat("llama3", messages, "text", TRUE)
# chat(model = "llama3", messages = messages, output = "text", stream = TRUE)  # same as above
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
embeddings("llama3", "Hello, how are you?")

# don't normalize embeddings
embeddings("llama3", "Hello, how are you?", normalize = FALSE)
```

``` r
# get embeddings for similar prompts
e1 <- embeddings("llama3", "Hello, how are you?")
e2 <- embeddings("llama3", "Hi, how are you?")

# compute cosine similarity
sum(e1 * e2)  # 0.9859769
sum(e1 * e1)  # 1 (identical vectors/embeddings)

# non-normalized embeddings
e3 <- embeddings("llama3", "Hello, how are you?", normalize = FALSE)
e4 <- embeddings("llama3", "Hi, how are you?", normalize = FALSE)
sum(e3 * e4)  # 23695.96
sum(e3 * e3)  # 24067.32
```

### Generate a completion

Generate a response for a given prompt (see [API
doc](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion)).

``` r
generate("llama3", "Tomorrow is a...", output = "text")
generate("llama3", "Tomorrow is a...", stream = TRUE)  # return httr2 response object and stream output
generate("llama3", "Tomorrow is a...", output = "df", stream = TRUE)
generate("llama3", "Tomorrow is a...", "text", TRUE)  # return text/vector output and stream output
```
