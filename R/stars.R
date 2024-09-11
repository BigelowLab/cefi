#' Cast a tidync object to stars
#'
#' Taken from https://github.com/ropensci/tidync/issues/68#issuecomment-484773118
#' @export
#' @param x tidync object
#' @param ... other arguments (ignored)
#' @return stars object
tidync_as_stars <- function(x, ...) {
  ## x is a tidync
  
  ## ignore unit details for the moment
  data <- lapply(tidync::hyper_array(x, drop = FALSE), 
                 units::as_units)
  ## this needs to be a bit easier ...
  transforms <- tidync:::active_axis_transforms(x)
  dims <- lapply(names(transforms), function(trname) {
    transform <- transforms[[trname]] %>% dplyr::filter(selected)
    values <- transform[[trname]]
    if (length(values) > 1) {
      stars:::create_dimension(
        values = values)
    } else {
      ## a hack for now when there's only one value
      structure(list(from = values, to = values, 
                     offset = values, delta = NA_real_, 
                     geotransform = rep(NA_real_, 6), 
                     refsys = NA_character_, 
                     point = NA, 
                     values = NULL), 
                class = "dimension")
    }
  })
  names(dims) <- names(transforms)
  if (length(transforms)>= 2L) {
    r <- structure(list(affine = c(0, 0), 
                        dimensions = names(dims)[1:2], 
                        curvilinear = FALSE, class = "stars_raster"))
    
    attr(dims, "raster") <- r
  }  
  geotransform_xy <- c(dims[[1]]$offset, dims[[1]]$delta, 0, dims[[2]]$offset, 0, dims[[2]]$delta)
  dims[[1]]$geotransform <- dims[[2]]$geotransform <- geotransform_xy
  structure(data, dimensions =   structure(dims, class = "dimensions"), 
            class = "stars")
  
}