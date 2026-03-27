# SQL Scripts

The scripts in this folder create the Phase 1 database structures for landing workbook data and exposing Power BI compatibility views.

## Schemas

- `meta`: portfolio, workbook, and ingestion metadata
- `landing`: raw worksheet-cell landing tables
- `util`: helper functions
- `ingest`: procedures for ADF orchestration
- `sheet`: relational views over workbook tabs
- `pbi`: Power BI-facing compatibility views

## Deployment

Use `deploy.sql` from SQLCMD tooling, or run the files in numeric order.

## Design principle

The landing model is cell-based on purpose. It lets us ingest changing workbook layouts without redesigning the database every time a new month appears.
