library(testthat)
library(ollamar)

test_that("list_models function works", {
    skip_if_not(test_connection(logical = TRUE), "Ollama server not available")

    # incorrect output type
    expect_error(list_models("sdf"))

    result <- list_models()
    expect_s3_class(result, "data.frame")
    expect_true(all(c("name", "size", "parameter_size", "quantization_level", "modified") %in% names(result)))

    expect_s3_class(list_models("df"), "data.frame")
    expect_s3_class(list_models("resp"), "httr2_response")
    expect_type(list_models("jsonlist"), "list")
    expect_type(list_models("raw"), "character")
    expect_type(list_models("text"), "character")
})
