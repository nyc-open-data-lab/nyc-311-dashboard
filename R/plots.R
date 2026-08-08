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

# Create a time-series plot of 311 requests by date
create_time_series_plot <- function(data) {
  
  plot_data <- data %>%
    mutate(
      request_date = as.Date(created_date)
    ) %>%
    count(
      request_date,
      name = "n"
    ) %>%
    arrange(request_date)
  
  ggplot(
    plot_data,
    aes(
      x = request_date,
      y = n,
      text = paste0(
        "Date: ", request_date,
        "<br>Requests: ", scales::comma(n)
      )
    )
  ) +
    geom_line() +
    geom_point() +
    labs(
      title = "311 Requests Over Time",
      x = "Date",
      y = "Number of Requests"
    ) +
    theme_minimal()
}

# Create a bar chart comparing 311 requests across boroughs
create_borough_plot <- function(data) {
  
  plot_data <- data %>%
    filter(!is.na(borough)) %>%
    count(
      borough,
      name = "n"
    ) %>%
    arrange(desc(n))
  
  ggplot(
    plot_data,
    aes(
      x = reorder(borough, n),
      y = n,
      text = paste0(
        "Borough: ", borough,
        "<br>Requests: ", scales::comma(n)
      )
    )
  ) +
    geom_col() +
    coord_flip() +
    labs(
      title = "311 Requests by Borough",
      x = "Borough",
      y = "Number of Requests"
    ) +
    theme_minimal()
}