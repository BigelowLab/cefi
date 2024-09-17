#' Retrieve a catalog based upon region and period
#' 
#' @export
#' @param period chr one of "history" or "forecast"
#' @param region chr, one of "Northwest Atlantic", "NWA", "Northeast Pacific" or "NEP"
#' @param stub chr the base uri for catalogs
#' @return character URL
catalog_uri = function(period = c("history", "forecast")[1],
                       region = c("NWA", "NEP")[1],
                       stub = "https://psl.noaa.gov/cefi_portal/data_index"){
  
  # https://psl.noaa.gov/cefi_portal/var_list_northwest_atlantic_hist_run.json
  # https://psl.noaa.gov/cefi_portal/var_list_northwest_atlantic_forecast.json
  
  reg = switch(tolower(region[1]),
    "northwest atlantic" = "northwest_atlantic", 
    "nwa" = "northwest_atlantic", 
    "northeast_pacific")
  per = switch(tolower(period[1]),
    "history" = "hist_run",
    "historical" = "hist_run",
    "forecast")

  "https://psl.noaa.gov/cefi_portal/data_index/var_list_northwest_atlantic_hist_run.json"
  sprintf("%s/var_list_%s_%s.json", stub, reg, per)
}


# A private function to tag a table wiht an attribute, "region" with "nwa" or "nep" 
# @param x a catalog table
# @return a character region nickname
which_region = function(x){
  name = if (grepl("northwest_atlantic", x$OPeNDAP_URL[1], fixed = TRUE)){
    "nwa"
  } else if (grepl("northeast_pacific", x$OPeNDAP_URL[1], fixed = TRUE)){
    "nep"
  } else{
    stop("unable able to detemine region from URL")
  }
  name
}

# A private function to tag a table with an attribute, "period" with "hist" or "forecast" 
# @param x a catalog table
# @return a character period nickname
which_period = function(x){
  name = if (grepl("hist", x$OPeNDAP_URL[1], fixed = TRUE)){
    "hist"
  } else if (grepl("forecast", x$OPeNDAP_URL[1], fixed = TRUE)){
    "forecast"
  } else{
    stop("unable able to detemine region from URL")
  }
  name
}

#' Read the CEFI catalog
#' 
#' @export
#' @param uri chr, the URI of the json resource
#' @return table of metadata (of class CEFI_catalog)
read_catalog = function(uri = catalog_uri(region = "NWA", period = "history")){
  
  x = jsonlite::read_json(uri, simplifyVector= TRUE) |>
    lapply(dplyr::as_tibble) |>
    dplyr::bind_rows()
  class(x) = c("CEFI_catalog", class(x))
  attr(x, "cefi_region") = which_region(x)
  attr(x, "cefi_period") = which_period(x)
  x
}