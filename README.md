# NYC 311 Dashboard

An interactive dashboard for exploring **NYC 311 service request data**, 
developed through the **NYC Open Data Lab**.

## About

The **NYC 311 Dashboard** is an open-source project designed to make 
New York City's 311 service request data easier to explore, visualize, 
and understand.

Using publicly available data from NYC Open Data, the dashboard provides 
an interactive interface for examining patterns in 311 requests across 
New York City.

The project is being developed as part of the **NYC Open Data Lab**, with 
an emphasis on open data, reproducible workflows, accessible data 
visualization, and hands-on student development experience.

## Project Goals

The dashboard is designed to provide users with an accessible way to 
explore NYC 311 data without requiring them to directly query or analyze 
the underlying dataset.

The project focuses on:

- retrieving and preparing NYC 311 service request data;
- creating reproducible data processing workflows;
- developing interactive visualizations and summaries;
- allowing users to explore patterns across time, geography, and 
  complaint characteristics;
- designing an accessible and intuitive user interface; and
- demonstrating how open government data can be transformed into 
  useful public-facing tools.

## Data Source

Data used in this project are provided through **NYC Open Data** and the 
NYC 311 service request dataset.

NYC 311 data contain information about service requests submitted by 
residents and other users of the 311 system, including information such as:

- complaint type;
- date and time;
- responding agency;
- geographic location;
- borough; and
- request status.

The specific variables and time periods used by the dashboard may evolve 
as development continues.

## Development

The dashboard is developed primarily using **R** and **Shiny**.

The development workflow separates data acquisition and preparation from 
the application itself, helping keep the project reproducible and easier 
to maintain.

Core technologies include:

- **R** for data processing and analysis;
- **Shiny** for the interactive dashboard;
- **NYC Open Data** as the primary data source;
- **Git and GitHub** for version control and collaborative development; and
- reproducible R workflows for preparing and updating application data.

## Repository Structure

This repository contains the code and supporting files used to develop the 
NYC 311 Dashboard.

As the project develops, the repository may include components for:

- data retrieval;
- data cleaning and transformation;
- reusable R functions;
- dashboard user interface components;
- server-side application logic;
- visualizations;
- testing; and
- supporting assets.

## Development Plan

The dashboard is supported by a separate project development guide that 
documents the planned development process, milestones, and workflow.

The development plan includes stages for:

1. project setup;
2. dashboard prototyping;
3. development of the data pipeline;
4. implementation of interactivity;
5. visual and interface design;
6. testing and refinement; and
7. final release.

This separation allows this repository to remain focused on the **application 
and its code**, while the accompanying documentation focuses on **how the 
project is planned and developed**.

## NYC Open Data Lab

This project is developed through the **NYC Open Data Lab**, an open-source 
initiative focused on expanding access to civic data through software, 
analysis, education, and public-facing data tools.

The Lab develops projects that make public data easier to access, analyze, 
teach with, and understand.

## Contributors

This project is developed collaboratively through the NYC Open Data Lab.

Contributors are recognized through the repository's Git history and project 
documentation.

## Status

**In active development.**

Features, data pipelines, visualizations, and documentation may change as 
the dashboard continues to be developed and tested.
