% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ollama.R
\name{push}
\alias{push}
\title{Push or upload a model to a model library}
\usage{
push(
  name,
  insecure = FALSE,
  stream = FALSE,
  output = c("resp", "jsonlist", "raw", "text", "df"),
  endpoint = "/api/push",
  host = NULL
)
}
\arguments{
\item{name}{A character string of the model name to upload, in the form of \verb{<namespace>/<model>:<tag>}}

\item{insecure}{Allow insecure connections. Only use this if you are pushing to your own library during development. Default is FALSE.}

\item{stream}{Enable response streaming. Default is FALSE.}

\item{output}{The output format. Default is "resp". Other options are "jsonlist", "raw", "text", and "df".}

\item{endpoint}{The endpoint to push the model. Default is "/api/push".}

\item{host}{The base URL to use. Default is NULL, which uses Ollama's default base URL.}
}
\value{
A httr2 response object.
}
\description{
Push or upload a model to an Ollama model library. Requires registering for ollama.ai and adding a public key first.
}
\examples{
\dontshow{if (test_connection(logical = TRUE)) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
push("mattw/pygmalion:latest")
\dontshow{\}) # examplesIf}
}
\references{
\href{https://github.com/ollama/ollama/blob/main/docs/api.md#push-a-model}{API documentation}
}
