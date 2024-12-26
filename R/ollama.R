#' Package configuration
#' @importFrom glue glue
package_config <- list(
    baseurls = c("http://127.0.0.1:11434", "http://localhost:11434"),
    package_version = packageVersion("ollamar"),
    user_agent = glue("ollama-r/{packageVersion('ollamar')} ({tolower(R.version$platform)}) R/{R.version$major}.{R.version$minor}")
)





#' Create a httr2 request object
#'
#' Creates a httr2 request object with base URL, headers and endpoint. Used by other functions in the package and not intended to be used directly.
#'
#' @param endpoint The endpoint to create the request
#' @param host The base URL to use. Default is NULL, which uses http://127.0.0.1:11434
#'
#' @return A httr2 request object.
#' @export
#'
#' @examples
#' create_request("/api/tags")
#' create_request("/api/chat")
#' create_request("/api/embeddings")
create_request <- function(endpoint, host = NULL) {
    if (is.null(host)) {
        url <- package_config$baseurls[1] # use default base URL
    } else {
        url <- host # use custom base URL
    }
    url <- httr2::url_parse(url)
    url$path <- endpoint
    req <- httr2::request(httr2::url_build(url))
    headers <- list(
        content_type = "application/json",
        accept = "application/json",
        user_agent = package_config$user_agent
    )
    req <- httr2::req_headers(req, !!!headers)
    return(req)
}











#' Generate a response for a given prompt
#'
#' @param model A character string of the model name such as "llama3".
#' @param prompt A character string of the prompt like "The sky is..."
#' @param suffix A character string after the model response. Default is "".
#' @param images A path to an image file to include in the prompt. Default is "".
#' @param system A character string of the system prompt (overrides what is defined in the Modelfile). Default is "".
#' @param template A character string of the prompt template (overrides what is defined in the Modelfile). Default is "".
#' @param context A list of context from a previous response to include previous conversation in the prompt. Default is an empty list.
#' @param stream Enable response streaming. Default is FALSE.
#' @param raw If TRUE, no formatting will be applied to the prompt. You may choose to use the raw parameter if you are specifying a full templated prompt in your request to the API. Default is FALSE.
#' @param keep_alive The time to keep the connection alive. Default is "5m" (5 minutes).
#' @param output A character vector of the output format. Default is "resp". Options are "resp", "jsonlist", "raw", "df", "text", "req" (httr2_request object).
#' @param endpoint The endpoint to generate the completion. Default is "/api/generate".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#' @param ... Additional options to pass to the model.
#'
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion)
#'
#' @examplesIf test_connection()
#' # text prompt
#' generate("llama3", "The sky is...", stream = FALSE, output = "df")
#' # stream and increase temperature
#' generate("llama3", "The sky is...", stream = TRUE, output = "text", temperature = 2.0)
#'
#' # image prompt
#' # something like "image1.png"
#' image_path <- file.path(system.file("extdata", package = "ollamar"), "image1.png")
#' # use vision or multimodal model such as https://ollama.com/benzie/llava-phi-3
#' generate("benzie/llava-phi-3:latest", "What is in the image?", images = image_path, output = "text")
generate <- function(model, prompt, suffix = "", images = "", system = "", template = "", context = list(), stream = FALSE, raw = FALSE, keep_alive = "5m", output = c("resp", "jsonlist", "raw", "df", "text", "req"), endpoint = "/api/generate", host = NULL, ...) {
    output <- output[1]
    if (!output %in% c("df", "resp", "jsonlist", "raw", "text", "req")) {
        stop("Invalid output format specified. Supported formats: 'df', 'resp', 'jsonlist', 'raw', 'text', 'req'")
    }

    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")

    images_list <- list()
    if (images[1] != "") images_list <- lapply(images, image_encode_base64)

    body_json <- list(
        model = model,
        prompt = prompt,
        suffix = suffix,
        system = system,
        template = template,
        context = context,
        stream = stream,
        raw = raw,
        images = images_list,
        stream = stream,
        keep_alive = keep_alive
    )

    # check if model options are passed and specified correctly
    opts <- list(...)
    if (length(opts) > 0) {
        if (validate_options(...)) {
            body_json$options <- opts
        } else {
            stop("Invalid model options passed to ... argument. Please check the model options and try again.")
        }
    }

    req <- httr2::req_body_json(req, body_json, stream = stream)

    if (output == "req") {
        return(req)
    }

    if (!stream) {
        tryCatch(
            {
                resp <- httr2::req_perform(req)
                return(resp_process(resp = resp, output = output))
            },
            error = function(e) {
                stop(e)
            }
        )
    }

    # streaming
    env <- new.env()
    env$buffer <- ""
    env$content <- ""
    env$accumulated_data <- raw()
    wrapped_handler <- function(x) stream_handler(x, env, endpoint)
    resp <- httr2::req_perform_stream(req, wrapped_handler, buffer_kb = 1)
    cat("\n\n")
    resp$body <- env$accumulated_data

    return(resp_process(resp = resp, output = output))
}











