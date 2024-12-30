library(testthat)
library(ollamar)

test_that("delete function works", {
    skip_if_not(test_connection(logical = TRUE), "Ollama server not available")

    # wrong model
    expect_invisible(delete("sdafds"))
})

