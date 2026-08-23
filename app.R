#
# NYC 311 Shiny Dashboard
#

# Core dashboard packages
library(shiny)
library(shinydashboard)
library(shinythemes)
library(tidyverse)
library(plotly)

# NYC Open Data helper package
library(nycOpenData)


# -------------------------
# Load Project Scripts
# -------------------------

# Data retrieval and cleaning functions
source("R/data.R")

# Reusable plotting functions
source("R/plots.R")

# Helper functions for dashboard filters
source("R/helpers.R")


# -------------------------
# Load and Prepare Data
# -------------------------

# Retrieve recent NYC 311 data.
# The data function uses a local cache when available
# to improve startup speed and reduce repeated API requests.
data_nyc <- get_311_data()

# Remove records that are missing required agency information.
data_nyc <- clean_311_data(data_nyc)


# -------------------------
# User Interface
# -------------------------

ui <- dashboardPage(
  
  # Dashboard header
  dashboardHeader(
    title = "NYC 311 Dashboard"
  ),
  
  
  # -------------------------
  # Sidebar Filters
  # -------------------------
  
  dashboardSidebar(
    
    sidebarMenu(
      menuItem(
        "Dashboard",
        tabName = "dashboard",
        icon = icon("chart-bar")
      )
    ),
    
    # Filter requests by NYC borough
    selectInput(
      "borough",
      "Select Borough",
      choices = get_borough_choices(data_nyc),
      selected = "All"
    ),
    
    # Search and filter requests by ZIP code
    selectizeInput(
      "zip_code",
      "Select ZIP Code",
      choices = get_zip_choices(data_nyc),
      selected = "All",
      options = list(
        placeholder = "Search ZIP code"
      )
    ),
    
    # Filter requests by complaint category
    selectInput(
      "complaint_type",
      "Select Complaint Type",
      choices = get_complaint_choices(data_nyc),
      selected = "All"
    ),
    
    # Filter requests by responsible NYC agency
    selectInput(
      "agency",
      "Select Agency",
      choices = get_agency_choices(data_nyc),
      selected = "All"
    ),
    
    # Filter requests by creation date
    dateRangeInput(
      "date_range",
      "Select Date Range",
      start = min(
        as.Date(data_nyc$created_date),
        na.rm = TRUE
      ),
      end = max(
        as.Date(data_nyc$created_date),
        na.rm = TRUE
      ),
      min = min(
        as.Date(data_nyc$created_date),
        na.rm = TRUE
      ),
      max = max(
        as.Date(data_nyc$created_date),
        na.rm = TRUE
      )
    )
  ),
  
  
  # -------------------------
  # Main Dashboard
  # -------------------------
  
  dashboardBody(
    
    # Load custom CSS from the www/ directory
    tags$head(
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "custom.css"
      )
    ),
    
    tabItems(
      
      tabItem(
        tabName = "dashboard",
        
        
        # -------------------------
        # Summary Value Boxes
        # -------------------------
        
        fluidRow(
          
          valueBoxOutput(
            "totalRequestsBox",
            width = 4
          ),
          
          valueBoxOutput(
            "topComplaintBox",
            width = 4
          ),
          
          valueBoxOutput(
            "topAgencyBox",
            width = 4
          )
        ),
        
        
        # -------------------------
        # Time Series + Borough Comparison
        # -------------------------
        
        fluidRow(
          
          box(
            title = "311 Requests Over Time",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("timeSeriesPlot")
          ),
          
          box(
            title = "Borough Comparison",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("boroughPlot")
          )
        ),
        
        
        # -------------------------
        # Agency + Complaint Charts
        # -------------------------
        
        fluidRow(
          
          box(
            title = "Top 10 Agencies",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("distPlot")
          ),
          
          box(
            title = "Top 10 Complaint Types",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("complaintPlot")
          )
        )
      )
    )
  )
)


# -------------------------
# Server Logic
# -------------------------