#' Generate a chat completion with message history
#'
#' @param model A character string of the model name such as "llama3".
#' @param messages A list with list of messages for the model (see examples below).
#' @param tools Tools for the model to use if supported. Requires stream = FALSE. Default is an empty list.
#' @param stream Enable response streaming. Default is FALSE.
#' @param keep_alive The duration to keep the connection alive. Default is "5m".
#' @param output The output format. Default is "resp". Other options are "jsonlist", "raw", "df", "text", "req" (httr2_request object), "tools" (tool calling)
#' @param endpoint The endpoint to chat with the model. Default is "/api/chat".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#' @param ... Additional options to pass to the model.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-chat-completion)
#'
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @examplesIf test_connection()
#' # one message
#' messages <- list(
#'     list(role = "user", content = "How are you doing?")
#' )
#' chat("llama3", messages) # returns response by default
#' chat("llama3", messages, output = "text") # returns text/vector
#' chat("llama3", messages, temperature = 2.8) # additional options
#' chat("llama3", messages, stream = TRUE) # stream response
#' chat("llama3", messages, output = "df", stream = TRUE) # stream and return dataframe
#'
#' # multiple messages
#' messages <- list(
#'     list(role = "user", content = "Hello!"),
#'     list(role = "assistant", content = "Hi! How are you?"),
#'     list(role = "user", content = "Who is the prime minister of the uk?"),
#'     list(role = "assistant", content = "Rishi Sunak"),
#'     list(role = "user", content = "List all the previous messages.")
#' )
#' chat("llama3", messages, stream = TRUE)
#'
#' # image
#' image_path <- file.path(system.file("extdata", package = "ollamar"), "image1.png")
#' messages <- list(
#'    list(role = "user", content = "What is in the image?", images = image_path)
#' )
#' chat("benzie/llava-phi-3", messages, output = 'text')
chat <- function(model, messages, tools = list(), stream = FALSE, keep_alive = "5m", output = c("resp", "jsonlist", "raw", "df", "text", "req", "tools"), endpoint = "/api/chat", host = NULL, ...) {
    output <- output[1]
    if (!output %in% c("df", "resp", "jsonlist", "raw", "text", "req", "tools")) {
        stop("Invalid output format specified. Supported formats: 'df', 'resp', 'jsonlist', 'raw', 'text'")
    }

    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")

    if (!validate_messages(messages)) {
        stop("Invalid messages.")
    }

    messages <- encode_images_in_messages(messages)

    body_json <- list(
        model = model,
        messages = messages,
        tools = tools,
        stream = stream,
        keep_alive = keep_alive
    )

    opts <- list(...)
    if (length(opts) > 0) {
        if (validate_options(...)) {
            body_json$options <- opts
        } else {
            stop("Invalid model options passed to ... argument. Please check the model options and try again.")
        }
    }

    req <- httr2::req_body_json(req, body_json, stream = stream)
    if (output == "req") {
        return(req)
    }

    if (!stream) {
        tryCatch(
            {
                resp <- httr2::req_perform(req)
                return(resp_process(resp = resp, output = output))
            },
            error = function(e) {
                stop(e)
            }
        )
    }

    # streaming
    env <- new.env()
    env$buffer <- ""
    env$content <- ""
    env$accumulated_data <- raw()
    wrapped_handler <- function(x) stream_handler(x, env, endpoint)
    resp <- httr2::req_perform_stream(req, wrapped_handler, buffer_kb = 1)
    cat("\n\n")
    resp$body <- env$accumulated_data

    return(resp_process(resp = resp, output = output))
}










