library(testthat)
library(ollamar)

test_that("copy function works with basic input", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    x <- rnorm(5)
    expect_true(vector_norm(x) == sqrt(sum(x^2)))
    expect_true( all.equal(1, vector_norm(x)) != TRUE )
    expect_true(all.equal(1, vector_norm(normalize(x))))

    messages <- create_message(content = "hello", role = "user")
    expect_true(length(messages) == 1)
    expect_true(messages[[1]]$content == "hello")
    expect_true(messages[[1]]$role == "user")
    expect_true(names(messages[[1]])[1] == "role" & names(messages[[1]])[2] == "content")

    msg <- append_message("hello3", "3")
    expect_true(length(msg) == 1)
    expect_true(msg[[1]]$content == "hello3")
    expect_true(msg[[1]]$role == "3")
    expect_true(names(msg[[1]])[1] == "role" & names(msg[[1]])[2] == "content")

    msg2 <- append_message("hello4", "4", msg)
    expect_true(length(msg2) == 2)
    expect_true(msg2[[1]]$role == "3" & msg2[[2]]$role == "4")

    msg3 <- prepend_message("hello2", "2", msg2)
    expect_true(length(msg3) == 3)
    expect_true(msg3[[1]]$role == "2" & msg3[[2]]$role == "3" & msg3[[3]]$role == "4")
    expect_true(msg3[[1]]$content == "hello2" & msg3[[2]]$content == "hello3" & msg3[[3]]$content == "hello4")

    msg4 <- insert_message("hello2.1", "2.1", msg3, 2)
    expect_true(length(msg4) == 4)
    expect_true(msg4[[1]]$role == "2" & msg4[[2]]$role == "2.1" & msg4[[3]]$role == "3" & msg4[[4]]$role == "4")
    expect_true(msg4[[1]]$content == "hello2" & msg4[[2]]$content == "hello2.1" & msg4[[3]]$content == "hello3" & msg4[[4]]$content == "hello4")

    msg5 <- delete_message(msg4, 3)
    expect_true(length(msg5) == 3)
    expect_true(msg5[[1]]$role == "2" & msg5[[2]]$role == "2.1" & msg5[[3]]$role == "4")
    expect_true(msg5[[1]]$content == "hello2" & msg5[[2]]$content == "hello2.1" & msg5[[3]]$content == "hello4")

})
