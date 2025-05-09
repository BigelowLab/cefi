#' Open a CEFI connection
#' 
#' @export
#' @param x a (single-row) table of "CEFI_catalog" class
#' @return a tidync object
cefi_open = function(x = read_catalog() |> dplyr::slice(1)){
  stopifnot(inherits(x, "CEFI_catalog"))
  silent = options(tidync.silent = TRUE)
  on.exit(options(tidync.silent = silent[[1]]))
  nc = tidync::tidync(x$cefi_opendap[1])
  grid_type = x$cefi_grid_type[1]
  # transfer the region and period
  nc = set_attrs(nc, c(get_attrs(x), grid_type = x$cefi_grid_type[1]))
  nc = append_attr(nc, "catalog",  x)
  # we don't need the static data if the grid is lonlat regular
  if (x$cefi_grid_type[1] == "raw"){
    static = static_open(x) |>
      tidync::activate("geolon")
    nc = append_attr(nc, "static", static)
  }
  nc
}

#' Test if a cefi object is an ensemble
#' 
#' @export
#' @param x tidync or tidync_data object
#' @return logical TRUE if the object is an ensemble 
cefi_is_ensemble = function(x = cefi_open()){
  "member" %in% names(x$transforms)
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
    attrs = get_attrs(x)
    if (attrs[["xcast"]] == "hindcast"){
      tc = tidync::activate(x, "time") |>
        tidync::hyper_transforms() |>
        getElement(1)
      tc = dplyr::mutate(tc, time_ = as.POSIXct(.data$timestamp, format = "%Y-%m-%dT%H:%H:%S", tz = "UTC"))
      if (tolower(form[1]) == "date")  tc = dplyr::mutate(tc, time_ = as.Date(.data$time_))
    } else if (cefi_is_ensemble(x)){
      catalog = get_attr(x, "catalog")
      start = paste0(catalog$cefi_init_date, "01") |>
        as.Date("i%Y%m%d")
      tc = tidync::activate(x, "lead") |>
        tidync::hyper_transforms() |>
        getElement(1) |>
        dplyr::mutate(time_= seq(from = start, length = nrow(x$transform$lead), by = "month"))
      if (tolower(form[1]) == "posixct") tc = dplyr::mutate(tc, time_ = as.POSIXct(.data$time_, tz = "UTC"))
    } else if (attrs[["xcast"]] %in% c("reforecast", "forecast")) {
      epoch = x[['attribute']] |>
        dplyr::filter(.data$variable == "init", .data$name == "units") |>
        dplyr::pull(dplyr::all_of("value")) |>
        getElement(1) |>
        as.Date(format = "days since %Y-%m-%d")
      step = x[['attribute']] |>
        dplyr::filter(.data$variable == "lead", .data$name == "units") |>
        dplyr::pull(dplyr::all_of("value")) |>
        getElement(1)
      tc = tidync::activate(x, "lead") |>
        tidync::hyper_transforms() |>
        getElement(1) |>
        dplyr::mutate(time_ = seq(from = epoch, length = dplyr::n(), by = step))
      if (tolower(form[1]) == "posixct") tc = dplyr::mutate(tc, time_ = as.POSIXct(.data$time_, tz = "UTC"))
    } else {
      stop("cefi_xcast is unknown - must be hindcast or reforecast, or forecast")
    }
  } else {
    stop("input must be of class tidync")
  }
  tc
}