#' Create a model from a Modelfile
#'
#' It is recommended to set `modelfile` to the content of the Modelfile rather than just set path.
#'
#' @param name Name of the model to create.
#' @param modelfile Contents of the Modelfile as character string. Default is NULL.
#' @param stream Enable response streaming. Default is FALSE.
#' @param path The path to the Modelfile. Default is NULL.
#' @param endpoint The endpoint to create the model. Default is "/api/create".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#create-a-model)
#'
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @examplesIf test_connection()
#' create("mario", "FROM llama3\nSYSTEM You are mario from Super Mario Bros.")
#' generate("mario", "who are you?", output = "text")  # model should say it's Mario
#' delete("mario")  # delete the model created above
create <- function(name, modelfile = NULL, stream = FALSE, path = NULL, endpoint = "/api/create", host = NULL) {

    if (is.null(modelfile) && is.null(path)) {
        stop("Either modelfile or path must be provided. Using modelfile is recommended.")
    }

    if (!is.null(modelfile) && !is.null(path)) {
        stop("Only one of modelfile or path should be provided.")
    }

    if (!is.null(path)) {
        if (file.exists(path)) {
            modelfile <- paste0(readLines("inst/extdata/example_modefile.txt", warn = FALSE), collapse = "\n")
            cat(paste0("Modefile\n", modelfile, "\n"))
        } else {
            stop("The path provided does not exist.")
        }
    }

    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")

    body_json <- list(
        name = name,
        modelfile = modelfile,
        stream = stream
    )

    req <- httr2::req_body_json(req, body_json, stream = stream)

    if (!stream) {
        tryCatch(
            {
                resp <- httr2::req_perform(req)
                return(resp)
            },
            error = function(e) {
                stop(e)
            }
        )
    }

    # streaming
    env <- new.env()
    env$buffer <- ""
    env$content <- ""
    env$accumulated_data <- raw()
    wrapped_handler <- function(x) stream_handler(x, env, endpoint)
    resp <- httr2::req_perform_stream(req, wrapped_handler, buffer_kb = 1)
    resp$body <- env$accumulated_data
    return(resp)

}















#' List models that are available locally
#'
#' @param output The output format. Default is "df". Other options are "resp", "jsonlist", "raw", "text".
#' @param endpoint The endpoint to get the models. Default is "/api/tags".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#list-local-models)
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @examplesIf test_connection()
#' list_models() # returns dataframe
#' list_models("df") # returns dataframe
#' list_models("resp") # httr2 response object
#' list_models("jsonlist")
#' list_models("raw")
list_models <- function(output = c("df", "resp", "jsonlist", "raw", "text"), endpoint = "/api/tags", host = NULL) {
    output <- output[1]
    if (!output %in% c("df", "resp", "jsonlist", "raw", "text")) {
        stop("Invalid output format specified. Supported formats: 'df', 'resp', 'jsonlist', 'raw', 'text'")
    }
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "GET")
    tryCatch(
        {
            resp <- httr2::req_perform(req)
            return(resp_process(resp = resp, output = output))
        },
        error = function(e) {
            stop(e)
        }
    )
}








#' Show model information
#'
#' Model information includes details, modelfile, template, parameters, license, system prompt.
#'
#' @param name Name of the model to show
#' @param verbose Returns full data for verbose response fields. Default is FALSE.
#' @param output The output format. Default is "jsonlist". Other options are "resp", "raw".
#' @param endpoint The endpoint to show the model. Default is "/api/show".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#show-model-information)
#'
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @examplesIf test_connection()
#' # show("llama3") # returns jsonlist
#' show("llama3", output = "resp") # returns response object
show <- function(name, verbose = FALSE, output = c("jsonlist", "resp", "raw"), endpoint = "/api/show", host = NULL) {
    output <- output[1]
    if (!output %in% c("resp", "jsonlist", "raw")) {
        stop("Invalid output format specified. Supported formats: 'resp', 'jsonlist', 'raw'")
    }

    body_json <- list(
        name = name,
        verbose = verbose
    )
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")
    tryCatch(
        {
            req <- httr2::req_body_json(req, body_json, verbose = verbose)
            resp <- httr2::req_perform(req)
            return(resp_process(resp, output = output))
        },
        error = function(e) {
            stop(e)
        }
    )
}






