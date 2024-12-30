library(testthat)
library(ollamar)

test_that("copy function works with basic input", {
    skip_if_not(test_connection(logical = TRUE), "Ollama server not available")

    copy("llama3", "llama3-BACKUP")
    expect_true(model_avail("llama3-BACKUP"))
    delete("llama3-BACKUP")

    expect_invisible(copy("wrong_model", "wrong_model_backup"))
    expect_false(model_avail("wrong_model_backup"))
})
