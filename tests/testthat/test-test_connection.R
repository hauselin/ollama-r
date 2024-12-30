library(testthat)
library(ollamar)

test_that("test_connection function works", {
    skip_if_not(test_connection(logical = TRUE), "Ollama server not available")

    expect_equal(test_connection()$status_code, 200)
    expect_equal(test_connection(logical = TRUE), TRUE)
    expect_equal(test_connection(url = "dsfdsf")$status_code, 503)
})
