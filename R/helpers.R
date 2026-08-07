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