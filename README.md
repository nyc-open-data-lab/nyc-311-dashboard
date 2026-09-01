# NYC 311 Shiny Dashboard

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
- Interactive map of NYC 311 requests with points color-coded by borough
- Top 10 agency chart
- Top 10 complaint type chart
- Interactive Plotly tooltips
- Graceful handling of filter combinations with no matching records
- Local data caching to improve reliability and reduce repeated API requests

## Built With

- R
- Shiny
- shinydashboard
- tidyverse
- ggplot2
- Plotly
- Leaflet
- nycOpenData

## Data Source

The dashboard uses NYC 311 Service Requests data available through NYC Open Data.

Dataset ID:

`erm2-nwe9`

Data are retrieved using the `nycOpenData` R package.

The application retrieves up to 50,000 recent service requests for interactive exploration.

## Installation

### 1. Clone the Repository

Clone the repository from GitHub:

```bash
git clone https://github.com/nyc-open-data-lab/nyc-311-dashboard.git
```

Navigate to the cloned repository and open the RStudio project file:

`nyc-311-app.Rproj`

### 2. Install Required R Packages

Install the required packages if they are not already installed:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinythemes",
  "tidyverse",
  "plotly",
  "leaflet",
  "nycOpenData"
))
```

### 3. Run the Dashboard

Open `app.R` in RStudio and click **Run App**.

Alternatively, run the following command from the project directory:

```r
shiny::runApp()
```

The dashboard will open in the RStudio Viewer or your web browser.

## Data Caching

To reduce repeated API requests and provide a fallback when NYC Open Data is temporarily unavailable, the application uses a local cache for NYC 311 data.

The cache is stored locally at:

```text
data/311_cache.rds
```

This file is excluded from Git using `.gitignore` and is not included in the repository.

When the application starts, it checks whether a recent cached dataset is available. If the cache is less than 24 hours old, the cached data are used.

If a recent cache is not available, the application attempts to retrieve fresh data from NYC Open Data and saves the retrieved data locally for future use.

If the NYC Open Data request fails but an existing cache is available, the application uses the cached data as a fallback.

If neither live data nor a cached dataset is available, the application stops and displays an error message.

## Dashboard Filters

Users can filter service requests using:

- **Borough** — Explore requests within a selected NYC borough.
- **ZIP Code** — Search for requests within a specific ZIP code.
- **Complaint Type** — Filter requests by the type of reported issue.
- **Agency** — Filter requests based on the NYC agency associated with the request.
- **Date Range** — Limit results to a selected period.

Filters can be combined to explore more specific subsets of NYC 311 requests.

## Dashboard Summary

Three summary boxes provide a quick overview of the currently filtered data:

- **Total Requests** — Number of service requests matching the selected filters.
- **Top Complaint** — Most common complaint type within the filtered data.
- **Top Agency** — Agency associated with the greatest number of requests within the filtered data.

These summaries update automatically when filters are changed.

## Visualizations

### 311 Requests Over Time

Displays the number of service requests submitted each day within the selected filters.

### NYC 311 Request Map

Displays the geographic locations of NYC 311 service requests using an interactive map. Request locations are color-coded by borough, and users can zoom, pan, and select individual points to view the borough, complaint type, and responsible agency.

### Top 10 Agencies

Displays the agencies associated with the greatest number of service requests within the selected filters.

### Top 10 Complaint Types

Displays the most common complaint types within the selected filters.

The visualizations update reactively as dashboard filters are changed. Plotly charts include interactive tooltips, while the Leaflet map supports zooming, panning, and clickable request locations.

## Project Structure

```text
nyc-311-dashboard/
├── app.R
├── R/
│   ├── data.R
│   ├── helpers.R
│   └── plots.R
├── data/
├── www/
│   └── custom.css
├── .gitignore
├── README.md
└── nyc-311-app.Rproj
```

### `app.R`

Defines the Shiny user interface, server logic, reactive filtering, summary value boxes, interactive Plotly charts, and Leaflet map.

### `R/data.R`

Contains functions for retrieving, caching, and cleaning NYC 311 service request data.

### `R/helpers.R`

Contains reusable helper functions used to generate choices for the dashboard filters.

### `R/plots.R`

Contains reusable functions for creating the dashboard visualizations and interactive request map.

### `data/`

Stores the local NYC 311 data cache. The cached `.rds` file is excluded from version control.

### `www/custom.css`

Contains custom CSS used to style and polish the dashboard interface.

## Error Handling

The dashboard is designed to handle filter combinations that return no matching service requests without causing the application to crash.

When no records match the selected filters, the dashboard summary displays zero requests and "No Data" where appropriate. The chart outputs also provide no-data handling for empty filter results.

The data-loading workflow uses a local cache as a fallback when possible if the NYC Open Data API is temporarily unavailable.

## Usage

After launching the dashboard:

1. Select a borough or leave the filter set to **All**.
2. Optionally select a ZIP code.
3. Select a complaint type or leave it set to **All**.
4. Select an agency or leave it set to **All**.
5. Adjust the date range if desired.
6. Explore the updated summary metrics and interactive visualizations.

Multiple filters can be applied at the same time.

## Future Improvements

Potential future extensions of the dashboard include:

- Additional geographic analysis and map features
- Expanded historical data coverage
- Additional interactive visualizations
- Alternative ways of representing NYC 311 data, including data sonification

## Repository Status

This dashboard was developed as part of the NYC Open Data Lab internship program.

The application has been tested for dashboard filtering, interactive visualization, empty-result handling, and data-loading behavior and is being finalized for public release.