#' Get the hyper transforms slightly doctored for time
#' 
#' @export
#' @param x tidync or tidync_data object
#' @return list of one or more tidync axis transform(s)
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
#' If a requested product is an ensemble (with replicate runs), you have the option
#' to collapse the multiple runs into a single item - typically with `mean`.
#' 
#' @export 
#' @param x tidync, likely filtered with hyper_filter
#' @param collapse_fun function reference for collapsing multiple 'member' layers or NULL to skip
#' @param vars chr, the variable to retrieve
#' @param na.rm logical, passed to the `collapse_fun` if used
#' @param shift one of 180, 360 or TRUE or FALSE.  If 180 or 360 then
#'   shift the output to the desired longitude range, if FALSE then do no
#'   intervention, and if TRUE then try to shift the appropriate way. This
#'   is only used when a "regrid" `cefi_grid_type` is provided by `x`.
#' @return stars object
cefi_stars = function(x = cefi_open(), 
                      collapse_fun = mean,
                      na.rm = TRUE,
                      vars = cefi_active(x),
                      shift = TRUE){
  if (FALSE){
    x = cefi_open()
    collapse_fun = mean
    na.rm = TRUE
    vars = cefi_active(x)
    shift = TRUE
  }

  ax = cefi_transforms(x)
  attrs = get_attrs(x)
  xcast = attrs[["xcast"]]
  
  a = tidync::hyper_array(x, select_var = vars, drop = FALSE)
  
  # here we determine the 
  
  if("member" %in% names(ax) && !is.null(collapse_fun)){
    a = lapply(a, 
               function(arr) {
                 r = apply(arr, 1:3, collapse_fun, na.rm = TRUE)
                 r[is.nan(r)] <- NA
                 r
               })
  }

  
  if (attrs[["grid_type"]] == "raw"){
    static = attrs[['static']] |>
      tidync::activate("geolon")
    sx = tidync::hyper_transforms(static)
    lonlat = static_lonlat(x)
    
    if (xcast == "hindcast"){
      tc = dplyr::filter(ax[[3]], .data$selected) |> dplyr::pull()
    } else if (xcast %in% c("reforecast", "forecast")){
      tc = cefi_time(x) |>
        dplyr::filter(.data$selected) |> 
        dplyr::pull()
    }
  
    if (!is.null(collapse_fun)){
      rr = lapply(names(a),
        function(nm){
            xx = apply(a[[nm]], 3,
                  function(m){
                      dimnames(m) <- NULL
                      stars::st_as_stars(m) |>
                        stars::st_as_stars(curvilinear = list(X1=lonlat$lon, X2=lonlat$lat)) |>
                        sf::st_set_crs(4326) |>
                      rlang::set_names(nm) |>
                        stars::st_set_dimensions(names = c("x", "y"))
                  }, simplify = FALSE)
            # see https://github.com/r-spatial/stars/issues/440
            do.call(c, append(xx, list(along =  3))) |>
              stars::st_set_dimensions(3, names = "time", values = tc)
        }) 
    } else {
      rr = lapply(names(a),
        function(nm){         
          xx = apply(a[[nm]], 3,
                     function(m){
                       dimnames(m) <- NULL
                       stars::st_as_stars(m) |>
                         stars::st_as_stars(curvilinear = list(X1=lonlat$lon, X2=lonlat$lat)) |>
                         sf::st_set_crs(4326) |>
                         rlang::set_names(nm) |>
                         stars::st_set_dimensions(names = c("x", "y", "member"))
                     }, simplify = FALSE)
          # see https://github.com/r-spatial/stars/issues/440
          do.call(c, append(xx, list(along =  4))) |>
            stars::st_set_dimensions(4, names = "time", values = tc)
        })
      
      
    }
    r = do.call(c, rr)
  } else {
    # regular lonlat grid
    lon = dplyr::filter(ax[['lon']], .data$selected) |>
      dplyr::pull(1)
    lat = dplyr::filter(ax[["lat"]], .data$selected) |>
      dplyr::pull(1)
    tc = cefi_time(x) |>
      dplyr::filter(.data$selected) |> 
      dplyr::pull()
    if (xcast == "hindcast"){
      # single layer
      rr = lapply(names(a),
                  function(nm){         
                    xx = apply(a[[nm]], 3,
                               function(m){
                                 dimnames(m) <- NULL
                                 stars::st_as_stars(m) |>
                                   #sf::st_set_crs(4326) |>
                                   rlang::set_names(nm) |>
                                   stars::st_set_dimensions(1, names = "x", values = lon) |>
                                   stars::st_set_dimensions(2, names = "y", values = lat) |>
                                   sf::st_set_crs(4326)
                               }, simplify = FALSE) 
                    # see https://github.com/r-spatial/stars/issues/440
                    do.call(c, append(xx, list(along =  3))) |>
                      stars::st_set_dimensions(3, names = "time", values = tc)
                  })
      
      r = do.call(c, rr)
    } else {
      # ensembles
      rr = lapply(names(a),
                  function(nm){         
                    xx = apply(a[[nm]], 3,
                               function(m){
                                 dimnames(m) <- NULL
                                 stars::st_as_stars(m) |>
                                   #sf::st_set_crs(4326) |>
                                   rlang::set_names(nm) |>
                                   stars::st_set_dimensions(1, names = "x", values = lon) |>
                                   stars::st_set_dimensions(2, names = "y", values = lat) |>
                                   sf::st_set_crs(4326)
                               }, simplify = FALSE) 
                    # see https://github.com/r-spatial/stars/issues/440
                    do.call(c, append(xx, list(along =  3))) |>
                      stars::st_set_dimensions(3, names = "time", values = tc)
                  })
      
      r = do.call(c, rr)
      } # ensemble
    
    if (is.numeric(shift)){
      r = shift_stars(r, to = shift[1])
    } else if (is.logical(shift) && shift){
      r = shift_stars(r, to = 180)
    }
    
    r
  } # regrid

  
  r
}

