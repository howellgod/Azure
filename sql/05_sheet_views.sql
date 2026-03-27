CREATE OR ALTER VIEW sheet.vw_LatestSuccessfulRun
AS
WITH LatestRun AS
(
    SELECT
        ir.WorkbookId,
        MAX(ir.IngestionRunId) AS IngestionRunId
    FROM meta.IngestionRun AS ir
    WHERE ir.Status = N'Succeeded'
      AND ir.WorkbookId IS NOT NULL
    GROUP BY ir.WorkbookId
)
SELECT ir.*
FROM meta.IngestionRun AS ir
INNER JOIN LatestRun AS lr
    ON ir.WorkbookId = lr.WorkbookId
   AND ir.IngestionRunId = lr.IngestionRunId;
GO

CREATE OR ALTER VIEW sheet.vw_WorkbookCellLatest
AS
SELECT
    c.WorkbookCellId,
    c.IngestionRunId,
    c.PortfolioId,
    c.WorkbookId,
    c.WorksheetName,
    c.CellAddress,
    c.RowNumber,
    c.ColumnNumber,
    c.ColumnLetter,
    c.CellDataType,
    c.CellTextValue,
    c.CellNumericValue,
    c.CellDateValue,
    c.CellBooleanValue,
    c.FormulaText,
    c.FileName,
    c.FilePath,
    c.SourceModifiedAtUtc,
    c.LoadedAtUtc
FROM landing.WorkbookCell AS c
INNER JOIN sheet.vw_LatestSuccessfulRun AS lr
    ON c.IngestionRunId = lr.IngestionRunId;
GO

CREATE OR ALTER VIEW sheet.vw_QBODropRows
AS
SELECT
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName AS Asset,
    sw.SourceFileName AS FileName,
    c.PortfolioId,
    c.WorkbookId,
    c.IngestionRunId,
    c.RowNumber,
    MAX(CASE WHEN c.ColumnNumber = 1 THEN c.CellTextValue END) AS Code,
    MAX(CASE WHEN c.ColumnNumber = 2 THEN c.CellTextValue END) AS [Group],
    MAX(CASE WHEN c.ColumnNumber = 3 THEN c.CellTextValue END) AS Label,
    MAX(CASE WHEN c.ColumnNumber = 4 THEN COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue) END) AS ValueRaw,
    TRY_CONVERT(DECIMAL(19,4), MAX(CASE WHEN c.ColumnNumber = 4 THEN COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue) END)) AS Value,
    util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), MAX(CASE WHEN c.ColumnNumber = 5 THEN COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue) END))) AS [Date],
    MAX(CASE WHEN c.ColumnNumber = 6 THEN c.CellTextValue END) AS [Statement],
    MAX(CASE WHEN c.ColumnNumber = 7 THEN c.CellTextValue END) AS [Key],
    MAX(CASE WHEN c.ColumnNumber = 8 THEN c.CellTextValue END) AS [Gen V Label],
    MAX(CASE WHEN c.ColumnNumber = 9 THEN c.CellTextValue END) AS [Cash Mapping]
FROM sheet.vw_WorkbookCellLatest AS c
INNER JOIN meta.Portfolio AS p
    ON c.PortfolioId = p.PortfolioId
LEFT JOIN meta.SourceWorkbook AS sw
    ON c.WorkbookId = sw.WorkbookId
WHERE c.WorksheetName = N'QBODrop'
  AND c.RowNumber >= 2
GROUP BY
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName,
    sw.SourceFileName,
    c.PortfolioId,
    c.WorkbookId,
    c.IngestionRunId,
    c.RowNumber;
GO

