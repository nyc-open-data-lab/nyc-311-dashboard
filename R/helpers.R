# ----------------------------------------
# Helper Functions
# ----------------------------------------

# Create sorted dropdown choices from a selected data column.
# "All" is included as the default option so users can view
# the complete dataset without applying that filter.
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


# Create borough choices for the borough filter.
get_borough_choices <- function(data) {
  
  get_filter_choices(
    data,
    "borough"
  )
}


# Create ZIP code choices for the ZIP code filter.
get_zip_choices <- function(data) {
  
  get_filter_choices(
    data,
    "incident_zip"
  )
}


# Create complaint type choices for the complaint type filter.
get_complaint_choices <- function(data) {
  
  get_filter_choices(
    data,
    "complaint_type"
  )
}


# Create agency choices for the agency filter.
get_agency_choices <- function(data) {
  
  get_filter_choices(
    data,
    "agency_name"
  )
}