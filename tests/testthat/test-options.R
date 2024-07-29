library(testthat)
library(ollamar)

test_that("model options", {

    expect_true(check_option_valid("mirostat"))
    expect_false(check_option_valid("sdfadsfdf"))

})
