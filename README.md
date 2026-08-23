# NYC 311 Interactive Dashboard

An interactive R Shiny dashboard for exploring NYC 311 service request data from NYC Open Data.

The dashboard allows users to explore recent 311 service requests by borough, ZIP code, complaint type, agency, and date range. Interactive visualizations and summary metrics update automatically based on the selected filters.

## Features

The dashboard includes:

- Interactive filtering by borough
- Searchable ZIP code filtering
- Filtering by complaint type
- Filtering by NYC agency
- Custom date range selection
- Total request count
- Most common complaint type
- Agency receiving the most requests
- Interactive time-series visualization of requests over time
- Borough comparison chart
- Top 10 agency chart
- Top 10 complaint type chart
- Interactive Plotly tooltips
- Graceful handling of filter combinations with no matching records
- Local data caching to improve loading speed and provide a fallback when the NYC Open Data API is temporarily unavailable

## Built With

- R
- Shiny
- shinydashboard
- tidyverse
- ggplot2
- Plotly
- nycOpenData

## Data Source

The dashboard uses NYC 311 Service Requests data available through NYC Open Data.

Dataset ID:

`erm2-nwe9`

Data are retrieved using the `nycOpenData` R package.

The dashboard currently retrieves up to 50,000 recent service requests for interactive exploration.

## Installation

### 1. Clone the Repository

Clone the repository from GitHub:

```bash
git clone https://github.com/nyc-open-data-lab/nyc-311-dashboard.git
```

Then open the project in RStudio.

### 2. Install Required R Packages

Install the required packages if they are not already installed:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinythemes",
  "tidyverse",
  "plotly"
))
```

Install `nycOpenData` if needed:

```r
install.packages("nycOpenData")
```

### 3. Run the Dashboard

Open `app.R` in RStudio and click **Run App**, or run:

```r
shiny::runApp()
```

The dashboard will open in the RStudio Viewer or your web browser.

## Data Caching

To improve startup speed and reduce repeated API requests, the application uses a local cache for NYC 311 data.

The cache file is stored locally at:

```text
data/311_cache.rds
```

This file is excluded from Git using `.gitignore` and is not included in the repository.

When a local cache is unavailable, the application retrieves data from NYC Open Data and creates a new cache for future use.

If the NYC Open Data API is temporarily unavailable and a local cache exists, the application can use the cached data as a fallback.

## Dashboard Filters

Users can filter service requests using:

- **Borough** — Explore requests within a selected NYC borough.
- **ZIP Code** — Search for requests within a specific ZIP code.
- **Complaint Type** — Filter requests by the type of reported issue.
- **Agency** — Filter requests based on the NYC agency responsible for the request.
- **Date Range** — Limit results to a selected period.

Filters can also be combined for more specific exploration.

## Visualizations

### 311 Requests Over Time

Displays the number of service requests submitted each day within the selected filters.

### Borough Comparison

Compares the number of service requests across NYC boroughs.

### Top 10 Agencies

Displays the agencies receiving the greatest number of service requests within the selected filters.

### Top 10 Complaint Types

Displays the most common complaint types within the selected filters.

All visualizations update reactively when filters are changed.

## Project Structure

```text
nyc-311-dashboard/
├── app.R
├── R/
│   ├── data.R
│   ├── helpers.R
│   └── plots.R
├── www/
│   └── custom.css
├── data/
├── .gitignore
├── README.md
└── nyc-311-app.Rproj
```

### `app.R`

Defines the Shiny user interface, server logic, reactive filtering, summary value boxes, and interactive Plotly outputs.

### `R/data.R`

Contains functions for retrieving, caching, and cleaning NYC 311 data.

### `R/helpers.R`

Contains reusable helper functions used to generate dashboard filter choices.

### `R/plots.R`

Contains reusable functions for creating the dashboard visualizations.

### `www/custom.css`

Contains custom CSS used to style and polish the dashboard interface.

## Error Handling

The dashboard is designed to handle filter combinations that return no matching service requests. When no data match the selected filters, the visualizations display a message rather than producing an application error.

The data-loading workflow also provides a local cache fallback when possible if the NYC Open Data API is temporarily unavailable.

## Repository Status

This dashboard was developed as part of the NYC Open Data Lab internship program.

The project is currently being tested and prepared for public release.