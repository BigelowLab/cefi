#' Retrieve a catalog based upon region and xcast
#' 
#' @export
#' @param xcast chr one of "history" or "forecast"
#' @param region chr, one of "Northwest Atlantic", "NWA", "Northeast Pacific" or "NEP"
#' @param stub chr the base uri for catalogs
#' @param name_prefix chr, the prefix to attach to a filename
#' @return character URL
catalog_uri = function(xcast = c("hindcast", 
                                  "seasonal_reforecast", 
                                  "seasonal_forecast")[1],
                       # xcast = c("history", "forecast")[1],  pre march 2025
                       region = c("NWA", "NEP")[1],
                       stub = "https://psl.noaa.gov/cefi_portal/data_index",
                       name_prefix = "cefi_data_indexing.Projects.CEFI.regional_mom6.cefi_portal"){
  
  if(FALSE){
    xcast = c("hindcast", 
               "seasonal_reforecast", 
               "seasonal_forecast")[1]
    region = c("NWA", "NEP")[1]
    stub = "https://psl.noaa.gov/cefi_portal/data_index"
    name_prefix = "cefi_data_indexing.Projects.CEFI.regional_mom6.cefi_portal"
  }
  
  exp_type = tolower(xcast[1])
  if (exp_type %in% names(CEFI_EXPERIMENT_TYPE)){
    exp_type = CEFI_EXPERIMENT_TYPE[exp_type]
  }
  
  reg = tolower(region[1])
  if(reg %in% names(CEFI_REGIONS)){
    reg = CEFI_REGIONS[reg]
  } 
  
  

  # pre March 2025
  # https://psl.noaa.gov/cefi_portal/var_list_northwest_atlantic_hist_run.json
  # https://psl.noaa.gov/cefi_portal/var_list_northwest_atlantic_forecast.json
  
  # post March 2025
  # https://psl.noaa.gov/cefi_portal/data_index/cefi_data_indexing.Projects.CEFI.regional_mom6.cefi_portal.northwest_atlantic.full_domain.hindcast.json
  # https://psl.noaa.gov/cefi_portal/data_index/cefi_data_indexing.Projects.CEFI.regional_mom6.cefi_portal.northwest_atlantic.full_domain.seasonal_reforecast.json
  # https://psl.noaa.gov/cefi_portal/data_index/cefi_data_indexing.Projects.CEFI.regional_mom6.cefi_portal.northwest_atlantic.full_domain.seasonal_forecast.json
  
  #printf("%s/var_list_%s_%s.json", stub, reg, per)
  sprintf("%s%s%s.%s.full_domain.%s.json", 
          stub[1], 
          .Platform$file.sep, 
          name_prefix[1],
          reg,
          exp_type)
}


#' Parse one or more URIs
#' 
#' @export
#' @param uri chr one or more catalog_uris
#' @param name_prefix chr the name prefix (of course)
#' @return a table of parse table components
parse_catalog_uri = function(uri = catalog_uri(),
                             name_prefix = "cefi_data_indexing.Projects.CEFI.regional_mom6.cefi_portal.") {
  stub = dirname(uri)
  nm = sub(name_prefix, "", basename(uri), fixed = TRUE) |>
    strsplit(".", fixed = TRUE)
  
  dplyr::tibble(
    region = sapply(nm, `[[`, 1),
    domain = sapply(nm, `[[`, 2),
    per = sapply(nm, `[[`, 3),
    uri = uri)
}


#' Parse a cefi opendap filename
#'
#' @export
#' @param uri chr one or more opendap uris
#' @return table
parse_cefi_opendap = function(uri = c("btm_o2.nwa.full.hcast.daily.raw.r20230401.199301-201912.nc",
                                      "thetao.nep.full.ss_refcast.monthly.raw.r20230401.ens_stats.i199303.nc",
                                      "tos.nwa.full.ltm_proj.yearly.raw.r20230401.proj_ssp585.enss.202001-209912.nc")){
  # hindcast
  # variable_name.region.subdomain.experiment_type.output_frequency.grid_type.rYYYYMMDD.YYYY0M-YYYY0M.nc
  
  # seasonal/decadal forecast-reforecast
  # variable_name.region.subdomain.experiment_type.output_frequency.grid_type.rYYYYMMDD.ensemble_info.iYYYY0M

  # long-term projection
  # variable_name.region.subdomain.experiment_type.output_frequency.grid_type.rYYYYMMDD.picontrol/historical/proj_forcing.ensemble_info.YYYY0M-YYYY0M
  
}


# A private function to tag a table with an attribute, "region" with "nwa" or "nep" 
# @param x a catalog table
# @param varname chr the name of the variable to query
# @return a character region nickname
which_region = function(x, varname = "cefi_opendap"){
  #name = if (grepl("northwest_atlantic", x[[varname]][1], fixed = TRUE)){
  #  "nwa"
  #} else if (grepl("northeast_pacific",x[[varname]][1], fixed = TRUE)){
  #  "nep"
  #} else{
  #  stop("unable able to detemine region from URL")
  #}
  #name
  x$cefi_region[1]
}

# A private function to tag a table with an attribute, "xcast" with
#  "hindcast", "seasonal_reforecast", "seasonal_forecast"
# @param x a catalog table
# @param varname chr the name of the variable to query
# @return a character xcast nickname
which_xcast = function(x, varname = "cefi_opendap"){
  fname = x[[varname]][1] |> basename()
  name = if (grepl("hcast", fname, fixed = TRUE)){
    "hindcast"
  } else if (grepl("ss_fcast", fname, fixed = TRUE)){
    "seasonal_forecast"
  } else if (grepl("ss_refcast", x[[varname]][1], fixed = TRUE)){
      "seasonal_reforecast"
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
read_catalog = function(uri = catalog_uri(region = "NWA", xcast = "hindcast")){
  
  swap_na = function(x){
    for (i in seq_len(ncol(x))) x[[i]][x[[i]] == "N/A"] <- NA_character_
    x
  }
  
  x = jsonlite::read_json(uri, simplifyVector= TRUE) |>
    lapply(dplyr::as_tibble) |>
    dplyr::bind_rows() |>
    swap_na()
  
  class(x) = c("CEFI_catalog", class(x))
  x = set_attrs(x, list(region = which_region(x), xcast = which_xcast(x)))
  x
}
