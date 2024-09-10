#' Open a CEFI connection
#' 
#' @export
#' @param x a (single-row) table of "CEFI_catalog" class
#' @return a ncdf4 object
open_cefi = function(x = read_catalog() |> dplyr::slice(1)){
  stopifnot(inherits(x, "CEFI_catalog"))
  #ncdf4::nc_open(x$OPeNDAP_URL[1])
  tidync::tidync(x$OPeNDAP_URL[1])
}

#' Get the transformed time dimension, add a POSIXct time variable
#' 
#' @export
#' @param x tidync object OR a tibble of transformed time
#' @param form chr, one of "POSIXct" or "Date" which determines the class of the 
#'   result
#' @return tibble of time transform
cefi_time = function(x = open_cefi(),
                     form = c("POSIXct", "Date")[2]){
  if (inherits(x, "tidync")){
    x = tidync::activate(x, "time") |>
      tidync::hyper_transforms() |>
      getElement(1)
  }
 x = dplyr::mutate(x, time_ = as.POSIXct(.data$timestamp, format = "%Y-%m-%d %H:%H:%S", tz = "UTC"))
 if (tolower(form[1]) == "date") x = dplyr::mutate(x, time_ = as.Date(.data$time_))
 x
}

#' Get the hyper transforms slightly doctored for time
#' 
#' @export
#' @param x tidync or tidync_data object
#' @param list of one or more tidync axis transform(s)
cefi_transforms = function(x){
  if (inherits(x, "tidync")){
    ax = tidync::hyper_transforms(x)
  } else if (inherits(x, "tidync_data")){
    ax = attr(x, "transforms")
  } else {
    stop("input must be 'tidync' or 'tidync_data' class object")
  }
  if ("time" %in% names(ax)) ax[['time']] = cefi_time(ax[['time']])
  ax
}


#' Extract data as stars
#' 
#' @export 
#' @param x tidync, likely filtered with hyper_filter
#' @return stars object
cefi_stars = function(x = open_cefi()){
    
  a = tidync::hyper_array(x)
  ax = cefi_transforms(x)
  
  xc = dplyr::filter(ax[[1]], .data$selected) |> dplyr::pull(var = 1)
  yc = dplyr::filter(ax[[2]], .data$selected) |> dplyr::pull(var = 1)
  tc = dplyr::filter(ax[[3]], .data$selected) |> dplyr::pull(var = -1)
  dx = (xc[2] - xc[1])/2
  dy = (yc[2] - yc[1])/2
  bb = c(xmin = min(xc), ymin = min(yc), xmax = max(xc), ymax = max(yc)) + 
       c(-dx, -dy, dx, dy) 
  bb = sf::st_bbox(bb, crs = 4326)
  
  rr = lapply(names(a),
    function(nm){
        xx = apply(a[[nm]], 3,
              function(m){
                    stars::st_as_stars(bb, 
                                       nx = length(xc),
                                       ny = length(yc),
                                       values = m) |>
                      stars::st_flip("y") |>
                      rlang::set_names(nm)
              }, simplify = FALSE)
        # see https://github.com/r-spatial/stars/issues/440
        do.call(c, append(xx, list(along =  3))) |>
          stars::st_set_dimensions(3, names = "time", values = tc)
    }) 
  do.call(c, rr)
}

#' Get a CEFI variable as either a 'tidync_data' or 'stars' object
#' 
#' @export
#' @param x the tidync object (possibly pre-filtered)
#' @param form one of 'tidync_data' or 'stars'
#' @return either 'tidync_data' or 'stars' object
cefi_var = function(x = open_cefi(),
                    form = c("tidync_data", "stars")[2]){
  
  switch(tolower(form[1]),
         "stars" = cefi_stars(x),
         tidync::hyper_array(x))
  
}
