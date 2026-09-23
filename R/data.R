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
  
  chunk_file <- file.path(
    chunk_cache_dir,
    paste0(
      "311_",
      chunk_start,
      "_",
      chunk_end - 1,
      ".parquet"
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
    
    cached_data <- arrow::read_parquet(
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
  
  
  if (is.null(chunk_data)) {
    
    return(
      NULL
    )
  }
  
  
  # ----------------------------------------
  # Split Oversized Chunk
  # ----------------------------------------
  
  if (nrow(chunk_data) >= row_limit) {
    
    number_of_days <- as.integer(
      chunk_end - chunk_start
    )
    
    
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
    
    
    if (is.null(second_half)) {
      
      return(
        NULL
      )
    }
    
    
    chunk_data <- bind_rows(
      first_half,
      second_half
    )
    
    
    arrow::write_parquet(
      chunk_data,
      chunk_file,
      compression = "gzip"
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
  
  
  arrow::write_parquet(
    chunk_data,
    chunk_file,
    compression = "gzip"
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
# Load NYC 311 Data
# ----------------------------------------

# Load the existing complete 2026-to-date dashboard cache.
# App startup does not trigger a live API refresh.
get_311_data <- function(
    cache_file = "data/311_cache.parquet"
) {
  
  if (!file.exists(cache_file)) {
    
    stop(
      paste(
        "The NYC 311 cache does not exist.",
        "Run refresh_311_data() first to create it."
      )
    )
  }
  
  
  message(
    "Loading NYC 311 data from local cache..."
  )
  
  
  arrow::read_parquet(
    cache_file
  )
}


# ----------------------------------------
# Refresh NYC 311 Data
# ----------------------------------------

# Update the existing 2026-to-date NYC 311 cache with only the
# newer records that are not already present.
#
# This function is intended to be run separately
# from normal Shiny app startup, such as once per day.
refresh_311_data <- function(
    cache_file = "data/311_cache.parquet",
    chunk_cache_dir = "data/311_chunks",
    start_date = as.Date("2026-01-01")
) {
  
  if (!file.exists(cache_file)) {
    
    stop(
      paste(
        "No complete NYC 311 cache was found.",
        "Create the initial cache before running",
        "the incremental refresh."
      )
    )
  }
  
  
  message(
    "Loading existing NYC 311 cache..."
  )
  
  
  existing_data <- arrow::read_parquet(
    cache_file
  ) %>%
    standardize_311_columns()
  
  
  existing_dates <- as.Date(
    existing_data$created_date
  )
  
  
  if (all(is.na(existing_dates))) {
    
    stop(
      "The existing NYC 311 cache contains no valid dates."
    )
  }
  
  
  latest_cached_date <- max(
    existing_dates,
    na.rm = TRUE
  )
  
  
  # Use the most recent complete day.
  # The API "to" date is exclusive.
  latest_complete_date <- Sys.Date() - 2
  
  
  message(
    paste0(
      "Latest cached date: ",
      latest_cached_date
    )
  )
  
  
  message(
    paste0(
      "Latest complete date available for refresh: ",
      latest_complete_date
    )
  )
  
  
  # ----------------------------------------
  # Retrieve Missing Days
  # ----------------------------------------
  
  new_data <- NULL
  
  
  if (latest_cached_date < latest_complete_date) {
    
    refresh_start <- latest_cached_date + 1
    
    refresh_end <- latest_complete_date + 1
    
    
    dir.create(
      chunk_cache_dir,
      showWarnings = FALSE,
      recursive = TRUE
    )
    
    
    message(
      paste0(
        "Retrieving new NYC 311 data from ",
        refresh_start,
        " through ",
        latest_complete_date,
        "..."
      )
    )
    
    
    new_data <- retrieve_311_chunk(
      chunk_start = refresh_start,
      chunk_end = refresh_end,
      chunk_cache_dir = chunk_cache_dir,
      row_limit = 100000,
      timeout_sec = 180
    )
    
    
    if (is.null(new_data)) {
      
      stop(
        paste(
          "The NYC 311 incremental refresh failed.",
          "The existing complete cache was left unchanged."
        )
      )
    }
  } else {
    
    message(
      "The NYC 311 cache is already up to date."
    )
    
    return(
      invisible(existing_data)
    )
  }
  
  
  # ----------------------------------------
  # Combine Existing and New Data
  # ----------------------------------------
  
  if (!is.null(new_data)) {
    
    updated_data <- bind_rows(
      existing_data,
      new_data
    )
    
  } else {
    
    updated_data <- existing_data
  }
  
  
  # ----------------------------------------
  # Remove Duplicate Records
  # ----------------------------------------
  
  updated_data <- updated_data %>%
    distinct()
  
  
  # ----------------------------------------
  # Keep 2026-to-Date Window
  # ----------------------------------------
  
  final_end_date <- latest_complete_date
  
  updated_data <- updated_data %>%
    mutate(
      request_date_temp = as.Date(created_date)
    ) %>%
    filter(
      request_date_temp >= start_date,
      request_date_temp <= final_end_date
    ) %>%
    select(
      -request_date_temp
    )
  
  
  # ----------------------------------------
  # Validate Updated Dataset
  # ----------------------------------------
  
  if (nrow(updated_data) == 0) {
    
    stop(
      "The refreshed NYC 311 dataset contains no records."
    )
  }
  
  
  updated_dates <- as.Date(
    updated_data$created_date
  )
  
  
  message(
    paste0(
      "Updated date range: ",
      min(
        updated_dates,
        na.rm = TRUE
      ),
      " through ",
      max(
        updated_dates,
        na.rm = TRUE
      )
    )
  )
  
  
  # ----------------------------------------
  # Save Updated Cache
  # ----------------------------------------
  
  arrow::write_parquet(
    updated_data,
    cache_file,
    compression = "gzip"
  )
  
  
  message(
    paste0(
      "NYC 311 cache updated successfully (",
      format(
        nrow(updated_data),
        big.mark = ","
      ),
      " requests)."
    )
  )
  
  
  invisible(
    updated_data
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
  
  
  stop(
    paste(
      "Unable to retrieve NYC borough boundaries",
      "and no cached boundary data is available."
    )
  )
}