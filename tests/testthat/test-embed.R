library(testthat)
library(ollamar)

# Note for the following test to work you need to make sure the "all-minilm" model exists locally

test_that("embed function works with basic input", {
    skip_if_not(test_connection(), "Ollama server not available")

    # one input
    result <- embed("all-minilm", "hello")
    expect_type(result, "double")
    expect_true(dim(result)[2] == 1)
    expect_true(dim(result)[1] > 1)

    # two inputs
    result <- embed("all-minilm", c("hello", "world"))
    expect_true(dim(result)[2] == 2)
    expect_true(dim(result)[1] > 1)

    # model options
    expect_type(embed("all-minilm", "hello", temperature = 2), "double")
    expect_error(embed("all-minilm", "hello", dfdsffds = 0))

    # check normalize (default is normalize = TRUE)
    result <- embed("all-minilm", "hello", normalize = TRUE)
    v <- result[, 1]
    expect_true(all.equal(1, vector_norm(v)))
    result2 <- embed("all-minilm", "hello")
    expect_true(sum(result[, 1] - result2[, 1]) == 0)  # result and result2 vectors should be the same

    # check unormalize
    result3 <- embed("all-minilm", "hello", normalize = FALSE)
    expect_false(sum(result[, 1] - result3[, 1]) == 0)  # result and result3 vectors are different

    # cosine similarity
    expect_true(all.equal((t(result) %*% result)[1], 1))
    expect_true(t(result) %*% result2 != 1)
    expect_true(t(result) %*% result3 != 1)

})
