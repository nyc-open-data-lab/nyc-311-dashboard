# ----------------------------------------
# Data Functions
# ----------------------------------------


# ----------------------------------------
# NYC 311 Data
# ----------------------------------------

get_311_data <- function(
    cache_file = "data/311_cache.rds",
    cache_hours = 24
) {

  cache_is_recent <- FALSE


  # Check whether a recent local cache is available.
  if (file.exists(cache_file)) {

    cache_age <- difftime(
      Sys.time(),
      file.info(cache_file)$mtime,
      units = "hours"
    )

    cache_is_recent <- as.numeric(cache_age) < cache_hours
  }


  # Use the cached 311 data when it is still recent.
  if (cache_is_recent) {

    message(
      "Loading NYC 311 data from local cache..."
    )

    return(
      readRDS(cache_file)
    )
  }


  # Retrieve fresh NYC 311 data when the cache
  # does not exist or is more than 24 hours old.
  message(
    "Retrieving fresh NYC 311 data..."
  )


  fresh_data <- tryCatch(

    nyc_pull_dataset(
      dataset = "erm2-nwe9",
      date_field = "created_date",
      from = Sys.Date() - 30,
      to = Sys.Date(),
      limit = 50000,
      timeout_sec = 90
    ),

    error = function(e) {

      message(
        "NYC Open Data request failed: ",
        conditionMessage(e)
      )

      NULL
    }
  )


  # Save successfully retrieved data to the local cache.
  if (!is.null(fresh_data)) {

    dir.create(
      dirname(cache_file),
      showWarnings = FALSE,
      recursive = TRUE
    )

    saveRDS(
      fresh_data,
      cache_file
    )

    message(
      "Fresh NYC 311 data saved to cache."
    )

    return(
      fresh_data
    )
  }


  # If the live request fails, use an older cache
  # when one is available.
  if (file.exists(cache_file)) {

    message(
      paste(
        "Using cached NYC 311 data because",
        "the live request failed."
      )
    )

    return(
      readRDS(cache_file)
    )
  }


  # Stop only when neither live nor cached data
  # is available.
  stop(
    paste(
      "Unable to retrieve NYC 311 data",
      "and no cached dataset is available."
    )
  )
}


# ----------------------------------------
# Clean NYC 311 Data
# ----------------------------------------

clean_311_data <- function(data) {

  data %>%
    filter(
      !is.na(agency_name)
    )
}


# ----------------------------------------
# Borough Boundary Data
# ----------------------------------------

get_borough_boundaries <- function(
    cache_file = "data/borough_boundaries.rds"
) {

  # Use the locally cached borough boundaries when available.
  # These geographic boundaries do not need to be downloaded
  # every time a dashboard filter changes.
  if (file.exists(cache_file)) {

    return(
      readRDS(cache_file)
    )
  }


  message(
    "Retrieving NYC borough boundaries..."
  )


  boundary_url <- paste0(
    "https://data.cityofnewyork.us/",
    "resource/gthc-hcne.geojson"
  )


  # Retrieve the official NYC borough boundary geometry.
  boundaries <- tryCatch(

    sf::st_read(
      boundary_url,
      quiet = TRUE
    ),

    error = function(e) {

      message(
        "NYC borough boundary request failed: ",
        conditionMessage(e)
      )

      NULL
    }
  )


  # Save successfully retrieved boundaries locally
  # so future map updates do not require another request.
  if (!is.null(boundaries)) {

    dir.create(
      dirname(cache_file),
      showWarnings = FALSE,
      recursive = TRUE
    )

    saveRDS(
      boundaries,
      cache_file
    )

    message(
      "NYC borough boundaries saved to cache."
    )

    return(
      boundaries
    )
  }


  # Stop if neither live nor cached boundary data
  # is available.
  stop(
    paste(
      "Unable to retrieve NYC borough boundaries",
      "and no cached boundary data is available."
    )
  )
}