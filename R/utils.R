#' Test connection to Ollama server
#'
#' @description
#' Tests whether the Ollama server is running or not.
#'
#' @param url The URL of the Ollama server. Default is http://localhost:11434
#' @param logical Logical. If TRUE, returns a boolean value. Default is FALSE.
#'
#' @return Boolean value or httr2 response object, where status_code is either 200 (success) or 503 (error).
#' @export
#'
#' @examples
#' test_connection(logical = TRUE)
#' test_connection("http://localhost:11434") # default url
#' test_connection("http://127.0.0.1:11434")
test_connection <- function(url = "http://localhost:11434", logical = FALSE) {
    req <- httr2::request(url)
    req <- httr2::req_method(req, "GET")

    tryCatch(
        {
            resp <- httr2::req_perform(req)
            message("Ollama local server running")
            if (logical) {
                return(TRUE)
            } else {
                return(resp)
            }
        },
        error = function(e) {
            message("Ollama local server not running or wrong server.\nDownload and launch Ollama app to run the server. Visit https://ollama.com or https://github.com/ollama/ollama")
            if (logical) {
                return(FALSE)
            } else {
                return(httr2::response(status_code = 503, url = url))
            }
        }
    )
}








#' Stream handler helper function
#'
#' Function to handle streaming.
#'
#' @keywords internal
stream_handler <- function(x, env, endpoint) {
    s <- rawToChar(x)
    env$accumulated_data <- append(env$accumulated_data, x)
    json_strings <- strsplit(s, "\n")[[1]]
    for (i in seq_along(json_strings)) {
        tryCatch(
            {
                json_string <- paste0(env$buffer, json_strings[i], "\n", collapse = "")
                if (endpoint == "/api/generate") {
                    stream_content <- jsonlite::fromJSON(json_string)$response
                } else if (endpoint == "/api/chat") {
                    stream_content <- jsonlite::fromJSON(json_string)$message$content
                } else if (endpoint %in% c("/api/pull", "/api/push")) {
                    stream_content <- jsonlite::fromJSON(json_string)$status
                    stream_content <- paste0(stream_content, "\n")
                }
                # concatenate the content
                env$content <- c(env$content, stream_content)
                env$buffer <- ""
                cat(stream_content) # stream/print stream
            },
            error = function(e) {
                env$buffer <- paste0(env$buffer, json_strings[i])
            }
        )
    }
    return(TRUE)
}






#' Get tool calls helper function
#'
#' Get tool calls from response object.
#'
#' @keywords internal
get_tool_calls <- function(resp) {
    body <- httr2::resp_body_json(resp)
    tools <- list()
    tools_called <- c()
    tools_list <- c()
    if (!is.null(body$message)) {
        if (!is.null(body$message$tool_calls)) {
            tools <- body$message$tool_calls
            tools_list <- list()
            if (length(tools) > 0) {
                for (i in seq_along(tools)) {
                    func <- tools[[i]]$`function`
                    func_name <- func$name
                    tools_list[[i]] <- func
                    tools_called <- c(tools_called, func_name)
                }
            }
            tools_called <- unique(tools_called)
            message(paste0("Tools called: ", paste0(tools_called, collapse = ", ")))
        }
    }

    return(tools_list)
}





