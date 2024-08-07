library(testthat)
library(ollamar)

test_that("model_avail function works with basic input", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    expect_false(model_avail("test"))
    expect_true(model_avail("llama3"))
})
