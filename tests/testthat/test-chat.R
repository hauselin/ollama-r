library(testthat)
library(ollamar)

test_that("chat function works with basic input", {
    skip_if_not(test_connection(), "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Tell me a 5-word story.")
    )

    # incorrect output type
    expect_error(chat("llama3", messages, output = "abc"))

    expect_s3_class(chat("llama3.1", messages, output = "req"), "httr2_request")

    # not streaming
    expect_s3_class(chat("llama3", messages), "httr2_response")
    expect_s3_class(chat("llama3", messages, output = "resp"), "httr2_response")
    expect_s3_class(chat("llama3", messages, output = "df"), "data.frame")
    expect_type(chat("llama3", messages, output = "jsonlist"), "list")
    expect_type(chat("llama3", messages, output = "text"), "character")
    expect_type(chat("llama3", messages, output = "raw"), "character")

    # streaming
    expect_s3_class(chat("llama3", messages, stream = TRUE), "httr2_response")
    expect_s3_class(chat("llama3", messages, stream = TRUE, output = "resp"), "httr2_response")
    expect_s3_class(chat("llama3", messages, stream = TRUE, output = "df"), "data.frame")
    expect_type(chat("llama3", messages, stream = TRUE, output = "jsonlist"), "list")
    expect_type(chat("llama3", messages, stream = TRUE, output = "text"), "character")
    expect_type(chat("llama3", messages, stream = TRUE, output = "raw"), "character")

    # resp_process
    # not streaming
    result <- chat("llama3", messages)
    expect_s3_class(result, "httr2_response")
    expect_s3_class(resp_process(result, "resp"), "httr2_response")
    expect_s3_class(resp_process(result, "df"), "data.frame")
    expect_type(resp_process(result, "jsonlist"), "list")
    expect_type(resp_process(result, "text"), "character")
    expect_type(resp_process(result, "raw"), "character")

    # streaming
    result <- chat("llama3", messages, stream = TRUE)
    expect_s3_class(result, "httr2_response")
    expect_s3_class(resp_process(result, "resp"), "httr2_response")
    expect_s3_class(resp_process(result, "df"), "data.frame")
    expect_type(resp_process(result, "jsonlist"), "list")
    expect_type(resp_process(result, "text"), "character")
    expect_type(resp_process(result, "raw"), "character")

    result <- chat("llama3", messages, output = "df")
    expect_s3_class(result, "data.frame")
    expect_true(all(c("model", "role", "content", "created_at") %in% names(result)))
    expect_equal(result$model[1], "llama3")
    expect_equal(result$role[1], "assistant")
})

test_that("chat function handles streaming correctly", {
    skip_if_not(test_connection(), "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Count to 5")
    )

    result <- chat("llama3", messages, stream = TRUE, output = "text")
    expect_type(result, "character")
    expect_true(nchar(result) > 0)
    expect_match(result, "1.*2.*3.*4.*5", all = FALSE)
})


test_that("chat function handles multiple messages", {
    skip_if_not(test_connection(), "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Hello!"),
        list(role = "assistant", content = "Hi! How can I help you?"),
        list(role = "user", content = "What's the capital of France?")
    )

    result <- chat("llama3", messages, output = "df")

    expect_s3_class(result, "data.frame")
    expect_equal(nrow(result), 1)  # Expecting one response
    expect_match(result$content[1], "Paris", ignore.case = TRUE)
})

test_that("chat function handles additional options", {
    skip_if_not(test_connection(), "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Tell me a very short joke")
    )

    result_normal <- chat("llama3", messages, output = "text")
    result_creative <- chat("llama3", messages, output = "text", temperature = 2.0)

    expect_type(result_normal, "character")
    expect_type(result_creative, "character")
    expect_error(chat("llama3", messages, output = "text", abc = 2.0))
})