#' Copy a model
#'
#' Creates a model with another name from an existing model.
#'
#' @param source The name of the model to copy.
#' @param destination The name for the new model.
#' @param endpoint The endpoint to copy the model. Default is "/api/copy".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#copy-a-model)
#'
#' @return A httr2 response object.
#' @export
#'
#' @examplesIf test_connection()
#' copy("llama3", "llama3_copy")
#' delete("llama3_copy")  # delete the model was just got copied
copy <- function(source, destination, endpoint = "/api/copy", host = NULL) {

    if (!model_avail(source)) {
        return(invisible())
    }

    body_json <- list(
        source = source,
        destination = destination
    )
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")
    tryCatch(
        {
            req <- httr2::req_body_json(req, body_json)
            resp <- httr2::req_perform(req)
            return(resp)
        },
        error = function(e) {
            stop(e)
        }
    )
}








#' Delete a model and its data
#'
#' Delete a model from your local machine that you downloaded using the pull() function. To see which models are available, use the list_models() function.
#'
#' @param name A character string of the model name such as "llama3".
#' @param endpoint The endpoint to delete the model. Default is "/api/delete".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#delete-a-model)
#' @return A httr2 response object.
#' @export
#'
#' @examples
#' \dontrun{
#' delete("llama3")
#' }
delete <- function(name, endpoint = "/api/delete", host = NULL) {
    if (!model_avail(name)) {
        message("Available models listed below.")
        print(list_models(output = "text", host = host))
        return(invisible())
    }

    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "DELETE")
    body_json <- list(name = name)
    req <- httr2::req_body_json(req, body_json)

    tryCatch(
        {
            resp <- httr2::req_perform(req)
            return(resp)
        },
        error = function(e) {
            stop("Model not found and cannot be deleted. Please check the model name with list_models() and try again.")
        }
    )
}





#' Pull/download a model from the Ollama library
#'
#' See https://ollama.com/library for a list of available models. Use the list_models() function to get the list of models already downloaded/installed on your machine. Cancelled pulls are resumed from where they left off, and multiple calls will share the same download progress.
#'
#' @param name A character string of the model name to download/pull, such as "llama3".
#' @param stream Enable response streaming. Default is FALSE.
#' @param insecure Allow insecure connections Only use this if you are pulling from your own library during development. Default is FALSE.
#' @param endpoint The endpoint to pull the model. Default is "/api/pull".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#pull-a-model)
#'
#' @return A httr2 response object.
#' @export
#'
#' @examplesIf test_connection()
#' pull("llama3")
#' pull("all-minilm", stream = FALSE)
pull <- function(name, stream = FALSE, insecure = FALSE, endpoint = "/api/pull", host = NULL) {
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")

    body_json <- list(name = name, insecure = insecure)
    req <- httr2::req_body_json(req, body_json, stream = stream)

    if (!stream) {
        tryCatch(
            {
                resp <- httr2::req_perform(req)
                return(resp)
            },
            error = function(e) {
                stop(e)
            }
        )
    }

    # streaming
    env <- new.env()
    env$buffer <- ""
    env$content <- ""
    env$accumulated_data <- raw()
    wrapped_handler <- function(x) stream_handler(x, env, endpoint)
    resp <- httr2::req_perform_stream(req, wrapped_handler, buffer_kb = 1)
    resp$body <- env$accumulated_data
    return(resp)
}


















