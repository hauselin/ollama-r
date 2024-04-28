#' Package configuration
#' @importFrom glue glue
package_config <- list(
    baseurls = c("http://localhost:11434", "http://127.0.0.1:11434"),
    package_version = packageVersion("ollamar"),
    user_agent = glue("ollama-r/{packageVersion('ollamar')} ({tolower(R.version$platform)}) R/{R.version$major}.{R.version$minor}")
)


#' Create a httr2 request object
#'
#' @param endpoint The endpoint to create the request
#'
#' @return A httr2 request object.
#' @export
#'
#' @examples
#' create_request("/api/tags")
create_request <- function(endpoint) {
    for (url in package_config$baseurls) {
        url <- httr2::url_parse(url)
        url$path <- endpoint
        req <- httr2::request(httr2::url_build(url))
        headers <- list(content_type = "application/json",
                        accept = "application/json",
                        user_agent = package_config$user_agent)
        req <- httr2::req_headers(req, !!!headers)
        return(req)
    }
}



#' Get available local models
#'
#' @param output The output format. Default is "df". Other options are "resp", "jsonlist", "raw".
#' @param endpoint The endpoint to get the models. Default is "/api/tags".
#'
#' @return A httr2 response object, json list, raw or data frame. Default is "df".
#' @export
#'
#' @examples
#' \dontrun{
#' list_models()  # returns dataframe/tibble by default
#' list_models("df")
#' list_models("resp")
#' list_models("jsonlist")
#' list_models("raw")
#' }
list_models <- function(output = c("df", "resp", "jsonlist", "raw"), endpoint = "/api/tags") {

    req <- create_request(endpoint)
    req <- httr2::req_method(req, "GET")
    tryCatch({
        resp <- httr2::req_perform(req)
        print(resp)
        return(resp_process(resp = resp, output = output[1]))
    }, error = function(e) {
        stop(e)
    })
}



