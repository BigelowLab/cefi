CEFI
================

[NOAA’s Physical Science Laboratory (PSL)](https://psl.noaa.gov/)
[Climate Ecosystems and Fisheries Initiative
Portal](https://psl.noaa.gov/cefi_portal/) serves historical and
forecast data useful in ecological studies. Data is served using a
[THREDDS](https://psl.noaa.gov/thredds/catalog/Projects/CEFI/regional_mom6/catalog.html)
catalog, but PSL also makes [tabular
catalogs](https://psl.noaa.gov/cefi_portal/var_list_northwest_atlantic_hist_run.html)
available, too.

# Requirements

- [R v4.1+](https://www.r-project.org/)
- [rlang](https://CRAN.R-project.org/package=rlang)
- [dplyr](https://CRAN.R-project.org/package=dplyr)
- [sf](https://CRAN.R-project.org/package=sf)
- [stars](https://CRAN.R-project.org/package=stars)
- [jsonlite](https://CRAN.R-project.org/package=jsonlite)
- [ncdf4](https://CRAN.R-project.org/package=ncdf4)

# Installation

    remotes::install_github("BigelowLab/cefi")

# Usage

Load the libraries needed.

``` r
suppressPackageStartupMessages({
  library(cefi)
  library(dplyr)
})
```

## Catalogs

``` r
uri = catalog_uri(region = "Northwest Atlantic", period = "history")
hist = read_catalog(uri) |>
  dplyr::glimpse()
```

    ## Rows: 42
    ## Columns: 6
    ## $ Varible_Name     <chr> "siconc", "btm_o2", "chlos", "dissicos", "talkos", "s…
    ## $ Output_Frequency <chr> "monthly", "daily", "monthly", "monthly", "monthly", …
    ## $ Long_Name        <chr> "ice concentration", "Bottom Oxygen", "Surface Mass C…
    ## $ Unit             <chr> "0-1", "mol kg-1", "kg m-3", "mol m-3", "mol m-3", "m…
    ## $ File_Name        <chr> "ice_monthly.199301-201912.siconc.nc", "ocean_cobalt_…
    ## $ OPeNDAP_URL      <chr> "http://psl.noaa.gov/thredds/dodsC/Projects/CEFI/regi…

``` r
uri = catalog_uri(region = "Northwest Atlantic", period = "forecast")
fcst = read_catalog(uri) |>
  dplyr::glimpse()
```

    ## Rows: 480
    ## Columns: 6
    ## $ Varible_Name           <chr> "tob", "tob_anom", "tob", "tob_anom", "tob", "t…
    ## $ Time_of_Initialization <chr> "1993-03", "1993-03", "1993-06", "1993-06", "19…
    ## $ Long_Name              <chr> "Sea Water Potential Temperature at Sea Floor",…
    ## $ Unit                   <chr> "degC", "No unit provided in netCDF", "degC", "…
    ## $ File_Name              <chr> "tob_forecast_i199303.nc", "tob_forecast_i19930…
    ## $ OPeNDAP_URL            <chr> "http://psl.noaa.gov/thredds/dodsC/Projects/CEF…