test_that("chat function handles images in messages", {
    skip_if_not(test_connection(), "Ollama server not available")
    skip_if_not(model_avail("benzie/llava-phi-3"), "benzie/llava-phi-3 model not available")

    images <- c(file.path(system.file("extdata", package = "ollamar"), "image1.png"),
                file.path(system.file("extdata", package = "ollamar"), "image2.png"))

    # 1 image
    messages <- list(
        list(role = "system", content = "You have to evaluate what objects are in images."),
        list(role = "user", content = "what is in the image?", images = images[2])
    )

    result <- chat("benzie/llava-phi-3", messages, output = "text")
    expect_match(tolower(result), "cam")

    # multiple images
    messages <- list(
        list(role = "system", content = "You have to evaluate what objects are in the two images."),
        list(role = "user", content = "what objects are in the two separate images?", images = images)
    )

    result <- chat("benzie/llava-phi-3", messages, output = "text")
    expect_type(result, "character")
    expect_true(grepl("melon", tolower(result)) | grepl("cam", tolower(result)))

})


test_that("chat function tool calling", {
    skip_if_not(test_connection(), "Ollama server not available")

    add_two_numbers <- function(x, y) {
        return(x + y)
    }

    multiply_two_numbers <- function(x, y) {
        return(x * y)
    }

    tools <- list(list(type = "function",
                       "function" = list(
                           name = "add_two_numbers",
                           description = "add two numbers",
                           parameters = list(
                               type = "object",
                               required = list("x", "y"),
                               properties = list(
                                   x = list(class = "numeric", description = "first number"),
                                   y = list(class = "numeric", description = "second number")
                               )
                           )
                       )
    )
    )

    msg <- create_message("what is three plus one?")
    resp <- chat("llama3.1", msg, tools = tools, output = "tools")
    resp2 <- resp[[1]]
    expect_equal(resp2$name, "add_two_numbers")
    expect_equal(do.call(resp2$name, resp2$arguments), 4)

    tools <- list(list(type = "function",
                       "function" = list(
                           name = "multiply_two_numbers",
                           description = "multiply two numbers",
                           parameters = list(
                               type = "object",
                               required = list("x", "y"),
                               properties = list(
                                   x = list(class = "numeric", description = "first number"),
                                   y = list(class = "numeric", description = "second number")
                               )
                           )
                       )
    )
    )

    msg <- create_message("what is three times eleven?")
    resp <- chat("llama3.1", msg, tools = tools, output = "tools")
    resp2 <- resp[[1]]
    expect_equal(resp2$name, "multiply_two_numbers")
    expect_equal(do.call(resp2$name, resp2$arguments), 33)



    # test multiple tools
    msg <- create_message("add three plus four. then multiply by ten")
    tools <- list(list(type = "function",
                       "function" = list(
                           name = "add_two_numbers",
                           description = "add two numbers",
                           parameters = list(
                               type = "object",
                               required = list("x", "y"),
                               properties = list(
                                   x = list(class = "numeric", description = "first number"),
                                   y = list(class = "numeric", description = "second number")
                               )
                           )
                       )
                       ),
                  list(type = "function",
                       "function" = list(
                           name = "multiply_two_numbers",
                           description = "multiply two numbers",
                           parameters = list(
                               type = "object",
                               required = list("x", "y"),
                               properties = list(
                                   x = list(class = "numeric", description = "first number"),
                                   y = list(class = "numeric", description = "second number")
                               )
                           )
                       )
                  )
    )

    msg <- create_message("what is four plus five?")
    resp <- chat("llama3.1", msg, tools = tools, output = "tools")
    expect_equal(resp[[1]]$name, "add_two_numbers")

    msg <- create_message("what is four multiplied by five?")
    resp <- chat("llama3.1", msg, tools = tools, output = "tools")
    expect_equal(resp[[1]]$name, "multiply_two_numbers")

    # not a reliable test
    # msg <- create_message("three and four. sum the numbers then multiply the output by ten")
    # resp <- chat("llama3.1", msg, tools = tools, output = "tools")
    # expect_equal(resp[[1]]$name, "add_two_numbers")
    # expect_equal(resp[[2]]$name, "multiply_two_numbers")

})




test_that("structured output", {
    skip_if_not(test_connection(), "Ollama server not available")

    format <- list(
        type = "object",
        properties = list(
            name = list(
                type = "string"
            ),
            capital = list(
                type = "string"
            ),
            languages = list(
                type = "array",
                items = list(
                    type = "string"
                )
            )
        ),
        required = list("name", "capital", "languages")
    )

    msg <- create_message("tell me about canada")
    resp <- chat("llama3.1", msg, format = format)
    # content <- httr2::resp_body_json(resp)$message$content
    structured_output <- resp_process(resp, "structured")
    expect_equal(tolower(structured_output$name), "canada")

})


