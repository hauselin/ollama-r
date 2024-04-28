#' Test connection to Ollama server
#'
#' @param url The URL of the Ollama server. Default is http://localhost:11434
#'
#' @return A httr2 response object.
#' @export
#'
#' @examples
#' test_connection()
#' test_connection("http://localhost:11434")
#' test_connection("http://127.0.0.1:11434")
test_connection <- function(url = "http://localhost:11434") {
    req <- httr2::request(url)
    req <- httr2::req_method(req, "GET")
    tryCatch({
        resp <- httr2::req_perform(req)
        message("Ollama local server running")
        return(resp)
    }, error = function(e) {
        message("Ollama local server not running or wrong server.\nDownload and launch Ollama app to run the server. Visit https://ollama.com or https://github.com/ollama/ollama")
        req$status_code <- 503
        return(req)
    })
}
