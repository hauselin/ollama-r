library(testthat)
library(ollamar)

test_that("model options", {

    # check_option_valid
    expect_true(check_option_valid("mirostat"))
    expect_false(check_option_valid("sdfadsfdf"))

    # check options
    test1 <- check_options(c("a", "b", "temperature"))
    expect_type(check_options(c("a", "b", "temperature")), "list")
    expect_true(length(test1$valid_options) == 1)
    expect_true(length(test1$invalid_options) == 2)

    test2 <- check_options(c("mirostat_tau", "temperature"))
    expect_true(length(test2$valid_options) == 2)
    expect_true(length(test2$invalid_options) == 0)

    # search_options
    test1 <- search_options("learning rate")
    expect_type(test1, "list")
    expect_true(length(test1) > 0)
    expect_true(names(test1) == "mirostat_eta")

    test1 <- search_options("abcsfsdfdaf")
    expect_type(test1, "list")
    expect_true(length(test1) == 0)

    # validate_options
    test1 <- validate_options(mirostat = 1, mirostat_eta = 0.2, num_ctx = 1024)
    expect_true(test1)
    test2 <- validate_options(mirostat = 1, mirostat_eta = 0.2, invalid_opt = 1024)
    expect_false(test2)
    test3 <- validate_options()
    expect_true(test3)

})
