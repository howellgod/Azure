# Power BI Database Schema

This repository is the Phase 1 landing zone for moving the current Power BI reporting workflow away from SharePoint-hosted Excel workbooks and toward Azure SQL plus Azure Data Factory.

Phase 1 keeps the workbook process intact from a business perspective:

- SharePoint remains the source of truth
- Azure SQL becomes the reporting store
- Azure Data Factory orchestrates ingestion
- Power BI-facing SQL views preserve the current model as closely as possible

## Repository layout

- `.azure/plan.md`: approved implementation plan and execution tracker
- `terraform/`: Azure infrastructure for new resources around the existing SQL database
- `sql/`: database schemas, tables, procedures, functions, and Power BI compatibility views
- `adf/`: Azure Data Factory scaffolding and JSON artifacts
- `docs/`: workbook and Power BI interface notes used to shape the first-pass schema

## What is included

- Terraform to provision Azure Data Factory and optional supporting resources
- SQL scripts for:
  - metadata tables
  - raw workbook-cell landing tables
  - ingestion procedures
  - sheet-specific relational views
  - Power BI compatibility views
- ADF scaffolding for a parameterized SharePoint-to-SQL ingestion pattern

## Azure assumptions

- The Azure SQL server and database already exist
- Terraform references the existing SQL deployment instead of managing it
- One database stores many workbooks and portfolios by key
- Workbook data is first landed as cells so shifting month columns do not break the model

## SQL deployment order

Run the files in `sql/` in this order, or use `sql/deploy.sql` from SQLCMD-compatible tooling:

1. `00_schemas.sql`
2. `01_meta_tables.sql`
3. `02_landing_tables.sql`
4. `03_functions.sql`
5. `04_ingestion_procedures.sql`
6. `05_sheet_views.sql`
7. `06_pbi_views.sql`
8. `07_seed_worksheet_config.sql`

## Terraform usage

Copy `terraform/terraform.tfvars.example` to a local `.tfvars` file and fill in the existing Azure SQL details plus the deployment-specific names.

Example:

```powershell
cd terraform
terraform init
terraform plan -var-file="dev.tfvars"
```

## Notes on Power BI compatibility

The included `pbi.*` views preserve the current semantic layer names as a first pass:

- `pbi.Checks`
- `pbi.Financials`
- `pbi.Budget`
- `pbi.Assets`
- `pbi.StatementMapping`
- `pbi.SummaryMapping`
- `pbi.Cash`
- `pbi.CAPEX`
- `pbi.Loan`
- `pbi.ValuationPivot`
- `pbi.DateTable`

Those views are intentionally built on top of the raw landing model so we can harden logic incrementally without changing the ingestion contract.
