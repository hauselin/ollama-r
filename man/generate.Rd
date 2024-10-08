% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ollama.R
\name{generate}
\alias{generate}
\title{Generate a response for a given prompt}
\usage{
generate(
  model,
  prompt,
  suffix = "",
  images = "",
  system = "",
  template = "",
  context = list(),
  stream = FALSE,
  raw = FALSE,
  keep_alive = "5m",
  output = c("resp", "jsonlist", "raw", "df", "text", "req"),
  endpoint = "/api/generate",
  host = NULL,
  ...
)
}
\arguments{
\item{model}{A character string of the model name such as "llama3".}

\item{prompt}{A character string of the prompt like "The sky is..."}

\item{suffix}{A character string after the model response. Default is "".}

\item{images}{A path to an image file to include in the prompt. Default is "".}

\item{system}{A character string of the system prompt (overrides what is defined in the Modelfile). Default is "".}

\item{template}{A character string of the prompt template (overrides what is defined in the Modelfile). Default is "".}

\item{context}{A list of context from a previous response to include previous conversation in the prompt. Default is an empty list.}

\item{stream}{Enable response streaming. Default is FALSE.}

\item{raw}{If TRUE, no formatting will be applied to the prompt. You may choose to use the raw parameter if you are specifying a full templated prompt in your request to the API. Default is FALSE.}

\item{keep_alive}{The time to keep the connection alive. Default is "5m" (5 minutes).}

\item{output}{A character vector of the output format. Default is "resp". Options are "resp", "jsonlist", "raw", "df", "text", "req" (httr2_request object).}

\item{endpoint}{The endpoint to generate the completion. Default is "/api/generate".}

\item{host}{The base URL to use. Default is NULL, which uses Ollama's default base URL.}

\item{...}{Additional options to pass to the model.}
}
\value{
A response in the format specified in the output parameter.
}
\description{
Generate a response for a given prompt
}
\examples{
\dontshow{if (test_connection()$status_code == 200) (if (getRversion() >= "3.4") withAutoprint else force)(\{ # examplesIf}
# text prompt
generate("llama3", "The sky is...", stream = FALSE, output = "df")
# stream and increase temperature
generate("llama3", "The sky is...", stream = TRUE, output = "text", temperature = 2.0)

# image prompt
# something like "image1.png"
image_path <- file.path(system.file("extdata", package = "ollamar"), "image1.png")
# use vision or multimodal model such as https://ollama.com/benzie/llava-phi-3
generate("benzie/llava-phi-3:latest", "What is in the image?", images = image_path, output = "text")
\dontshow{\}) # examplesIf}
}
\references{
\href{https://github.com/ollama/ollama/blob/main/docs/api.md#generate-a-completion}{API documentation}
}
