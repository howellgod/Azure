# Workbook Analysis Notes

The sample workbook `Asset_Template_1012_1014StAndrews_FEED_TRE.xlsx` was used to shape the first-pass SQL landing model.

## Observed worksheet inventory

- `Date`
- `Annual Rollup`
- `FinancialStatements`
- `CashPositions`
- `Acquisition`
- `Valuation`
- `Global Inputs`
- `LoanEquity`
- `OPEX`
- `CAPEX`
- `DeprAmortOther`
- `Tenants>>`
- `TruluckConstruction`
- `AVConnections`
- `EastCostBB`
- `PackAthletics`
- `<<Tenants`
- `ResidentialTenantTemplate`
- `OtherTenantTemplate`
- `Yield Curve`
- `QBODrop`
- `QBOMapping`
- `SomeList`

## Important structure patterns

### Matrix-style monthly tabs

These sheets include moving period columns and are the reason the Phase 1 landing model stores raw worksheet cells instead of fixed SQL month columns.

- `FinancialStatements`
- `CashPositions`
- `LoanEquity`
- `OPEX`
- `CAPEX`

### Relational-style tabs

These are already much closer to SQL row models and are easier to expose through compatibility views.

- `QBODrop`
- `QBOMapping`

## First-pass positional assumptions used in SQL views

- `FinancialStatements`
  - period headers: row `3`, columns `E+`
  - scenario headers: row `5`, columns `E+`
  - account code: column `B`
  - account label: column `C`
- `CashPositions`
  - period headers: row `3`, columns `D+`
  - account code: column `B`
  - account label: column `C`
- `OPEX`
  - period headers: row `3`, columns `G+`
  - account code: column `D`
  - account label: column `E`
- `CAPEX`
  - period headers: row `3`, columns `J+`
  - item metadata: columns `A:H`
- `QBODrop`
  - row-oriented extract starting on row `2`
- `QBOMapping`
  - row-oriented extract starting on row `2`

## Recommendation

As additional workbook examples are collected, update `meta.WorksheetConfig` and refine the relational views instead of changing the landing table contract.
