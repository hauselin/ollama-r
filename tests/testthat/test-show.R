library(testthat)
library(ollamar)

test_that("show function works", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    result <- show("llama3", output = "resp")
    expect_s3_class(result, "httr2_response")
    expect_equal(result$status_code, 200)
    expect_type(show("llama3"), "list")

    # wrong model
    expect_error(show("llama333"))

    expect_s3_class(show("llama3", output = "resp"), "httr2_response")
    expect_type(show("llama3", output = "jsonlist"), "list")
    expect_type(show("llama3", output = "raw"), "character")

    # wrong output type
    expect_error(show("llama3", output = "df"))
    expect_error(show("llama3", output = "abc"))
    expect_error(show("llama3", output = "text"))

    # resp_process
    result <- show("llama3", output = "resp")
    expect_s3_class(resp_process(result, 'resp'), "httr2_response")
    expect_type(resp_process(result, 'jsonlist'), "list")
    expect_type(resp_process(result, 'raw'), "character")
    expect_error(resp_process(result, 'df'))
    expect_error(resp_process(result, 'text'))

})