#' Process httr2 response object
#'
#' @param resp A httr2 response object.
#' @param output The output format. Default is "df". Other options are "jsonlist", "raw", "resp" (httr2 response object), "text", "tools" (tool_calls), "structured" (structured output).
#'
#' @return A data frame, json list, raw or httr2 response object.
#' @export
#'
#' @examplesIf test_connection(logical = TRUE)
#' resp <- list_models("resp")
#' resp_process(resp, "df") # parse response to dataframe/tibble
#' resp_process(resp, "jsonlist") # parse response to list
#' resp_process(resp, "raw") # parse response to raw string
#' resp_process(resp, "text") # return text/character vector
#' resp_process(resp, "tools") # return tool_calls
resp_process <- function(resp, output = c("df", "jsonlist", "raw", "resp", "text", "tools")) {
    if (!inherits(resp, "httr2_response")) {
        stop("Input must be a httr2 response object")
    }

    if (is.null(resp) || resp$status_code != 200) {
        stop("Cannot process response")
    }

    endpoints_to_skip <- c("api/delete", "api/embed", "api/embeddings", "api/create")
    for (endpoint in endpoints_to_skip) {
        if (grepl(endpoint, resp$url)) {
            message("Returning response object because resp_process not supported for this endpoint.")
            return(resp)
        }
    }

    output <- output[1]
    if (output == "resp") {
        return(resp)
    }

    if (output == "tools") {
        return(get_tool_calls(resp))
    }

    # process stream resp separately
    stream <- FALSE
    headers <- httr2::resp_headers(resp)
    # if response is chunked, then it was a streamed output
    transfer_encoding <- headers$`Transfer-Encoding`
    if (!is.null(transfer_encoding)) {
        stream <- grepl("chunked", transfer_encoding)
    }

    # endpoints that should never be processed with resp_process_stream
    endpoints_without_stream <- c("api/tags", "api/delete", "api/show", "api/ps")
    for (endpoint in endpoints_without_stream) {
        if (grepl(endpoint, resp$url)) {
            stream <- FALSE
            break
        }
    }
    if (stream) {
        return(resp_process_stream(resp, output))
    }

    # process non-stream response below
    if (output == "raw") {
        return(rawToChar(resp$body))
    } else if (output == "jsonlist") {
        tryCatch(
            {
                return(httr2::resp_body_json(resp))
            },
            error = function(e) {}
        )
    }

    # process different endpoints
    if (grepl("api/generate", resp$url)) { # process generate endpoint
        json_body <- httr2::resp_body_json(resp)
        df_response <- tibble::tibble(
            model = json_body$model,
            response = json_body$response,
            created_at = json_body$created_at
        )

        if (output == "df") {
            return(df_response)
        } else if (output == "text") {
            return(df_response$response)
        } else if (output == "structured") {
            return(jsonlite::fromJSON(df_response$response))
        }
    } else if (grepl("api/chat", resp$url)) { # process chat endpoint
        json_body <- httr2::resp_body_json(resp)
        df_response <- tibble::tibble(
            model = json_body$model,
            role = json_body$message$role,
            content = json_body$message$content,
            created_at = json_body$created_at
        )

        if (output == "df") {
            return(df_response)
        } else if (output == "text") {
            return(df_response$content)
        } else if (output == "structured") {
            return(jsonlite::fromJSON(df_response$content))
        }
    } else if (grepl("api/tags", resp$url)) { # process tags endpoint
        json_body <- httr2::resp_body_json(resp)[[1]]
        df_response <- tibble::tibble(
            name = character(length(json_body)),
            size = character(length(json_body)),
            parameter_size = character(length(json_body)),
            quantization_level = character(length(json_body)),
            modified = character(length(json_body))
        )
        for (i in seq_along(json_body)) {
            df_response[i, "name"] <- json_body[[i]]$name
            size <- json_body[[i]]$size / 10^9
            df_response[i, "size"] <- ifelse(size > 1, paste0(round(size, 1), " GB"), paste0(round(size * 1000), " MB"))
            df_response[i, "parameter_size"] <- json_body[[i]]$details$parameter_size
            df_response[i, "quantization_level"] <- json_body[[i]]$details$quantization_level
            df_response[i, "modified"] <- strsplit(json_body[[i]]$modified_at, ".", fixed = TRUE)[[1]][1]
        }

        df_response <- df_response[order(df_response$name, df_response$size), ]

        if (output == "df") {
            return(data.frame(df_response))
        } else if (output == "text") {
            return(df_response$name)
        }
    } else if (grepl("api/show", resp$url)) {
        if (output %in% c("df", "text")) stop("Output format not supported for this endpoint: Only 'jsonlist' and 'raw' are supported.")
    } else if (grepl("api/ps", resp$url)) {
        json_body <- httr2::resp_body_json(resp)$models
        df_response <- tibble::tibble(
            name = character(length(json_body)),
            size = character(length(json_body)),
            parameter_size = character(length(json_body)),
            quantization_level = character(length(json_body)),
            digest = character(length(json_body)),
            expires_at = character(length(json_body)),
        )

        for (i in seq_along(json_body)) {
            df_response[i, "name"] <- json_body[[i]]$name
            size <- json_body[[i]]$size / 10^9
            df_response[i, "size"] <- ifelse(size > 1, paste0(round(size, 1), " GB"), paste0(round(size * 1000), " MB"))
            df_response[i, "parameter_size"] <- json_body[[i]]$details$parameter_size
            df_response[i, "quantization_level"] <- json_body[[i]]$details$quantization_level
            df_response[i, "digest"] <- json_body[[i]]$details$parameter_size
            df_response[i, "expires_at"] <- json_body[[i]]$expires_at
        }

        if (output == "df") {
            return(data.frame(df_response))
        } else if (output == "text") {
            return(df_response$name)
        }
    } else if (grepl("api/version", resp$url)) {
        return(httr2::resp_body_json(resp)$version)
    }
}




