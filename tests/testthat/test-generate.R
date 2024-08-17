library(testthat)
library(ollamar)

test_that("generate function works with different outputs and resp_process", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    # incorrect output type
    expect_error(generate("llama3", "The sky is...", output = "abc"))

    expect_s3_class(generate("llama3.1", "tell me a 5-word story", output = "req"), "httr2_request")

    # not streaming
    expect_s3_class(generate("llama3", "The sky is..."), "httr2_response")
    expect_s3_class(generate("llama3", "The sky is...", output = "resp"), "httr2_response")
    expect_s3_class(generate("llama3", "The sky is...", output = "df"), "data.frame")
    expect_type(generate("llama3", "The sky is...", output = "jsonlist"), "list")
    expect_type(generate("llama3", "The sky is...", output = "text"), "character")
    expect_type(generate("llama3", "The sky is...", output = "raw"), "character")

    # streaming
    expect_s3_class(generate("llama3", "The sky is...", stream = TRUE), "httr2_response")
    expect_s3_class(generate("llama3", "The sky is...", stream = TRUE, output = "resp"), "httr2_response")
    expect_s3_class(generate("llama3", "The sky is...", stream = TRUE, output = "df"), "data.frame")
    expect_type(generate("llama3", "The sky is...", stream = TRUE, output = "jsonlist"), "list")
    expect_type(generate("llama3", "The sky is...", stream = TRUE, output = "text"), "character")
    expect_type(generate("llama3", "The sky is...", stream = TRUE, output = "raw"), "character")

    # resp_process
    # not streaming
    result <- generate("llama3", "The sky is...")
    expect_s3_class(result, "httr2_response")
    expect_s3_class(resp_process(result, "resp"), "httr2_response")
    expect_s3_class(resp_process(result, "df"), "data.frame")
    expect_type(resp_process(result, "jsonlist"), "list")
    expect_type(resp_process(result, "text"), "character")
    expect_type(resp_process(result, "raw"), "character")

    # streaming
    result <- generate("llama3", "The sky is...", stream = TRUE)
    expect_s3_class(result, "httr2_response")
    expect_s3_class(resp_process(result, "resp"), "httr2_response")
    expect_s3_class(resp_process(result, "df"), "data.frame")
    expect_type(resp_process(result, "jsonlist"), "list")
    expect_type(resp_process(result, "text"), "character")
    expect_type(resp_process(result, "raw"), "character")
})

test_that("generate function works with additional options", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")

    expect_s3_class(generate("llama3", "The sky is...", num_predict = 1, temperature = 0), "httr2_response")
    expect_error(generate("llama3", "The sky is...", abc = 1, sdf = 2))
})



test_that("generate function works with images", {
    skip_if_not(test_connection()$status_code == 200, "Ollama server not available")
    skip_if_not(model_avail("benzie/llava-phi-3"), "benzie/llava-phi-3 model not available")

    image_path <- file.path(system.file("extdata", package = "ollamar"), "image1.png")

    result <- generate("benzie/llava-phi-3", "What is in the image?", images = image_path)
    expect_s3_class(result, "httr2_response")
    expect_type(resp_process(result, "text"), "character")
    expect_match(tolower(resp_process(result, "text")), "watermelon")

    expect_error(generate("benzie/llava-phi-3", "What is in the image?", images = "incorrect_path.png"))

    images <- c(file.path(system.file("extdata", package = "ollamar"), "image1.png"),
                file.path(system.file("extdata", package = "ollamar"), "image2.png"))

    # multiple images
    result <- generate("benzie/llava-phi-3", "What objects are in the two images?",
                       images = images, output = 'text')
    expect_type(result, "character")
    expect_true(grepl("melon", tolower(result)) | grepl("cam", tolower(result)))

})


