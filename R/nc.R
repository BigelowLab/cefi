#' Open a CEFI connection
#' 
#' @export
#' @param x a (single-row) table of "CEFI_catalog" class
#' @return a tidync object
cefi_open = function(x = read_catalog() |> dplyr::slice(1)){
  stopifnot(inherits(x, "CEFI_catalog"))
  silent = options(tidync.silent = TRUE)
  on.exit(options(tidync.silent = silent[[1]]))
  nc = tidync::tidync(x$OPeNDAP_URL[1])
  
  # transfer the region and period
  attr(nc, "cefi_region") = attr(x, "cefi_region") 
  attr(nc, "cefi_period") = attr(x, "cefi_period") 
  
  static = static_open(x) |>
    tidync::activate("geolon")
  set_static(nc,static)
}

#' Get the transformed time dimension, add a POSIXct time variable
#' 
#' @export
#' @param x tidync object OR a tibble of transformed time
#' @param form chr, one of "POSIXct" or "Date" which determines the class of the 
#'   result
#' @return tibble of time transform
cefi_time = function(x = cefi_open(),
                     form = c("POSIXct", "Date")[2]){
  if (inherits(x, "tidync")){
    if (attr(x,"cefi_period") == "history"){
      x = tidync::activate(x, "time") |>
        tidync::hyper_transforms() |>
        getElement(1) 
      x = dplyr::mutate(x, time_ = as.POSIXct(.data$timestamp, format = "%Y-%m-%d %H:%H:%S", tz = "UTC"))
      if (tolower(form[1]) == "date") x = dplyr::mutate(x, time_ = as.Date(.data$time_))
      x
    } else if (attr(x,"cefi_period") == "forecast") {
      epoch = x[['attribute']] |>
        dplyr::filter(variable == "init", name == "units") |>
        dplyr::pull(value) |>
        getElement(1) |>
        as.Date(format = "days since %Y-%m-%d")
      step = x[['attribute']] |>
        dplyr::filter(variable == "lead", name == "units") |>
        dplyr::pull(value) |>
        getElement(1)
      
      x = tidync::activate(x, "lead") |>
        tidync::hyper_transforms() |>
        getElement(1) |>
        dplyr::mutate(time_ = seq(from = epoch, length = n(), by = step))
      if (tolower(form[1]) == "posixct") x = dplyr::mutate(x, time_ = as.POSIXct(.data$time_, tz = "UTC"))
    } else {
      stop("cefi_period in unknown - must be history or forecast")
    }
  } else {
    stop("input must be of class tidync")
  }
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
  if ("time" %in% names(ax)) ax[['time']] = cefi_time(x)
  ax
}


#' Extract data as stars
#' 
#' @export 
#' @param x tidync, likely filtered with hyper_filter
#' @param var chr, the variable to retrieve
#' @param collapse NULL or a function for computing summary stats
#' @param na.rm logical, see \code{mean}
#' @return stars object
cefi_stars = function(x = cefi_open(), 
                      collapse_fun = mean,
                      na.rm = TRUE,
                      var = cefi_active(x)){
  
  static = get_static(x) |>
    tidync::activate("geolon")
  a = tidync::hyper_array(x, select_var = var, drop = FALSE)
  if(!is.null(collapse_fun)){
    a = lapply(a, 
               function(arr) {
                 r = apply(arr, 1:3, collapse_fun, na.rm = TRUE)
                 r[is.nan(r)] <- NA
                 r
               })
  }
  ax = cefi_transforms(x)
  sx = tidync::hyper_transforms(static)
  
  lonlat = static_lonlat(x)
  
  period = attr(x, "cefi_period")
  if (period == "history"){
    tc = dplyr::filter(ax[[3]], .data$selected) |> dplyr::pull()
  } else if (period == "forecast"){
    tc = cefi_time(x) |>
      dplyr::filter(selected) |> 
      dplyr::pull()
  }

  rr = lapply(names(a),
    function(nm){
        xx = apply(a[[nm]], 3,
              function(m){
                  dimnames(m) <- NULL
                  stars::st_as_stars(m) |>
                    stars::st_as_stars(curvilinear = list(X1=lonlat$lon, X2=lonlat$lat)) |>
                    sf::st_set_crs(4326) |>
                  rlang::set_names(nm)
              }, simplify = FALSE)
        # see https://github.com/r-spatial/stars/issues/440
        do.call(c, append(xx, list(along =  3))) |>
          stars::st_set_dimensions(3, names = "time", values = tc)
    }) 
  do.call(c, rr)
}

#' Retrieve one or more names of the active grids
#' 
#' @export
#' @param x the tidync object (possibly pre-filtered)
#' @return character vector of active variable names
cefi_active = function(x){
  act = tidync::active(x)
  dplyr::filter(x$grid, grid == act) |>
    dplyr::pull(variables) |>
    getElement(1) |>
    dplyr::pull()
}


#' Get a CEFI variable as either a 'tidync_data' or 'stars' object
#' 
#' @export
#' @param x the tidync object (possibly pre-filtered)
#' @param var chr, the variable to retrieve
#' @param form one of 'tidync_data' or 'stars'
#' @return either 'tidync_data' or 'stars' object
cefi_var = function(x = cefi_open(),
                    var = cefi_active(x),
                    form = c("tidync_data", "stars")[2]){
  
  switch(tolower(form[1]),
         "stars" = cefi_stars(x, var = var),
         tidync::hyper_array(x, select_var = var))
  
}



#' A wrapper around \code{\link[tidync]{hyper_filter}} to help the user filter
#' by time.
#' 
#' @export
#' @param x tidync object
#' @param time NULL or a two element vector of Date or POSIXct start and stop times
#'   \code{time} must be provided **before** any other filtering arguments.
#' @param ... other arguments passed to \code{\link[tidync]{hyper_filter}} 
#' @return tidync object with filter pre-set
cefi_filter = function(x, time = NULL, ...){
  dots = as.list(substitute(list(...)))[-1L]
  if ("time" %in% names(dots)) stop("time must be listed as the first filtering argument after input x")
 
  
  period = attr(x, "cefi_period")
  if (period == "history"){
    if (!is.null(time)){
      if (is.numeric(x)){
        x = tidync::hyper_filter(x, dplyr::between(time, time[1], time[2]))
      } else {
        if (inherits(time, "POSIXt")) time = as.Date(time)
        ax = cefi_time(x)
        ix = findInterval(time, ax$time_)
        ix[ix < 1] = 1
        x = tidync::hyper_filter(x, time = dplyr::between(time, ix[1], ix[2]))
      }
    }
  } else if (period == "forecast"){
    if (is.numeric(x)){
      x = tidync::hyper_filter(x, dplyr::between(lead, time[1], time[2]))
    } else {
      if (inherits(time, "POSIXt")) time = as.Date(time)
      ax = cefi_time(x)
      ix = findInterval(time, ax$time_)
      ix[ix < 1] = 1
      x = tidync::hyper_filter(x, lead = dplyr::between(lead, ix[1], ix[2]))
    }
  } else {
    stop("period of data must be 'history' or 'forecast'")
  }
  
  x = tidync::hyper_filter(x, ...)
  attr(x, "static") = tidync::hyper_filter(attr(x, "static"), ...)
  x
}
