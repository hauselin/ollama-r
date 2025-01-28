library(testthat)
library(ollamar)

test_that("ps list running models endpoint", {
    skip_if_not(test_connection(logical = TRUE), "Ollama server not available")

    # load models first
    g1 <- generate('llama3', "tell me a 5 word story")

    result <- ps()
    expect_true(nrow(result) >= 1)
    expect_true(all(c("name", "size", "parameter_size", "quantization_level", "digest", "expires_at") %in% names(result)))
    expect_s3_class(ps("df"), "data.frame")
    expect_s3_class(ps("resp"), "httr2_response")
    expect_type(ps("jsonlist"), "list")
    expect_type(ps("text"), "character")
    expect_type(ps("raw"), "character")

    # resp_process
    result <- ps("resp")
    expect_s3_class(result, "httr2_response")
    expect_s3_class(resp_process(result, "resp"), "httr2_response")
    expect_s3_class(resp_process(result, "df"), "data.frame")
    expect_type(resp_process(result, "jsonlist"), "list")
    expect_type(resp_process(result, "text"), "character")
    expect_type(resp_process(result, "raw"), "character")

})
