# ----------------------------------------
# Data Functions
# ----------------------------------------

# Retrieve NYC 311 service request data
get_311_data <- function() {
  
  nyc_pull_dataset(
    dataset = "erm2-nwe9",
    date_field = "created_date",
    from = Sys.Date() - 30,
    to = Sys.Date(),
    limit = 50000
  )
  
}


# Clean and prepare the data
clean_311_data <- function(data) {
  
  data %>%
    filter(!is.na(agency_name))
  
}