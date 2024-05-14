# https://github.com/ollama/ollama/blob/main/docs/modelfile.md#valid-parameters-and-values
model_options <- list(
    mirostat = list(
        description = "Enable Mirostat sampling for controlling perplexity.",
        default_value = 0
    ),
    mirostat_eta = list(
        description = "Influences how quickly the algorithm responds to feedback from the generated text. A lower learning rate will result in slower adjustments, while a higher learning rate will make the algorithm more responsive.",
        default_value = 0.1
    ),
    mirostat_tau = list(
        description = "Controls the balance between coherence and diversity of the output. A lower value will result in more focused and coherent text.",
        default_value = 5.0
    ),
    num_ctx = list(
        description = "Sets the size of the context window used to generate the next token.",
        default_value = 2048
    ),
    repeat_last_n = list(
        description = "Sets how far back for the model to look back to prevent repetition.",
        default_value = 64
    ),
    repeat_penalty = list(
        description = "Sets how strongly to penalize repetitions. A higher value (e.g., 1.5) will penalize repetitions more strongly, while a lower value (e.g., 0.9) will be more lenient.",
        default_value = 1.1
    ),
    temperature = list(
        description = "The temperature of the model. Increasing the temperature will make the model answer more creatively.",
        default_value = 0.8
    ),
    seed = list(
        description = "Sets the random number seed to use for generation. Setting this to a specific number will make the model generate the same text for the same prompt.",
        default_value = 0
    ),
    stop = list(
        description = "Sets the stop sequences to use. When this pattern is encountered the LLM will stop generating text and return. Multiple stop patterns may be set by specifying multiple separate `stop` parameters in a modelfile.",
        default_value = NULL
    ),
    tfs_z = list(
        description = "Tail free sampling is used to reduce the impact of less probable tokens from the output. A higher value (e.g., 2.0) will reduce the impact more, while a value of 1.0 disables this setting.",
        default_value = 1
    ),
    num_predict = list(
        description = "Maximum number of tokens to predict when generating text. (Default: 128, -1 = infinite generation, -2 = fill context)",
        default_value = 128
    ),
    top_k = list(
        description = "Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative.",
        default_value = 40
    ),
    top_p = list(
        description = "Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text.",
        default_value = 0.9
    )
)

check_option_valid <- function(opt) {
    return(opt %in% names(model_options))
}



check_options <- function(opts = NULL) {
    if (is.null(opts)) {
        return(names(model_options))
    }

    list_validity <- list(valid_options = character(), invalid_options = character())
    for (opt in opts) {
        if (check_option_valid(opt)) {
            list_validity$valid_options <- c(list_validity$valid_options, opt)
        } else {
            list_validity$invalid_options <- c(list_validity$invalid_options, opt)
        }
    }
    return(list_validity)
}


search_options <- function(query) {
    matching_options <- list()
    option_names <- names(model_options)
    for (option in option_names) {
        if (grepl(query, option, ignore.case = TRUE)) {
            matching_options[[option]] <- model_options[[option]]
            next
        }
        desc <- model_options[[option]]$description
        if (grepl(query, desc, ignore.case = TRUE)) {
            matching_options[[option]] <- model_options[[option]]
            next
        }
    }
    if (length(matching_options) == 0) {
        message("No matching options found")
    } else {
        message(paste0("Matching options: ", paste(names(matching_options), collapse = ", ")))
    }
    return(matching_options)
}






#' Validate additional options or parameters provided to the API call
#'
#' @param ... Additional options or parameters provided to the API call
#'
#' @return TRUE if all additional options are valid, FALSE otherwise
#' @examples
#' validate_options(mirostat = 1, mirostat_eta = 0.2, num_ctx = 1024)
#' validate_options(mirostat = 1, mirostat_eta = 0.2, invalid_opt = 1024)
validate_options <- function(...) {
    opts <- list(...)
    opts_validity <- check_options(names(opts))
    if (length(opts_validity$invalid_options > 0)) {
        invalid <- opts_validity$invalid_options
        valid <- opts_validity$valid_options
        cat(crayon::green( paste0("Valid options: ", paste0(valid, collapse = ", "), "\n") ) )
        cat(crayon::red( paste0("Invalid options: ", paste0(invalid, collapse = ", ", "\n") ) ) )
        cat(("See available options with check_options() or model_options.\nSee also https://github.com/ollama/ollama/blob/main/docs/modelfile.md#parameter\n"))
        return(FALSE)
    }
    # cat(crayon::green("All additional options provided to ... are valid\n"))
    return(TRUE)
}