CREATE OR ALTER VIEW sheet.vw_QBOMappingRows
AS
SELECT
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName AS Asset,
    sw.SourceFileName AS FileName,
    c.PortfolioId,
    c.WorkbookId,
    c.IngestionRunId,
    c.RowNumber,
    MAX(CASE WHEN c.ColumnNumber = 1 THEN c.CellTextValue END) AS Code,
    MAX(CASE WHEN c.ColumnNumber = 2 THEN c.CellTextValue END) AS [Group],
    MAX(CASE WHEN c.ColumnNumber = 3 THEN c.CellTextValue END) AS Label,
    MAX(CASE WHEN c.ColumnNumber = 4 THEN c.CellTextValue END) AS [Statement],
    MAX(CASE WHEN c.ColumnNumber = 5 THEN c.CellTextValue END) AS [Key],
    MAX(CASE WHEN c.ColumnNumber = 6 THEN c.CellTextValue END) AS [Gen V Label],
    MAX(CASE WHEN c.ColumnNumber = 7 THEN c.CellTextValue END) AS [Cash Mapping]
FROM sheet.vw_WorkbookCellLatest AS c
INNER JOIN meta.Portfolio AS p
    ON c.PortfolioId = p.PortfolioId
LEFT JOIN meta.SourceWorkbook AS sw
    ON c.WorkbookId = sw.WorkbookId
WHERE c.WorksheetName = N'QBOMapping'
  AND c.RowNumber >= 2
GROUP BY
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName,
    sw.SourceFileName,
    c.PortfolioId,
    c.WorkbookId,
    c.IngestionRunId,
    c.RowNumber;
GO

CREATE OR ALTER VIEW sheet.vw_FinancialStatementsLong
AS
WITH PeriodColumns AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.ColumnNumber,
        util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue))) AS PeriodEndDate
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'FinancialStatements'
      AND c.RowNumber = 3
      AND c.ColumnNumber >= 5
),
ScenarioColumns AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.ColumnNumber,
        c.CellTextValue AS ScenarioLabel
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'FinancialStatements'
      AND c.RowNumber = 5
      AND c.ColumnNumber >= 5
),
AccountRows AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        MAX(CASE WHEN c.ColumnNumber = 2 THEN c.CellTextValue END) AS AccountCode,
        MAX(CASE WHEN c.ColumnNumber = 3 THEN c.CellTextValue END) AS AccountLabel
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'FinancialStatements'
      AND c.RowNumber >= 7
    GROUP BY
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber
),
Amounts AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        c.ColumnNumber,
        TRY_CONVERT(DECIMAL(19,4), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue)) AS Amount
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'FinancialStatements'
      AND c.RowNumber >= 7
      AND c.ColumnNumber >= 5
)
SELECT
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName AS Asset,
    sw.SourceFileName AS FileName,
    a.PortfolioId,
    a.WorkbookId,
    a.IngestionRunId,
    a.RowNumber,
    a.AccountCode,
    a.AccountLabel,
    amt.ColumnNumber AS PeriodColumnNumber,
    pc.PeriodEndDate,
    sc.ScenarioLabel,
    amt.Amount
FROM AccountRows AS a
INNER JOIN Amounts AS amt
    ON a.PortfolioId = amt.PortfolioId
   AND a.WorkbookId = amt.WorkbookId
   AND a.IngestionRunId = amt.IngestionRunId
   AND a.RowNumber = amt.RowNumber
LEFT JOIN PeriodColumns AS pc
    ON amt.PortfolioId = pc.PortfolioId
   AND amt.WorkbookId = pc.WorkbookId
   AND amt.IngestionRunId = pc.IngestionRunId
   AND amt.ColumnNumber = pc.ColumnNumber
LEFT JOIN ScenarioColumns AS sc
    ON amt.PortfolioId = sc.PortfolioId
   AND amt.WorkbookId = sc.WorkbookId
   AND amt.IngestionRunId = sc.IngestionRunId
   AND amt.ColumnNumber = sc.ColumnNumber
INNER JOIN meta.Portfolio AS p
    ON a.PortfolioId = p.PortfolioId
LEFT JOIN meta.SourceWorkbook AS sw
    ON a.WorkbookId = sw.WorkbookId
WHERE a.AccountLabel IS NOT NULL;
GO