#' Retrieve one or more names of the active grids
#' 
#' @export
#' @param x the tidync object (possibly pre-filtered)
#' @return character vector of active variable names
cefi_active = function(x){
  act = tidync::active(x)
  x$grid |> 
    dplyr::filter(.data$grid == act) |>
    dplyr::pull(dplyr::all_of("variables")) |>
    getElement(1) |>
    dplyr::pull()
}


#' Get a CEFI variable as either a 'tidync_data' or 'stars' object
#' 
#' @export
#' @param x the tidync object (possibly pre-filtered)
#' @param var chr, the variable to retrieve
#' @param form one of 'tidync_data' or 'stars'
#' @param ... other arguments passed through
#' @return either 'tidync_data' or 'stars' object
cefi_var = function(x = cefi_open(),
                    var = cefi_active(x),
                    form = c("tidync_data", "stars")[2],
                    ...){
  
  switch(tolower(form[1]),
         "stars" = cefi_stars(x, var = var, ...),
         tidync::hyper_array(x, select_var = var))
  
}



#' A wrapper around \code{\link[tidync]{hyper_filter}} to help the user filter
#' by time.
#' 
#' @export
#' @param x tidync object
#' @param time NULL or a two element vector of index, Date or POSIXct start and stop times
#'   \code{time} must be provided **before** any other filtering arguments.
#' @param ... other arguments passed to \code{\link[tidync]{hyper_filter}} 
#' @return tidync object with filter pre-set
cefi_filter = function(x, time = NULL, ...){
  dots = as.list(substitute(list(...)))[-1L]
  if ("time" %in% names(dots)) stop("time must be listed as the first filtering argument after input x")
  attrs = get_attrs(x)
  if (attrs[['xcast']] == "hindcast"){
    if (!is.null(time)){
      if (is.numeric(time)){
        x = tidync::hyper_filter(x, dplyr::between(time, time[1], time[2]))
      } else {
        if (inherits(time, "POSIXt")) time = as.Date(time)
        ax = cefi_time(x)
        ix = findInterval(time, ax$time_)
        ix[ix < 1] = 1
        x = tidync::hyper_filter(x, time = dplyr::between(time, ix[1], ix[2]))
      }
    }
  } else if (!is.null(time)){
      if (is.numeric(time)){
        x = tidync::hyper_filter(x, dplyr::between(.data$lead, time[1], time[2]))
      } else {
        if (inherits(time, "POSIXt")) time = as.Date(time)
        ax = cefi_time(x)
        ix = findInterval(time, ax$time_)
        ix[ix < 1] = 1
        x = tidync::hyper_filter(x, lead = dplyr::between(.data$lead, ix[1], ix[2]))
     }
  }
  
  x = tidync::hyper_filter(x, ...)
  if (attrs[["grid_type"]] == "raw"){
    append_attr(x, "static", tidync::hyper_filter(attrs[["static"]], ...))
  }
  x
}
