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


blah <- nyc_list_datasets()

trying <- nyc_pull_dataset(dataset = "erm2-nwe9", date_field = "created_date")

plot_trying <- ggplot(trying, aes(x = agency_name)) +
  geom_bar()

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("NYC 311 Data"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput("borough", "Select Borough",
                        choices = c(All = "All", trying$borough),
                        selected = "All")
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("distPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  output$distPlot <- renderPlot({
    dat <- trying
    
    if (!is.null(input$borough) && input$borough != "All") {
      dat <- dat %>% filter(borough == input$borough)
    }
    
    dat %>%
      count(agency_name, name = "n") %>%
      slice_max(n, n = 10) %>%
      ggplot(aes(x = reorder(agency_name, n), y = n, fill = agency_name)) +
      geom_col() +
      coord_flip() +
      labs(title = "Counts By Agency", x = "Agency", y = "") +
      theme(legend.position = "none")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