#' Process httr2 response object for streaming
#'
#' @keywords internal
resp_process_stream <- function(resp, output) {
    if (output == "raw") {
        return(rawToChar(resp$body))
    }

    if (grepl("api/generate", resp$url)) { # process generate endpoint
        json_lines <- strsplit(rawToChar(resp$body), "\n")[[1]]
        json_lines_output <- vector("list", length = length(json_lines))
        df_response <- tibble::tibble(
            model = character(length(json_lines_output)),
            response = character(length(json_lines_output)),
            created_at = character(length(json_lines_output))
        )

        for (i in seq_along(json_lines)) {
            json_lines_output[[i]] <- jsonlite::fromJSON(json_lines[[i]])
            df_response$model[i] <- json_lines_output[[i]]$model
            df_response$response[i] <- json_lines_output[[i]]$response
            df_response$created_at[i] <- json_lines_output[[i]]$created_at
        }

        if (output == "jsonlist") {
            return(json_lines_output)
        }
        if (output == "df") {
            return(df_response)
        }
        if (output == "text") {
            return(paste0(df_response$response, collapse = ""))
        }
    } else if (grepl("api/chat", resp$url)) { # process chat endpoint
        json_lines <- strsplit(rawToChar(resp$body), "\n")[[1]]
        json_lines_output <- vector("list", length = length(json_lines))
        df_response <- tibble::tibble(
            model = character(length(json_lines_output)),
            role = character(length(json_lines_output)),
            content = character(length(json_lines_output)),
            created_at = character(length(json_lines_output))
        )

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
    } else if (grepl("api/pull", resp$url)) {
        json_lines <- strsplit(rawToChar(resp$body), "\n")[[1]]
        json_lines_output <- vector("list", length = length(json_lines))
        df_response <- tibble::tibble(
            status = character(length(json_lines_output)),
        )

        for (i in seq_along(json_lines)) {
            json_lines_output[[i]] <- jsonlite::fromJSON(json_lines[[i]])
            df_response$status[i] <- json_lines_output[[i]]$status
        }

        if (output[1] == "jsonlist") {
            return(json_lines_output)
        }
        if (output[1] == "df") {
            return(df_response)
        }
        if (output[1] == "text") {
            return(paste0(df_response$status, collapse = ""))
        }
    } else if (grepl("api/push", resp$url)) {
        json_lines <- strsplit(rawToChar(resp$body), "\n")[[1]]

        json_lines_output <- vector("list", length = length(json_lines))
        df_response <- tibble::tibble(
            status = character(length(json_lines_output))
        )

        for (i in seq_along(json_lines)) {
            json_lines_output[[i]] <- jsonlite::fromJSON(json_lines[i])
            if (grepl("error", json_lines[i])) {
                df_response$status[i] <- "error"
            } else if (grepl("success", json_lines[i])) {
                df_response$status[i] <- "success"
            } else {
                df_response$status[i] <- json_lines_output[[i]]$status
            }
        }

        if (output[1] == "jsonlist") {
            return(json_lines_output)
        }
        if (output[1] == "df") {
            return(df_response)
        }
        if (output[1] == "text") {
            return(paste0(df_response$status, collapse = ""))
        }
    }
}






#' Read image file and encode it to base64
#'
#' @param image_path The path to the image file.
#'
#' @return A base64 encoded string.
#' @export
#'
#' @examples
#' image_path <- file.path(system.file("extdata", package = "ollamar"), "image1.png")
#' substr(image_encode_base64(image_path), 1, 5) # truncate output
image_encode_base64 <- function(image_path) {
    if (!file.exists(image_path)) {
        stop("Image file does not exist.")
    }
    img_raw <- readBin(image_path, "raw", file.info(image_path)$size)
    return(base64enc::base64encode(img_raw))
}















