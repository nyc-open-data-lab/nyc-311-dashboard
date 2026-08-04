#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(shinydashboard)
library(shinythemes)
library(tidyverse)
library(DT)
library(plotly)

library(nycOpenData)

source("R/data.R")
source("R/plots.R")
source("R/helpers.R")

trying <- get_311_data()
trying <- clean_311_data(trying)

# -------------------------
# User Interface
# -------------------------

ui <- fluidPage(
  
  # Application title
  titlePanel("NYC 311 Data"),
  
  sidebarLayout(
    
    # Sidebar controls
    sidebarPanel(
      
      # Borough selector
      selectInput(
        "borough",
        "Select Borough",
        choices = get_borough_choices(trying),
        selected = "All"
      )
    ),
    
    # Main dashboard content
    mainPanel(
      
      h3("Top 10 Agencies Receiving 311 Requests"),
      
      # Interactive agency chart
      plotlyOutput("distPlot"),
      
      br(),
      
      h3("Top 10 Complaint Types"),
      
      # Interactive complaint-type chart
      plotlyOutput("complaintPlot"),
      
      br(),
      
      h3("Agency Summary Table"),
      
      # Interactive data table
      DTOutput("agencyTable")
    )
  )
)


# -------------------------
# Server Logic
# -------------------------

server <- function(input, output) {
  
  # Filter the dataset based on the selected borough.
  # Selecting "All" displays the complete dataset.
  filtered_data <- reactive({
    
    dat <- trying
    
    if (!is.null(input$borough) && input$borough != "All") {
      dat <- dat %>%
        filter(borough == input$borough)
    }
    
    dat
  })
  
  
  # Summarize the number of requests submitted to each agency.
  agency_summary <- reactive({
    
    filtered_data() %>%
      count(
        agency_name,
        name = "n"
      ) %>%
      arrange(desc(n))
  })
  
  
  output$distPlot <- renderPlotly({
    
    plot <- create_agency_plot(filtered_data())
    
    ggplotly(
      plot,
      tooltip = "text"
    )
    
  })
  
  # Render an interactive bar chart of the top complaint types
  output$complaintPlot <- renderPlotly({
    
    plot <- create_complaint_plot(filtered_data())
    
    ggplotly(
      plot,
      tooltip = "text"
    )
    
  })
  
  # Render an interactive summary table of agency request counts.
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


# Run the application
shinyApp(
  ui = ui,
  server = server
)