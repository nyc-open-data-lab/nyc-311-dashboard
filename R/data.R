# ----------------------------------------
# Data Functions
# ----------------------------------------

# Retrieve recent NYC 311 service request data.
#
# The function first checks for a recent local cache.
# If a valid cache is available, it is used to reduce
# startup time and unnecessary API requests.
#
# If the cache is unavailable or outdated, the function
# attempts to retrieve fresh data from NYC Open Data.
#
# If the live request fails but an older cache exists,
# the cached data are used as a fallback.
get_311_data <- function(
    cache_file = "data/311_cache.rds",
    cache_hours = 24
) {
  
  # Determine whether a recent cached dataset exists
  cache_is_recent <- FALSE
  
  if (file.exists(cache_file)) {
    
    cache_age <- difftime(
      Sys.time(),
      file.info(cache_file)$mtime,
      units = "hours"
    )
    
    cache_is_recent <- as.numeric(cache_age) < cache_hours
  }
  
  
  # Use the cache when it is still recent
  if (cache_is_recent) {
    
    message("Loading NYC 311 data from local cache...")
    
    return(
      readRDS(cache_file)
    )
  }
  
  
  # Otherwise, attempt to retrieve fresh NYC 311 data
  message("Retrieving fresh NYC 311 data...")
  
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
  
  
  # Save successfully retrieved data to the local cache
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
    
    message("Fresh NYC 311 data saved to cache.")
    
    return(fresh_data)
  }
  
  
  # Fall back to an existing cache if the live request fails
  if (file.exists(cache_file)) {
    
    message(
      "Using cached NYC 311 data because the live request failed."
    )
    
    return(
      readRDS(cache_file)
    )
  }
  
  
  # Stop if neither live nor cached data are available
  stop(
    paste(
      "Unable to retrieve NYC 311 data",
      "and no cached dataset is available."
    )
  )
}


# ----------------------------------------
# Clean and Prepare Data
# ----------------------------------------

# Remove records that do not contain an agency name.
clean_311_data <- function(data) {
  
  data %>%
    filter(!is.na(agency_name))
}