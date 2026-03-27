IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'meta')
    EXEC(N'CREATE SCHEMA meta');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'landing')
    EXEC(N'CREATE SCHEMA landing');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'util')
    EXEC(N'CREATE SCHEMA util');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ingest')
    EXEC(N'CREATE SCHEMA ingest');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sheet')
    EXEC(N'CREATE SCHEMA sheet');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'pbi')
    EXEC(N'CREATE SCHEMA pbi');
GO
