CREATE OR ALTER VIEW pbi.Assets
AS
WITH PropertyAddress AS
(
    SELECT
        gi.WorkbookId,
        MAX(CASE WHEN gi.InputName = N'Property Address' THEN gi.InputValue END) AS PropertyAddress,
        MAX(CASE WHEN gi.InputName = N'Property Name' THEN gi.InputValue END) AS PropertyName,
        MAX(CASE WHEN gi.InputName = N'Quickbooks Name' THEN gi.InputValue END) AS QuickbooksName,
        MAX(CASE WHEN gi.InputName = N'Asset Key' THEN gi.InputValue END) AS AssetKey
    FROM sheet.vw_GlobalInputs AS gi
    GROUP BY gi.WorkbookId
)
SELECT
    p.PortfolioId,
    p.PortfolioCode,
    p.PortfolioName,
    sw.WorkbookId,
    sw.AssetName AS Asset,
    sw.SourceFileName AS FileName,
    sw.SourceFilePath AS FilePath,
    sw.SourceCreatedAtUtc AS [Date created],
    sw.SourceModifiedAtUtc AS [Date modified],
    sw.SharePointSiteUrl,
    sw.SharePointFolderPath,
    pa.PropertyAddress,
    pa.PropertyName,
    pa.QuickbooksName,
    pa.AssetKey
FROM meta.SourceWorkbook AS sw
INNER JOIN meta.Portfolio AS p
    ON sw.PortfolioId = p.PortfolioId
LEFT JOIN PropertyAddress AS pa
    ON sw.WorkbookId = pa.WorkbookId
WHERE sw.IsActive = 1;
GO

CREATE OR ALTER VIEW pbi.SummaryMapping
AS
SELECT DISTINCT
    Asset,
    COALESCE(NULLIF([Gen V Label], N''), NULLIF([Group], N''), [Statement]) AS Section,
    Label AS Account
FROM sheet.vw_QBOMappingRows
WHERE Label IS NOT NULL;
GO

CREATE OR ALTER VIEW pbi.StatementMapping
AS
SELECT DISTINCT
    Asset,
    COALESCE(NULLIF([Gen V Label], N''), NULLIF([Group], N''), [Statement]) AS Section,
    Label AS Account,
    [Statement],
    COALESCE(NULLIF([Gen V Label], N''), NULLIF([Group], N''), [Statement]) AS [GFCF Section],
    Label AS [GFCF],
    [Key],
    [Cash Mapping]
FROM sheet.vw_QBOMappingRows
WHERE Label IS NOT NULL;
GO

CREATE OR ALTER VIEW pbi.Budget
AS
SELECT
    Asset,
    PortfolioCode,
    PortfolioName,
    PeriodEndDate AS [Date],
    CAST(N'FinancialStatements' AS NVARCHAR(100)) AS [Statement],
    AccountLabel AS Account,
    ScenarioLabel AS Scenario,
    Amount AS [Statement Value Budget],
    Amount AS [Budget (Hybrid)],
    FileName
FROM sheet.vw_FinancialStatementsLong
WHERE PeriodEndDate IS NOT NULL
  AND Amount IS NOT NULL;
GO

