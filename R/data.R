#' A look-up-table of regional names and abbreviations
#' 
#' @format a named character vector `abb = long_name`
#' @source \url{https://psl.noaa.gov/cefi_portal/}
"CEFI_REGIONS"
# CEFI_REGIONS = c(arc = "arctic", 
#                  glk = "great_lakes", 
#                  nep = "northeast_pacific" ,
#                  nwa = "northwest_atlantic",
#                  pci = "pacific_islands")
# save(CEFI_REGIONS, file = "data/CEFI_REGIONS.RData")

#' A look-up-table of experiment type names and abbreviations
#' 
#' @format a named character vector `abb = long_name`
#' @source \url{https://psl.noaa.gov/cefi_portal/}
"CEFI_EXPERIMENT_TYPE"
# CEFI_EXPERIMENT_TYPE = c(
#     hcast = "hindcast", 
#     ss_fcast = "seasonal_forecast",
#     ss_fcast_init = "seasonal_forecast_initialization",
#     ss_refcast = "seasonal_reforecast",
#     dc_fcast_init = "decadal_forecast_initialization",
#     dc_fcast = "decadal_forecast", 
#     ltm_proj = "long_term_projection") 
# save(CEFI_EXPERIMENT_TYPE, file = "data/CEFI_EXPERIMENT_TYPE.RData")

#' A look-up-table of domain names and abbreviations
#' 
#' @format a named character vector `abb = long_name`
#' @source \url{https://psl.noaa.gov/cefi_portal/}
"CEFI_SUBDOMAIN"
# CEFI_SUBDOMAIN = c(full = "full_domain")
# save(CEFI_SUBDOMAIN, file = "data/CEFI_SUBDOMAIN.RData")

