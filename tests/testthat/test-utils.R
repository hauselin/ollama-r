library(testthat)
library(ollamar)

test_that("copy function works with basic input", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    x <- rnorm(5)
    expect_true(vector_norm(x) == sqrt(sum(x^2)))
    expect_true( all.equal(1, vector_norm(x)) != TRUE )
    expect_true(all.equal(1, vector_norm(normalize(x))))

})
