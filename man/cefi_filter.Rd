% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nc.R
\name{cefi_filter}
\alias{cefi_filter}
\title{A wrapper around \code{\link[tidync]{hyper_filter}} to help the user filter
by time.}
\usage{
cefi_filter(x, time = NULL, ...)
}
\arguments{
\item{x}{tidync object}

\item{time}{NULL or a two element vector of Date or POSIXct start and stop times
\code{time} must be provided \strong{before} any other filtering arguments.}

\item{...}{other arguments passed to \code{\link[tidync]{hyper_filter}}}
}
\value{
tidync object with filter pre-set
}
\description{
A wrapper around \code{\link[tidync]{hyper_filter}} to help the user filter
by time.
}