#' Chat with Ollama models
#'
#' @param model A character string of the model name such as "llama3".
#' @param messages A list with list of messages for the model (see examples below).
#' @param stream Enable response streaming. Default is FALSE.
#' @param output The output format. Default is "resp". Other options are "jsonlist", "raw", "df".
#' @param endpoint The endpoint to chat with the model. Default is "/api/chat".
#'
#' @return A httr2 response object, json list, raw or data frame.
#' @export
#'
#' @examples
#' \dontrun{
#' # one message
#' messages <- list(
#'  list(role = "user", content = "How are you doing?")
#' )
#' chat("llama3", messages)
#' chat("llama3", messages, stream = TRUE)
#' chat("llama3", messages, stream = TRUE, output = "df")
#'
#' # multiple messages
#' messages <- list(
#'  list(role = "user", content = "Hello!"),
#'  list(role = "assistant", content = "Hi! How are you?"),
#'  list(role = "user", content = "Who is the prime minister of the uk?"),
#'  list(role = "assistant", content = "Rishi Sunak"),
#'  list(role = "user", content = "List all the previous messages.")
#' )
#' chat("llama3", messages, stream = TRUE)
#' }
chat <- function(model, messages, stream = FALSE, output = c("resp", "jsonlist", "raw", "df"), endpoint = "/api/chat") {

    req <- create_request(endpoint)
    req <- httr2::req_method(req, "POST")

    body_json <- list(model = model,
                      stream = stream,
                      messages = messages)
    req <- httr2::req_body_json(req, body_json)

    content <- ""
    if (!stream) {
        tryCatch({
            resp <- httr2::req_perform(req)
            print(resp)
            return(resp_process(resp = resp, output = output[1]))
        }, error = function(e) {
            stop(e)
        })
    }

    # streaming
    buffer <- ""
    content <- ""
    accumulated_data <- raw()
    stream_handler <- function(x) {
        s <- rawToChar(x)
        accumulated_data <<- append(accumulated_data, x)
        json_strings <- strsplit(s, '\n')[[1]]

        for (i in seq_along(json_strings)) {
            tryCatch({
                json_string <- paste0(buffer, json_strings[i], "\n", collapse = "")
                stream_content <- jsonlite::fromJSON(json_string)$message$content
                content <<- c(content, stream_content)
                buffer <<- ""
                # stream/print stream
                cat(stream_content)
            }, error = function(e) {
                buffer <<- paste0(buffer, json_strings[i])
            })
        }
        return(TRUE)
    }
    resp <- httr2::req_perform_stream(req, stream_handler, buffer_kb = 1)
    cat("\n\n")

    # process treaming output
    json_lines <- strsplit(rawToChar(accumulated_data), "\n")[[1]]
    json_lines_output <- vector("list", length = length(json_lines))
    df_response <- tibble::tibble(
        model = character(length(json_lines_output)),
        role = character(length(json_lines_output)),
        content = character(length(json_lines_output)),
        created_at = character(length(json_lines_output))
    )

    if (output[1] == "raw") {
        return(rawToChar(accumulated_data))
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

    return(resp)
}






#' Pull/download a model
#'
#' See https://ollama.com/library for a list of available models. Use the list_models() function to get the list of models already downloaded/installed on your machine.
#'
#' @param model A character string of the model name such as "llama3".
#' @param stream Enable response streaming. Default is TRUE.
#' @param endpoint The endpoint to pull the model. Default is "/api/pull".
#'
#' @return A httr2 response object.
#' @export
#'
#' @examples
#' \dontrun{
#' pull("llama3")
#' pull("llama3", stream = FALSE)
#" pull("all-minilm")
#' }
pull <- function(model, stream = TRUE, endpoint = "/api/pull") {
    req <- create_request(endpoint)
    req <- httr2::req_method(req, "POST")

    body_json <- list(model = model, stream = stream)
    req <- httr2::req_body_json(req, body_json)

    content <- ""
    if (!stream) {
        tryCatch({
            resp <- httr2::req_perform(req)
            print(resp)
            return(resp)
        }, error = function(e) {
            stop(e)
        })
    }

    # streaming
    buffer <- ""
    content <- ""
    accumulated_data <- raw()
    stream_handler <- function(x) {
        s <- rawToChar(x)
        accumulated_data <<- append(accumulated_data, x)
        json_strings <- strsplit(s, '\n')[[1]]

        for (i in seq_along(json_strings)) {
            tryCatch({
                json_string <- paste0(buffer, json_strings[i], "\n", collapse = "")
                stream_content <- jsonlite::fromJSON(json_string)$status
                content <<- c(content, stream_content)
                buffer <<- ""
                # stream/print stream
                cat(stream_content, "\n")
            }, error = function(e) {
                buffer <<- paste0(buffer, json_strings[i])
            })
        }
        return(TRUE)
    }
    resp <- httr2::req_perform_stream(req, stream_handler, buffer_kb = 1)
    return(resp)
}



#' Delete a model
#'
#' Delete a model from your local machine that you downlaoded using the pull() function. To see which models are available, use the list_models() function.
#'
#' @param model A character string of the model name such as "llama3".
#' @param endpoint The endpoint to delete the model. Default is "/api/delete".
#'
#' @return A httr2 response object.
#' @export
#'
#' @examples
#' \dontrun{
#' delete("llama3")
#' }
delete <- function(model, endpoint = "/api/delete") {
    req <- create_request(endpoint)
    req <- httr2::req_method(req, "DELETE")
    body_json <- list(model = model)
    req <- httr2::req_body_json(req, body_json)

    tryCatch({
        resp <- httr2::req_perform(req)
        print(resp)
        return(resp)
    }, error = function(e) {
        message("Model not found and cannot be deleted. Please check the model name with list_models() and try again.")
    })
}



#' Get vector embedding for a prompt
#'
#' @param model A character string of the model name such as "llama3".
#' @param prompt A character string of the prompt that you want to get the vector embedding for.
#' @param endpoint The endpoint to get the vector embedding. Default is "/api/embeddings".
#'
#' @return A numeric vector of the embedding.
#' @export
#'
#' @examples
#' \dontrun{
#' get_embeddings("gemma:latest", "The quick brown fox jumps over the lazy dog.")
#' }
embeddings <- function(model, prompt, endpoint = "/api/embeddings") {
    req <- create_request(endpoint)
    req <- httr2::req_method(req, "POST")

    body_json <- list(model = model, prompt = prompt)
    req <- httr2::req_body_json(req, body_json)

    tryCatch({
        resp <- httr2::req_perform(req)
        print(resp)
        return(unlist(resp_process(resp, "jsonlist")$embedding))
    }, error = function(e) {
        stop(e)
    })
}
