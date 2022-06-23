
/********************************************************************************************************/
/* Help function: */
DROP FUNCTION IF EXISTS  [dbo].[FN_GET_EXCEPTION_INFO]
GO

/********************************************************************************************************/
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

/********************************************************************************************************/
DROP FUNCTION IF EXISTS dbo.FN_GET_TIME_DIFF
GO

/********************************************************************************************************/
/* Help function: Get Time Diff as string in format: d:hh:mi:ss.mmm */
CREATE FUNCTION dbo.FN_GET_TIME_DIFF( @TimeBeg DateTime, @TimeEnd DateTime )
	RETURNS VARCHAR(64)
AS 
BEGIN
	declare @Result		varchar(32) = ''
		,	@MiliSec	bigint		= 0
		,	@DiffDais	bigint		= DATEDIFF(dd, @TimeBeg, @TimeEnd)
	;
	if @DiffDais > 1
		select @TimeBeg = cast(@TimeBeg as time), @TimeEnd = cast(@TimeEnd as time)
	;
	select @MiliSec = datediff(ms, @TimeBeg, @TimeEnd) 
	;
	select @Result = str(@DiffDais,len(@DiffDais),0) 
		+ ':' + right(convert(varchar(32), dateadd(ms, @MiliSec, 0), 121),12)
	;

    return @Result;
END
GO

/*****************************************************************************/
-- Create table dbo.[CURRENCIES_TA] for currency rate
drop table if exists dbo.[CURRENCIES_TA]
GO

CREATE TABLE [dbo].[CURRENCIES_TA](
	[ROW_ID] [int] IDENTITY(1, 1),
	[CODE] [char](3) NULL,
	[FIXING] [FLOAT] NULL,
	[BASE] [int] NULL,
	[CCY_CODE] [int] NULL,
	CONSTRAINT [PK_CURRENCIES_TA] PRIMARY KEY CLUSTERED ([ROW_ID])
)
GO

INSERT INTO dbo.[CURRENCIES_TA]
	([CODE], [FIXING], [BASE], [CCY_CODE]) 
VALUES
('BGN', 1.00000, 1, 100),
('USD', 1.75348, 1, 840),
('EUR', 1.95583, 1, 978),
('GBP', 2.47768, 1, 826)
GO

/********************************************************************************************************/
DROP FUNCTION IF EXISTS dbo.[TRANS_CCY_TO_CCY_TA]
GO

/********************************************************************************************************/
/* Help function: Convert amount from one currency to another */
CREATE OR ALTER FUNCTION [dbo].[TRANS_CCY_TO_CCY_TA]( @SUMA AS FLOAT, @SUM_CCY AS INT, @TO_CCY AS INT )
RETURNS FLOAT
AS
BEGIN
	IF( @SUMA IS NULL OR @SUMA = 0.0 )
		RETURN 0.0

	DECLARE @FIXING_FROM AS FLOAT, @BASE_FROM AS INT
		,	@FIXING_TO AS FLOAT, @BASE_TO AS INT, @PRE_TO AS SMALLINT

	SELECT	@FIXING_TO = [FIXING], @BASE_TO = [BASE] , @PRE_TO = NULL
	FROM 	dbo.[CURRENCIES_TA] WITH (NOLOCK)
	WHERE	[CCY_CODE] = @TO_CCY

	/* Ако двете валути са еднакви връщаме входната сума */
	IF( @SUM_CCY IS NULL OR @SUM_CCY = @TO_CCY )
		RETURN ROUND( ISNULL( @SUMA, 0.0 ), ISNULL(@PRE_TO, 2) )

	SELECT	@FIXING_FROM = [FIXING], @BASE_FROM = [BASE]
	FROM 	dbo.[CURRENCIES_TA] WITH (NOLOCK)
	WHERE	[CCY_CODE] = @SUM_CCY

	IF ( ISNULL ( @BASE_FROM, 0.0 ) = 0.0 OR ISNULL ( @BASE_TO, 0.0 ) = 0.0 
		OR ISNULL ( @FIXING_FROM, 0.0 ) = 0.0 OR ISNULL ( @FIXING_TO, 0.0 ) = 0.0 )
		RETURN 0.0

	RETURN ROUND( ( @FIXING_FROM / @BASE_FROM ) * @SUMA / ( @FIXING_TO / @BASE_TO ),  ISNULL( @PRE_TO, 2 ) )
END
GO



/********************************************************************************************************/
/* Help procedure: */
DROP PROCEDURE IF EXISTS  dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB]
GO