#' Create a message
#'
#' @param content The content of the message.
#' @param role The role of the message. Can be "user", "system", "assistant". Default is "user".
#' @param ... Additional arguments such as images.
#'
#' @return A list of messages.
#' @export
#'
#' @examples
#' create_message("Hello", "user")
#' create_message("Always respond nicely", "system")
#' create_message("I am here to help", "assistant")
create_message <- function(content, role = "user", ...) {
    message <- list(c(list(role = role, content = content), list(...)))
    return(message)
}



#' Append message to a list
#'
#' Appends a message (add to end of a list) to a list of messages. The role and content will be converted to a list and appended to the input list.
#'
#' @param content  The content of the message.
#' @param role The role of the message. Can be "user", "system", "assistant". Default is "user".
#' @param x A list of messages. Default is NULL.
#' @param ... Additional arguments such as images.
#'
#' @return A list of messages with the new message appended.
#' @export
#'
#' @examples
#' append_message("user", "Hello")
#' append_message("system", "Always respond nicely")
append_message <- function(content, role = "user", x = NULL, ...) {
    if (is.null(x)) {
        x <- list()
    }
    new_message <- c(list(role = role, content = content), list(...))
    x[[length(x) + 1]] <- new_message
    return(x)
}


#' Prepend message to a list
#'
#' Prepends a message (add to beginning of a list) to a list of messages.
#' The role and content will be converted to a list and prepended to the input list.
#'
#' @param content  The content of the message.
#' @param role The role of the message. Can be "user", "system", "assistant".
#' @param x A list of messages. Default is NULL.
#' @param ... Additional arguments such as images.
#'
#' @return A list of messages with the new message prepended.
#' @export
#'
#' @examples
#' prepend_message("user", "Hello")
#' prepend_message("system", "Always respond nicely")
prepend_message <- function(content, role = "user", x = NULL, ...) {
    if (is.null(x)) {
        x <- list()
    }
    new_message <- c(list(role = role, content = content), list(...))
    x <- c(list(new_message), x) # Prepend by combining the new message with the existing list
    return(x)
}



#' Insert message into a list at a specified position
#'
#' Inserts a message at a specified position in a list of messages.
#' The role and content are converted to a list and inserted into the input list at the given position.
#'
#' @param content The content of the message.
#' @param role The role of the message. Can be "user", "system", "assistant". Default is "user".
#' @param x A list of messages. Default is NULL.
#' @param position The position at which to insert the new message. Default is -1 (end of list).
#' @param ... Additional arguments such as images.
#'
#' @return A list of messages with the new message inserted at the specified position.
#' @export
#'
#' @examples
#' messages <- list(
#'     list(role = "system", content = "Be friendly"),
#'     list(role = "user", content = "How are you?")
#' )
#' insert_message("INSERT MESSAGE AT THE END", "user", messages)
#' insert_message("INSERT MESSAGE AT THE BEGINNING", "user", messages, 2)
insert_message <- function(content, role = "user", x = NULL, position = -1, ...) {
    if (position == -1) position <- length(x) + 1
    new_message <- c(list(role = role, content = content), list(...))
    if (is.null(x)) {
        return(list(new_message))
    }
    if (position == 1) {
        return(prepend_message(content, role, x))
    }
    if (position == length(x) + 1) {
        return(append_message(content, role, x))
    }
    x <- c(x[1:(position - 1)], list(new_message), x[position:length(x)])

    return(x)
}




#' Delete a message in a specified position from a list
#'
#' Delete a message using positive or negative positions/indices.
#' Negative positions/indices can be used to refer to
#' elements/messages from the end of the sequence.
#'
#' @param x A list of messages.
#' @param position The position of the message to delete.
#'
#' @return A list of messages with the message at the specified position removed.
#' @export
#'
#' @examples
#' messages <- list(
#'     list(role = "system", content = "Be friendly"),
#'     list(role = "user", content = "How are you?")
#' )
#' delete_message(messages, 1) # delete first message
#' delete_message(messages, -2) # same as above (delete first message)
#' delete_message(messages, 2) # delete second message
#' delete_message(messages, -1) # same as above (delete second message)
delete_message <- function(x, position = -1) {
    if (position == 0 || abs(position) > length(x)) {
        stop("Position out of valid range.")
    }
    if (position < 0) position <- length(x) + position + 1
    return(x[-position])
}




