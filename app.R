# NYC 311 Shiny Dashboard


# -------------------------
# Packages
# -------------------------

# Core dashboard packages
library(shiny)
library(shinydashboard)
library(shinythemes)
library(tidyverse)
library(plotly)
library(leaflet)

# Sonification and audio packages
library(sonify)
library(tuneR)

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

# Load 2026-to-date NYC 311 data from the local cache.
data_nyc <- get_311_data()

# Clean the data and create a reusable request-date column.
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
    
    # Filter requests by NYC borough.
    selectInput(
      "borough",
      "Select Borough",
      choices = get_borough_choices(data_nyc),
      selected = "All"
    ),
    
    # Search and filter requests by ZIP code.
    selectizeInput(
      "zip_code",
      "Select ZIP Code",
      choices = get_zip_choices(data_nyc),
      selected = "All",
      options = list(
        placeholder = "Search ZIP code"
      )
    ),
    
    # Filter requests by complaint category.
    selectInput(
      "complaint_type",
      "Select Complaint Type",
      choices = get_complaint_choices(data_nyc),
      selected = "All"
    ),
    
    # Filter requests by responsible NYC agency.
    selectInput(
      "agency",
      "Select Agency",
      choices = get_agency_choices(data_nyc),
      selected = "All"
    ),
    
    # Filter requests by creation date.
    # Default to the latest 7 days available in the dataset,
    # while allowing users to select the full available range.
    dateRangeInput(
      "date_range",
      "Select Date Range",
      start = max(
        data_nyc$request_date,
        na.rm = TRUE
      ) - 6,
      end = max(
        data_nyc$request_date,
        na.rm = TRUE
      ),
      min = min(
        data_nyc$request_date,
        na.rm = TRUE
      ),
      max = max(
        data_nyc$request_date,
        na.rm = TRUE
      )
    )
  ),
  
  
  # -------------------------
  # Main Dashboard
  # -------------------------
  
  dashboardBody(
    
    # Load custom CSS from the www/ directory.
    tags$head(
      
      tags$link(
        rel = "stylesheet",
        type = "text/css",
        href = "custom.css"
      ),
      
      # Google Analytics
      tags$script(
        async = NA,
        src = "https://www.googletagmanager.com/gtag/js?id=G-V238GJK21R"
      ),
      
      tags$script(
        HTML("
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', 'G-V238GJK21R');
    ")
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
        # Time Series + Request Map
        # -------------------------
        
        fluidRow(
          
          box(
            title = "311 Requests Over Time",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            
            plotlyOutput(
              "timeSeriesPlot"
            ),
            
            br(),
            
            actionButton(
              "playSonification",
              "Play Sonification",
              icon = icon("play")
            ),
            
            uiOutput(
              "sonificationPlayer"
            )
          ),
          
          box(
            title = "311 Request Map",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            
            leafletOutput(
              "requestMap",
              height = 400
            )
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
            
            plotlyOutput(
              "distPlot"
            )
          ),
          
          box(
            title = "Top 10 Complaint Types",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            
            plotlyOutput(
              "complaintPlot"
            )
          )
        )
      )
    ),
    # Dashboard footer
    tags$footer(
      class = "dashboard-footer",
      
      "Created by ",
      
      tags$a(
        "Emma Tupone",
        href = "https://www.linkedin.com/in/emma-tupone/",
        target = "_blank"
      ),
      
      " and ",
      
      tags$a(
        "Christian Martinez",
        href = "https://www.linkedin.com/in/christian-a-martinez/",
        target = "_blank"
      ),
      
      " · ",
      
      tags$a(
        "The Open Data Lab",
        href = "https://nycopendatalab.org",
        target = "_blank"
      )
    )
  )
)


# -------------------------
# Server Logic
# -------------------------

server <- function(input, output, session) {
  
  
  # -------------------------
  # Reactive Data Filtering
  # -------------------------
  
  # Start with the full dataset and apply each
  # selected dashboard filter in sequence.
  filtered_data <- reactive({
    
    dat <- data_nyc
    
    
    # Filter by borough.
    if (!is.null(input$borough) &&
        input$borough != "All") {
      
      dat <- dat %>%
        filter(
          borough == input$borough
        )
    }
    
    
    # Filter by ZIP code.
    if (!is.null(input$zip_code) &&
        input$zip_code != "All") {
      
      dat <- dat %>%
        filter(
          incident_zip == input$zip_code
        )
    }
    
    
    # Filter by complaint type.
    if (!is.null(input$complaint_type) &&
        input$complaint_type != "All") {
      
      dat <- dat %>%
        filter(
          complaint_type == input$complaint_type
        )
    }
    
    
    # Filter by agency.
    if (!is.null(input$agency) &&
        input$agency != "All") {
      
      dat <- dat %>%
        filter(
          agency_name == input$agency
        )
    }
    
    
    # Filter by selected date range.
    if (!is.null(input$date_range)) {
      
      dat <- dat %>%
        filter(
          request_date >= input$date_range[1],
          request_date <= input$date_range[2]
        )
    }
    
    
    # Return the filtered dataset for downstream outputs.
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
  # Sonification Data
  # -------------------------
  
  # Summarize the currently filtered requests by day so
  # the sonification matches the time-series visualization.
  sonification_data <- reactive({
    
    filtered_data() %>%
      filter(
        !is.na(request_date)
      ) %>%
      count(
        request_date,
        name = "n"
      ) %>%
      arrange(
        request_date
      )
  })
  
  
  # -------------------------
  # Sonification Generation
  # -------------------------
  
  # Track when a new sonification has been generated.
  # This also gives each audio source a unique URL so
  # the browser does not reuse an older cached recording.
  sonification_version <- reactiveVal(0)
  
  
  # Generate a new sonification only when the user
  # presses the Play Sonification button.
  observeEvent(input$playSonification, {
    
    sonify_data <- sonification_data()
    
    
    # Require at least two daily observations to create
    # a meaningful sonification.
    if (nrow(sonify_data) < 2) {
      
      showNotification(
        "Not enough data to create a sonification for the current filters.",
        type = "warning"
      )
      
      return()
    }
    
    
    # Generate a sonification using the same daily request
    # counts represented by the time-series chart.
    # The duration matches the number of days displayed.
    sonification_audio <- sonify(
      x = seq_len(
        nrow(sonify_data)
      ),
      y = sonify_data$n,
      waveform = "triangle",
      interpolation = "linear",
      duration = nrow(sonify_data),
      flim = c(
        220,
        440
      ),
      pulse_len = 0.03,
      pulse_amp = 0.1
    )
    
    
    # Save the generated audio file in the www directory
    # so it can be served by the Shiny application.
    writeWave(
      sonification_audio,
      filename = "www/sonification.wav"
    )
    
    
    # Increment the version after the new audio file
    # has been successfully created.
    sonification_version(
      sonification_version() + 1
    )
  })
  
  
  # Display an audio player after the first sonification
  # has been generated. Autoplay allows the sound to begin
  # after the user presses the Play Sonification button.
  output$sonificationPlayer <- renderUI({
    
    req(
      sonification_version() > 0
    )
    
    tags$audio(
      id = "sonificationAudio",
      controls = NA,
      autoplay = NA,
      src = paste0(
        "sonification.wav?v=",
        sonification_version()
      ),
      type = "audio/wav",
      style = "width: 100%; margin-top: 10px;"
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
  
  
  # Display NYC 311 request locations on an interactive map.
  output$requestMap <- renderLeaflet({
    
    create_311_map(
      filtered_data()
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