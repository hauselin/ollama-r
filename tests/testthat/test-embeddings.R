library(testthat)
library(ollamar)

test_that("embeddings function works with basic input", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    result <- embeddings("all-minilm", "hello")
    expect_type(result, "double")
    expect_true(is.null(dim(result)[2]))  # not matrix

    # model options
    expect_type(embeddings("all-minilm", "hello", temperature = 2), "double")
    expect_error(embeddings("all-minilm", "hello", dfdsffds = 0))

    # check normalize (default is normalize = TRUE)
    result <- embeddings("all-minilm", "hello", normalize = TRUE)
    result
    expect_true(all.equal(1, vector_norm(result)))
    result2 <- embeddings("all-minilm", "hello")  # default is normalize = TRUE
    expect_true(sum(result - result2) == 0)  # result and result2 vectors should be the same

    # check unormalize
    result3 <- embeddings("all-minilm", "hello", normalize = FALSE)
    expect_false(sum(result - result3) == 0)  # result and result3 vectors are different

    # cosine similarity
    expect_true(all.equal(sum(result * result), 1))
    expect_true(sum(result * result2) != 1)
    expect_true(sum(result * result3) != 1)
})
