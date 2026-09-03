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
    ) %>%
    mutate(
      agency_label = case_when(
        agency_name == "New York City Police Department" ~ "NYPD",
        agency_name == "Department of Housing Preservation and Development" ~ "HPD",
        agency_name == "Department of Sanitation" ~ "DSNY",
        agency_name == "Department of Transportation" ~ "DOT",
        agency_name == "Department of Environmental Protection" ~ "DEP",
        agency_name == "Department of Parks and Recreation" ~ "DPR",
        agency_name == "Department of Buildings" ~ "DOB",
        agency_name == "Department of Health and Mental Hygiene" ~ "DOHMH",
        agency_name == "Department of Homeless Services" ~ "DHS",
        agency_name == "Taxi and Limousine Commission" ~ "TLC",
        TRUE ~ agency_name
      )
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
        agency_label,
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
    coord_flip() +
    scale_y_continuous(
      expand = expansion(
        mult = c(0, 0.03)
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
    coord_flip() +
    scale_y_continuous(
      expand = expansion(
        mult = c(0, 0.03)
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

# Create an interactive geographic visualization of
# NYC 311 requests with points color-coded by borough.
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


  # Load official NYC borough boundaries.
  borough_boundaries <- get_borough_boundaries()


  # Display a message if no mappable records match
  # the selected filters.
  if (nrow(map_data) == 0) {

    return(
      leaflet() %>%
        addPolygons(
          data = borough_boundaries,
          color = "#8A8A8A",
          weight = 1.5,
          opacity = 1,
          fillColor = "#F2F2F2",
          fillOpacity = 1
        ) %>%
        fitBounds(
          lng1 = -74.25559,
          lat1 = 40.49613,
          lng2 = -73.70001,
          lat2 = 40.91553
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
  leaflet() %>%

    # Draw official NYC borough boundaries first
    # so the request points remain visually dominant.
    addPolygons(
      data = borough_boundaries,
      color = "#8A8A8A",
      weight = 1.5,
      opacity = 1,
      fillColor = "#F2F2F2",
      fillOpacity = 1,
      smoothFactor = 0.5
    ) %>%

    # Overlay NYC 311 requests.
    addCircleMarkers(
      data = map_data,
      lng = ~longitude,
      lat = ~latitude,
      radius = 5,
      stroke = TRUE,
      weight = 1,
      opacity = 1,
      color = "white",
      fillColor = ~borough_colors(borough),
      fillOpacity = 0.8,
      popup = ~paste0(
        "<strong>Borough:</strong> ", borough,
        "<br><strong>Complaint:</strong> ", complaint_type,
        "<br><strong>Agency:</strong> ", agency_name
      )
    ) %>%

    # Automatically fit the map to the requests
    # currently displayed after filtering.
    fitBounds(
      lng1 = min(
        map_data$longitude,
        na.rm = TRUE
      ),
      lat1 = min(
        map_data$latitude,
        na.rm = TRUE
      ),
      lng2 = max(
        map_data$longitude,
        na.rm = TRUE
      ),
      lat2 = max(
        map_data$latitude,
        na.rm = TRUE
      )
    ) %>%

    addLegend(
      position = "bottomright",
      pal = borough_colors,
      values = map_data$borough,
      title = "Borough",
      opacity = 1
    )
}