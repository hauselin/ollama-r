library(testthat)
library(ollamar)

test_that("pull function works", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    # wrong model
    result <- pull('WRONGMODEL')
    expect_s3_class(result, "httr2_response")
    expect_equal(result$status_code, 200)
    expect_vector(result$body)

    # correct model
    result <- pull('llama3')
    expect_s3_class(result, "httr2_response")
    expect_equal(result$status_code, 200)
    expect_vector(result$body)
})

