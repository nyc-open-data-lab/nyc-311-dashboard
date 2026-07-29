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

# Load available NYC Open Data datasets
blah <- nyc_list_datasets()

# Load NYC 311 service request data
trying <- nyc_pull_dataset(
  dataset = "erm2-nwe9",
  date_field = "created_date"
)


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
        choices = c(
          "All",
          sort(unique(na.omit(trying$borough)))
        ),
        selected = "All"
      )
    ),
    
    # Main dashboard content
    mainPanel(
      
      h3("Top 10 Agencies Receiving 311 Requests"),
      
      # Interactive Plotly chart
      plotlyOutput("distPlot"),
      
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
  
  
  # Render an interactive bar chart of the top ten agencies.
  output$distPlot <- renderPlotly({
    
    plot_data <- agency_summary() %>%
      slice_max(
        order_by = n,
        n = 10,
        with_ties = FALSE
      )
    
    agency_plot <- plot_data %>%
      ggplot(
        aes(
          x = reorder(agency_name, n),
          y = n,
          text = paste0(
            "Agency: ",
            agency_name,
            "<br>Requests: ",
            scales::comma(n)
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
    
    ggplotly(
      agency_plot,
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