CREATE OR ALTER VIEW sheet.vw_CashPositionsLong
AS
WITH PeriodColumns AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.ColumnNumber,
        util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue))) AS PeriodEndDate
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'CashPositions'
      AND c.RowNumber = 3
      AND c.ColumnNumber >= 4
),
AccountRows AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        MAX(CASE WHEN c.ColumnNumber = 2 THEN c.CellTextValue END) AS AccountCode,
        MAX(CASE WHEN c.ColumnNumber = 3 THEN c.CellTextValue END) AS AccountLabel
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'CashPositions'
      AND c.RowNumber >= 4
    GROUP BY
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber
),
Amounts AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        c.ColumnNumber,
        TRY_CONVERT(DECIMAL(19,4), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue)) AS Amount
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'CashPositions'
      AND c.RowNumber >= 4
      AND c.ColumnNumber >= 4
)
SELECT
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName AS Asset,
    sw.SourceFileName AS FileName,
    a.PortfolioId,
    a.WorkbookId,
    a.IngestionRunId,
    a.RowNumber,
    a.AccountCode,
    a.AccountLabel,
    amt.ColumnNumber AS PeriodColumnNumber,
    pc.PeriodEndDate,
    amt.Amount
FROM AccountRows AS a
INNER JOIN Amounts AS amt
    ON a.PortfolioId = amt.PortfolioId
   AND a.WorkbookId = amt.WorkbookId
   AND a.IngestionRunId = amt.IngestionRunId
   AND a.RowNumber = amt.RowNumber
LEFT JOIN PeriodColumns AS pc
    ON amt.PortfolioId = pc.PortfolioId
   AND amt.WorkbookId = pc.WorkbookId
   AND amt.IngestionRunId = pc.IngestionRunId
   AND amt.ColumnNumber = pc.ColumnNumber
INNER JOIN meta.Portfolio AS p
    ON a.PortfolioId = p.PortfolioId
LEFT JOIN meta.SourceWorkbook AS sw
    ON a.WorkbookId = sw.WorkbookId
WHERE a.AccountLabel IS NOT NULL;
GO

CREATE OR ALTER VIEW sheet.vw_OPEXLong
AS
WITH PeriodColumns AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.ColumnNumber,
        util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue))) AS PeriodEndDate
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'OPEX'
      AND c.RowNumber = 3
      AND c.ColumnNumber >= 7
),
MetadataRows AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        MAX(CASE WHEN c.ColumnNumber = 1 THEN c.CellTextValue END) AS ModelingStyle,
        MAX(CASE WHEN c.ColumnNumber = 2 THEN c.CellTextValue END) AS InputMode,
        MAX(CASE WHEN c.ColumnNumber = 3 THEN c.CellTextValue END) AS GrowthRate,
        MAX(CASE WHEN c.ColumnNumber = 4 THEN c.CellTextValue END) AS AccountCode,
        MAX(CASE WHEN c.ColumnNumber = 5 THEN c.CellTextValue END) AS AccountLabel
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'OPEX'
      AND c.RowNumber >= 6
    GROUP BY
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber
),
Amounts AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        c.ColumnNumber,
        TRY_CONVERT(DECIMAL(19,4), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue)) AS Amount
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'OPEX'
      AND c.RowNumber >= 6
      AND c.ColumnNumber >= 7
)
SELECT
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName AS Asset,
    sw.SourceFileName AS FileName,
    m.PortfolioId,
    m.WorkbookId,
    m.IngestionRunId,
    m.RowNumber,
    m.ModelingStyle,
    m.InputMode,
    m.GrowthRate,
    m.AccountCode,
    m.AccountLabel,
    pc.PeriodEndDate,
    amt.Amount
FROM MetadataRows AS m
INNER JOIN Amounts AS amt
    ON m.PortfolioId = amt.PortfolioId
   AND m.WorkbookId = amt.WorkbookId
   AND m.IngestionRunId = amt.IngestionRunId
   AND m.RowNumber = amt.RowNumber
