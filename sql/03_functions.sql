CREATE OR ALTER FUNCTION util.ExcelSerialToDateTime2
(
    @ExcelSerial DECIMAL(18,5)
)
RETURNS DATETIME2(0)
AS
BEGIN
    IF @ExcelSerial IS NULL
        RETURN NULL;

    DECLARE @wholeDays INT = FLOOR(@ExcelSerial);
    DECLARE @fraction  DECIMAL(18,10) = @ExcelSerial - FLOOR(@ExcelSerial);
    DECLARE @baseDate  DATETIME2(0);

    SET @baseDate = DATEADD
    (
        DAY,
        @wholeDays - CASE WHEN @wholeDays < 60 THEN 1 ELSE 2 END,
        CONVERT(DATETIME2(0), '1900-01-01')
    );

    RETURN DATEADD(SECOND, CAST(ROUND(@fraction * 86400, 0) AS INT), @baseDate);
END;
GO

CREATE OR ALTER FUNCTION util.ExcelSerialToDate
(
    @ExcelSerial DECIMAL(18,5)
)
RETURNS DATE
AS
BEGIN
    RETURN CONVERT(DATE, util.ExcelSerialToDateTime2(@ExcelSerial));
END;
GO
