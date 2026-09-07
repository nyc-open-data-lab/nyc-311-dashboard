# ----------------------------------------
# Data Functions
# ----------------------------------------


# ----------------------------------------
# Standardize NYC 311 Columns
# ----------------------------------------

# Keep only the fields used by the dashboard and make
# their data types consistent across API requests.
standardize_311_columns <- function(data) {

  data %>%
    transmute(
      created_date = as.character(created_date),
      agency_name = as.character(agency_name),
      complaint_type = as.character(complaint_type),
      borough = as.character(borough),
      incident_zip = as.character(incident_zip),
      latitude = as.numeric(latitude),
      longitude = as.numeric(longitude)
    )
}


# ----------------------------------------
# Retrieve One NYC 311 Date Chunk
# ----------------------------------------

# Retrieve a requested date range from NYC Open Data.
# If the range reaches the 100,000-row API limit,
# automatically divide it into smaller date ranges.
retrieve_311_chunk <- function(
    chunk_start,
    chunk_end,
    chunk_cache_dir,
    row_limit = 100000,
    timeout_sec = 180
) {

  # Create a cache filename for this exact date range.
  chunk_file <- file.path(
    chunk_cache_dir,
    paste0(
      "311_",
      chunk_start,
      "_",
      chunk_end - 1,
      ".rds"
    )
  )


  # ----------------------------------------
  # Use Existing Chunk Cache
  # ----------------------------------------

  if (file.exists(chunk_file)) {

    message(
      paste0(
        "Loading cached chunk ",
        chunk_start,
        " through ",
        chunk_end - 1,
        "..."
      )
    )

    cached_data <- readRDS(
      chunk_file
    )

    return(
      standardize_311_columns(
        cached_data
      )
    )
  }


  # ----------------------------------------
  # Retrieve Chunk
  # ----------------------------------------

  message(
    paste0(
      "Retrieving ",
      chunk_start,
      " through ",
      chunk_end - 1,
      "..."
    )
  )


  chunk_data <- tryCatch(

    nyc_pull_dataset(
      dataset = "erm2-nwe9",
      date_field = "created_date",
      from = chunk_start,
      to = chunk_end,
      limit = row_limit,
      timeout_sec = timeout_sec
    ),

    error = function(e) {

      message(
        paste0(
          "Chunk failed for ",
          chunk_start,
          " through ",
          chunk_end - 1,
          ": ",
          conditionMessage(e)
        )
      )

      NULL
    }
  )


  # Return NULL when the API request itself fails.
  if (is.null(chunk_data)) {

    return(
      NULL
    )
  }


  # ----------------------------------------
  # Split Oversized Chunk
  # ----------------------------------------

  # If the API returned the full row limit, assume the
  # requested range may have been truncated.
  if (nrow(chunk_data) >= row_limit) {

    number_of_days <- as.integer(
      chunk_end - chunk_start
    )


    # A single day should not normally exceed the limit.
    # Stop rather than silently accepting incomplete data.
    if (number_of_days <= 1) {

      stop(
        paste0(
          "A single-day NYC 311 request for ",
          chunk_start,
          " reached the ",
          format(
            row_limit,
            big.mark = ","
          ),
          "-row limit. The data may be incomplete."
        )
      )
    }


    message(
      paste0(
        "Chunk ",
        chunk_start,
        " through ",
        chunk_end - 1,
        " reached the ",
        format(
          row_limit,
          big.mark = ","
        ),
        "-row limit. Splitting into smaller ranges..."
      )
    )


    # Split the date range approximately in half.
    split_date <- chunk_start + floor(
      number_of_days / 2
    )


    first_half <- retrieve_311_chunk(
      chunk_start = chunk_start,
      chunk_end = split_date,
      chunk_cache_dir = chunk_cache_dir,
      row_limit = row_limit,
      timeout_sec = timeout_sec
    )


    # Stop this chunk if the first half could not
    # be retrieved successfully.
    if (is.null(first_half)) {

      return(
        NULL
      )
    }


    second_half <- retrieve_311_chunk(
      chunk_start = split_date,
      chunk_end = chunk_end,
      chunk_cache_dir = chunk_cache_dir,
      row_limit = row_limit,
      timeout_sec = timeout_sec
    )


    # Stop this chunk if the second half could not
    # be retrieved successfully.
    if (is.null(second_half)) {

      return(
        NULL
      )
    }


    # Combine the complete smaller ranges.
    chunk_data <- bind_rows(
      first_half,
      second_half
    )


    # Save the reconstructed complete date range so
    # future runs can load it directly.
    saveRDS(
      chunk_data,
      chunk_file
    )


    message(
      paste0(
        "Saved complete split chunk with ",
        format(
          nrow(chunk_data),
          big.mark = ","
        ),
        " requests."
      )
    )


    return(
      chunk_data
    )
  }


  # ----------------------------------------
  # Save Normal Chunk
  # ----------------------------------------

  chunk_data <- standardize_311_columns(
    chunk_data
  )


  saveRDS(
    chunk_data,
    chunk_file
  )


  message(
    paste0(
      "Saved chunk with ",
      format(
        nrow(chunk_data),
        big.mark = ","
      ),
      " requests."
    )
  )


  return(
    chunk_data
  )
}


