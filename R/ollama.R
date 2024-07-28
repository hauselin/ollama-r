#' Package configuration
#' @importFrom glue glue
package_config <- list(
    baseurls = c("http://127.0.0.1:11434", "http://localhost:11434"),
    package_version = packageVersion("ollamar"),
    user_agent = glue("ollama-r/{packageVersion('ollamar')} ({tolower(R.version$platform)}) R/{R.version$major}.{R.version$minor}")
)





#' Create a httr2 request object.
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











#' Generate a completion.
#'
#' Generate a response for a given prompt with a provided model.
#'
#' @param model A character string of the model name such as "llama3".
#' @param prompt A character string of the promp like "The sky is..."
#' @param suffix A character string after the model response. Default is "".
#' @param images A path to an image file to include in the prompt. Default is "".
#' @param system A character string of the system prompt (overrides what is defined in the Modelfile). Default is "".
#' @param template A character string of the prompt template (overrides what is defined in the Modelfile). Default is "".
#' @param context A list of context from a previous response to include previous conversation in the prompt. Default is an empty list.
#' @param stream Enable response streaming. Default is FALSE.
#' @param raw If TRUE, no formatting will be applied to the prompt. You may choose to use the raw parameter if you are specifying a full templated prompt in your request to the API. Default is FALSE.
#' @param keep_alive The time to keep the connection alive. Default is "5m" (5 minutes).
#' @param output A character vector of the output format. Default is "resp". Options are "resp", "jsonlist", "raw", "df", "text".
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
#' @examplesIf test_connection()$status_code == 200
#' generate("llama3", "The sky is...", stream = FALSE, output = "df")
#' generate("llama3", "The sky is...", stream = TRUE, output = "text")
#' generate("llama3", "The sky is...", stream = TRUE, output = "text", temperature = 2.0)
#' generate("llama3", "The sky is...", stream = FALSE, output = "jsonlist")
generate <- function(model, prompt, suffix = "", images = "", system = "", template = "", context = list(), stream = FALSE, raw = FALSE, keep_alive = "5m", output = c("resp", "jsonlist", "raw", "df", "text"), endpoint = "/api/generate", host = NULL, ...) {

    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")

    images_list <- list()
    if (images != "") images_list <- list(image_encode_base64(images))

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

    if (!stream) {
        tryCatch(
            {
                resp <- httr2::req_perform(req)
                return(resp_process(resp = resp, output = output[1]))
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

    return(resp_process(resp = resp, output = output[1]))
}











#' Chat with Ollama models
#'
#' @param model A character string of the model name such as "llama3".
#' @param messages A list with list of messages for the model (see examples below).
#' @param output The output format. Default is "resp". Other options are "jsonlist", "raw", "df", "text".
#' @param stream Enable response streaming. Default is FALSE.
#' @param keep_alive The duration to keep the connection alive. Default is "5m".
#' @param endpoint The endpoint to chat with the model. Default is "/api/chat".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#' @param ... Additional options to pass to the model.
#'
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
#' # one message
#' messages <- list(
#'     list(role = "user", content = "How are you doing?")
#' )
#' chat("llama3", messages) # returns response by default
#' chat("llama3", messages, "text") # returns text/vector
#' chat("llama3", messages, "hello!", temperature = 2.8) # additional options
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
chat <- function(model, messages, output = c("resp", "jsonlist", "raw", "df", "text"), stream = FALSE, keep_alive = "5m", endpoint = "/api/chat", host = NULL, ...) {
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")

    body_json <- list(
        model = model,
        messages = messages,
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

    req <- httr2::req_body_json(req, body_json)

    if (!stream) {
        tryCatch(
            {
                resp <- httr2::req_perform(req)
                return(resp_process(resp = resp, output = output[1]))
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

    # process streaming output
    json_lines <- strsplit(rawToChar(env$accumulated_data), "\n")[[1]]
    json_lines_output <- vector("list", length = length(json_lines))
    df_response <- tibble::tibble(
        model = character(length(json_lines_output)),
        role = character(length(json_lines_output)),
        content = character(length(json_lines_output)),
        created_at = character(length(json_lines_output))
    )

    if (output[1] == "raw") {
        return(rawToChar(env$accumulated_data))
    }

    for (i in seq_along(json_lines)) {
        json_lines_output[[i]] <- jsonlite::fromJSON(json_lines[[i]])
        df_response$model[i] <- json_lines_output[[i]]$model
        df_response$role[i] <- json_lines_output[[i]]$message$role
        df_response$content[i] <- json_lines_output[[i]]$message$content
        df_response$created_at[i] <- json_lines_output[[i]]$created_at
    }

    if (output[1] == "jsonlist") {
        return(json_lines_output)
    }

    if (output[1] == "df") {
        return(df_response)
    }

    if (output[1] == "text") {
        return(paste0(df_response$content, collapse = ""))
    }

    return(resp)
}






















#' Get available local models
#'
#' @param output The output format. Default is "df". Other options are "resp", "jsonlist", "raw", "text".
#' @param endpoint The endpoint to get the models. Default is "/api/tags".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @return A response in the format specified in the output parameter.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
#' list_models() # returns dataframe/tibble by default
#' list_models("df")
#' list_models("resp") # httr2 response object
#' list_models("jsonlist")
#' list_models("raw")
list_models <- function(output = c("df", "resp", "jsonlist", "raw", "text"), endpoint = "/api/tags", host = NULL) {

    output <- output[1]
    if (!output %in% c("df", "resp", "jsonlist", "raw", "text")) {
        stop("Invalid output format specified. Supported formats are 'df', 'resp', 'jsonlist', 'raw', 'text'.")
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









#' Delete a model
#'
#' Delete a model from your local machine that you downlaoded using the pull() function. To see which models are available, use the list_models() function.
#'
#' @param model A character string of the model name such as "llama3".
#' @param endpoint The endpoint to delete the model. Default is "/api/delete".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @return A httr2 response object.
#' @export
#'
#' @examples
#' \dontrun{
#' delete("llama3")
#' }
delete <- function(model, endpoint = "/api/delete", host = NULL) {
    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "DELETE")
    body_json <- list(model = model)
    req <- httr2::req_body_json(req, body_json)

    tryCatch(
        {
            resp <- httr2::req_perform(req)
            return(resp)
        },
        error = function(e) {
            message("Model not found and cannot be deleted. Please check the model name with list_models() and try again.")
        }
    )
}





#' Pull/download a model
#'
#' See https://ollama.com/library for a list of available models. Use the list_models() function to get the list of models already downloaded/installed on your machine.
#'
#' @param model A character string of the model name to download/pull, such as "llama3".
#' @param stream Enable response streaming. Default is TRUE.
#' @param insecure Allow insecure connections Only use this if you are pulling from your own library during development. Default is FALSE.
#' @param endpoint The endpoint to pull the model. Default is "/api/pull".
#' @param host The base URL to use. Default is NULL, which uses Ollama's default base URL.
#'
#' @return A httr2 response object.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
#' pull("llama3")
#' pull("all-minilm", stream = FALSE)
pull <- function(model, stream = TRUE, insecure = FALSE, endpoint = "/api/pull", host = NULL) {

    req <- create_request(endpoint, host)
    req <- httr2::req_method(req, "POST")

    body_json <- list(model = model, stream = stream, insecure = insecure)
    req <- httr2::req_body_json(req, body_json)

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
    return(resp)
}




normalize <- function(x) {
    norm <- sqrt(sum(x^2))
    normalized_vector <- x / norm
    return(normalized_vector)
}















#' Get embedding for inputs
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
#' @return A numeric matrix of the embedding. Each column is the embedding for one input.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
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













#' Get vector embedding for a single prompt
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
#' @return A numeric vector of the embedding.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
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
            v <- unlist(resp_process(resp, "jsonlist")$embedding)
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


















#' Chat with a model in real-time in R console.
#'
#' @param model A character string of the model name such as "llama3". Defaults to "codegemma:7b" which is a decent coding model as of 2024-07-27.
#' @param ... Additional options. No options are currently available at this time.
#'
#' @return Does not return anything. It prints the conversation in the console.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
#' ohelp(first_prompt = "quit")
#' # regular usage: ohelp()
ohelp <- function(model = "codegemma:7b", ...) {

    if (!model_avail(model)) {
        return(invisible())
    }

    cat("Say something or type /q to quit or end the conversation.\n\n")

    n_messages <- 0
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
            messages <- create_message(prompt, role = 'user')
        } else {
            messages <- append(messages, create_message(prompt, role = 'user'))
        }
        n_messages <- n_messages + 1
        response <- chat(model, messages = messages, output = 'text', stream = TRUE)
        messages <- append_message(response, "assistant", messages)
        n_messages <- n_messages + 1
        prompt <- readline()
    }

    cat("Goodbye!\n")

}







#' Check if model is available locally.
#'
#' @param model A character string of the model name such as "llama3".
#'
#' @return A logical value indicating if the model exists.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
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
        cat(paste("Model", model, "does not exist. Please check available models with list_models() or download the model with pull().\n"))
    }
    return(exist)
}