CREATE OR ALTER VIEW pbi.Financials
AS
WITH Base AS
(
    SELECT
        q.Asset,
        q.PortfolioCode,
        q.PortfolioName,
        q.[Date],
        q.[Statement],
        COALESCE(NULLIF(q.[Gen V Label], N''), NULLIF(q.[Group], N''), q.[Statement]) AS Section,
        q.Label AS Account,
        q.Value AS [Statement Value],
        q.Value AS [Value (Hybrid)],
        q.[Key],
        q.[Gen V Label],
        q.[Cash Mapping],
        q.FileName,
        q.WorkbookId
    FROM sheet.vw_QBODropRows AS q
    WHERE q.[Date] IS NOT NULL
      AND q.Label IS NOT NULL
),
BudgetBase AS
(
    SELECT
        b.Asset,
        b.[Date],
        b.Account,
        MAX(b.[Statement Value Budget]) AS BudgetValue
    FROM pbi.Budget AS b
    GROUP BY b.Asset, b.[Date], b.Account
)
SELECT
    b.Asset,
    b.PortfolioCode,
    b.PortfolioName,
    b.[Date],
    b.[Statement],
    b.Section,
    b.Account,
    b.[Statement Value],
    b.[Value (Hybrid)],
    CASE WHEN b.[Statement] = N'Balance Sheet' THEN b.[Statement Value] END AS [Ending Balance],
    pye.[Ending Balance (Prior Year End)],
    CASE
        WHEN b.[Statement] = N'Balance Sheet' AND pye.[Ending Balance (Prior Year End)] IS NOT NULL
            THEN b.[Statement Value] - pye.[Ending Balance (Prior Year End)]
        ELSE NULL
    END AS [Balance Sheet Change vs PY],
    CASE
        WHEN bb.BudgetValue IS NOT NULL THEN b.[Value (Hybrid)] - bb.BudgetValue
        ELSE NULL
    END AS [Variance],
    CASE
        WHEN bb.BudgetValue IS NOT NULL THEN b.[Statement Value] - bb.BudgetValue
        ELSE NULL
    END AS [Summary Variance],
    b.[Key],
    b.[Gen V Label],
    b.[Cash Mapping],
    b.FileName
FROM Base AS b
LEFT JOIN BudgetBase AS bb
    ON b.Asset = bb.Asset
   AND b.[Date] = bb.[Date]
   AND b.Account = bb.Account
OUTER APPLY
(
    SELECT TOP (1)
        b2.[Statement Value] AS [Ending Balance (Prior Year End)]
    FROM Base AS b2
    WHERE b2.Asset = b.Asset
      AND b2.Account = b.Account
      AND b2.[Statement] = b.[Statement]
      AND b.[Statement] = N'Balance Sheet'
      AND b2.[Date] < DATEFROMPARTS(YEAR(b.[Date]), 1, 1)
    ORDER BY b2.[Date] DESC
) AS pye;
GO

CREATE OR ALTER VIEW pbi.Cash
AS
WITH Base AS
(
    SELECT
        c.Asset,
        c.PortfolioCode,
        c.PortfolioName,
        c.PeriodEndDate AS [Date],
        c.AccountLabel AS Label,
        c.Amount AS Value,
        c.FileName,
        c.WorkbookId,
        c.RowNumber
    FROM sheet.vw_CashPositionsLong AS c
    WHERE c.PeriodEndDate IS NOT NULL
      AND c.AccountLabel IS NOT NULL
),
Targets AS
(
    SELECT
        t.WorkbookId,
        t.RowNumber,
        t.TargetAmount
    FROM sheet.vw_CashPositionTargets AS t
)
SELECT
    b.Asset,
    b.PortfolioCode,
    b.PortfolioName,
    b.[Date],
    b.Label,
    b.Value,
    t.TargetAmount AS [Target],
    py.Value AS [Prior Year],
    CASE WHEN py.Value IS NOT NULL THEN b.Value - py.Value END AS [PY Variance],
    CASE WHEN t.TargetAmount IS NOT NULL THEN b.Value - t.TargetAmount END AS [Target Variance],
    b.FileName
FROM Base AS b
LEFT JOIN Targets AS t
    ON b.WorkbookId = t.WorkbookId
   AND b.RowNumber = t.RowNumber
LEFT JOIN Base AS py
    ON b.Asset = py.Asset
   AND b.Label = py.Label
   AND py.[Date] = DATEADD(YEAR, -1, b.[Date]);
GO

CREATE OR ALTER VIEW pbi.CAPEX
AS
SELECT DISTINCT
    c.Asset,
    c.PortfolioCode,
    c.PortfolioName,
    c.ItemLabel AS Label,
    c.Category AS [CAPEX Category],
    c.Cost,
    c.StartDate AS [Start],
    c.StartEOMDate,
    c.EndEOMDate,
    c.NumberOfMonths,
    c.FileName
FROM sheet.vw_CAPEXLong AS c
WHERE c.ItemLabel IS NOT NULL;
GO

