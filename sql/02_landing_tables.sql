CREATE TABLE landing.WorkbookCell
(
    WorkbookCellId          BIGINT IDENTITY(1,1) NOT NULL,
    IngestionRunId          BIGINT NOT NULL,
    PortfolioId             INT NOT NULL,
    WorkbookId              INT NULL,
    WorksheetName           NVARCHAR(255) NOT NULL,
    CellAddress             NVARCHAR(20) NOT NULL,
    RowNumber               INT NOT NULL,
    ColumnNumber            INT NOT NULL,
    ColumnLetter            NVARCHAR(8) NOT NULL,
    CellDataType            NVARCHAR(50) NULL,
    CellTextValue           NVARCHAR(4000) NULL,
    CellNumericValue        DECIMAL(38,10) NULL,
    CellDateValue           DATETIME2(0) NULL,
    CellBooleanValue        BIT NULL,
    FormulaText             NVARCHAR(4000) NULL,
    FileName                NVARCHAR(260) NOT NULL,
    FilePath                NVARCHAR(1024) NULL,
    SourceModifiedAtUtc     DATETIME2(0) NULL,
    LoadedAtUtc             DATETIME2(0) NOT NULL CONSTRAINT DF_WorkbookCell_LoadedAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_WorkbookCell PRIMARY KEY CLUSTERED (WorkbookCellId),
    CONSTRAINT FK_WorkbookCell_IngestionRun FOREIGN KEY (IngestionRunId) REFERENCES meta.IngestionRun (IngestionRunId),
    CONSTRAINT FK_WorkbookCell_Portfolio FOREIGN KEY (PortfolioId) REFERENCES meta.Portfolio (PortfolioId),
    CONSTRAINT FK_WorkbookCell_Workbook FOREIGN KEY (WorkbookId) REFERENCES meta.SourceWorkbook (WorkbookId),
    CONSTRAINT UQ_WorkbookCell_Run_Sheet_Address UNIQUE (IngestionRunId, WorksheetName, CellAddress)
);
GO

CREATE INDEX IX_WorkbookCell_Sheet_Row_Column
    ON landing.WorkbookCell (WorksheetName, RowNumber, ColumnNumber)
    INCLUDE (PortfolioId, WorkbookId, IngestionRunId, CellTextValue, CellNumericValue, CellDateValue, FileName);
GO

CREATE INDEX IX_WorkbookCell_Workbook_Sheet
    ON landing.WorkbookCell (WorkbookId, WorksheetName, IngestionRunId DESC);
GO
