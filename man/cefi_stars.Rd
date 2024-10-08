% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/nc.R
\name{cefi_stars}
\alias{cefi_stars}
\title{Extract data as stars}
\usage{
cefi_stars(
  x = cefi_open(),
  collapse_fun = mean,
  na.rm = TRUE,
  var = cefi_active(x)
)
}
\arguments{
\item{x}{tidync, likely filtered with hyper_filter}

\item{na.rm}{logical, see \code{mean}}

\item{var}{chr, the variable to retrieve}

\item{collapse}{NULL or a function for computing summary stats}
}
\value{
stars object
}
\description{
Extract data as stars
}
