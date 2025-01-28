library(testthat)
library(ollamar)

test_that("create function works with basic input", {
    skip_if_not(test_connection(logical = TRUE), "Ollama server not available")

    resp <- create("mario", "deepseek-r1:1.5b")
    expect_s3_class(resp, "httr2_response")
    expect_equal(resp$status_code, 200)
    expect_true(model_avail("mario"))

    delete("mario")
    expect_false(model_avail("mario"))
})
