% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_options.R
\name{validate_options}
\alias{validate_options}
\title{Validate additional options or parameters provided to the API call}
\usage{
validate_options(...)
}
\arguments{
\item{...}{Additional options or parameters provided to the API call}
}
\value{
TRUE if all additional options are valid, FALSE otherwise
}
\description{
Validate additional options or parameters provided to the API call
}
\examples{
validate_options(mirostat = 1, mirostat_eta = 0.2, num_ctx = 1024)
validate_options(mirostat = 1, mirostat_eta = 0.2, invalid_opt = 1024)
}