server <- function(input, output) {
  
  
  # -------------------------
  # Reactive Data Filtering
  # -------------------------
  
  # Start with the full dataset and apply each selected
  # dashboard filter in sequence.
  filtered_data <- reactive({
    
    dat <- data_nyc
    
    
    # Filter by borough
    if (!is.null(input$borough) &&
        input$borough != "All") {
      
      dat <- dat %>%
        filter(
          borough == input$borough
        )
    }
    
    
    # Filter by ZIP code
    if (!is.null(input$zip_code) &&
        input$zip_code != "All") {
      
      dat <- dat %>%
        filter(
          incident_zip == input$zip_code
        )
    }
    
    
    # Filter by complaint type
    if (!is.null(input$complaint_type) &&
        input$complaint_type != "All") {
      
      dat <- dat %>%
        filter(
          complaint_type == input$complaint_type
        )
    }
    
    
    # Filter by agency
    if (!is.null(input$agency) &&
        input$agency != "All") {
      
      dat <- dat %>%
        filter(
          agency_name == input$agency
        )
    }
    
    
    # Filter by selected date range
    if (!is.null(input$date_range)) {
      
      dat <- dat %>%
        filter(
          as.Date(created_date) >= input$date_range[1],
          as.Date(created_date) <= input$date_range[2]
        )
    }
    
    
    # Return the filtered dataset for downstream outputs
    dat
  })
  
  
  # -------------------------
  # Summary Data
  # -------------------------
  
  # Count requests by agency and rank from highest to lowest.
  agency_summary <- reactive({
    
    filtered_data() %>%
      filter(
        !is.na(agency_name)
      ) %>%
      count(
        agency_name,
        name = "n"
      ) %>%
      arrange(
        desc(n)
      )
  })
  
  
  # Count requests by complaint type and rank from highest
  # to lowest.
  complaint_summary <- reactive({
    
    filtered_data() %>%
      filter(
        !is.na(complaint_type)
      ) %>%
      count(
        complaint_type,
        name = "n"
      ) %>%
      arrange(
        desc(n)
      )
  })
  
  
  # -------------------------
  # Summary Value Boxes
  # -------------------------
  
  # Display the total number of requests matching the
  # currently selected filters.
  output$totalRequestsBox <- renderValueBox({
    
    valueBox(
      value = scales::comma(
        nrow(filtered_data())
      ),
      subtitle = "Total Requests",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  
  # Display the most common complaint type in the
  # currently filtered dataset.
  output$topComplaintBox <- renderValueBox({
    
    top_complaint <- complaint_summary() %>%
      slice_head(n = 1)
    
    valueBox(
      value = ifelse(
        nrow(top_complaint) == 0,
        "No Data",
        top_complaint$complaint_type
      ),
      subtitle = "Top Complaint",
      icon = icon("exclamation-circle"),
      color = "yellow"
    )
  })
  
  
  # Display the agency receiving the greatest number
  # of requests in the currently filtered dataset.
  output$topAgencyBox <- renderValueBox({
    
    top_agency <- agency_summary() %>%
      slice_head(n = 1)
    
    valueBox(
      value = ifelse(
        nrow(top_agency) == 0,
        "No Data",
        top_agency$agency_name
      ),
      subtitle = "Top Agency",
      icon = icon("building"),
      color = "green"
    )
  })
  
  
  # -------------------------
  # Interactive Visualizations
  # -------------------------
  
  # Display request volume over time.
  output$timeSeriesPlot <- renderPlotly({
    
    plot <- create_time_series_plot(
      filtered_data()
    )
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
  
  
  # Compare request volume across NYC boroughs.
  output$boroughPlot <- renderPlotly({
    
    plot <- create_borough_plot(
      filtered_data()
    )
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
  
  
  # Display the agencies receiving the most requests.
  output$distPlot <- renderPlotly({
    
    plot <- create_agency_plot(
      filtered_data()
    )
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
  
  
  # Display the most common complaint types.
  output$complaintPlot <- renderPlotly({
    
    plot <- create_complaint_plot(
      filtered_data()
    )
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
}


# -------------------------
# Launch Application
# -------------------------

shinyApp(
  ui = ui,
  server = server
)