/********************************************************************************************************/
/* Help procedure: Get account data from OnlineDB */
CREATE PROCEDURE dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB]
(
	@SqlServerName		sysname
,	@SqlDatabase		sysname
,	@CUR_ACCOUNT_DATE	DateTime OUT
)
AS 
BEGIN 

	DECLARE @SqlStms NVARCHAR(4000) = N'', @Msg nvarchar(max) = N'', @Ret int = -1
		,	@StmsParmams NVARCHAR(500) = N'@CUR_DATE_OUT datetime OUTPUT'
	;

	select	@StmsParmams = N'@CUR_DATE_OUT DateTime OUTPUT'
		,	@SqlStms = N'SELECT @CUR_DATE_OUT = CAST( CAST( CAST( REVERSE( SUBSTRING( DATA, 5, 4 ) ) AS BINARY(4) ) AS INT ) AS CHAR(8) )
	FROM ' + @SqlServerName + '.' + @SqlDatabase + '.dbo.CSOFT_SYS	WHERE CODE = 1'
	
	begin try
		exec @Ret = sp_executesql @SqlStms, @StmsParmams, @CUR_DATE_OUT = @CUR_ACCOUNT_DATE OUTPUT
	end try
	begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, @SqlStms, @Msg
			return 1;
	end catch

	return @Ret;
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


/****** Object:  StoredProcedure dbo.[sp_log_proc]    Script Date: 03.05.2022 Рі. 14:44:11 ******/
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




/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от Online базата с активни запори */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
(
	@OnlineSqlServerName	sysname 
,	@OnlineSqlDataBaseName	sysname 
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
        ,   @Sql1 nvarchar(2000) = N'', @Msg nvarchar(2000) = N''
    ;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	/************************************************************************************************************/
	/* 2.1. Prepare Online Database FullName */
	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	declare @Sql nvarchar(4000) = N'', @Ret int = 0
		,	@SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;
	;

	/************************************************************************************************************/
	/* 2.2. Prepare SQL statement */
	select @Sql = 
	'declare @Ret int = 0
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	
	declare @Tbl_Distraint_Codes TABLE ( [CODE] INT )
	;

	insert into @Tbl_Distraint_Codes
	SELECT [n].[CODE]
	from '+@SqlFullDBName+'.dbo.[NOMS] [n] with(nolock)
	where	[n].[NOMID] = 136
		and ([n].[sTATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
	;
	WITH [CTE_X] AS
	(
		SELECT [CODE] 
		FROM @Tbl_Distraint_Codes 
	)
	SELECT distinct [CLC].[CUSTOMER_ID]
	FROM '+@SqlFullDBName+'.dbo.[BLOCKSUM] [BLK] with(nolock)
	inner join [CTE_X] [X] with(nolock)
		on	[BLK].[WHYFREEZED] = [X].[CODE]
		and [BLK].[CLOSED_FROZEN_SUM] <> 1
		and [BLK].[SUMA] > 0.0
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		on [ACC].[PART_ID] = [BLK].[PARTIDA]
	inner join '+@SqlFullDBName+'.dbo.[dt015] [CLC] with(nolock)
		on [CLC].[CODE] = [ACC].[CLIENT_ID]
	';

	/************************************************************************************************************/
	/* 3. Execute SQL statement */
	begin try
        exec @Ret = sp_executesql @Sql
    end try
	begin catch
		select @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go

/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от OnlineDb с неплатени такси към всички кл. сметки */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
(
	@OnlineSqlServerName	sysname 
,	@OnlineSqlDataBaseName	sysname 
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
        ,   @Sql1 nvarchar(2000) = N'', @Msg nvarchar(2000) = N''
    ;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end   

    /************************************************************************************************************/
	/* 2.1. Prepare Online Database FullName */
	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	declare @Sql nvarchar(4000) = N'', @Ret int = 0
		,	@SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;
	;

	/************************************************************************************************************/
	/* 2.2. Prepare SQL statement */
	select @Sql = '
    select distinct [C].[CUSTOMER_ID] 
    from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
    inner join '+@SqlFullDBName+'.dbo.[PARTS] [A] with(nolock)
        on [a].[PART_ID] = [T].[ACCOUNT_DT]
    inner join '+@SqlFullDBName+'.dbo.[DT015] [C] with(nolock)
        on [C].[CODE] = [A].[CLIENT_ID]
    where	[T].[TAX_STATUS] =  0 /* eTaxActive = 0 // Действаща такса */
        and [T].[COLLECT_FROM_ALL_CUSTOMER_ACCOUNTS] = 1
    ';

	/************************************************************************************************************/
	/* 3. Execute SQL statement */
	begin try
        exec @Ret = sp_executesql @Sql
    end try
	begin catch
		select @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch    

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go

