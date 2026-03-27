CREATE TABLE meta.Portfolio
(
    PortfolioId          INT IDENTITY(1,1) NOT NULL,
    PortfolioCode        NVARCHAR(100) NOT NULL,
    PortfolioName        NVARCHAR(255) NOT NULL,
    IsActive             BIT NOT NULL CONSTRAINT DF_Portfolio_IsActive DEFAULT (1),
    CreatedAtUtc         DATETIME2(0) NOT NULL CONSTRAINT DF_Portfolio_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
    UpdatedAtUtc         DATETIME2(0) NOT NULL CONSTRAINT DF_Portfolio_UpdatedAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Portfolio PRIMARY KEY CLUSTERED (PortfolioId),
    CONSTRAINT UQ_Portfolio_PortfolioCode UNIQUE (PortfolioCode)
);
GO

CREATE TABLE meta.SourceWorkbook
(
    WorkbookId              INT IDENTITY(1,1) NOT NULL,
    PortfolioId             INT NOT NULL,
    AssetName               NVARCHAR(255) NOT NULL,
    SourceFileName          NVARCHAR(260) NOT NULL,
    SourceFilePath          NVARCHAR(1024) NULL,
    SharePointSiteUrl       NVARCHAR(1024) NULL,
    SharePointLibrary       NVARCHAR(255) NULL,
    SharePointFolderPath    NVARCHAR(1024) NULL,
    TemplateName            NVARCHAR(255) NULL,
    SourceSystem            NVARCHAR(100) NOT NULL CONSTRAINT DF_SourceWorkbook_SourceSystem DEFAULT (N'SharePoint'),
    SourceCreatedAtUtc      DATETIME2(0) NULL,
    SourceModifiedAtUtc     DATETIME2(0) NULL,
    IsActive                BIT NOT NULL CONSTRAINT DF_SourceWorkbook_IsActive DEFAULT (1),
    CreatedAtUtc            DATETIME2(0) NOT NULL CONSTRAINT DF_SourceWorkbook_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
    UpdatedAtUtc            DATETIME2(0) NOT NULL CONSTRAINT DF_SourceWorkbook_UpdatedAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_SourceWorkbook PRIMARY KEY CLUSTERED (WorkbookId),
    CONSTRAINT FK_SourceWorkbook_Portfolio FOREIGN KEY (PortfolioId) REFERENCES meta.Portfolio (PortfolioId),
    CONSTRAINT UQ_SourceWorkbook_Portfolio_File UNIQUE (PortfolioId, SourceFileName)
);
GO

CREATE TABLE meta.WorksheetConfig
(
    WorksheetConfigId       INT IDENTITY(1,1) NOT NULL,
    WorksheetName           NVARCHAR(255) NOT NULL,
    LandingMode             NVARCHAR(50) NOT NULL,
    IsEnabled               BIT NOT NULL CONSTRAINT DF_WorksheetConfig_IsEnabled DEFAULT (1),
    IsPbiRelevant           BIT NOT NULL CONSTRAINT DF_WorksheetConfig_IsPbiRelevant DEFAULT (0),
    ExpectedHeaderRow       INT NULL,
    PeriodHeaderRow         INT NULL,
    FirstDataRow            INT NULL,
    FirstPeriodColumn       INT NULL,
    CodeColumn              INT NULL,
    LabelColumn             INT NULL,
    Notes                   NVARCHAR(2000) NULL,
    CreatedAtUtc            DATETIME2(0) NOT NULL CONSTRAINT DF_WorksheetConfig_CreatedAtUtc DEFAULT (SYSUTCDATETIME()),
    UpdatedAtUtc            DATETIME2(0) NOT NULL CONSTRAINT DF_WorksheetConfig_UpdatedAtUtc DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_WorksheetConfig PRIMARY KEY CLUSTERED (WorksheetConfigId),
    CONSTRAINT UQ_WorksheetConfig_WorksheetName UNIQUE (WorksheetName)
);
GO

CREATE TABLE meta.IngestionRun
(
    IngestionRunId          BIGINT IDENTITY(1,1) NOT NULL,
    PortfolioId             INT NOT NULL,
    WorkbookId              INT NULL,
    PipelineRunId           NVARCHAR(100) NULL,
    TriggerType             NVARCHAR(50) NOT NULL CONSTRAINT DF_IngestionRun_TriggerType DEFAULT (N'Scheduled'),
    Status                  NVARCHAR(50) NOT NULL CONSTRAINT DF_IngestionRun_Status DEFAULT (N'Started'),
    SourceFileName          NVARCHAR(260) NOT NULL,
    SourceFilePath          NVARCHAR(1024) NULL,
    SourceLastModifiedAtUtc DATETIME2(0) NULL,
    StartedAtUtc            DATETIME2(0) NOT NULL CONSTRAINT DF_IngestionRun_StartedAtUtc DEFAULT (SYSUTCDATETIME()),
    CompletedAtUtc          DATETIME2(0) NULL,
    WorksheetCount          INT NULL,
    CellCount               BIGINT NULL,
    ErrorMessage            NVARCHAR(4000) NULL,
    CONSTRAINT PK_IngestionRun PRIMARY KEY CLUSTERED (IngestionRunId),
    CONSTRAINT FK_IngestionRun_Portfolio FOREIGN KEY (PortfolioId) REFERENCES meta.Portfolio (PortfolioId),
    CONSTRAINT FK_IngestionRun_Workbook FOREIGN KEY (WorkbookId) REFERENCES meta.SourceWorkbook (WorkbookId)
);
GO

CREATE INDEX IX_IngestionRun_Workbook_Status
    ON meta.IngestionRun (WorkbookId, Status, IngestionRunId DESC);
GO
