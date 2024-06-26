% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ollama.R
\name{embeddings}
\alias{embeddings}
\title{Get vector embedding for a prompt}
\usage{
embeddings(
  model,
  prompt,
  normalize = TRUE,
  keep_alive = "5m",
  endpoint = "/api/embeddings",
  ...
)
}
\arguments{
\item{model}{A character string of the model name such as "llama3".}

\item{prompt}{A character string of the prompt that you want to get the vector embedding for.}

\item{normalize}{Normalize the vector to length 1. Default is TRUE.}

\item{keep_alive}{The time to keep the connection alive. Default is "5m" (5 minutes).}

\item{endpoint}{The endpoint to get the vector embedding. Default is "/api/embeddings".}

\item{...}{Additional options to pass to the model.}
}
\value{
A numeric vector of the embedding.
}
\description{
Get vector embedding for a prompt
}
\examples{
\dontshow{if (test_connection()$status_code == 200) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
embeddings("nomic-embed-text:latest", "The quick brown fox jumps over the lazy dog.")
# pass model options to the model
embeddings("nomic-embed-text:latest", "Hello!", temperature = 0.1, num_predict = 3)
\dontshow{\}) # examplesIf}
}
