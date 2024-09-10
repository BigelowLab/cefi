#' Retrieve a catalog based upon region and period
#' 
#' @export
#' @param period chr one of "history" or "forecast"
#' @param region chr, one of "Northwest Atlantic", "NWA", "Northeast Pacific" or "NEP"
#' @return character URL
catalog_uri = function(period = c("history", "forecast")[1],
                       region = c("NWA", "NEP")[1]){
  
  # https://psl.noaa.gov/cefi_portal/var_list_northwest_atlantic_hist_run.json
  # https://psl.noaa.gov/cefi_portal/var_list_northwest_atlantic_forecast.json
  
  reg = switch(tolower(region[1]),
    "northwest atlantic" = "northwest_atlantic", 
    "nwa" = "northwest_atlantic", 
    "northeast_pacific")
  per = switch(tolower(period[1]),
    "history" = "hist_run",
    "historcial" = "hist_run",
    "forecast")

  sprintf("https://psl.noaa.gov/cefi_portal/var_list_%s_%s.json", reg, per)
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
  x
}