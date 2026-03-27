# Azure Data Factory Scaffolding

This folder contains the first-pass ADF artifacts for the workbook-to-SQL ingestion pattern.

## What is scaffolded

- linked services for:
  - the existing Azure SQL database
  - a SharePoint or Microsoft Graph-backed REST source
- datasets for:
  - workbook-cell JSON payloads
  - the SQL landing table
- a parameterized pipeline that:
  - starts an ingestion run
  - loads worksheet configuration
  - writes workbook cells to `landing.WorkbookCell`
  - completes the ingestion run

## Important note

ADF does not natively flatten every Excel workbook pattern into the exact cell-level payload we want. The JSON artifacts here are an orchestration-first scaffold. If SharePoint extraction needs an intermediary step, the least disruptive Phase 1 option is to keep the ADF contract intact and insert one of these:

- Microsoft Graph workbook extraction
- Office Script plus staging output
- a lightweight Azure Function or notebook that emits worksheet cells as JSON

The SQL landing model and stored procedures are already shaped for that contract.
