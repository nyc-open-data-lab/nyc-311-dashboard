#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
# https://shiny.posit.co/
#

library(shiny)
library(shinydashboard)
library(shinythemes)
library(tidyverse)
library(DT)
library(plotly)

library(nycOpenData)


# -------------------------
# Load Helper Scripts
# -------------------------

source("R/data.R")
source("R/plots.R")
source("R/helpers.R")


# -------------------------
# Load and Clean Data
# -------------------------

trying <- get_311_data()
trying <- clean_311_data(trying)


# -------------------------
# User Interface
# -------------------------

ui <- fluidPage(
  
  # Application title
  titlePanel("NYC 311 Data"),
  
  sidebarLayout(
    
    # -------------------------
    # Sidebar Controls
    # -------------------------
    
    sidebarPanel(
      
      # Borough selector
      selectInput(
        "borough",
        "Select Borough",
        choices = get_borough_choices(trying),
        selected = "All"
      ),
      
      # Complaint type selector
      selectInput(
        "complaint_type",
        "Select Complaint Type",
        choices = get_complaint_choices(trying),
        selected = "All"
      ),
      
      # Agency selector
      selectInput(
        "agency",
        "Select Agency",
        choices = get_agency_choices(trying),
        selected = "All"
      ),
      
      # Date range selector
      dateRangeInput(
        "date_range",
        "Select Date Range",
        start = min(as.Date(trying$created_date), na.rm = TRUE),
        end = max(as.Date(trying$created_date), na.rm = TRUE),
        min = min(as.Date(trying$created_date), na.rm = TRUE),
        max = max(as.Date(trying$created_date), na.rm = TRUE)
      )
    ),
    
    
    # -------------------------
    # Main Dashboard Content
    # -------------------------
    
    mainPanel(
      
      # Complaint count
      h3("Complaint Count"),
      
      textOutput("complaintCount"),
      
      br(),
      
      
      # Time series
      h3("311 Requests Over Time"),
      
      plotlyOutput("timeSeriesPlot"),
      
      br(),
      
      # Borough comparison
      h3("Borough Comparison"),
      
      plotlyOutput("boroughPlot"),
      
      br(),
      
      # Agency visualization
      h3("Top 10 Agencies Receiving 311 Requests"),
      
      plotlyOutput("distPlot"),
      
      br(),
      
      
      # Complaint type visualization
      h3("Top 10 Complaint Types"),
      
      plotlyOutput("complaintPlot"),
      
      br(),
      
      
      # Top complaints table
      h3("Top Complaints Table"),
      
      DTOutput("complaintTable"),
      
      br(),
      
      
      # Agency summary table
      h3("Agency Summary Table"),
      
      DTOutput("agencyTable")
    )
  )
)


# -------------------------
# Server Logic
# -------------------------

server <- function(input, output) {
  
  
  # -------------------------
  # Filter Data
  # -------------------------
  
  # Filter the dataset based on user selections
  filtered_data <- reactive({
    
    # Create a working copy of the original data
    dat <- trying
    
    
    # Filter by borough
    if (!is.null(input$borough) &&
        input$borough != "All") {
      
      dat <- dat %>%
        filter(borough == input$borough)
    }
    
    
    # Filter by complaint type
    if (!is.null(input$complaint_type) &&
        input$complaint_type != "All") {
      
      dat <- dat %>%
        filter(complaint_type == input$complaint_type)
    }
    
    
    # Filter by agency
    if (!is.null(input$agency) &&
        input$agency != "All") {
      
      dat <- dat %>%
        filter(agency_name == input$agency)
    }
    
    
    # Filter by date range
    if (!is.null(input$date_range)) {
      
      dat <- dat %>%
        filter(
          as.Date(created_date) >= input$date_range[1],
          as.Date(created_date) <= input$date_range[2]
        )
    }
    
    
    # Return the filtered dataset
    dat
  })
  
  
  # -------------------------
  # Complaint Count
  # -------------------------
  
  # Display the number of complaints matching the selected filters
  output$complaintCount <- renderText({
    
    paste(
      scales::comma(nrow(filtered_data())),
      "311 Requests"
    )
  })
  
  
  # -------------------------
  # Agency Summary
  # -------------------------
  
  # Summarize the number of requests submitted to each agency
  agency_summary <- reactive({
    
    filtered_data() %>%
      filter(!is.na(agency_name)) %>%
      count(
        agency_name,
        name = "n"
      ) %>%
      arrange(desc(n))
  })
  
  
  # -------------------------
  # Complaint Summary
  # -------------------------
  
  # Summarize the number of requests for each complaint type
  complaint_summary <- reactive({
    
    filtered_data() %>%
      filter(!is.na(complaint_type)) %>%
      count(
        complaint_type,
        name = "n"
      ) %>%
      arrange(desc(n))
  })
  
  
  # -------------------------
  # Time Series Plot
  # -------------------------
  
  # Render an interactive time-series chart
  output$timeSeriesPlot <- renderPlotly({
    
    plot <- create_time_series_plot(filtered_data())
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
  
  # -------------------------
  # Borough Comparison Plot
  # -------------------------
  
  # Render an interactive bar chart comparing boroughs
  output$boroughPlot <- renderPlotly({
    
    plot <- create_borough_plot(filtered_data())
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
  
  # -------------------------
  # Agency Plot
  # -------------------------
  
  # Render an interactive bar chart of the top agencies
  output$distPlot <- renderPlotly({
    
    plot <- create_agency_plot(filtered_data())
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
  
  
  # -------------------------
  # Complaint Type Plot
  # -------------------------
  
  # Render an interactive bar chart of the top complaint types
  output$complaintPlot <- renderPlotly({
    
    plot <- create_complaint_plot(filtered_data())
    
    ggplotly(
      plot,
      tooltip = "text"
    )
  })
  
  
  # -------------------------
  # Top Complaints Table
  # -------------------------
  
  # Render an interactive table of the top complaint types
  output$complaintTable <- renderDT({
    
    complaint_summary() %>%
      slice_head(n = 10) %>%
      rename(
        `Complaint Type` = complaint_type,
        `Number of Requests` = n
      )
    
  },
  options = list(
    pageLength = 10,
    order = list(
      list(1, "desc")
    )
  ),
  rownames = FALSE
  )
  
  
  # -------------------------
  # Agency Summary Table
  # -------------------------
  
  # Render an interactive table of agency request counts
  output$agencyTable <- renderDT({
    
    agency_summary() %>%
      rename(
        Agency = agency_name,
        `Number of Requests` = n
      )
    
  },
  options = list(
    pageLength = 10,
    order = list(
      list(1, "desc")
    )
  ),
  rownames = FALSE
  )
}


# -------------------------
# Run Application
# -------------------------

shinyApp(
  ui = ui,
  server = server
)