#' Push or upload a model to a model library
#'
#' @description
#' Push or upload a model to an Ollama model library. Requires registering for ollama.ai and adding a public key first.
#'
#' @param name A character string of the model name to upload, in the form of `<namespace>/<model>:<tag>`
#' @param insecure Allow insecure connections. Only use this if you are pushing to your own library during development. Default is FALSE.
#' @param stream Enable response streaming. Default is FALSE.
#' @param output The output format. Default is "resp". Other options are "jsonlist", "raw", "text", and "df".
#' @param endpoint The endpoint to push the model. Default is "/api/push".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#push-a-model)
#'
#' @return A httr2 response object.
#' @export
#'
#' @examplesIf test_connection()
#' push("mattw/pygmalion:latest")
push <- function(name, insecure = FALSE, stream = FALSE, output = c("resp", "jsonlist", "raw", "text", "df"), endpoint = "/api/push", host = NULL) {

    output <- output[1]
    if (!output %in% c("text", "jsonlist", "raw", "resp", "df")) {
        stop("Invalid output format specified.")
    }

    body_json <- list(name = name, insecure = insecure, stream = stream)

    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")
    body_json <- list(name = name)
    req <- httr2::req_body_json(req, body_json, stream = stream)

    if (!stream) {
        tryCatch(
            {
                resp <- httr2::req_perform(req)
                resp <- resp_process(resp, output = output)
                return(resp)
            },
            error = function(e) {
                stop(e)
            }
        )
    }

    # streaming
    env <- new.env()
    env$buffer <- ""
    env$content <- ""
    env$accumulated_data <- raw()
    wrapped_handler <- function(x) stream_handler(x, env, endpoint)
    resp <- httr2::req_perform_stream(req, wrapped_handler, buffer_kb = 1)
    resp$body <- env$accumulated_data

    # print final message
    df_response <- resp_process(resp, output = "df")
    status_messages <- df_response[nrow(df_response), ]$status
    cat(status_messages, "\n")

    return(resp)
}
















vector_norm <- function(x) {
    return(sqrt(sum(x^2)))
}


normalize <- function(x) {
    norm <- vector_norm(x)
    normalized_vector <- x / norm
    return(normalized_vector)
}










#' Generate embedding for inputs
#'
#' Supercedes the `embeddings()` function.
#'
#' @param model A character string of the model name such as "llama3".
#' @param input A vector of characters that you want to get the embeddings for.
#' @param truncate Truncates the end of each input to fit within context length. Returns error if FALSE and context length is exceeded. Defaults to TRUE.
#' @param normalize Normalize the vector to length 1. Default is TRUE.
#' @param keep_alive The time to keep the connection alive. Default is "5m" (5 minutes).
#' @param endpoint The endpoint to get the vector embedding. Default is "/api/embeddings".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#' @param ... Additional options to pass to the model.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embeddings)
#'
#' @return A numeric matrix of the embedding. Each column is the embedding for one input.
#' @export
#'
#' @examplesIf test_connection()
#' embed("nomic-embed-text:latest", "The quick brown fox jumps over the lazy dog.")
#' # pass multiple inputs
#' embed("nomic-embed-text:latest", c("Good bye", "Bye", "See you."))
#' # pass model options to the model
#' embed("nomic-embed-text:latest", "Hello!", temperature = 0.1, num_predict = 3)
embed <- function(model, input, truncate = TRUE, normalize = TRUE, keep_alive = "5m", endpoint = "/api/embed", host = NULL, ...) {
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")
    body_json <- list(model = model, input = input, keep_alive = keep_alive)

    opts <- list(...)
    if (length(opts) > 0) {
        if (validate_options(...)) {
            body_json$options <- opts
        } else {
            stop("Invalid model options passed to ... argument. Please check the model options and try again.")
        }
    }

    req <- httr2::req_body_json(req, body_json)

    tryCatch(
        {
            resp <- httr2::req_perform(req)
            json_body <- httr2::resp_body_json(resp)$embeddings
            # matrix
            m <- do.call(cbind, lapply(json_body, function(x) {
                v <- unlist(x)
                if (normalize) {
                    v <- normalize(v)
                }
                return(v)
            }))
            return(m)
        },
        error = function(e) {
            stop(e)
        }
    )
}













