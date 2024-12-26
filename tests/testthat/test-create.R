library(testthat)
library(ollamar)

test_that("create function works with basic input", {
    skip_if_not(test_connection(), "Ollama server not available")

    expect_error(create("mario"))
    expect_error(create("mario", modelfile = "abc", path = "abc"))
    expect_error(create("mario", path = "abc"))

    resp <- create("mario", "FROM llama3\nSYSTEM You are mario from Super Mario Bros.")
    expect_s3_class(resp, "httr2_response")
    expect_equal(resp$status_code, 200)
    expect_true(model_avail("mario"))

    delete("mario")
    expect_false(model_avail("mario"))
})
