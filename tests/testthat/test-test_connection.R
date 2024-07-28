library(testthat)
library(ollamar)

test_that("test_connection function works", {
    result <- test_connection()
    expect_s3_class(result, "httr2_response")
    expect_equal(result$status_code, 200)

    # wrong url
    result <- test_connection(url = "dsfdsf")
    expect_s3_class(result, "httr2_request")
    expect_equal(result$status_code, 503)
})
