library(testthat)
library(ollamar)

test_that("pull function works", {
    skip_if_not(test_connection(), "Ollama server not available")

    # streaming is FALSE by default
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

    expect_s3_class(result, "httr2_response")
    expect_s3_class(resp_process(result), "data.frame")
    expect_s3_class(resp_process(result, "df"), "data.frame")
    expect_type(resp_process(result, "text"), "character")
    expect_type(resp_process(result, "raw"), "character")
    expect_type(resp_process(result, "jsonlist"), "list")

    # streaming TRUE
    result <- pull('WRONGMODEL', stream = TRUE)
    expect_s3_class(result, "httr2_response")
    expect_equal(result$status_code, 200)
    expect_vector(result$body)

    # correct model
    result <- pull('llama3', stream = TRUE)
    # for this endpoint, even when stream = FALSE, the response is chunked)
    expect_true(httr2::resp_headers(result)$`Transfer-Encoding` == "chunked")
    expect_s3_class(result, "httr2_response")
    expect_equal(result$status_code, 200)
    expect_vector(result$body)

    expect_s3_class(result, "httr2_response")
    expect_s3_class(resp_process(result), "data.frame")
    expect_s3_class(resp_process(result, "df"), "data.frame")
    expect_type(resp_process(result, "text"), "character")
    expect_type(resp_process(result, "raw"), "character")
    expect_type(resp_process(result, "jsonlist"), "list")

    # insecure parameter
    expect_s3_class(pull('llama3', stream = FALSE, insecure = TRUE), "httr2_response")
    expect_s3_class(pull('sdafd', stream = FALSE, insecure = FALSE), "httr2_response")
    expect_s3_class(pull('sdafd', stream = TRUE, insecure = TRUE), "httr2_response")
    expect_s3_class(pull('sdafd', stream = TRUE, insecure = FALSE), "httr2_response")

})

