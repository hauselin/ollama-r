library(testthat)
library(ollamar)

test_that("test_connection function works", {
    skip_if_not(test_connection(), "Ollama server not available")
    expect_equal(test_connection(), TRUE)
    expect_equal(test_connection(url = "dsfdsf"), FALSE)
})