#' Validate a message
#'
#' Validate a message to ensure it has the required fields and the correct data types for the `chat()` function.
#' @param message A list with a single message of list class.
#'
#' @return TRUE if message is valid, otherwise an error is thrown.
#' @export
#'
#' @examples
#' validate_message(create_message("Hello"))
#' validate_message(list(role = "user", content = "Hello"))
validate_message <- function(message) {
    # if message is a list of messages, extract the first message
    # likely created by create_message()
    if (is.list(message) & all(c("role", "content") %in% names(message[[1]]))) {
        message <- message[[1]]
    }

    if (!is.list(message)) {
        stop("Message must be list.")
    }
    if (!all(c("role", "content") %in% names(message))) {
        stop("Message must have role and content.")
    }
    if (!is.character(message$role)) {
        stop("Message role must be character.")
    }
    if (!is.character(message$content)) {
        stop("Message content must be character.")
    }
    return(TRUE)
}







#' Create a list of messages
#'
#' Create messages for `chat()` function.
#'
#' @param ... A list of messages, each of list class.
#'
#' @return A list of messages, each of list class.
#' @export
#'
#' @examples
#' messages <- create_messages(
#'     create_message("be nice", "system"),
#'     create_message("tell me a 3-word joke")
#' )
#'
#' messages <- create_messages(
#'     list(role = "system", content = "be nice"),
#'     list(role = "user", content = "tell me a 3-word joke")
#' )
create_messages <- function(...) {
    messages <- list(...)
    for (i in 1:length(messages)) {
        message <- messages[[i]]
        # in case message is in a nested list created by create_message()
        if (is.null(names(message))) {
            if (validate_message(message[[1]])) {
                message <- message[[1]]
                messages[[i]] <- message
            }
        }
        if (validate_message(message)) {
            next
        }
    }
    return(messages)
}













#' Validate a list of messages
#'
#' Validate a list of messages to ensure they have the required fields and the correct data types for the `chat()` function.
#'
#' @param messages A list of messages, each of list class.
#'
#' @return TRUE if all messages are valid, otherwise warning messages are printed and FALSE is returned.
#' @export
#'
#' @examples
#' validate_messages(create_messages(
#'     create_message("Be friendly", "system"),
#'     create_message("Hello")
#' ))
validate_messages <- function(messages) {
    status <- TRUE
    for (i in 1:length(messages)) {
        tryCatch(
            {
                validate_message(messages[[i]])
            },
            error = function(e) {
                status <<- FALSE
                message(paste0("Message ", i, ": ", conditionMessage(e)))
            }
        )
    }
    return(status)
}



#' Encode images in messages to base64 format
#'
#' @param messages A list of messages, each of list class. Generally used in the `chat()` function.
#'
#' @return A list of messages with images encoded in base64 format.
#' @export
#'
#' @examples
#' image <- file.path(system.file("extdata", package = "ollamar"), "image1.png")
#' message <- create_message(content = "what is in the image?", images = image)
#' message_updated <- encode_images_in_messages(message)
encode_images_in_messages <- function(messages) {
    if (!validate_messages(messages)) {
        stop("Invalid messages.")
    }

    for (i in 1:length(messages)) {
        message <- messages[[i]]
        if ("images" %in% names(message)) {
            images <- message$images
            if (images[1] != "") {
                message$images <- lapply(images, image_encode_base64)
                messages[[i]] <- message
            } else {
                next
            }
        }
    }

    # revalidate messages
    if (!validate_messages(messages)) {
        stop("Invalid messages.")
    }

    return(messages)
}















#' Get last response
#'
#' Get and print the last response for debugging or when catching errors.
#'
#' @return Last httr2 response or NULL.
#' @export
#'
#' @examples test_connection(logical = TRUE)
#' last_response()
last_response <- function() {
    failed_resp <- httr2::last_response()
    print(failed_resp$headers)
    if (is.null(failed_resp)) {
        return(NULL)
    }
    tryCatch(
        {
            body <- httr2::resp_body_json(failed_resp)
            print(body)
        },
        error = function(e_body) {
            cat(httr2::resp_body_string(failed_resp), "\n")
        }
    )
    return(failed_resp)
}
