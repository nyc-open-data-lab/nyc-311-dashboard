# ----------------------------------------
# Plot Functions
# ----------------------------------------

create_agency_plot <- function(data) {
  
  plot_data <- data %>%
    count(agency_name, name = "n") %>%
    slice_max(
      order_by = n,
      n = 10,
      with_ties = FALSE
    )
  
  ggplot(
    plot_data,
    aes(
      x = reorder(agency_name, n),
      y = n,
      text = paste0(
        "Agency: ", agency_name,
        "<br>Requests: ", scales::comma(n)
      )
    )
  ) +
    geom_col() +
    coord_flip() +
    labs(
      title = "Counts by Agency",
      x = "Agency",
      y = "Number of Requests"
    ) +
    theme_minimal() +
    theme(
      legend.position = "none"
    )
  
}

# Create a bar chart of the top complaint types
create_complaint_plot <- function(data) {
  
  plot_data <- data %>%
    count(complaint_type, name = "n") %>%
    filter(!is.na(complaint_type)) %>%
    slice_max(
      order_by = n,
      n = 10,
      with_ties = FALSE
    )
  
  ggplot(
    plot_data,
    aes(
      x = reorder(complaint_type, n),
      y = n,
      text = paste0(
        "Complaint Type: ", complaint_type,
        "<br>Requests: ", scales::comma(n)
      )
    )
  ) +
    geom_col() +
    coord_flip() +
    labs(
      title = "Top 10 Complaint Types",
      x = "Complaint Type",
      y = "Number of Requests"
    ) +
    theme_minimal()
}