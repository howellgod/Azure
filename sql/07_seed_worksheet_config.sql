MERGE meta.WorksheetConfig AS target
USING
(
    SELECT N'FinancialStatements' AS WorksheetName, N'Matrix' AS LandingMode, 1 AS IsPbiRelevant, 5 AS ExpectedHeaderRow, 3 AS PeriodHeaderRow, 7 AS FirstDataRow, 5 AS FirstPeriodColumn, 2 AS CodeColumn, 3 AS LabelColumn, N'Balance sheet and statement-style tab with shifting month columns.' AS Notes
    UNION ALL SELECT N'CashPositions', N'Matrix', 1, 3, 3, 4, 4, 2, 3, N'Cash balances by account and period.'
    UNION ALL SELECT N'LoanEquity', N'Matrix', 0, 5, 3, 9, 7, NULL, NULL, N'Loan and equity schedule.'
    UNION ALL SELECT N'OPEX', N'Matrix', 1, 5, 3, 6, 7, 4, 5, N'Operating expense schedule.'
    UNION ALL SELECT N'CAPEX', N'Matrix', 1, 4, 3, 5, 10, NULL, 2, N'Capital expenditure schedule.'
    UNION ALL SELECT N'QBODrop', N'Row', 1, 1, NULL, 2, NULL, 1, 3, N'QuickBooks drop mapped to reporting semantics.'
    UNION ALL SELECT N'QBOMapping', N'Row', 1, 1, NULL, 2, NULL, 1, 3, N'QuickBooks key-to-report mapping.'
) AS source
    ON target.WorksheetName = source.WorksheetName
WHEN MATCHED THEN
    UPDATE SET
        LandingMode       = source.LandingMode,
        IsPbiRelevant     = source.IsPbiRelevant,
        ExpectedHeaderRow = source.ExpectedHeaderRow,
        PeriodHeaderRow   = source.PeriodHeaderRow,
        FirstDataRow      = source.FirstDataRow,
        FirstPeriodColumn = source.FirstPeriodColumn,
        CodeColumn        = source.CodeColumn,
        LabelColumn       = source.LabelColumn,
        Notes             = source.Notes,
        UpdatedAtUtc      = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT
    (
        WorksheetName,
        LandingMode,
        IsPbiRelevant,
        ExpectedHeaderRow,
        PeriodHeaderRow,
        FirstDataRow,
        FirstPeriodColumn,
        CodeColumn,
        LabelColumn,
        Notes
    )
    VALUES
    (
        source.WorksheetName,
        source.LandingMode,
        source.IsPbiRelevant,
        source.ExpectedHeaderRow,
        source.PeriodHeaderRow,
        source.FirstDataRow,
        source.FirstPeriodColumn,
        source.CodeColumn,
        source.LabelColumn,
        source.Notes
    );
GO
