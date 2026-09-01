# ----------------------------------------
# Plot Functions
# ----------------------------------------


# ----------------------------------------
# Top Agencies Plot
# ----------------------------------------

# Create a horizontal bar chart showing the top 10 agencies
# receiving NYC 311 requests.
create_agency_plot <- function(data) {
  
  plot_data <- data %>%
    filter(!is.na(agency_name)) %>%
    count(
      agency_name,
      name = "n"
    ) %>%
    slice_max(
      order_by = n,
      n = 10,
      with_ties = FALSE
    )
  
  
  # Display a message if no records match the selected filters.
  if (nrow(plot_data) == 0) {
    
    return(
      ggplot() +
        annotate(
          "text",
          x = 0,
          y = 0,
          label = "No 311 requests match the selected filters",
          size = 5
        ) +
        xlim(-1, 1) +
        ylim(-1, 1) +
        theme_void()
    )
  }
  
  
  ggplot(
    plot_data,
    aes(
      x = reorder(
        stringr::str_wrap(
          agency_name,
          width = 28
        ),
        n
      ),
      y = n,
      text = paste0(
        "Agency: ",
        agency_name,
        "<br>Requests: ",
        scales::comma(n)
      )
    )
  ) +
    geom_col(
      fill = "#21618C"
    ) +
    geom_text(
      aes(
        label = scales::comma(n)
      ),
      hjust = -0.1,
      size = 3.5
    ) +
    coord_flip() +
    scale_y_continuous(
      expand = expansion(
        mult = c(0, 0.15)
      )
    ) +
    labs(
      title = "Counts by Agency",
      x = NULL,
      y = "Number of Requests"
    ) +
    theme_minimal() +
    theme(
      legend.position = "none"
    )
}


# ----------------------------------------
# Top Complaint Types Plot
# ----------------------------------------

# Create a horizontal bar chart showing the top 10
# complaint types in the filtered NYC 311 data.
create_complaint_plot <- function(data) {
  
  plot_data <- data %>%
    filter(!is.na(complaint_type)) %>%
    count(
      complaint_type,
      name = "n"
    ) %>%
    slice_max(
      order_by = n,
      n = 10,
      with_ties = FALSE
    )
  
  
  # Display a message if no records match the selected filters.
  if (nrow(plot_data) == 0) {
    
    return(
      ggplot() +
        annotate(
          "text",
          x = 0,
          y = 0,
          label = "No 311 requests match the selected filters",
          size = 5
        ) +
        xlim(-1, 1) +
        ylim(-1, 1) +
        theme_void()
    )
  }
  
  
  ggplot(
    plot_data,
    aes(
      x = reorder(
        complaint_type,
        n
      ),
      y = n,
      text = paste0(
        "Complaint Type: ",
        complaint_type,
        "<br>Requests: ",
        scales::comma(n)
      )
    )
  ) +
    geom_col(
      fill = "#2A9D8F"
    ) +
    geom_text(
      aes(
        label = scales::comma(n)
      ),
      hjust = -0.1,
      size = 3.5
    ) +
    coord_flip() +
    scale_y_continuous(
      expand = expansion(
        mult = c(0, 0.15)
      )
    ) +
    labs(
      title = "Top 10 Complaint Types",
      x = NULL,
      y = "Number of Requests"
    ) +
    theme_minimal()
}


# ----------------------------------------
# Time Series Plot
# ----------------------------------------

# Create a line chart showing the number of NYC 311
# requests submitted on each date.
create_time_series_plot <- function(data) {
  
  plot_data <- data %>%
    mutate(
      request_date = as.Date(
        created_date
      )
    ) %>%
    count(
      request_date,
      name = "n"
    ) %>%
    arrange(
      request_date
    )
  
  
  # Display a message if no records match the selected filters.
  if (nrow(plot_data) == 0) {
    
    return(
      ggplot() +
        annotate(
          "text",
          x = 0,
          y = 0,
          label = "No 311 requests match the selected filters",
          size = 5
        ) +
        xlim(-1, 1) +
        ylim(-1, 1) +
        theme_void()
    )
  }
  
  
  ggplot(
    plot_data,
    aes(
      x = request_date,
      y = n,
      group = 1,
      text = paste0(
        "Date: ",
        request_date,
        "<br>Requests: ",
        scales::comma(n)
      )
    )
  ) +
    geom_line(
      color = "#2C7FB8",
      linewidth = 1
    ) +
    geom_point(
      color = "#2C7FB8",
      size = 2.5
    ) +
    labs(
      title = "311 Requests Over Time",
      x = "Date",
      y = "Number of Requests"
    ) +
    theme_minimal()
}


# ----------------------------------------
# NYC 311 Request Map
# ----------------------------------------

# Create an interactive map of NYC 311 requests
# with points color-coded by borough.
create_311_map <- function(data) {
  
  # Keep only records with valid geographic coordinates
  # and one of the five recognized NYC boroughs.
  map_data <- data %>%
    filter(
      !is.na(latitude),
      !is.na(longitude),
      !is.na(borough),
      borough %in% c(
        "BRONX",
        "BROOKLYN",
        "MANHATTAN",
        "QUEENS",
        "STATEN ISLAND"
      )
    )
  
  
  # Display a message if no mappable records match
  # the selected filters.
  if (nrow(map_data) == 0) {
    
    return(
      leaflet() %>%
        addTiles() %>%
        setView(
          lng = -74.0060,
          lat = 40.7128,
          zoom = 10
        ) %>%
        addControl(
          html = paste0(
            "<div style='font-size: 18px;",
            " background-color: white;",
            " padding: 10px;",
            " border-radius: 4px;'>",
            "No 311 requests match the selected filters",
            "</div>"
          ),
          position = "topright"
        )
    )
  }
  
  
  # Create a consistent color for each borough.
  borough_colors <- colorFactor(
    palette = "Set1",
    domain = c(
      "BRONX",
      "BROOKLYN",
      "MANHATTAN",
      "QUEENS",
      "STATEN ISLAND"
    )
  )

  # Create the interactive map.
  leaflet(map_data) %>%
    addTiles() %>%
    addCircleMarkers(
      lng = ~longitude,
      lat = ~latitude,
      radius = 4,
      stroke = FALSE,
      fillOpacity = 0.6,
      color = ~borough_colors(borough),
      popup = ~paste0(
        "<strong>Borough:</strong> ", borough,
        "<br><strong>Complaint:</strong> ", complaint_type,
        "<br><strong>Agency:</strong> ", agency_name
      )
    ) %>%
    addLegend(
      position = "bottomright",
      pal = borough_colors,
      values = ~borough,
      title = "Borough",
      opacity = 1
    )
}