LEFT JOIN PeriodColumns AS pc
    ON amt.PortfolioId = pc.PortfolioId
   AND amt.WorkbookId = pc.WorkbookId
   AND amt.IngestionRunId = pc.IngestionRunId
   AND amt.ColumnNumber = pc.ColumnNumber
INNER JOIN meta.Portfolio AS p
    ON m.PortfolioId = p.PortfolioId
LEFT JOIN meta.SourceWorkbook AS sw
    ON m.WorkbookId = sw.WorkbookId
WHERE m.AccountLabel IS NOT NULL;
GO

CREATE OR ALTER VIEW sheet.vw_CAPEXLong
AS
WITH PeriodColumns AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.ColumnNumber,
        util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue))) AS PeriodEndDate
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'CAPEX'
      AND c.RowNumber = 3
      AND c.ColumnNumber >= 10
),
MetadataRows AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        MAX(CASE WHEN c.ColumnNumber = 1 THEN c.CellTextValue END) AS ItemNumber,
        MAX(CASE WHEN c.ColumnNumber = 2 THEN c.CellTextValue END) AS ItemLabel,
        MAX(CASE WHEN c.ColumnNumber = 3 THEN c.CellTextValue END) AS Category,
        MAX(CASE WHEN c.ColumnNumber = 4 THEN c.CellTextValue END) AS Cost,
        MAX(CASE WHEN c.ColumnNumber = 5 THEN c.CellTextValue END) AS StartSerial,
        MAX(CASE WHEN c.ColumnNumber = 6 THEN c.CellTextValue END) AS NumberOfMonths,
        MAX(CASE WHEN c.ColumnNumber = 7 THEN c.CellTextValue END) AS StartEOM,
        MAX(CASE WHEN c.ColumnNumber = 8 THEN c.CellTextValue END) AS EndEOM
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'CAPEX'
      AND c.RowNumber >= 5
    GROUP BY
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber
),
Amounts AS
(
    SELECT
        c.PortfolioId,
        c.WorkbookId,
        c.IngestionRunId,
        c.RowNumber,
        c.ColumnNumber,
        TRY_CONVERT(DECIMAL(19,4), COALESCE(CONVERT(NVARCHAR(100), c.CellNumericValue), c.CellTextValue)) AS Amount
    FROM sheet.vw_WorkbookCellLatest AS c
    WHERE c.WorksheetName = N'CAPEX'
      AND c.RowNumber >= 5
      AND c.ColumnNumber >= 10
)
SELECT
    p.PortfolioCode,
    p.PortfolioName,
    sw.AssetName AS Asset,
    sw.SourceFileName AS FileName,
    m.PortfolioId,
    m.WorkbookId,
    m.IngestionRunId,
    m.RowNumber,
    m.ItemNumber,
    m.ItemLabel,
    m.Category,
    TRY_CONVERT(DECIMAL(19,4), m.Cost) AS Cost,
    util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), m.StartSerial)) AS StartDate,
    TRY_CONVERT(INT, m.NumberOfMonths) AS NumberOfMonths,
    util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), m.StartEOM)) AS StartEOMDate,
    util.ExcelSerialToDate(TRY_CONVERT(DECIMAL(18,5), m.EndEOM)) AS EndEOMDate,
    pc.PeriodEndDate,
    amt.Amount
FROM MetadataRows AS m
INNER JOIN Amounts AS amt
    ON m.PortfolioId = amt.PortfolioId
   AND m.WorkbookId = amt.WorkbookId
   AND m.IngestionRunId = amt.IngestionRunId
   AND m.RowNumber = amt.RowNumber
LEFT JOIN PeriodColumns AS pc
    ON amt.PortfolioId = pc.PortfolioId
   AND amt.WorkbookId = pc.WorkbookId
   AND amt.IngestionRunId = pc.IngestionRunId
   AND amt.ColumnNumber = pc.ColumnNumber
INNER JOIN meta.Portfolio AS p
    ON m.PortfolioId = p.PortfolioId
LEFT JOIN meta.SourceWorkbook AS sw
    ON m.WorkbookId = sw.WorkbookId
WHERE m.ItemLabel IS NOT NULL;
GO
