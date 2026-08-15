# ----------------------------------------
# Helper Functions
# ----------------------------------------

# Create sorted dropdown choices from a selected data column
get_filter_choices <- function(data, column) {
  
  c(
    "All",
    sort(
      unique(
        na.omit(data[[column]])
      )
    )
  )
  
}


# Create borough choices for the dropdown menu
get_borough_choices <- function(data) {
  
  get_filter_choices(
    data,
    "borough"
  )
  
}


# Create ZIP code choices for the dropdown menu
get_zip_choices <- function(data) {
  
  c(
    "All",
    sort(
      unique(
        na.omit(data$incident_zip)
      )
    )
  )
  
}


# Create complaint type choices for the dropdown menu
get_complaint_choices <- function(data) {
  
  get_filter_choices(
    data,
    "complaint_type"
  )
  
}


# Create agency choices for the dropdown menu
get_agency_choices <- function(data) {
  
  get_filter_choices(
    data,
    "agency_name"
  )
  
}