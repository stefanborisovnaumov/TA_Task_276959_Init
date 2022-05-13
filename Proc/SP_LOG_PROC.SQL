/********************************************************************************************************/
/* Help function: */
DROP FUNCTION IF EXISTS  [dbo].[FN_GET_EXCEPTION_INFO]
GO

/* Help function: Get Exception information */
CREATE FUNCTION [dbo].[FN_GET_EXCEPTION_INFO]()
	returns VARCHAR(MAX)
AS
BEGIN
	DECLARE @OUT_MSG VARCHAR(MAX)
	DECLARE @ERR_NUM		INT 			= ERROR_NUMBER()
	DECLARE @ERR_SEVERITY	INT 			= ERROR_SEVERITY()
	DECLARE @ERR_STATE		INT 			= ERROR_STATE()
	DECLARE @ERR_LINE		INT				= ERROR_LINE()
	DECLARE @ERR_PROCEDURE  sysname			= ERROR_PROCEDURE()
	DECLARE @ERR_MSG		nvarchar(2048)	= ERROR_MESSAGE()

	SET @OUT_MSG = 'Exception caught during ' + CASE	WHEN @ERR_PROCEDURE IS NULL 
														THEN 'script' 
														ELSE 'Stored Procedure' 
														END 
				+ ' execution. Details: ' + CHAR(13) + CHAR(10)
				
	IF @ERR_PROCEDURE IS NOT NULL
		SET @OUT_MSG += '[ERROR_PROCEDURE]: "' + @ERR_PROCEDURE + '"' + CHAR(13) + CHAR(10)
	IF @ERR_MSG IS NOT NULL
		SET @OUT_MSG += '[ERROR_MESSAGE]: "' + @ERR_MSG + '"' + CHAR(13) + CHAR(10)
	IF @ERR_LINE IS NOT NULL
		SET @OUT_MSG += '[ERROR_LINE]: ' + LTRIM(STR(@ERR_LINE)) + CHAR(13) + CHAR(10)
	IF @ERR_NUM IS NOT NULL
		SET @OUT_MSG += '[ERROR_NUMBER]: ' + LTRIM(STR(@ERR_NUM)) + CHAR(13) + CHAR(10)
	IF @ERR_SEVERITY IS NOT NULL
		SET @OUT_MSG += '[ERROR_SEVERITY]: ' + LTRIM(STR(@ERR_SEVERITY)) + CHAR(13) + CHAR(10)
	IF @ERR_STATE IS NOT NULL
		SET @OUT_MSG += '[ERROR_STATE]: ' + LTRIM(STR(@ERR_STATE)) + CHAR(13) + CHAR(10)
	
	RETURN @OUT_MSG
END
GO

DROP FUNCTION IF EXISTS dbo.FN_GET_TIME_DIFF
GO

/* Help function: Get Time Diff as string in format: d:hh:mi:ss.mmm */
CREATE FUNCTION dbo.FN_GET_TIME_DIFF( @TimeBeg DateTime, @TimeEnd DateTime )
	RETURNS VARCHAR(64)
AS 
BEGIN
	DECLARE @Result varchar(32) = '', @MiliSec BigInt = DATEDIFF(ms, @TimeBeg, @TimeEnd) 
    ;
    select @Result = CONVERT(VARCHAR(32), (@MiliSec / 86400000)) + ':' 
            + right(CONVERT(VARCHAR(32), DATEADD(ms, @MiliSec, 0), 121),12);

    return @Result;
END
GO

/********************************************************************************************************/
/* Help procedure: */
DROP PROCEDURE IF EXISTS  dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB]
GO

/* Help procedure: Get account data from OnlineDB */
CREATE PROCEDURE dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB]
(
	@SqlServerName		sysname
,	@SqlDatabase		sysname
,	@CUR_ACCOUNT_DATE	DateTime OUT
)
AS 
BEGIN 

	DECLARE @SqlStms NVARCHAR(4000) = N''
		,	@StmsParmams NVARCHAR(500) = N'@CUR_DATE_OUT datetime OUTPUT'
	;

	select	@StmsParmams = N'@CUR_DATE_OUT DateTime OUTPUT'
		,	@SqlStms = N'SELECT @CUR_DATE_OUT = CAST( CAST( CAST( REVERSE( SUBSTRING( DATA, 5, 4 ) ) AS BINARY(4) ) AS INT ) AS CHAR(8) )
	FROM ' + @SqlServerName + '.' + @SqlDatabase + '.dbo.CSOFT_SYS	WHERE CODE = 1'
	
	EXEC sys.sp_executesql @SqlStms, @StmsParmams, @CUR_DATE_OUT = @CUR_ACCOUNT_DATE OUTPUT
END
GO

/********************************************************************************************************/
/* Table: SYS_LOG_PROC */
DROP TABLE IF EXISTS [dbo].[SYS_LOG_PROC]
GO

CREATE TABLE [dbo].[SYS_LOG_PROC]
(
	[ID]		[int] IDENTITY(1,1) NOT NULL
,	[DATE]		[datetime] NULL    
,	[PROC_NAME]	SYSNAME NULL
,	[MSG]		nvarchar(max) NULL
,	[SQL]		nvarchar(max) NULL
    CONSTRAINT [PK_SYS_LOG_PROC] 
        PRIMARY KEY CLUSTERED ([ID])
)
GO

ALTER TABLE dbo.[SYS_LOG_PROC]
	ADD CONSTRAINT _DF_SYS_LOG_PROC_DATE_  DEFAULT (getdate()) FOR [Date]
GO


/****** Object:  StoredProcedure dbo.[sp_log_proc]    Script Date: 03.05.2022 г. 14:44:11 ******/
DROP PROCEDURE IF EXISTS dbo.[SP_SYS_LOG_PROC]
GO

/********************************************************************************************************/
/* Help proc: SP_SYS_LOG_PROC log trace information */
CREATE PROCEDURE dbo.[SP_SYS_LOG_PROC]
	@ProcID int
,	@Sql	nvarchar(max)
,	@Msg	nvarchar(max)
AS
	INSERT INTO dbo.[SYS_LOG_PROC] ( [proc_name], [sql], [Msg], [Date]  )
		VALUES( OBJECT_NAME( @ProcID ), @Sql, @Msg, GetDate() )
GO