# ----------------------------------------
# NYC 311 Data
# ----------------------------------------

get_311_data <- function(
    cache_file = "data/311_cache.rds",
    chunk_cache_dir = "data/311_chunks",
    cache_hours = 24,
    days_back = 365,
    chunk_days = 7
) {

  cache_is_recent <- FALSE


  # ----------------------------------------
  # Check Final Cache
  # ----------------------------------------

  # Check whether a recent complete year-long cache
  # is already available.
  if (file.exists(cache_file)) {

    cache_age <- difftime(
      Sys.time(),
      file.info(cache_file)$mtime,
      units = "hours"
    )

    cache_is_recent <- as.numeric(cache_age) < cache_hours
  }


  # Use the complete cached dataset when it is recent.
  if (cache_is_recent) {

    message(
      "Loading NYC 311 data from local cache..."
    )

    return(
      readRDS(cache_file)
    )
  }


  # ----------------------------------------
  # Set Date Range
  # ----------------------------------------

  message(
    "Preparing one year of NYC 311 data..."
  )


  # Use the most recent complete day.
  # The NYC Open Data "to" date is an exclusive bound,
  # so this setup includes data through two days ago.
  end_date <- Sys.Date() - 1
  start_date <- end_date - days_back


  chunk_starts <- seq(
    from = start_date,
    to = end_date - 1,
    by = chunk_days
  )


  # Create the directory used to store individual chunks.
  dir.create(
    chunk_cache_dir,
    showWarnings = FALSE,
    recursive = TRUE
  )


  # ----------------------------------------
  # Retrieve Weekly Chunks
  # ----------------------------------------

  data_chunks <- vector(
    mode = "list",
    length = length(chunk_starts)
  )


  retrieval_failed <- FALSE


  for (i in seq_along(chunk_starts)) {

    chunk_start <- chunk_starts[i]


    # The "to" date is an exclusive upper bound.
    chunk_end <- min(
      chunk_start + chunk_days,
      end_date
    )


    chunk_data <- retrieve_311_chunk(
      chunk_start = chunk_start,
      chunk_end = chunk_end,
      chunk_cache_dir = chunk_cache_dir,
      row_limit = 100000,
      timeout_sec = 180
    )


    # Stop the current yearly refresh if a chunk
    # could not be retrieved.
    if (is.null(chunk_data)) {

      retrieval_failed <- TRUE

      break
    }


    data_chunks[[i]] <- chunk_data
  }


  # ----------------------------------------
  # Handle Failed Retrieval
  # ----------------------------------------

  if (retrieval_failed) {

    message(
      paste(
        "The yearly NYC 311 refresh was not completed.",
        "Successfully retrieved chunks were saved",
        "and will be reused on the next attempt."
      )
    )


    # If an older complete cache exists, use it.
    if (file.exists(cache_file)) {

      message(
        paste(
          "Using the existing complete NYC 311 cache",
          "for the dashboard."
        )
      )

      return(
        readRDS(cache_file)
      )
    }


    stop(
      paste(
        "Unable to complete the yearly NYC 311 data refresh.",
        "Run get_311_data() again to continue from the",
        "last successfully saved chunk."
      )
    )
  }


  # ----------------------------------------
  # Combine All Chunks
  # ----------------------------------------

  message(
    "Combining NYC 311 data..."
  )


  fresh_data <- bind_rows(
    data_chunks
  )


  # ----------------------------------------
  # Validate Final Dataset
  # ----------------------------------------

  if (nrow(fresh_data) == 0) {

    stop(
      "The combined NYC 311 dataset contains no records."
    )
  }


  retrieved_dates <- as.Date(
    fresh_data$created_date
  )


  message(
    paste0(
      "Combined date range: ",
      min(
        retrieved_dates,
        na.rm = TRUE
      ),
      " through ",
      max(
        retrieved_dates,
        na.rm = TRUE
      )
    )
  )


  # ----------------------------------------
  # Save Complete Cache
  # ----------------------------------------

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
    paste0(
      "One year of NYC 311 data saved to cache (",
      format(
        nrow(fresh_data),
        big.mark = ","
      ),
      " requests)."
    )
  )


  return(
    fresh_data
  )
}


# ----------------------------------------
# Clean NYC 311 Data
# ----------------------------------------

clean_311_data <- function(data) {

  data %>%
    mutate(
      request_date = as.Date(created_date)
    ) %>%
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