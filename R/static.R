#' Set the static attribute
#' 
#' @export
#' @param x tidync object
#' @param y a static tidync object
#' @return the input tidync object \code{x}
set_static = function(x,y){
  attr(x, "static") = y
  x
}

#' Get the static attribute
#' 
#' @export
#' @param x tidync object
#' @return the input's static tidync object
get_static = function(x){
  attr(x, "static")
}


#' Get a static variables geolon and geolat
#' 
#' @export
#' @param x tidync object (with a static attribute object)
#' @return a two element list of lon and lat
static_lonlat = function(x){
  static = get_static(x) |>
    tidync::activate("geolon")
  lon = tidync::hyper_array(static, drop = FALSE)[[1]] 
  dimnames(lon) = NULL
  lat = tidync::hyper_array(tidync::activate(static, "geolat"), drop = FALSE)[[1]]
  dimnames(lat) = NULL
  list(lon = lon, lat = lat)
}

#' Retrieve static resource URL by region name
#' 
#' @export
#' @param region chr, one of "nwa" or "nep" (the latter is made up)
#' @return character url for the opendap resource
static_url = function(region = c("nwa", "nep")[1]){
  switch(tolower(region[1]),
    "nwa" = "http://psl.noaa.gov/thredds/dodsC/Projects/CEFI/regional_mom6/cefi_portal/northwest_atlantic/full_domain/hindcast/daily/raw/latest/ocean_static.nc",
    "nep" = "http://psl.noaa.gov/thredds/dodsC/Projects/CEFI/regional_mom6/cefi_portal/northeast_pacific/full_domain/hindcast/monthly/raw/latest/ocean_static.nc",
    NA_character_)
}

#' Open a static file
#' 
#' @export
#' @param x a (single-row) table of "CEFI_catalog" class
#' @return a tidync object
static_open = function(x = read_catalog() |> dplyr::slice(1)){
  stopifnot(inherits(x, "CEFI_catalog"))
  silent = options(tidync.silent = TRUE)
  on.exit(options(tidync.silent = silent[[1]]))
  
  reg = get_attr(x, "region")
  uri = static_url(reg)
  
  tidync::tidync(uri)
}