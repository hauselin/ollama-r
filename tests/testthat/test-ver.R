library(testthat)
library(ollamar)

test_that("ps list running models endpoint", {
    skip_if_not(test_connection(logical = TRUE), "Ollama server not available")

    expect_type(ver(), "character")
})
