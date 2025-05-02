#' Parse a cefi URL into a table
#' 
#' @export
#' @param x one or more URLs
#' @return table
parse_url = function(x = c("btm_htotal.nwa.full.hcast.daily.raw.r20230520.199301-201912.nc", 
                           "phycos.nwa.full.hcast.daily.regrid.r20230520.199301-201912.nc", 
                           "intppdiat.nwa.full.hcast.monthly.raw.r20230520.199301-201912.nc", 
                           "ffetot_btm.nwa.full.hcast.monthly.regrid.r20230520.199301-201912.nc")){
  ss = basename(x) |> strsplit( ".", fixed = TRUE)
  split_dates = function(x = c("199301-201912", "185001-201912")){
    ss = strsplit(x, "-", fixed = TRUE) |>
      lapply(
        function(s){
          paste0(s, "01")
        })
    dplyr::tibble(
      start_date = sapply(ss, `[[`, 1) |> as.Date(format = "%Y%m%d"),
      end_date = sapply(ss, `[[`, 2) |> as.Date(format = "%Y%m%d") )
    
  }
  # hcast:  variable_name.region.subdomain.experiment_type.output_frequency.grid_type.rYYYYMMDD.YYYY0M-YYYY0M.nc
  # ss_fcast: variable_name.region.subdomain.experiment_type.output_frequency.grid_type.rYYYYMMDD.ensemble_info.iYYYY0M
  # ltm_proj: variable_name.region.subdomain.experiment_type.output_frequency.grid_type.rYYYYMMDD.picontrol/historical/proj_forcing.ensemble_info.YYYY0M-YYYY0M
  r = dplyr::tibble(
    variable_name = sapply(ss, `[[`, 1),
    region = sapply(ss, `[[`, 2),
    subdomain = sapply(ss, `[[`, 3),
    experiment_type = sapply(ss, `[[`, 4),
    output_frequency = sapply(ss, `[[`, 5),
    grid_type = sapply(ss, `[[`, 6),
    release = sapply(ss, `[[`, 7),
    ss = ss) |> 
    dplyr::group_by(.data$experiment_type) |>
    dplyr::group_map(
      function(tbl, key){
        # start_date, end_date, ensemble_info, initialization_date,
        # ensemble_type, ensemble_info
        switch(tbl$experiment_type[1],
               "hcast" = {
                 dates = sapply(tbl$ss, `[[`, 8) |> split_dates()
                 tbl |>
                   dplyr::bind_cols(dates) |>
                   dplyr::mutate(ensemble_type = NA, 
                                 ensemble_info = NA,
                                 initalization_date = NA)
               },
               "ss_fcast" = {
                 tbl |>
                   dplyr::mutate(start_date = NA,
                                 end_date = NA,
                                 ensemble_type = NA,
                                 ensemble_info = sapply(.data$ss, `[[`, 8),
                                 initalization_date = NA)
               },
               "ltm_proj" = {
                 dates = sapply(tbl$ss, `[[`, 10) |> split_dates()
                 tbl |>
                   dplyr::bind_cols(dates) |>
                   dplyr::mutate(ensemble_type = sapply(.data$ss, `[[`, 8),
                                 ensemble_info = sapply(.data$ss, `[[`, 9),
                                 initalization_date = NA)
               },
               stop("experiment_type not known: ", tbl$experiment_type[1])
        ) # switch
      }, .keep = TRUE) |>
    dplyr::bind_rows() |>
    dplyr::select(-dplyr::all_of("ss")) |>
    dplyr::mutate(url = x)
  
  r
}