CREATE OR ALTER VIEW pbi.Loan
AS
SELECT
    l.Asset,
    l.PortfolioCode,
    l.PortfolioName,
    COALESCE(NULLIF(NULLIF(l.Borrower, N''), N'0'), l.PropertyName) AS Borrower,
    NULLIF(NULLIF(l.Lender, N'0'), N'') AS Lender,
    COALESCE(NULLIF(NULLIF(l.LoanName, N''), N'0'), N'Loan') AS [Loan Name],
    l.LoanStartDate AS [Loan Start],
    NULLIF(l.PropertyAddress, N'0') AS [Property Address],
    l.OriginalLoanBalance AS [Original Loan Balance],
    l.CurrentLoanBalance AS [Current Loan Balance],
    l.DebtService AS [Debt Service],
    l.NOI_Year AS [NOI (Yr)],
    l.DSCR,
    l.FileName
FROM sheet.vw_LoanSummary AS l;
GO

CREATE OR ALTER VIEW pbi.ValuationPivot
AS
SELECT
    v.Asset,
    v.PortfolioCode,
    v.PortfolioName,
    MAX(CASE WHEN v.MetricLabel = N'Current Book Value' THEN v.MetricValue END) AS [Current Book Value],
    MAX(CASE WHEN v.MetricLabel = N'Expected Property Value' THEN v.MetricValue END) AS [Expected Property Value],
    MAX(CASE WHEN v.MetricLabel = N'Projected NOI' THEN v.MetricValue END) AS [Projected NOI],
    MAX(CASE WHEN v.MetricLabel = N'Projected CF to Equity' THEN v.MetricValue END) AS [Projected CF to Equity],
    MAX(CASE WHEN v.MetricLabel = N'Projected Appreciation' THEN v.MetricValue END) AS [Projected Appreciation],
    MAX(CASE WHEN v.MetricLabel = N'Cash on Cash Return' THEN v.MetricValue END) AS [Cash on Cash Return],
    MAX(CASE WHEN v.MetricLabel = N'Appreciation Return' THEN v.MetricValue END) AS [Appreciation Return],
    MAX(CASE WHEN v.MetricLabel = N'Total Return' THEN v.MetricValue END) AS [Total Return],
    MAX(CASE WHEN v.MetricLabel = N'IRR' THEN v.MetricValue END) AS [IRR],
    MAX(CASE WHEN v.MetricLabel = N'DSCR' THEN v.MetricValue END) AS [DSCR],
    MAX(CASE WHEN v.MetricLabel = N'LTV' THEN v.MetricValue END) AS [LTV],
    MAX(CASE WHEN v.MetricLabel = N'Expected Liquidation Proceeds' THEN v.MetricValue END) AS [Expected Liquidation Proceeds],
    MAX(CASE WHEN v.MetricLabel = N'Asset 5 Year Total Returns' THEN v.MetricValue END) AS [Asset 5 Year Total Returns],
    MAX(CASE WHEN v.MetricLabel = N'Asset 5 Year Principal Paid' THEN v.MetricValue END) AS [Asset 5 Year Principal Paid],
    MAX(CASE WHEN v.MetricLabel = N'Asset 5 Year Appreciation' THEN v.MetricValue END) AS [Asset 5 Year Appreciation],
    MAX(CASE WHEN v.MetricLabel = N'Asset 5 Year Cash Returns' THEN v.MetricValue END) AS [Asset 5 Year Cash Returns],
    MAX(CASE WHEN v.MetricLabel = N'Fixed Income 5 Year Cash Returns' THEN v.MetricValue END) AS [Fixed Income 5 Year Cash Returns],
    MAX(CASE WHEN v.MetricLabel = N'Passive 5 Year Cash Returns' THEN v.MetricValue END) AS [Passive 5 Year Cash Returns],
    MAX(CASE WHEN v.MetricLabel = N'AM Score' THEN v.MetricValue END) AS [AM Score],
    MAX(CASE WHEN v.MetricLabel = N'Implied Cap Rate' THEN v.MetricValue END) AS [Implied Cap Rate]
FROM sheet.vw_ValuationKeyMetrics AS v
GROUP BY
    v.Asset,
    v.PortfolioCode,
    v.PortfolioName;
