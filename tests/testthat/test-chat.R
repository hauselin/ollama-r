library(testthat)
library(ollamar)

test_that("chat function works with basic input", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Hello! How are you?")
    )

    result <- chat("llama3", messages, output = "df")

    expect_s3_class(result, "data.frame")
    expect_true(all(c("model", "role", "content", "created_at") %in% names(result)))
    expect_equal(result$model[1], "llama3")
    expect_equal(result$role[1], "assistant")
    expect_true(nchar(result$content[1]) > 0)
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

test_that("chat function respects output parameter", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    messages <- list(
        list(role = "user", content = "Hello! How are you?")
    )

    result_jsonlist <- chat("llama3", messages, output = "jsonlist")
    expect_type(result_jsonlist, "list")
    expect_true(length(result_jsonlist) > 0)

    result_df <- chat("llama3", messages, output = "df")
    expect_s3_class(result_df, "data.frame")

    result_text <- chat("llama3", messages, output = "text")
    expect_type(result_text, "character")
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
})
