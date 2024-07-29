library(testthat)
library(ollamar)

test_that("push function works with basic input", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")
})