GO

CREATE OR ALTER VIEW pbi.DateTable
AS
WITH Dates AS
(
    SELECT [Date] FROM pbi.Financials
    UNION
    SELECT [Date] FROM pbi.Budget
    UNION
    SELECT [Date] FROM pbi.Cash
    UNION
    SELECT [Start] FROM pbi.CAPEX
    UNION
    SELECT [Loan Start] FROM pbi.Loan
)
SELECT DISTINCT
    CAST([Date] AS DATE) AS [Date],
    YEAR([Date]) AS [Year],
    MONTH([Date]) AS [Month Number],
    DATENAME(MONTH, [Date]) AS [Month],
    DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1) AS [Month Start Date],
    (YEAR([Date]) * 100) + MONTH([Date]) AS [Month Sort]
FROM Dates
WHERE [Date] IS NOT NULL;
GO

CREATE OR ALTER VIEW pbi.Checks
AS
WITH LatestActualDate AS
(
    SELECT
        f.Asset,
        MAX(f.[Date]) AS ActualsAsOf
    FROM pbi.Financials AS f
    GROUP BY f.Asset
),
CashRollup AS
(
    SELECT
        c.Asset,
        c.[Date],
        SUM(c.Value) AS CashValue
    FROM pbi.Cash AS c
    GROUP BY c.Asset, c.[Date]
),
QBOCashRollup AS
(
    SELECT
        f.Asset,
        f.[Date],
        SUM(f.[Statement Value]) AS CashValue
    FROM pbi.Financials AS f
    WHERE f.[Gen V Label] = N'Cash'
    GROUP BY f.Asset, f.[Date]
),
BalanceSheetRollup AS
(
    SELECT
        f.Asset,
        f.[Date],
        MAX(CASE WHEN f.Account = N'Total Assets' THEN f.[Statement Value] END) AS TotalAssets,
        MAX(CASE WHEN f.Account IN (N'Total Liabilities and Equity', N'Total Liabilities & Equity') THEN f.[Statement Value] END) AS TotalLiabilitiesEquity
    FROM pbi.Financials AS f
    WHERE f.[Statement] = N'Balance Sheet'
    GROUP BY f.Asset, f.[Date]
),
NegativeCashDate AS
(
    SELECT
        sw.AssetName AS Asset,
        util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), MAX(CASE WHEN c.RowNumber = 4 AND c.ColumnNumber = 2 THEN COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue) END))) AS NegativeCashDate
    FROM sheet.vw_WorkbookCellLatest AS c
    INNER JOIN meta.SourceWorkbook AS sw
        ON c.WorkbookId = sw.WorkbookId
    WHERE c.WorksheetName = N'FinancialStatements'
    GROUP BY sw.AssetName
)
SELECT
    a.Asset,
    CAST(CASE
        WHEN b.TotalAssets IS NULL OR b.TotalLiabilitiesEquity IS NULL THEN NULL
        ELSE b.TotalAssets - b.TotalLiabilitiesEquity
    END AS DECIMAL(19,4)) AS [BS Check],
    CAST(CASE
        WHEN qcr.CashValue IS NULL OR cr.CashValue IS NULL THEN NULL
        ELSE qcr.CashValue - cr.CashValue
    END AS DECIMAL(19,4)) AS [Cash Check],
    n.NegativeCashDate AS [Cash Negative Date],
    lad.ActualsAsOf AS [Date],
    a.[Date created],
    a.[Date modified],
    a.FileName
FROM pbi.Assets AS a
LEFT JOIN LatestActualDate AS lad
    ON a.Asset = lad.Asset
LEFT JOIN BalanceSheetRollup AS b
    ON a.Asset = b.Asset
   AND lad.ActualsAsOf = b.[Date]
LEFT JOIN CashRollup AS cr
    ON a.Asset = cr.Asset
   AND lad.ActualsAsOf = cr.[Date]
LEFT JOIN QBOCashRollup AS qcr
    ON a.Asset = qcr.Asset
   AND lad.ActualsAsOf = qcr.[Date]
LEFT JOIN NegativeCashDate AS n
    ON a.Asset = n.Asset;
GO
