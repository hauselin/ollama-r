library(testthat)
library(ollamar)

test_that("chat function works with basic input", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

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
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Count to 5")
    )

    result <- chat("llama3", messages, stream = TRUE, output = "text")
    expect_type(result, "character")
    expect_true(nchar(result) > 0)
    expect_match(result, "1.*2.*3.*4.*5", all = FALSE)
})


test_that("chat function handles multiple messages", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

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
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Tell me a very short joke")
    )

    result_normal <- chat("llama3", messages, output = "text")
    result_creative <- chat("llama3", messages, output = "text", temperature = 2.0)

    expect_type(result_normal, "character")
    expect_type(result_creative, "character")
    expect_false(result_normal == result_creative)
    expect_error(chat("llama3", messages, output = "text", abc = 2.0))
})