#' Generate embeddings for a single prompt - deprecated in favor of `embed()`
#'
#' This function will be deprecated over time and has been superceded by `embed()`. See `embed()` for more details.
#'
#' @param model A character string of the model name such as "llama3".
#' @param prompt A character string of the prompt that you want to get the vector embedding for.
#' @param normalize Normalize the vector to length 1. Default is TRUE.
#' @param keep_alive The time to keep the connection alive. Default is "5m" (5 minutes).
#' @param endpoint The endpoint to get the vector embedding. Default is "/api/embeddings".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#' @param ... Additional options to pass to the model.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#generate-embedding)
#'
#' @return A numeric vector of the embedding.
#' @export
#'
#' @examplesIf test_connection()
#' embeddings("nomic-embed-text:latest", "The quick brown fox jumps over the lazy dog.")
#' # pass model options to the model
#' embeddings("nomic-embed-text:latest", "Hello!", temperature = 0.1, num_predict = 3)
embeddings <- function(model, prompt, normalize = TRUE, keep_alive = "5m", endpoint = "/api/embeddings", host = NULL, ...) {
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")
    body_json <- list(model = model, prompt = prompt, keep_alive = keep_alive)

    opts <- list(...)
    if (length(opts) > 0) {
        if (validate_options(...)) {
            body_json$options <- opts
        } else {
            stop("Invalid model options passed to ... argument. Please check the model options and try again.")
        }
    }

    req <- httr2::req_body_json(req, body_json)

    tryCatch(
        {
            resp <- httr2::req_perform(req)
            # vector
            v <- unlist(httr2::resp_body_json(resp)$embedding)
            if (normalize) {
                v <- normalize(v)
            }
            return(v)
        },
        error = function(e) {
            stop(e)
        }
    )
}






#' List models that are currently loaded into memory
#'
#' @param output The output format. Default is "df". Supported formats are "df", "resp", "jsonlist", "raw", and "text".
#' @param endpoint The endpoint to list the running models. Default is "/api/ps".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @references
#' [API documentation](https://github.com/ollama/ollama/blob/main/docs/api.md#list-running-models)
#'
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @examplesIf test_connection()
#' ps("text")
ps <- function(output = c("df", "resp", "jsonlist", "raw", "text"), endpoint = "/api/ps", host = NULL) {
    output <- output[1]
    if (!output %in% c("df", "resp", "jsonlist", "raw", "text")) {
        stop("Invalid output format specified. Supported formats: 'df', 'resp', 'jsonlist', 'raw', 'text'")
    }
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "GET")
    tryCatch(
        {
            resp <- httr2::req_perform(req)
            return(resp_process(resp = resp, output = output))
        },
        error = function(e) {
            stop(e)
        }
    )
}



















#' Chat with a model in real-time in R console
#'
#' @param model A character string of the model name such as "llama3". Defaults to "codegemma:7b" which is a decent coding model as of 2024-07-27.
#' @param ... Additional options. No options are currently available at this time.
#'
#' @return Does not return anything. It prints the conversation in the console.
#' @export
#'
#' @examplesIf test_connection()
#' ohelp(first_prompt = "quit")
#' # regular usage: ohelp()
ohelp <- function(model = "codegemma:7b", ...) {
    if (!model_avail(model)) {
        return(invisible())
    }
    messages <- list()
    n_messages <- 0
    cat("Say something or type /q to quit or end the conversation.\n\n")

    opts <- list(...)
    if (length(opts) > 0) {
        if (opts$first_prompt == "quit") {
            prompt <- "/q"
        }
    } else {
        prompt <- readline()
    }

    while (prompt != "/q") {
        if (n_messages == 0) {
            messages <- create_message(prompt, role = "user")
        } else {
            messages <- append_message(prompt, "user", messages)
        }
        n_messages <- n_messages + 1
        response <- chat(model, messages = messages, output = "text", stream = TRUE)
        messages <- append_message(response, "assistant", messages)
        n_messages <- n_messages + 1
        prompt <- readline()
    }

    cat("Goodbye!\n")
}







#' Check if model is available locally
#'
#' @param model A character string of the model name such as "llama3".
#'
#' @return A logical value indicating if the model exists.
#' @export
#'
#' @examplesIf test_connection()
#' model_avail("codegemma:7b")
#' model_avail("abc")
#' model_avail("llama3")
model_avail <- function(model) {
    model <- tolower(model)
    models <- sort(list_models("text"))
    exist <- FALSE
    for (m in models) {
        mm <- tolower(strsplit(m, ":")[[1]][1])
        if (mm == model | m == model) {
            exist <- TRUE
            break
        }
    }
    if (!exist) {
        message(paste("Model", model, "does not exist.\nPlease check available models with list_models() or download the model with pull()."))
    }
    return(exist)
}
