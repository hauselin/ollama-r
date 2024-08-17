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


    messages1 <- create_messages(
        list(role = "system", content = "be nice"),
        list(role = "user", content = "hello")
    )
    messages2 <- create_messages(
        create_message("be nice", "system"),
        create_message("hello")
    )
    messages3 <- create_message("be nice", "system")
    messages3 <- append_message("hello", "user", messages3)
    expect_identical(messages1, messages3)
    expect_identical(messages1, messages2)
    expect_identical(messages2, messages3)

    msg1 <- create_message("be nice", "system")
    msg2 <- create_message("hello", "user")
    messages4 <- c(msg1, msg2)
    expect_true(validate_messages(messages4))
    expect_identical(messages4, messages1)

    messages5 <- append(msg1, msg2)
    expect_true(validate_messages(messages5))
    expect_identical(messages5, messages1)
    expect_identical(messages5, messages4)

    expect_true(validate_message(list(role = "user", content = "hello")))
    expect_true(validate_message(create_message('hello')))
    expect_error(validate_message(create_message('hello', 1)))
    expect_error(validate_message(create_message(2, 1)))
    expect_error(validate_message(""))
    expect_error(validate_message(list(role = "user")))
    expect_error(validate_message(list(content = "hello")))
    expect_error(validate_message(list(role = 1, content = "hello")))
    expect_error(validate_message(list(role = "user", content = 1)))

    expect_true(validate_messages(list(
        list(role = "user", content = "hello")
    )))
    expect_true(validate_messages(list(
        list(role = "system", content = "hello"),
        list(role = "user", content = "hello")
    )))
    expect_false(validate_messages(list(
        list(role = "system", content = "hello"),
        list(role = "user", content = 1)
    )))

    expect_true(validate_messages(create_messages(
        create_message(content = "hello")
    )))
    expect_true(validate_messages(create_messages(
        create_message(role = "system", content = "hello"),
        create_message(role = "user", content = "hello")
    )))
    expect_error(validate_messages(create_messages(
        create_message(role = 2, content = "hello"),
        create_message(role = "user", content = 1)
    )))

    images <- c(file.path(system.file("extdata", package = "ollamar"), "image1.png"),
                file.path(system.file("extdata", package = "ollamar"), "image2.png"))

    expect_type(encode_images_in_messages(list(
        list(role = "user", content = "hello", images = images[1]),
        list(role = "user", content = "hello"),
        list(role = "user", content = "hello", images = "")
    )), "list")

    # test additional arguments ...
    messages <- create_message("hello", images = c("image1", "image2"), abc = 4:5)
    expect_true(length(messages) == 1)
    expect_true(messages[[1]]$content == "hello")
    expect_true(messages[[1]]$role == "user")
    expect_true(names(messages[[1]])[1] == "role" &
                    names(messages[[1]])[2] == "content" &
                    names(messages[[1]])[3] == "images" &
                    names(messages[[1]])[4] == "abc")

    messages2 <- append_message("hello3", "3", messages, new_field = "NEW")
    expect_true(length(messages2) == 2)
    expect_true(messages2[[2]]$new_field == "NEW")

    messages3 <- prepend_message("hello4", "4", messages2, new_prepended = "NEW_PRE")
    expect_true(length(messages3) == 3)
    expect_true(messages3[[1]]$new_prepended == "NEW_PRE")

    messages4 <- insert_message("hello5", "5", messages3, 2, new_inserted = "NEW_INS")
    expect_true(length(messages4) == 4)
    expect_true(messages4[[2]]$new_inserted == "NEW_INS")

})
