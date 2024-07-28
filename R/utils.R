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
                } else if (endpoint == "/api/pull") {
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




#' Process httr2 response object.
#'
#' @param resp A httr2 response object.
#' @param output The output format. Default is "df". Other options are "jsonlist", "raw", "resp" (httr2 response object), "text"
#'
#' @return A data frame, json list, raw or httr2 response object.
#' @export
#'
#' @examplesIf test_connection()$status_code == 200
#' resp <- list_models("resp")
#' resp_process(resp, "df") # parse response to dataframe/tibble
#' resp_process(resp, "jsonlist") # parse response to list
#' resp_process(resp, "raw") # parse response to raw string
#' resp_process(resp, "resp") # return input response object
#' resp_process(resp, "text") # return text/character vector
resp_process <- function(resp, output = c("df", "jsonlist", "raw", "resp", "text")) {
    if (is.null(resp) || resp$status_code != 200) {
        warning("Cannot process response")
        return(NULL)
    }

    output <- output[1]
    if (output == "resp") {
        return(resp)
    }

    # process stream resp separately
    stream <- FALSE
    headers <- httr2::resp_headers(resp)
    transfer_encoding <- headers$`Transfer-Encoding` # if response is chunked, then it was a streamed output
    if (!is.null(transfer_encoding)) stream <- grepl("chunked", transfer_encoding)
    if (stream) {
        return(resp_process_stream(resp, output))
    }

    # process non-stream response below
    if (output == "raw") {
        return(httr2::resp_raw(resp))
    } else if (output == "jsonlist") {
        return(httr2::resp_body_json(resp))
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

        if (output == "df") {
            return(df_response)
        } else if (output == "text") {
            return(df_response$name)
        }
    }
}




#' Process httr2 response object for streaming.
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
    }  else if (grepl("api/chat", resp$url)) { # process chat endpoint
        return(NULL)  # TODO fill in
    } else if (grepl("api/tags", resp$url)) { # process tags endpoint {
        return(NULL)  # TODO fill in
    }

}






#' Read image file and encode it to base64.
#'
#' @param image_path The path to the image file.
#'
#' @return A base64 encoded string.
#' @export
#'
#' @examples
#' image_path <- file.path(system.file('extdata', package = "ollamar"), "image1.png")
#' image_encode_base64(image_path)
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
#'
#' @return A list of messages.
#' @export
#'
#' @examples
#' create_message("Hello", "user")
#' create_message("Always respond nicely", "system")
#' create_message("I am here to help", "assistant")
create_message <- function(content, role = "user") {
    message <- list(list(role = role, content = content))
    return(message)
}



#' Append message to a list
#'
#' Appends a message (add to end of a list) to a list of messages. The role and content will be converted to a list and appended to the input list.
#'
#' @param content  The content of the message.
#' @param role The role of the message. Can be "user", "system", "assistant". Default is "user".
#' @param x A list of messages. Default is NULL.
#'
#' @return A list of messages with the new message appended.
#' @export
#'
#' @examples
#' append_message("user", "Hello")
#' append_message("system", "Always respond nicely")
append_message <- function(content, role = "user", x = NULL) {
    if (is.null(x)) {
        x <- list()
    }
    new_message <- list(role = role, content = content)
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
#'
#' @return A list of messages with the new message prepended.
#' @export
#'
#' @examples
#' prepend_message("user", "Hello")
#' prepend_message("system", "Always respond nicely")
prepend_message <- function(content, role = "user", x = NULL) {
    if (is.null(x)) {
        x <- list()
    }
    new_message <- list(role = role, content = content)
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
insert_message <- function(content, role = "user", x = NULL, position = -1) {
    if (position == -1) position <- length(x) + 1
    new_message <- list(role = role, content = content)
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
