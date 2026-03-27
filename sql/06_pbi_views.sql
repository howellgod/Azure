CREATE OR ALTER VIEW pbi.Assets
AS
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
    sw.SharePointFolderPath
FROM meta.SourceWorkbook AS sw
INNER JOIN meta.Portfolio AS p
    ON sw.PortfolioId = p.PortfolioId
WHERE sw.IsActive = 1;
GO

CREATE OR ALTER VIEW pbi.SummaryMapping
AS
SELECT DISTINCT
    Asset,
    COALESCE(NULLIF([Group], N''), [Statement]) AS Section,
    Label AS Account,
    [Statement],
    [Key],
    [Gen V Label],
    [Cash Mapping]
FROM sheet.vw_QBOMappingRows
WHERE Label IS NOT NULL;
GO

CREATE OR ALTER VIEW pbi.Financials
AS
SELECT
    Asset,
    PortfolioCode,
    PortfolioName,
    [Date],
    [Statement],
    COALESCE(NULLIF([Group], N''), [Statement]) AS Section,
    Label AS Account,
    Value AS [Statement Value],
    CAST(NULL AS DECIMAL(19,4)) AS [Summary Variance],
    [Key],
    [Gen V Label],
    [Cash Mapping],
    FileName
FROM sheet.vw_QBODropRows
WHERE [Date] IS NOT NULL;
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
    FileName
FROM sheet.vw_FinancialStatementsLong
WHERE PeriodEndDate IS NOT NULL
  AND Amount IS NOT NULL;
GO

CREATE OR ALTER VIEW pbi.DateTable
AS
WITH Dates AS
(
    SELECT [Date] FROM pbi.Financials
    UNION
    SELECT [Date] FROM pbi.Budget
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
        q.WorkbookId,
        MAX(q.[Date]) AS ActualsAsOf
    FROM sheet.vw_QBODropRows AS q
    WHERE q.[Date] IS NOT NULL
    GROUP BY q.WorkbookId
),
CashFromQBO AS
(
    SELECT
        q.WorkbookId,
        q.[Date],
        SUM(CASE WHEN q.[Gen V Label] = N'Cash' THEN q.Value ELSE 0 END) AS CashValue
    FROM sheet.vw_QBODropRows AS q
    GROUP BY q.WorkbookId, q.[Date]
),
CashFromPositions AS
(
    SELECT
        c.WorkbookId,
        c.PeriodEndDate,
        SUM(c.Amount) AS CashValue
    FROM sheet.vw_CashPositionsLong AS c
    GROUP BY c.WorkbookId, c.PeriodEndDate
),
BalanceSheetRollup AS
(
    SELECT
        f.WorkbookId,
        f.PeriodEndDate,
        MAX(CASE WHEN f.AccountLabel = N'Total Assets' THEN f.Amount END) AS TotalAssets,
        MAX(CASE WHEN f.AccountLabel = N'Total Liabilities & Equity' THEN f.Amount END) AS TotalLiabilitiesEquity
    FROM sheet.vw_FinancialStatementsLong AS f
    GROUP BY f.WorkbookId, f.PeriodEndDate
),
NegativeCashDate AS
(
    SELECT
        c.WorkbookId,
        util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), MAX(CASE WHEN c.RowNumber = 4 AND c.ColumnNumber = 2 THEN COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue) END))) AS NegativeCashDate
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'FinancialStatements'
    GROUP BY c.WorkbookId
)
SELECT
    a.Asset,
    CAST(CASE
        WHEN b.TotalAssets IS NULL OR b.TotalLiabilitiesEquity IS NULL THEN NULL
        ELSE b.TotalAssets - b.TotalLiabilitiesEquity
    END AS DECIMAL(19,4)) AS [BS Check],
    CAST(CASE
        WHEN cq.CashValue IS NULL OR cp.CashValue IS NULL THEN NULL
        ELSE cq.CashValue - cp.CashValue
    END AS DECIMAL(19,4)) AS [Cash Check],
    n.NegativeCashDate AS [Cash Negative Date],
    lad.ActualsAsOf AS [Date],
    a.[Date created],
    a.[Date modified],
    a.FileName
FROM pbi.Assets AS a
LEFT JOIN LatestActualDate AS lad
    ON a.WorkbookId = lad.WorkbookId
LEFT JOIN BalanceSheetRollup AS b
    ON a.WorkbookId = b.WorkbookId
   AND lad.ActualsAsOf = b.PeriodEndDate
LEFT JOIN CashFromQBO AS cq
    ON a.WorkbookId = cq.WorkbookId
   AND lad.ActualsAsOf = cq.[Date]
LEFT JOIN CashFromPositions AS cp
    ON a.WorkbookId = cp.WorkbookId
   AND lad.ActualsAsOf = cp.PeriodEndDate
LEFT JOIN NegativeCashDate AS n
    ON a.WorkbookId = n.WorkbookId;
GO
