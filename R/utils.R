#' Process httr2 response object.
#'
#' @param resp A httr2 response object.
#' @param output The output format. Default is "df". Other options are "jsonlist", "raw", "resp" (httr2 response object).
#'
#' @return A data frame, json list, raw or httr2 response object.
#' @export
#'
#' @examples
#' \dontrun{
#' resp <- list_models("resp")
#' resp_process(resp, "df")  # parse response to dataframe/tibble
#' resp_process(resp, "jsonlist")  # parse response to list
#' resp_process(resp, "raw")  # parse response to raw string
#' resp_process(resp, "resp")  # return input response object
#' }
resp_process <- function(resp, output = c("df", "jsonlist", "raw", "resp")) {

    if (is.null(resp) || resp$status_code != 200) {
        warning("Cannot process response")
        return(NULL)
    }

    output <- output[1]
    if (output == "resp") {
        return(resp)
    } else if (output == "raw") {
        return(httr2::resp_raw(resp))
    } else if (output == "jsonlist") {
        return(httr2::resp_body_json(resp))
    }

    # convert data to data frame
    # process different endpoints
    if (grepl("api/tags", resp$url)) {

        json_body <- httr2::resp_body_json(resp)[[1]]
        df_response <- tibble::tibble(
            name = character(length(json_body)),
            model = character(length(json_body)),
            parameter_size = character(length(json_body)),
            quantization_level = character(length(json_body)))
        for (i in seq_along(json_body)) {
            df_response[i, 'name'] <- json_body[[i]]$name
            df_response[i, 'model'] <- json_body[[i]]$model
            df_response[i, 'parameter_size'] <- json_body[[i]]$details$parameter_size
            df_response[i, 'quantization_level'] <- json_body[[i]]$details$quantization_level
        }
        return(df_response)

    # process chat endpoint
    } else if (grepl("api/chat", resp$url)) {

        json_body <- httr2::resp_body_json(resp)
        df_response <- tibble::tibble(model = json_body$model,
                                role = json_body$message$role,
                                content = json_body$message$content,
                                created_at = json_body$created_at)

        return(df_response)

    # process generate endpoint
    } else if (grepl("api/generate", resp$url)) {

        json_body <- httr2::resp_body_json(resp)
        df_response <- tibble::tibble(model = json_body$model,
                                      response = json_body$response,
                                      created_at = json_body$created_at)

        return(df_response)
    }
}
