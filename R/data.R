# ----------------------------------------
# Data Functions
# ----------------------------------------

# Retrieve NYC 311 service request data
get_311_data <- function(
    cache_file = "data/311_cache.rds",
    cache_hours = 24
) {
  
  # Check whether a recent cached dataset already exists
  cache_is_recent <- FALSE
  
  if (file.exists(cache_file)) {
    
    cache_age <- difftime(
      Sys.time(),
      file.info(cache_file)$mtime,
      units = "hours"
    )
    
    cache_is_recent <- as.numeric(cache_age) < cache_hours
  }
  
  
  # Use the cached data if it is less than 24 hours old
  if (cache_is_recent) {
    
    message("Loading NYC 311 data from local cache...")
    
    return(
      readRDS(cache_file)
    )
  }
  
  
  # Otherwise, try to retrieve fresh data from NYC Open Data
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
  
  
  # If fresh data was retrieved successfully,
  # save it to the cache and return it
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
  
  
  # If the API request failed, use the existing cache
  if (file.exists(cache_file)) {
    
    message(
      "Using cached NYC 311 data because the live request failed."
    )
    
    return(
      readRDS(cache_file)
    )
  }
  
  
  # Stop only if neither live nor cached data is available
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

clean_311_data <- function(data) {
  
  data %>%
    filter(!is.na(agency_name))
}