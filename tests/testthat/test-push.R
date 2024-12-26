library(testthat)
library(ollamar)

test_that("push function works with basic input", {
    skip_if_not(test_connection(), "Ollama server not available")

    expect_s3_class(push("mattw/pygmalion:latest"), "httr2_response")

    # wrong output type
    expect_error(push("mattw/pygmalion:latest", output = "abc"))

    models <- c("mattw/pygmalion:latest", "all-minilm:latest")
    streaming <- c(TRUE, FALSE)
    for (model in models) {
        for (stream in streaming) {
            resp <- push(model, stream = stream)
            # expect_s3_class(push(model, output = "resp"), "httr2_response")
            # expect_s3_class(push(model, output = "df"), "data.frame")
            # expect_type(push(model, output = "jsonlist"), "list")
            # expect_type(push(model, output = "raw"), "character")
            # expect_type(push(model, output = "text"), "character")

            # resp_process
            expect_s3_class(resp_process(resp, "resp"), "httr2_response")
            expect_s3_class(resp_process(resp, "df"), "data.frame")
            expect_type(resp_process(resp, "jsonlist"), "list")
            expect_type(resp_process(resp, "raw"), "character")
            expect_type(resp_process(resp, "text"), "character")
        }

    }
})
