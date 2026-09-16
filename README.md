# NYC 311 Shiny Dashboard

An interactive R Shiny dashboard for exploring NYC 311 service request data from NYC Open Data.

The dashboard allows users to explore NYC 311 service requests from January 1, 2026 through the most recent complete date available to the dashboard by borough, ZIP code, complaint type, agency, and date range. Interactive visualizations, summary metrics, and an auditory representation of request trends respond to the selected filters.

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
- Data sonification of the filtered daily request trend
- Interactive map of NYC 311 requests with points color-coded by borough
- Map popups showing borough, ZIP code, complaint type, and responsible agency
- Top 10 agency chart
- Top 10 complaint type chart
- Interactive Plotly tooltips
- Graceful handling of filter combinations with no matching records
- Local gzip-compressed Parquet caching to improve startup reliability and reduce repeated API requests
- Separate incremental data-refresh workflow for updating the cache

## Built With

- R
- Shiny
- shinydashboard
- shinythemes
- tidyverse
- ggplot2
- Plotly
- Leaflet
- nycOpenData
- arrow
- sonify
- tuneR

## Data Source

The dashboard uses NYC 311 Service Requests data available through NYC Open Data.

Dataset ID:

`erm2-nwe9`

Data are retrieved using the `nycOpenData` R package.

The dashboard is designed around NYC 311 service requests beginning January 1, 2026 and extending through the most recent complete date available to the dashboard. Because this period contains millions of records, the data-retrieval workflow supports smaller date-based chunks and automatically divides an individual request into smaller ranges if it reaches the 100,000-row retrieval limit.

To reduce the risk of displaying a partially reported day as though it were complete, the refresh workflow uses a conservative cutoff and updates through two calendar days before the refresh date.

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
  "nycOpenData",
  "arrow",
  "sonify",
  "tuneR"
))
```

### 3. Prepare the Data Cache

The Shiny application loads its NYC 311 data from:

```text
data/311_cache.parquet
```

Normal app startup does not retrieve the complete 2026-to-date dataset from the API. A valid cache must therefore be available before the dashboard is launched.

The `refresh_311_data()` function in `R/data.R` is used separately from normal Shiny startup to incrementally update an existing cache with newly available complete days.

### 4. Run the Dashboard

Open `app.R` in RStudio and click **Run App**.

Alternatively, run the following command from the project directory:

```r
shiny::runApp()
```

The dashboard will open in the RStudio Viewer or your web browser.

## Data Caching and Refreshing

To improve startup reliability and avoid downloading millions of records whenever the application launches, the dashboard separates **data loading** from **data refreshing**.

When the application starts, `get_311_data()` loads the existing complete cache from:

```text
data/311_cache.parquet
```

The application does not perform a live NYC Open Data refresh during normal startup.

Individual successfully retrieved date chunks are stored as gzip-compressed Parquet files in:

```text
data/311_chunks/
```

The complete cache and chunk files are intended to remain outside version control.

Data updates are handled separately with `refresh_311_data()`. The refresh process:

1. Loads the existing complete cache.
2. Identifies the latest date already stored.
3. Uses two calendar days before the current date as the latest complete date available for refresh.
4. Retrieves only missing dates rather than downloading the complete 2026-to-date dataset again.
5. Automatically divides a request into smaller date ranges if it reaches the 100,000-row retrieval limit.
6. Combines the new records with the existing cache and removes duplicate rows.
7. Keeps records from January 1, 2026 through the latest complete date.
8. Saves the updated complete cache as a gzip-compressed Parquet file.

The refresh function is designed to be run separately from the Shiny application, such as through a scheduled daily process in the eventual deployment environment. The scheduling mechanism depends on the platform used to deploy the dashboard and is not performed automatically by `app.R`.

If an incremental API request fails, the existing complete cache is left unchanged.

## Dashboard Filters

Users can filter service requests using:

- **Borough** — Explore requests within a selected NYC borough.
- **ZIP Code** — Search for or select requests within a specific ZIP code.
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

The **Play Sonification** feature provides an auditory representation of this same filtered daily request trend. The sonification uses the currently selected borough, ZIP code, complaint type, agency, and date range, allowing the time-series pattern to be explored through sound as an additional, accessibility-oriented representation of the data.

### NYC 311 Request Map

Displays the geographic locations of NYC 311 service requests using an interactive grayscale street map. Request locations are color-coded by borough, and users can zoom, pan, and select individual points to view the borough, ZIP code, complaint type, and responsible agency.

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

Defines the Shiny user interface, server logic, reactive filtering, summary value boxes, interactive Plotly charts, Leaflet map, and filtered data-sonification controls.

### `R/data.R`

Contains functions for loading, incrementally refreshing, caching, validating, and cleaning NYC 311 service request data. Large API requests are divided into smaller date ranges when necessary to avoid incomplete retrievals.

### `R/helpers.R`

Contains reusable helper functions used to generate choices for the dashboard filters, including the searchable ZIP code selector.

### `R/plots.R`

Contains reusable functions for creating the dashboard visualizations and interactive request map.

### `data/`

Stores the complete local NYC 311 Parquet cache and individual Parquet date-chunk caches used by the data-retrieval workflow. These cached files are excluded from version control.

### `www/custom.css`

Contains custom CSS used to style and polish the dashboard interface, including the grayscale Leaflet basemap treatment.

## Error Handling

The dashboard is designed to handle filter combinations that return no matching service requests without causing the application to crash.

When no records match the selected filters, the dashboard summary displays zero requests and "No Data" where appropriate. The visualizations also provide no-data handling for empty filter results.

The data-refresh workflow preserves the existing complete cache if a required incremental API request fails. Successfully retrieved date chunks can be cached for reuse by the retrieval workflow.

## Usage

After launching the dashboard:

1. Select a borough or leave the filter set to **All**.
2. Optionally search for or select a ZIP code.
3. Select a complaint type or leave it set to **All**.
4. Select an agency or leave it set to **All**.
5. Adjust the date range if desired.
6. Explore the updated summary metrics and interactive visualizations.
7. Select **Play Sonification** to hear an auditory representation of the currently filtered request trend.

Multiple filters can be applied at the same time.

## Future Improvements

Potential future extensions of the dashboard include:

- Additional geographic analysis and map features
- User-selectable historical periods before January 1, 2026
- Additional interactive visualizations
- Further accessibility enhancements and refinement of the sonification experience
- Deployment-specific automation of the incremental data-refresh schedule

## Repository Status

This dashboard was developed as part of the NYC Open Data Lab internship program.

The application has been tested for dashboard filtering, searchable ZIP code selection, interactive visualization, map popups, empty-result handling, 2026-to-date Parquet cached data loading, incremental refresh behavior, and filtered data sonification. The current version is being prepared for public deployment.