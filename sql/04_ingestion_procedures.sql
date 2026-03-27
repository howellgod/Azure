CREATE OR ALTER PROCEDURE ingest.usp_RegisterWorkbook
    @PortfolioCode           NVARCHAR(100),
    @PortfolioName           NVARCHAR(255),
    @AssetName               NVARCHAR(255),
    @SourceFileName          NVARCHAR(260),
    @SourceFilePath          NVARCHAR(1024) = NULL,
    @SharePointSiteUrl       NVARCHAR(1024) = NULL,
    @SharePointLibrary       NVARCHAR(255) = NULL,
    @SharePointFolderPath    NVARCHAR(1024) = NULL,
    @TemplateName            NVARCHAR(255) = NULL,
    @SourceCreatedAtUtc      DATETIME2(0) = NULL,
    @SourceModifiedAtUtc     DATETIME2(0) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PortfolioId INT;

    IF NOT EXISTS (SELECT 1 FROM meta.Portfolio WHERE PortfolioCode = @PortfolioCode)
    BEGIN
        INSERT INTO meta.Portfolio (PortfolioCode, PortfolioName)
        VALUES (@PortfolioCode, @PortfolioName);
    END;

    SELECT @PortfolioId = PortfolioId
    FROM meta.Portfolio
    WHERE PortfolioCode = @PortfolioCode;

    MERGE meta.SourceWorkbook AS target
    USING
    (
        SELECT
            @PortfolioId          AS PortfolioId,
            @AssetName            AS AssetName,
            @SourceFileName       AS SourceFileName,
            @SourceFilePath       AS SourceFilePath,
            @SharePointSiteUrl    AS SharePointSiteUrl,
            @SharePointLibrary    AS SharePointLibrary,
            @SharePointFolderPath AS SharePointFolderPath,
            @TemplateName         AS TemplateName,
            @SourceCreatedAtUtc   AS SourceCreatedAtUtc,
            @SourceModifiedAtUtc  AS SourceModifiedAtUtc
    ) AS source
        ON target.PortfolioId = source.PortfolioId
       AND target.SourceFileName = source.SourceFileName
    WHEN MATCHED THEN
        UPDATE SET
            AssetName            = source.AssetName,
            SourceFilePath       = source.SourceFilePath,
            SharePointSiteUrl    = source.SharePointSiteUrl,
            SharePointLibrary    = source.SharePointLibrary,
            SharePointFolderPath = source.SharePointFolderPath,
            TemplateName         = source.TemplateName,
            SourceCreatedAtUtc   = source.SourceCreatedAtUtc,
            SourceModifiedAtUtc  = source.SourceModifiedAtUtc,
            UpdatedAtUtc         = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT
        (
            PortfolioId,
            AssetName,
            SourceFileName,
            SourceFilePath,
            SharePointSiteUrl,
            SharePointLibrary,
            SharePointFolderPath,
            TemplateName,
            SourceCreatedAtUtc,
            SourceModifiedAtUtc
        )
        VALUES
        (
            source.PortfolioId,
            source.AssetName,
            source.SourceFileName,
            source.SourceFilePath,
            source.SharePointSiteUrl,
            source.SharePointLibrary,
            source.SharePointFolderPath,
            source.TemplateName,
            source.SourceCreatedAtUtc,
            source.SourceModifiedAtUtc
        );

    SELECT WorkbookId, PortfolioId, AssetName, SourceFileName
    FROM meta.SourceWorkbook
    WHERE PortfolioId = @PortfolioId
      AND SourceFileName = @SourceFileName;
END;
GO

CREATE OR ALTER PROCEDURE ingest.usp_BeginIngestionRun
    @PortfolioCode             NVARCHAR(100),
    @SourceFileName            NVARCHAR(260),
    @SourceFilePath            NVARCHAR(1024) = NULL,
    @SourceLastModifiedAtUtc   DATETIME2(0) = NULL,
    @TriggerType               NVARCHAR(50) = N'Scheduled',
    @PipelineRunId             NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PortfolioId INT;
    DECLARE @WorkbookId INT;

    SELECT @PortfolioId = PortfolioId
    FROM meta.Portfolio
    WHERE PortfolioCode = @PortfolioCode;

    IF @PortfolioId IS NULL
    BEGIN
        THROW 50001, 'PortfolioCode not found in meta.Portfolio.', 1;
    END;

    SELECT @WorkbookId = WorkbookId
    FROM meta.SourceWorkbook
    WHERE PortfolioId = @PortfolioId
      AND SourceFileName = @SourceFileName;

    INSERT INTO meta.IngestionRun
    (
        PortfolioId,
        WorkbookId,
        PipelineRunId,
        TriggerType,
        Status,
        SourceFileName,
        SourceFilePath,
        SourceLastModifiedAtUtc
    )
    VALUES
    (
        @PortfolioId,
        @WorkbookId,
        @PipelineRunId,
        @TriggerType,
        N'Started',
        @SourceFileName,
        @SourceFilePath,
        @SourceLastModifiedAtUtc
    );

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS IngestionRunId;
END;
GO

CREATE OR ALTER PROCEDURE ingest.usp_CompleteIngestionRun
    @PipelineRunId         NVARCHAR(100),
    @Status                NVARCHAR(50),
    @WorksheetCount        INT = NULL,
    @CellCount             BIGINT = NULL,
    @ErrorMessage          NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE meta.IngestionRun
    SET
        Status         = @Status,
        WorksheetCount = COALESCE(@WorksheetCount, WorksheetCount),
        CellCount      = COALESCE(@CellCount, CellCount),
        ErrorMessage   = @ErrorMessage,
        CompletedAtUtc = SYSUTCDATETIME()
    WHERE PipelineRunId = @PipelineRunId;
END;
GO
