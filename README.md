# NYC 311 Shiny Dashboard

An interactive R Shiny dashboard for exploring NYC 311 service request data from NYC Open Data.

The dashboard allows users to explore approximately one year of 311 service requests by borough, ZIP code, complaint type, agency, and date range. Interactive visualizations and summary metrics update automatically based on the selected filters.

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

The application retrieves approximately one year of NYC 311 service requests for interactive exploration. Because a full year contains millions of records, data are retrieved in smaller date-based chunks and combined into a complete dataset.

If an individual API request reaches the 100,000-row retrieval limit, the application automatically divides that date range into smaller requests to avoid silently truncating the data.

The most recent potentially incomplete day is excluded from the retrieval window so that the dashboard does not display a partially reported day as though it were complete.

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

To reduce repeated API requests and provide a fallback when NYC Open Data is temporarily unavailable, the application uses local caching for NYC 311 data.

The complete combined dataset is stored locally at:

```text
data/311_cache.rds
```

Individual successfully retrieved date chunks are stored in:

```text
data/311_chunks/
```

Both the complete cache and individual chunk files are excluded from Git using `.gitignore` and are not included in the repository.

When the application starts, it checks whether a recent complete cached dataset is available. If the cache is less than 24 hours old, the cached data are used.

If a recent complete cache is not available, the application retrieves the approximately one-year dataset in smaller date-based chunks. Successfully retrieved chunks are saved individually so they can be reused if an API request fails before the full refresh is completed.

If a requested chunk reaches the 100,000-row API limit, the application automatically divides that date range into smaller requests and combines the results.

After all required chunks are successfully retrieved, they are combined and saved as the complete local cache.

If the yearly refresh cannot be completed but an older complete cache is available, the application uses that dataset as a fallback. If neither a complete refresh nor an existing complete cache is available, the application stops and displays an error message.

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

Displays the geographic locations of NYC 311 service requests using an interactive grayscale street map. Request locations are color-coded by borough, and users can zoom, pan, and select individual points to view the borough, complaint type, and responsible agency.

To maintain dashboard responsiveness when a large number of requests match the selected filters, the map displays a reproducible sample of up to 10,000 request locations. Summary metrics, filters, and other visualizations continue to use the complete filtered dataset.

### Top 10 Agencies

Displays the agencies associated with the greatest number of service requests within the selected filters. Agency acronyms are used where available to improve readability, while full agency names and exact request counts are available through interactive tooltips.

### Top 10 Complaint Types

Displays the most common complaint types within the selected filters. Exact request counts are available through interactive tooltips.

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
│   └── 311_chunks/
├── www/
│   └── custom.css
├── .gitignore
├── README.md
└── nyc-311-app.Rproj
```

### `app.R`

Defines the Shiny user interface, server logic, reactive filtering, summary value boxes, interactive Plotly charts, and Leaflet map.

### `R/data.R`

Contains functions for retrieving, caching, validating, and cleaning NYC 311 service request data. Large API requests are divided into smaller date ranges when necessary to avoid incomplete retrievals.

### `R/helpers.R`

Contains reusable helper functions used to generate choices for the dashboard filters.

### `R/plots.R`

Contains reusable functions for creating the dashboard visualizations and interactive request map.

### `data/`

Stores the complete local NYC 311 cache and individual date-chunk caches used by the data retrieval workflow. These cached files are excluded from version control.

### `www/custom.css`

Contains custom CSS used to style and polish the dashboard interface, including the grayscale Leaflet basemap treatment.

## Error Handling

The dashboard is designed to handle filter combinations that return no matching service requests without causing the application to crash.

When no records match the selected filters, the dashboard summary displays zero requests and "No Data" where appropriate. The visualizations also provide no-data handling for empty filter results.

The data-loading workflow saves successfully retrieved date chunks as they are downloaded. If an API request fails during a yearly refresh, completed chunks remain available for reuse during a later attempt.

If the refresh cannot be completed but an older complete cache is available, the dashboard uses the existing cached dataset as a fallback.

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
- User-selectable historical periods beyond the current one-year window
- Additional interactive visualizations
- Alternative ways of representing NYC 311 data, including data sonification

## Repository Status

This dashboard was developed as part of the NYC Open Data Lab internship program.

The application has been tested for dashboard filtering, interactive visualization, empty-result handling, full-year data retrieval, and data-loading behavior and is ready for public release and future extension.