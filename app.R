#
# NYC 311 Shiny Dashboard
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

# TEMPORARILY COMMENTED OUT FOR WEEK 4 DEVELOPMENT
# NYC Open Data is currently returning a 503 error.
# Existing 50,000-row "trying" object is being used instead.

trying <- get_311_data()
trying <- clean_311_data(trying)


# -------------------------
# User Interface
# -------------------------

ui <- dashboardPage(
  
  dashboardHeader(
    title = "NYC 311 Dashboard"
  ),
  
  dashboardSidebar(
    
    sidebarMenu(
      menuItem(
        "Dashboard",
        tabName = "dashboard",
        icon = icon("chart-bar")
      )
    ),
    
    # Borough selector
    selectInput(
      "borough",
      "Select Borough",
      choices = get_borough_choices(trying),
      selected = "All"
    ),
    
    # ZIP code selector
    selectizeInput(
      "zip_code",
      "Select ZIP Code",
      choices = get_zip_choices(trying),
      selected = "All",
      options = list(
        placeholder = "Search ZIP code"
      )
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
  
  dashboardBody(
    
    # Custom dashboard styling
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
        # Value Boxes
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
        # Time Series
        # -------------------------
        
        fluidRow(
          
          box(
            title = "311 Requests Over Time",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("timeSeriesPlot")
          )
        ),
        
        
        # -------------------------
        # Borough + Agency Charts
        # -------------------------
        
        fluidRow(
          
          box(
            title = "Borough Comparison",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("boroughPlot")
          ),
          
          box(
            title = "Top 10 Agencies",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("distPlot")
          )
        ),
        
        
        # -------------------------
        # Complaint Type Chart
        # -------------------------
        
        fluidRow(
          
          box(
            title = "Top 10 Complaint Types",
            width = 12,
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("complaintPlot")
          )
        ),
        
        
        # -------------------------
        # Tables
        # -------------------------
        
        fluidRow(
          
          box(
            title = "Top Complaints Table",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            DTOutput("complaintTable")
          ),
          
          box(
            title = "Agency Summary Table",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            DTOutput("agencyTable")
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
  # Filter Data
  # -------------------------
  
  filtered_data <- reactive({
    
    dat <- trying
    
    
    # Filter by borough
    if (!is.null(input$borough) &&
        input$borough != "All") {
      
      dat <- dat %>%
        filter(borough == input$borough)
    }
    
    # Filter by ZIP code
    if (!is.null(input$zip_code) &&
        input$zip_code != "All") {
      
      dat <- dat %>%
        filter(incident_zip == input$zip_code)
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
    
    
    dat
  })
  
  
  # -------------------------
  # Agency Summary
  # -------------------------
  
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
  # Value Boxes
  # -------------------------
  
  output$totalRequestsBox <- renderValueBox({
    
    valueBox(
      value = scales::comma(nrow(filtered_data())),
      subtitle = "Total Requests",
      icon = icon("list"),
      color = "blue"
    )
  })
  
  
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
  # Time Series Plot
  # -------------------------
  
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