#' Get and set attributes
#' 
#' @export
#' @param x object that may have attributes
#' @param namespace chr, this is the name of list that holds cefi attributes
#' @param name chr, this is the name of and element of the cefi attribute namespace
#' @param value the value to set as the attribute.  When using `set_attrs` it should be 
#'   a named list.
#' @return `get_attrs` returns a list (or NULL), `get_attr` returns a value (or NULL)
#'   `set_attrs`, `set_attr` and `append_attr` return the updated input invisibly
get_attrs <- function(x, namespace = "cefi"){
  attr(x, namespace)
}

#' @export
#' @rdname get_attrs
set_attrs <- function(x, value, namespace = "cefi"){
  attr(x, namespace) <- value
  invisible(x)
}

#' @export
#' @rdname get_attrs
append_attr <- function(x, name, value, namespace = "cefi"){
  a <- get_attrs(x, namespace = namespace)
  a[[name]] = value
  attr(x, namespace) <- a
  invisible(x)
}

#' @export
#' @rdname get_attrs
get_attr <- function(x, name, namespace = "cefi"){
  attr(x, namespace)[[name]]
}

#' @export
#' @rdname get_attrs
set_attr <- function(x, name, value, namespace = "cefi"){
  a = attr(x, namespace)
  if (is.null(a)) a = list()
  a[[name]] <- value
  attr(x, namespace) <- a
  invisible(x)
}