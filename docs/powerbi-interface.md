# Power BI Interface Notes

The sample PBIX `NEW_GenVReports_Browns (1).pbix` shows that the report consumes semantic tables rather than raw worksheet tabs directly.

## Observed semantic entities

- `Checks`
- `Assets`
- `Financials`
- `Budget`
- `SummaryMapping`
- `DateTable`

## Observed `Checks` fields

- `Asset`
- `BS Check`
- `Cash Check`
- `Cash Negative Date`
- `Date`
- `Date created`
- `Date modified`
- `FileName`

## Phase 1 SQL compatibility strategy

- Keep the landing contract generic and workbook-safe through `landing.WorkbookCell`
- Build sheet-level relational views in the `sheet` schema
- Publish Power BI-facing compatibility views in the `pbi` schema using the current semantic names

## Expected follow-up work

- Compare the live Power Query logic in the production PBIX with these first-pass views
- Tighten measure logic for `Checks`, `Budget`, and summary variance calculations
- Decide whether later phases should move from compatibility views to a formal star schema
