#' Convert values in the range of `0 to 360` to the range `-180 to 180`
#'
#' @export
#' @seealso \href{https://gis.stackexchange.com/questions/201789/verifying-formula-that-will-convert-longitude-0-360-to-180-to-180/201793}{gis.stackexchange}
#' @export
#' @param x numeric vector, no check is done for being withing `0 to 360` range
#' @return numeric vector
to180 <- function(x) {
  x <- ((x + 180) %% 360) - 180
  x
}

#' Convert `-180 to 180` longitudes to `0 to 360`
#'
#' @export
#' @seealso \href{https://gis.stackexchange.com/questions/201789/verifying-formula-that-will-convert-longitude-0-360-to-180-to-180/201793}{gis.stackexchange}
#' @export
#' @param x numeric vector, no check is done for being within `0 to 360` range
#' @return numeric vector
to360 <- function(x) {x %% 360}