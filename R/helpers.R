# ----------------------------------------
# Helper Functions
# ----------------------------------------

# Create borough choices for the dropdown menu
get_borough_choices <- function(data) {
  
  c(
    "All",
    sort(unique(na.omit(data$borough)))
  )
  
}

# Create complaint type choices for the dropdown menu
get_complaint_choices <- function(data) {
  
  c(
    "All",
    sort(unique(na.omit(data$complaint_type)))
  )
  
}

# Create agency choices for the dropdown menu
get_agency_choices <- function(data) {
  
  c(
    "All",
    sort(unique(na.omit(data$agency_name)))
  )
  
}