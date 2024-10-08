% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ollama.R
\name{pull}
\alias{pull}
\title{Pull/download a model from the Ollama library}
\usage{
pull(
  name,
  stream = FALSE,
  insecure = FALSE,
  endpoint = "/api/pull",
  host = NULL
)
}
\arguments{
\item{name}{A character string of the model name to download/pull, such as "llama3".}

\item{stream}{Enable response streaming. Default is FALSE.}

\item{insecure}{Allow insecure connections Only use this if you are pulling from your own library during development. Default is FALSE.}

\item{endpoint}{The endpoint to pull the model. Default is "/api/pull".}

\item{host}{The base URL to use. Default is NULL, which uses Ollama's default base URL.}
}
\value{
A httr2 response object.
}
\description{
See https://ollama.com/library for a list of available models. Use the list_models() function to get the list of models already downloaded/installed on your machine. Cancelled pulls are resumed from where they left off, and multiple calls will share the same download progress.
}
\examples{
\dontshow{if (test_connection()$status_code == 200) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
pull("llama3")
pull("all-minilm", stream = FALSE)
\dontshow{\}) # examplesIf}
}
\references{
\href{https://github.com/ollama/ollama/blob/main/docs/api.md#pull-a-model}{API documentation}
}
