/***************************************************************************************************************/
-- Име          : Янко Янков
-- Дата и час   : 08.06.2022
-- Задача       : Task 276959 (v2.6.2)
-- Класификация : Test Automation
-- Описание     : Автоматизация на тестовете за вснони бележки с използване на наличните данни от Online базата
-- Параметри    : Няма
/***************************************************************************************************************/

/*****************************************************************************/
-- Init table dbo.[TEST_AUTOMATION_TA_TYPE]
drop table if exists dbo.[TEST_AUTOMATION_TA_TYPE]
go

create table dbo.[TEST_AUTOMATION_TA_TYPE]
(
	[ID] int identity(1,1)
,	[TA_TYPE] varchar(64)
,	[DB_TYPE] varchar(64)
	constraint [PK_TEST_AUTOMATION_TA_TYPE] 
		primary key clustered( [ID] )
)
go

create unique index [IX_TEST_AUTOMATION_TA_TYPE]
	on dbo.[TEST_AUTOMATION_TA_TYPE] ( [TA_TYPE], [DB_TYPE] )
go

DECLARE @DB_TYPE varchar(64)		= N'BETA'
	,	@TA_Type_Lile varchar(64)	= N'%CashPay%BETA%'
;
insert into dbo.[TEST_AUTOMATION_TA_TYPE]
( [TA_TYPE], [DB_TYPE] )
select distinct 
		[a].[TA_TYPE]	as [TA_TYPE]
	,	@DB_TYPE		as [DB_TYPE]
from 
(
	select distinct [TA_TYPE] as [TA_TYPE]
	from dbo.[DT015_CUSTOMERS_ACTIONS_TA]
	where TA_TYPE like @TA_Type_Lile
	union all
	select distinct [TA_TYPE] 
	from dbo.[PREV_COMMON_TA] with(nolock)
	where [TA_TYPE] like @TA_Type_Lile
) [a]
left outer join dbo.[TEST_AUTOMATION_TA_TYPE] [d] with(nolock)
	on	[d].[TA_TYPE] = [a].[TA_TYPE]
	and [d].[DB_TYPE] = @DB_TYPE
where [d].[ID] is null
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
drop table if exists dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
go

create table dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
(
	[ID]				int identity(1,1)
,	[TEST_ID]			nvarchar(512) 
,	[SQL_COND]			nvarchar(1000)
,	[DESCR]				nvarchar(2000)
,	[IS_BASE_SELECT]	bit constraint _DF_AGR_CASH_PAYMENTS_SQL_CONDITIONS_IS_BASE_SELECT DEFAULT(0)
,	[IS_SELECT_COUNT]	bit constraint _DF_AGR_CASH_PAYMENTS_SQL_CONDITIONS_IS_SELECT_COUNT DEFAULT(0)
	
	CONSTRAINT [PK_AGR_AGR_CASH_PAYMENTS_SQL_CONDITIONS]
		PRIMARY KEY CLUSTERED ( [ID] )
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] 
(
	 [CUSTOMER_ID] int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] 
(
	 [CUSTOMER_ID] int
)
go

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
	DECLARE @Result varchar(32) = '', @MiliSec BigInt = DATEDIFF(ms, @TimeBeg, @TimeEnd) 
    ;
    select @Result = CONVERT(VARCHAR(32), (@MiliSec / 86400000)) + ':' 
            + right(CONVERT(VARCHAR(32), DATEADD(ms, @MiliSec, 0), 121),12);

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


/********************************************************************************************************/
/* Създаване на помощно view за Условията към тестовите сценарии */
DROP VIEW IF EXISTS dbo.[VIEW_CASH_PAYMENTS_CONDITIONS]
GO

CREATE OR ALTER VIEW dbo.[VIEW_CASH_PAYMENTS_CONDITIONS]
AS

	WITH [CTE_CUST_EGFN_TYPE] AS 
	(
		SELECT [X].*
		FROM ( 
			VALUES	( 1 , 'ЕГН' )
				,	( 2 , 'ЕИК/БУЛСТАТ' )
				,	( 3 , 'БАЕ' )
				,	( 4 , 'ЛНЧ' )
				,	( 5 , 'Функционално ЕГН' )
				,	( 6 , 'Функционално ЛНЧ (ЧФЛ)' )
				,	( 7 , 'Функционално ЕИК (МЮЛ)' ) 
				,	( 8 , 'Функционално ЕИК (ЧЮЛ)' )
				,	( 9 , 'Идентификатор за клиенти по ЗЗКИ' )
		) X([ID], [NAME])
	)
	, [CTE_CUSTOMER_CHARACTERISTIC] AS 
	(
		SELECT [X].*
		FROM ( 
			VALUES	(0,	'Банков клиент' )
				,	(1,	'Външен клиент' )
				,	(2,	'Prospect клиент' )
				,	(3,	'Действителен собственик' )
				,	(4,	'Клиент без активни продукти' )
		) X([ID], [NAME])
	)
	, [CTE_CUSTOMER_AGE] AS 
	(
		SELECT [X].*, GetDate() as [SYS_DATE]
		FROM (
			VALUES	(-1, 00, 190, 'Без значение' )
				,	( 1, 18, 190, 'Пълнолетно лице (над 18г.)' )
				,	( 2, 14,  17, 'Непълнолетно физическо лице (от 14г. до 18г.)' )
				,	( 3, 00,  13, 'Малолетно физическо лице (до 14г.)' )
				,	( 4, 00, 190, 'Външен клиент' )
		) X([ID], [AGE_MIN], [AGE_MAX], [NAME])
	)
	, [CTE_UI_RAZPOREDITEL] AS 
	(
		SELECT [X].*
		FROM ( 
			VALUES	( 1	, 1,'Титуляр' )
				,	( 2	, 0,'Пълномощник' )
				,	( 3	, 0,'Законен представител' )
				,	( 4	,-1,'Действителен собственик' )
				,	( 5	,-1,'Трето лице' )
				,	( 6	,-1,'Картодържател' )
				,	(100,-1,'Наследник' )
				,	(101,-1,'Трето лице-представляващ' )
			) X([ID], [CND_ID], [NAME])
	)
	, [CTE_CCY] AS 
	(
		SELECT [X].*
		FROM ( 
			VALUES ( 36, 'AUD'), (100, 'BGN'), (124, 'CAD'), (756,	'CHF')
				,  (826, 'GBP'), (840,	'USD'), (946, 'RON'), (978,	'EUR')
		) X([ID], [NAME])		
	)
	SELECT	DISTINCT
			[PREV].[ROW_ID]									AS [ROW_ID]
		,	[PREV].[TA_TYPE]								AS [TA_TYPE]
		,	[CUST].[ROW_ID]									AS [CUST_ROW_ID]
		,	[DREG].[ROW_ID]									AS [DEAL_ROW_ID]
		,	[CORS].[ROW_ID]									AS [CORS_ROW_ID]		
		,	[PSPEC].[ROW_ID]								AS [PSPEC_ROW_ID]
		,	[PROXY].[ROW_ID]								AS [PROXY_ROW_ID]

		/* Условия за титуляра dbo.[DT015_CUSTOMERS_ACTIONS_TA] */
		,	[CUST].[SECTOR]									AS [SECTOR]
		,	[CUST].[UNIFIED]								AS [UNIFIED]
		,	[CUST].[IS_SERVICE]								AS [IS_SERVICE]
		,	[CUST].[EGFN_TYPE]								AS [EGFN_TYPE]
		,	IsNull([NM1].[CODE_EGFN_TYPE],-1)				AS [CODE_EGFN_TYPE]
		,	[CUST].[DB_CLIENT_TYPE]							AS [DB_CLIENT_TYPE_DT300]
		,	[CUST].[VALID_ID]								AS [VALID_ID]	
		,	[CUST].[CUSTOMER_CHARACTERISTIC]				AS [CUSTOMER_CHARACTERISTIC]
		,	IsNull([NM2].[CODE_CUSTOMER_CHARACTERISTIC],-1) AS [CODE_CUSTOMER_CHARACTERISTIC]
		,	[CUST].[CUSTOMER_AGE]							AS [CUSTOMER_AGE]
		,	cast(IsNull([NM3].[CUSTOMER_BIRTH_DATE_MIN],0) as DATE)
															AS [CUSTOMER_BIRTH_DATE_MIN]
		,	cast(IsNull([NM3].[CUSTOMER_BIRTH_DATE_MAX], 999) as DATE)
															AS [CUSTOMER_BIRTH_DATE_MAX]
		,	[CUST].[IS_PROXY]								AS [IS_PROXY]
		,	[CUST].[IS_UNIQUE]								AS [IS_UNIQUE_CUSTOMER]
		,	[CUST].[HAVE_CREDIT]							AS [HAVE_CREDIT]
		,	[CUST].[PROXY_COUNT]							AS [PROXY_COUNT]
		,	[CUST].[COLLECT_TAX_FROM_ALL_ACC]				AS [COLLECT_TAX_FROM_ALL_ACC]

		/* Условия за пълномощника dbo.[PROXY_SPEC_TA] */
		,	[PSPEC].[UI_RAZPOREDITEL]						AS [UI_RAZPOREDITEL]
		,	[PSPEC].[UI_UNLIMITED]							AS [UI_UNLIMITED]

		/* Условия за сделката dbo.[RAZPREG_TA] */
		,	[DREG].UI_STD_DOG_CODE							AS [UI_STD_DOG_CODE]
		,	[DREG].[UI_INDIVIDUAL_DEAL]						AS [UI_INDIVIDUAL_DEAL]
		,	[DREG].[INT_COND_STDCONTRACT]					AS [INT_COND_STDCONTRACT]
		,	[DREG].UI_NM342_CODE							AS [UI_NM342_CODE]
		,	[NM_ID].[CODE_UI_NM342]							AS [CODE_UI_NM342]
		,	[DREG].UI_CURRENCY_CODE							AS [UI_CURRENCY_CODE]
		,	[CCY_DEAL].[CCY_CODE_DEAL]						AS [CCY_CODE_DEAL]
		,	[DREG].UI_OTHER_ACCOUNT_FOR_TAX					AS [UI_OTHER_ACCOUNT_FOR_TAX]
		,	[DREG].UI_NOAUTOTAX								AS [UI_NOAUTOTAX]
		,	[DREG].UI_DENY_MANUAL_TAX_ASSIGN				AS [UI_DENY_MANUAL_TAX_ASSIGN]
		,	[DREG].UI_CAPIT_ON_BASE_DATE_OPEN				AS [UI_CAPIT_ON_BASE_DATE_OPEN]
		,	[DREG].UI_BANK_RECEIVABLES						AS [UI_BANK_RECEIVABLES]
		,	[DREG].UI_JOINT_TYPE							AS [UI_JOINT_TYPE]
		,	[DREG].LIMIT_AVAILABILITY						AS [LIMIT_AVAILABILITY]
		,	[DREG].DEAL_STATUS								AS [DEAL_STATUS]
		,	[DREG].LIMIT_TAX_UNCOLLECTED					AS [LIMIT_TAX_UNCOLLECTED]
		,	[DREG].LIMIT_ZAPOR								AS [LIMIT_ZAPOR]
		,	[DREG].IS_CORR									AS [IS_CORR]
		,	[DREG].IS_UNIQUE								AS [IS_UNIQUE_DEAL]
		,	[DREG].GS_PROGRAMME_CODE						AS [GS_PROGRAMME_CODE]
		,	[DREG].GS_CARD_PRODUCT							AS [GS_CARD_PRODUCT]
		,	[DREG].GS_PRODUCT_CODE							AS [GS_PRODUCT_CODE]
		,	[NM_ID].[CODE_GS_PROGRAMME]
		,	[NM_ID].[CODE_GS_CARD]

		/* Условия за кореспондиращи сметки dbo.[DEALS_CORR_TA] */
		,	[CORS].[CURRENCY]								AS [CURRENCY_CORS]
		,	[CCY_CORS].[CCY_CODE_CORS]						AS [CCY_CODE_CORS]
		,	[CORS].[LIMIT_AVAILABILITY]						AS [LIMIT_AVAILABILITY_CORS]
/*		,	[CORS].[LIMIT_TAX_UNCOLLECTED]					AS [LIMIT_TAX_UNCOLLECTED_CORS] */

			/* [PROXY_ACC_TA] */
/*		,	[PROXY_ACC_TA]  Пълномощника, да има права за действието по избраната сметка */

			/* Условия за вносната бележка [PREV_COMMON_TA] */
		,	[PREV].[RUNNING_ORDER]							AS [RUNNING_ORDER]
		,	[PREV].[TYPE_ACTION]							AS [TYPE_ACTION]
		,	[PREV].TAX_CODE									AS [TAX_CODE]
		,	[PREV].PREF_CODE								AS [PREF_CODE]

			/* Зададената сума на документа и очакванета сума на таксата */						
		,	[NM_ID].[DOC_SUM]								AS [DOC_SUM]
		,	[PREV].[TAX_SUM]								AS [DOC_TAX_SUM]

	FROM dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
	INNER JOIN dbo.[RAZPREG_TA] [DREG] WITH(NOLOCK)
		on [PREV].[REF_ID] = [DREG].[ROW_ID]
	INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
		on [DREG].[REF_ID] = [CUST].[ROW_ID]
	LEFT JOIN dbo.[DEALS_CORR_TA] [CORS] WITH(NOLOCK)
		on [CORS].REF_ID = [DREG].[ROW_ID]
	LEFT JOIN dbo.[PROXY_SPEC_TA] as [PSPEC] WITH(NOLOCK)
		on [CUST].[ROW_ID] = [PSPEC].[REF_ID]
	LEFT JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [PROXY] WITH(NOLOCK)
		on [PROXY].[ROW_ID] = [PSPEC].[PROXY_CLIENT_ID]
	CROSS APPLY (
		SELECT	CASE WHEN IsNumeric([DREG].[UI_NM342_CODE]) = 1
					then cast([DREG].[UI_NM342_CODE] as int )
					ELSE '' END 	AS [CODE_UI_NM342]

			,	CASE WHEN IsNumeric([DREG].[GS_PROGRAMME_CODE]) = 1
					THEN cast( [DREG].[GS_PROGRAMME_CODE] as int) 
					ELSE '' END 	AS [CODE_GS_PROGRAMME]

			,	CASE WHEN IsNumeric([DREG].[GS_CARD_PRODUCT]) = 1
					THEN cast([DREG].[GS_CARD_PRODUCT] as int) 
					ELSE '' END 	AS [CODE_GS_CARD]

			,	CASE WHEN IsNumeric([PREV].[UI_SUM]) = 0 then 0.0
						else cast([PREV].[UI_SUM] as float ) end AS [DOC_SUM]
	) [NM_ID]
	OUTER APPLY (
		SELECT TOP (1) [NV].[ID] AS [CODE_EGFN_TYPE]
		FROM [CTE_CUST_EGFN_TYPE] [NV] WITH(NOLOCK)
		WHERE [NV].[NAME] = [CUST].[EGFN_TYPE]
	) [NM1]
	OUTER APPLY (
		SELECT TOP (1) [NV].[ID] AS [CODE_CUSTOMER_CHARACTERISTIC]
		FROM [CTE_CUSTOMER_CHARACTERISTIC] [NV] WITH(NOLOCK)
		WHERE [NV].[NAME] = [CUST].[CUSTOMER_CHARACTERISTIC]
	) [NM2]
	OUTER APPLY (
		SELECT TOP (1) 
				DATEADD(yy, -[NV].[AGE_MIN], [NV].[SYS_DATE]) AS [CUSTOMER_BIRTH_DATE_MAX]
			,	DATEADD(yy, -[NV].[AGE_MAX], [NV].[SYS_DATE]) AS [CUSTOMER_BIRTH_DATE_MIN]			
		FROM [CTE_CUSTOMER_AGE] [NV] WITH(NOLOCK)
		WHERE [NV].[NAME] = [CUST].[CUSTOMER_AGE]
	) [NM3]
	OUTER APPLY (
		SELECT TOP (1) [NV].[ID] AS [TYPE_CODE]
		FROM [CTE_UI_RAZPOREDITEL] [NV] WITH(NOLOCK)
		WHERE [NV].[CND_ID] = [PSPEC].[UI_RAZPOREDITEL]
	) [NM4]
	OUTER APPLY (
		SELECT TOP (1) [NV].[ID] AS [CCY_CODE_DEAL]
		FROM [CTE_CCY] [NV] WITH(NOLOCK)
		WHERE [NV].[NAME] = [DREG].[UI_CURRENCY_CODE]
	) [CCY_DEAL]
	OUTER APPLY (
		SELECT TOP (1) [NV].[ID] AS [CCY_CODE_CORS]
		FROM [CTE_CCY] [NV] WITH(NOLOCK)
		WHERE [NV].[NAME] = [CORS].[CURRENCY]
	) [CCY_CORS]
	WHERE [PREV].[TA_TYPE] LIKE N'%CashPayment%BETA%'
		AND [PREV].[ROW_ID] = IsNull( NULL,  [PREV].[ROW_ID] )
	;
GO

/********************************************************************************************************/
/* Помощно view за визуализация на данните от TA таблиците, който подлежат на актуализация */
drop view if exists dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA]
go

create view dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA]
as 
select 	[v].[ROW_ID]
	,	[v].TA_TYPE
		
	/* Данни за Титуляра */
	,	[v].[CUST_ROW_ID]
	,	[c].[UI_CUSTOMER_ID]
	,	[c].[UI_EGFN]
	,	[c].[NAME]
	,	[c].[COMPANY_EFN]
	,	[c].[UI_CLIENT_CODE]
	,	[c].[UI_NOTES_EXIST]
	,	[c].[IS_ZAPOR]
	,	[c].[ID_NUMBER]
	,	[c].[SERVICE_GROUP_EGFN]
	,	[c].[IS_ACTUAL]
	,	[c].[PROXY_COUNT]
	,	[c].[IS_PROXY]

	/* Данни на Сделката */
	,	[v].[DEAL_ROW_ID]
	,	[R].[UI_DEAL_NUM]
	,	[R].[DB_ACCOUNT]
	,	[R].[UI_ACCOUNT]
	,	[R].[ZAPOR_SUM]
	,	[R].[IBAN]
	,	[R].[TAX_UNCOLLECTED_SUM]

	/* Данни за кореспонденцията */
	,	[v].[CORS_ROW_ID]
	,	[D].[DEAL_NUM]
	,	[D].[CURRENCY]
	,	[D].[UI_CORR_ACCOUNT]
	,	[D].[TAX_UNCOLLECTED_SUM]	as [TAX_UNCOLLECTED_SUM_CORS]

	/* Данни за пълномощника */
	,	[v].[PSPEC_ROW_ID]
	,	[v].[PROXY_ROW_ID]
	,	[p].[UI_CUSTOMER_ID]		as [UI_CUSTOMER_ID_PROXY]
	,	[p].[UI_EGFN]				as [UI_EGFN_PROXY]
	,	[p].[NAME]					as [NAME_PROXY]
	,	[p].[COMPANY_EFN]			as [COMPANY_EFN_PROXY]
	,	[p].[UI_CLIENT_CODE]		as [UI_CLIENT_CODE_PROXY]
	,	[p].[UI_NOTES_EXIST]		as [UI_NOTES_EXIST_PROXY]
	,	[p].[IS_ZAPOR]				as [IS_ZAPOR_PROXY]
	,	[p].[ID_NUMBER]				as [ID_NUMBER_PROXY]
	,	[p].[SERVICE_GROUP_EGFN]	as [SERVICE_GROUP_EGFN_PROXY]
	,	[p].[IS_ACTUAL]				as [IS_ACTUAL_PROXY]
	,	[p].[PROXY_COUNT]			as [PROXY_COUNT_PROXY]
	,	[p].[IS_PROXY]				as [PROXY_IS_PROXY]

from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [v]

inner join dbo.[DT015_CUSTOMERS_ACTIONS_TA] [c]
	on [c].[ROW_ID] = [v].[CUST_ROW_ID]
inner join dbo.[RAZPREG_TA] [R]
	on [R].[ROW_ID] = [v].[DEAL_ROW_ID]

left outer join dbo.[DEALS_CORR_TA] [D]
	on [d].[ROW_ID] = [v].[CORS_ROW_ID]

left outer join dbo.[PROXY_SPEC_TA] [S]
	on [S].[ROW_ID] = [v].PSPEC_ROW_ID

left outer join  dbo.[DT015_CUSTOMERS_ACTIONS_TA] [p]
	on [p].[ROW_ID] = [S].[PROXY_CLIENT_ID]
go

/********************************************************************************************************/
/* Процедура за визличане на Sql Online Server name и Onle Database name */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]
(
	@DB_TYPE				sysname = N'BETA'
,	@DB_ALIAS				sysname = N'VCS_OnlineDB'
,	@OnlineSqlServerName	sysname = N'' out
,	@OnlineSqlDataBaseName	sysname = N'' out
)
as
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Sql nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, '', N'*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]'
	;

	/************************************************************************************************************/
	/* @TODO: */
	select	@OnlineSqlServerName	= [SERVER_INSTANCE_NAME]
		,	@OnlineSqlDataBaseName	= [DATABASE_NAME]
	from dbo.[TEST_AUTOMATION_DATASOURCES] [DS] with(nolock)
	where [DB_TYPE] = @DB_TYPE and [UNIQUE_ALIAS] = @DB_ALIAS
	;

	if IsNull(@OnlineSqlServerName,'') = '' or IsNull(@OnlineSqlServerName,'') = ''
	begin
		select	@Msg = N'Can find datasource for [DB_TYPE] ='+@DB_TYPE+' AND [UNIQUE_ALIAS] = '+@DB_ALIAS+' '
			,	@Sql = N' SELECT [SERVER_INSTANCE_NAME], [DATABASE_NAME] from dbo.[TEST_AUTOMATION_DATASOURCES] [DS] with(nolock)'
					+  N'	where [DB_TYPE] = '+@DB_TYPE+' and [UNIQUE_ALIAS] = '+@DB_ALIAS+' '
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return 1;
	end

	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = N'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, N'*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]'
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за първоначална инициализация */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
GO

drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS]
GO
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
(
	@DB_TYPE				sysname = N'BETA'
,	@TestAutomationType		sysname = N'%CashPaymentCA%BETA%'
,	@LogTraceInfo			int = 0
)
as 
begin
	select @LogTraceInfo = 1
	;

	declare @Sql varchar(max) = N'', @Msg nvarchar(max) = N'', @LogBegEndProc int = 1
		,	@AccountDate varchar(32) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N'', @TimeBeg datetime = GetDate()
	;

	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestAutomationType, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_INIT_DEALS]'
	;


	/************************************************************************************************************/
	/* 0.1. Get Datasources: */
	declare @OnlineSqlServerName sysname = N'',	@OnlineSqlDataBaseName sysname = N'', @DB_ALIAS sysname = N'VCS_OnlineDB'
	;

	exec @Ret = dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE] @DB_TYPE, @DB_ALIAS, @OnlineSqlServerName out, @OnlineSqlDataBaseName out
	if @Ret <> 0
	begin
		select  @Msg = N'Error execute proc, Error code: '+str(@Ret,len(@Ret),0)
					+' ; Result: @OnlineSqlServerName = "'+@OnlineSqlServerName+'", @OnlineSqlDataBaseName = "'+@OnlineSqlDataBaseName+'"'
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return -1;
	end

	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE], @OnlineSqlServerName: ' +@OnlineSqlServerName+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end
	
	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;

	/************************************************************************************************************/
	/* 0.2. Get Account Date: */
	declare @CurrAccDate datetime = 0
	;

	begin try
		exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate OUT
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnlineSqlServerName+N', '+@OnlineSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return -2
	end catch 

	select @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnlineSqlServerName+N', '+@OnlineSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 1.1. Prepare BASE conditions */
	drop table if exists #TBL_WITH_FILTERS
	;

	select	[PREV].ROW_ID							AS [PREV_ROW_ID]
		,	[PREV].PROXY_ROW_ID						AS [PREV_PROXY_ROW_ID]
		,	[PREV].TA_TYPE							AS [PREV_TA_TYPE]

		,	[CUST].[SECTOR]							AS [CUST_CND_SECTOR]
		,	[DREG].[UI_STD_DOG_CODE]				AS [DEAL_CND_UI_STD_DOG_CODE]
		,	[DREG].[UI_CURRENCY_CODE]				AS [DEAL_CND_UI_CURRENCY_CODE]
		,	[DREG].[UI_INDIVIDUAL_DEAL]				AS [UI_INDIVIDUAL_DEAL]

	into #TBL_WITH_FILTERS
	from dbo.[PREV_COMMON_TA] [PREV] with(nolock)
	inner join dbo.[RAZPREG_TA] [DREG] with(nolock)
		on [PREV].REF_ID = [DREG].ROW_ID
	left join dbo.[DEALS_CORR_TA] [CORS] with(nolock)
		on [CORS].REF_ID = [DREG].ROW_ID
	inner join dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] with(nolock)
		on [DREG].REF_ID = [CUST].ROW_ID
	left join dbo.[PROXY_SPEC_TA] as [PSPEC] with(nolock)
		on [CUST].ROW_ID =[PSPEC].REF_ID
	where [PREV].[TA_TYPE] LIKE @TestAutomationType
	order by [PREV].ROW_ID
	;

	select @Rows = @@ROWCOUNT, @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin
		select @Msg = N'After: INSERT into [#TBL_WITH_FILTERS], Rows Affected: '+ str(@Rows,len(@Rows),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestAutomationType, @Msg
	end
	;

	/* 1.2. Prepare deals  */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS]
	;

	set @Sql1 = N'
	declare @DealType int = 1
		,	@DateAcc date = '+@AccountDate+'
	;

	declare @StsDeleted						int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@StsCloased						int	= dbo.SETBIT(cast(0 as binary(4)),  9, 1)
		,	@StsHasIndividualSpecCondPkgs	int = dbo.SETBIT(cast(0 as binary(4)),  5, 1)	/* STS_INDIVIDUAL_SPEC_COND_PKGS (5) */
		,	@StsExcludeFromBankCollection   int = dbo.SETBIT(cast(0 as binary(4)),  8, 1)	/* STS_EXCLUDE_FROM_BANK_COLLECTIONS (8) */
		,	@StsHasOtherTaxAcc				int	= dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* CMN_OTHER_ACCOUNT_FOR_TAX (14) */
		,	@StsIsIndividual				int	= dbo.SETBIT(cast(0 as binary(4)), 16, 1)	/* SD_INDIVIDUAL_DEAL (16) */
		,	@StsNoAutoPayTax				int	= dbo.SETBIT(cast(0 as binary(4)), 29, 1)	/* CMN_NOAUTOTAX (29) */
	;

	declare @StsExtJointDeal				int = dbo.SETBIT(cast(0 as binary(4)),  4, 1)	/* STS_EXT_JOINT_DEAL (4) */
		,	@StsExtCapitOnBaseDateOpen		int = dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* STS_EXT_CAPIT_ON_BASE_DATE_OPEN (14) */
		,	@StsExtDenyManualTaxAssign		int = dbo.SETBIT(cast(0 as binary(4)), 20, 1)	/* STS_EXT_DENY_MANUAL_TAX_ASSIGN (20)*/
			/* [BLOCKSUM] */
	;
	WITH [X] AS 
	(
		select	[CUST_CND_SECTOR]
			,	[DEAL_CND_UI_CURRENCY_CODE]
			,	count(*) AS CNT
		from #TBL_WITH_FILTERS with(nolock)
		group by [CUST_CND_SECTOR], [DEAL_CND_UI_CURRENCY_CODE]
	)';
	set @Sql2 = N'
	select	/* Deal info: */
			IDENTITY( INT, 1, 1)					AS [ROW_ID]
		,	1										AS [DEAL_TYPE]
		,	[REG].[DEAL_NUM]						AS [DEAL_NUM]
		,	[EXT].[ACCOUNT]							AS [DEAL_ACCOUNT]
		,	[REG].[CURRENCY_CODE]					AS [DEAL_CURRENCY_CODE]
		,	[REG].[STD_DOG_CODE]					AS [DEAL_STD_DOG_CODE]
		,	[REG].[INT_COND_STDCONTRACT]			AS [INT_COND_STDCONTRACT]

		,	[REG].[NM245_CODE]						AS [DEAL_NM245_GROUP_PROGRAM_TYPE_CODE]
		,	[REG].[NM342_CODE]						AS [DEAL_NM342_BUNDLE_PRODUCT_CODE] 
		,	[REG].[JOINT_ACCESS_TO_FUNDS_TYPE]		AS [DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] /* enum JointDealsAccessToFundsType: 0 - Separate; 1 - Always Together */		

		,	[REG].[INT_SUM_DAY]						AS [ACCOUNT_BEG_DAY_BALANCE]		/* Begin day saldo  */
		,	[ACC].[BLK_SUMA_MIN]					AS [BLK_SUMA_MIN] /* Block amount for deal */

			/* Client info: */
		,	[REG].[KL_SECTOR]						AS [CLIENT_SECTOR]
		,	[REG].[CLIENT_CODE]						AS [CLIENT_CODE]
		,	[CLC].[CUSTOMER_ID]						AS [CUSTOMER_ID]

			/* Bits from [STATUS]: */
		,	[STS].[IS_ACTIVE_DEAL]					AS [DEAL_IS_ACTIVE_DEAL]
		,	[STS].[IS_INDIVIDUAL_COND_PKGS]			AS [DEAL_IS_INDIVIDUAL_COND_PKGS]
		,	[STS].[EXCLUDE_FROM_BANK_COLLECTIONS]	AS [DEAL_EXCLUDE_FROM_BANK_COLLECTIONS]
		,	[STS].[IS_INDIVIDUAL_DEAL]				AS [DEAL_IS_INDIVIDUAL_DEAL]
		,	[STS].[HAS_OTHER_TAX_ACC]				AS [DEAL_HAS_OTHER_TAX_ACC]
		,	[STS].[NO_AUTO_PAY_TAX]					AS [DEAL_NO_AUTO_PAY_TAX]

			/* Bits from [STATUS_EXT]: */
		,	[STS].[IS_JOINT_DEAL]					AS [DEAL_IS_JOINT_DEAL]
		,	[STS].[CAPIT_ON_BASE_DATE_OPEN]			AS [DEAL_CAPIT_ON_BASE_DATE_OPEN]
		,	[STS].[IS_DENY_MANUAL_TAX_ASSIGN]		AS [DEAL_IS_DENY_MANUAL_TAX_ASSIGN]

			/* Additional flags */
		,	[EXT].[IS_INDIVIDUAL_COMB]				AS [DEAL_IS_INDIVIDUAL_COMBINATION]

		,	[EX_BITS].*
		,	CAST( 0 AS SMALLINT )					AS [PROXY_COUNT]

	into dbo.[AGR_CASH_PAYMENTS_DEALS]
	from '+@SqlFullDBName+'.dbo.[RAZPREG] [REG] with(nolock) 

	inner join '+@SqlFullDBName+'.dbo.[DT015] [CLC] with(nolock)	
		on  [CLC].[CODE] = [REG].[CLIENT_CODE] 

	inner join '+@SqlFullDBName+'.dbo.[DT008] [CCY] with(nolock) 
		on  [CCY].[CODE] = [REG].[CURRENCY_CODE]

	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock) 
		on  [ACC].[PART_ID] = [REG].[ACCOUNT]

	inner join [X] 
		on  [X].[CUST_CND_SECTOR]			= [REG].[KL_SECTOR]
		and [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
	';
	set @Sql3 = N' 
	cross apply (
		select	CAST(@DealType AS TINYINT)				AS [DEAL_TYPE]
			,	CAST([REG].[ACCOUNT] AS VARCHAR(33))	AS [ACCOUNT]
				/* Additional flags: */
			,	CAST( [REG].INDIVIDUAL_COMBINATION_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_COMB]
			,	CAST( [REG].INDIVIDUAL_PROGRAM_GS_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_PROG]
	) [EXT]
	cross apply (
		select 	CAST( 0 AS bit ) 						AS [DEAL_IS_USED]
			,	CAST( 0 AS bit ) 						AS [HAS_TAX_UNCOLECTED]
			,	CAST( 0 AS bit ) 						AS [HAS_OTHER_TAX_ACCOUNT]
			,	CAST( 0 AS bit ) 						AS [HAS_LEGAL_REPRESENTATIVE]
			,	CAST( 0 AS bit ) 						AS [HAS_PROXY]
			,	CAST( 0 AS bit ) 						AS [HAS_DISTRAINT]
			,	CAST( 0 AS bit ) 						AS [HAS_GS_INDIVIDUAL_PROGRAMME]
			,	CAST( 0 AS bit ) 						AS [HAS_WNOS_BEL]
			,	CAST( 0 AS bit ) 						AS [IS_DORMUNT_ACCOUNT]
	) [EX_BITS]
	cross apply (
		select	/* Bits from [STATUS]: */
				CAST(CASE WHEN ([REG].[STATUS] & @StsCloased) <> @StsCloased THEN 1 ELSE 0 END AS BIT)
										AS [IS_ACTIVE_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasIndividualSpecCondPkgs) = @StsHasIndividualSpecCondPkgs THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_COND_PKGS]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsExcludeFromBankCollection) = @StsExcludeFromBankCollection THEN 1 ELSE 0 END AS BIT)
										AS [EXCLUDE_FROM_BANK_COLLECTIONS]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasOtherTaxAcc) = @StsHasOtherTaxAcc THEN 1 ELSE 0 END AS BIT)
										AS [HAS_OTHER_TAX_ACC]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsIsIndividual) = @StsIsIndividual THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsNoAutoPayTax) = @StsNoAutoPayTax THEN 1 ELSE 0 END AS BIT)
										AS [NO_AUTO_PAY_TAX]

				/* Bits from [STATUS_EXT]: */
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtJointDeal) = @StsExtJointDeal THEN 1 ELSE 0 END AS BIT)
										AS [IS_JOINT_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtCapitOnBaseDateOpen) = @StsExtCapitOnBaseDateOpen THEN 1 ELSE 0 END AS BIT)
										AS [CAPIT_ON_BASE_DATE_OPEN]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtDenyManualTaxAssign) = @StsExtDenyManualTaxAssign THEN 1 ELSE 0 END AS BIT)
										AS [IS_DENY_MANUAL_TAX_ASSIGN]
	) [STS]
	WHERE	([REG].[STATUS] & @StsDeleted) <> @StsDeleted
		and ([REG].[STATUS] & @StsCloased) <> @StsCloased'
	;

	begin try
		execute( @Sql1 + @Sql2 + @Sql3 );
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO(), @Sql = @Sql1 + @Sql2 + @Sql3;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return 1
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS], Rows affected: ' + str(@Rows,len(@Rows),0), @Sql = @Sql1 + @Sql2 + @Sql3
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end
	;

	/* 1.2.1 Add Indexes on dbo.[AGR_CASH_PAYMENTS_DEALS] */
	alter table dbo.[AGR_CASH_PAYMENTS_DEALS]
		add constraint [PK_AGR_CASH_PAYMENTS_DEALS] 
			primary key clustered ( [ROW_ID] )
	;

	create index IX_AGR_CASH_PAYMENTS_DEALS_DEAL_NUM_DEAL_TYPE
		on dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_NUM], [DEAL_TYPE] )
	;

	create index IX_AGR_CASH_PAYMENTS_DEALS_DEAL_ACCOUNT
		on dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_ACCOUNT] )
	;	

	/* 1.3. Prepare TAX UNCOLECTED  */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	;

	select @Sql1 = N';
	declare @DealType int = 1
		,	@TaxActive int = 0 /* enum eTaxUncollectedStatus: eTaxActive = 1*/
	;

	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	from DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	where EXISTS (
		select	*
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		WHERE	[T].[DEAL_TYPE]		= @DealType
			and [T].[DEAL_NUM]		= [REG].[DEAL_NUM]
			and [T].[TAX_STATUS]	= @TaxActive 
	)'
	;
	
	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.4. Prepare Deal with Other Tax Account */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	;

	select @Sql1 = N';
	declare @DealType int = 1
		,	@CorreCapitAccount int = 1 /* eCapitAccount (1) */
		,	@CorrTaxServices int = 3 /* eTaxServices (3) */

	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]
		,	[C].[CORR_ACCOUNT]
		,	[ACC].[PART_CURRENCY]
		,	[BAL].[ACCOUNT_BEG_DAY_BALANCE]
		,	[ACC].[BLK_SUMA_MIN]

	into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	from DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[DEALS_CORR] [C] with(nolock)
		on  [C].[CORR_TYPE]		= @CorrTaxServices
		and	[C].[DEAL_TYPE]		= @DealType
		and [C].[DEAL_NUMBER]	= [REG].[DEAL_NUM]
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		on  [ACC].[PART_ID]	= [C].[CORR_ACCOUNT]
	cross apply (
		select CASE WHEN [ACC].[PART_TYPE] IN ( 1, 2, 5 )
				THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
				ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [ACCOUNT_BEG_DAY_BALANCE]
	) [BAL]
	';

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.5. Prepare Deal with Group Sales INDIVIDUAL PROGRAMME */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
	;

	select @Sql1 = N';
	declare @DealType int = 1
		,	@GSActive int = 1 /* enum eGS_STATUS: GSActive = 1 */
	;
	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]	
		,	[GSI].[PROGRAMME_CODE]					AS [DEAL_GS_INDIVIDUAL_PROGRAM_CODE]
		,	[GSI].[PRODUCT_CODE]					AS [DEAL_GS_INDIVIDUAL_PRODUCT_CODE]
		,	[GSI].[CARDHOLDER_PREMIUM]				AS [DEAL_GS_INDIVIDUAL_CARDHOLDER_PREMIUM]

	into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
	from DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[GS_INDIVIDUAL_PROGRAMME] [GSI] with(nolock)
		on  [GSI].[DEAL_TYPE]		= @DealType
		and [GSI].[DEAL_NUMBER]		= [REG].[DEAL_NUM]
		and [GSI].[ACTIVITY_STATUS] = @GSActive
	';

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.6. Prepare Deal with WNOS BEL*/
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
	;

	select @Sql1 = N';
	declare @DealType 	int = 1
		,	@CurrDate	date = GetDate()
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@REG_VNOS_BEL_BIS6 int = 63 /* #define REG_VNOS_BEL_BIS6 63 */		
	;

	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	where EXISTS (
		select	*
		from '+@SqlFullDBName+'.dbo.[TRAITEMS_DAY] [T] with(nolock)
		WHERE	[T].[DEAL_NUM]	= [REG].[DEAL_NUM]
			and [T].[DEAL_TYPE] = @DealType
			and	[T].[SUM_OPER] > 0
			and [T].[SYS_DATE] >= @CurrDate
			and [T].[REG_CODE_DEF] = @REG_VNOS_BEL_BIS6
			and ([T].[STATUS] & @StsDeleted) <> @StsDeleted
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.7. Prepare Deal with Distraint */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT]
	;

	select @Sql1 = N';
	declare @StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1)	/* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	select	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 

	into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] 
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock) 
	where EXISTS ( 
		select TOP (1) *  
		from '+@SqlFullDBName+'.dbo.BLOCKSUM [B] with(nolock) 
		inner join '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock) 
			on  [N].[NOMID] = 136 
			and [N].[CODE]	= [B].[WHYFREEZED] 
			and ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint 
		WHERE	[B].[PARTIDA] = [REG].[DEAL_ACCOUNT] 
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.8. Prepare Deal with DORMUNT ACCOUNT */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT]
	;

	select @Sql1 = N';
	declare @DealType 	int = 1
		,	@StsPART_IsSleepy int = dbo.SETBIT(cast(0 as binary(4)), 22, 1)	/* #define PART_IsSleepy (22) // Партидата е спяща(замразена) */
	;

	select	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 

	into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] 
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock) 
	where EXISTS ( 
		select TOP (1) * 
		from '+@SqlFullDBName+'.dbo.[PARTS] [P] with(nolock) 
		WHERE	[P].[PART_ID] = [REG].[DEAL_ACCOUNT] 
			and ([P].[STATUS] & @StsPART_IsSleepy) = @StsPART_IsSleepy 		
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end	

	/* 1.9. Prepare Deals Legal representative */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
	;

	select @Sql1 = N';
	declare @DealType int = 1 /* Razp deals */
		,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;
	select	[D].[DEAL_TYPE]
		,	[D].[DEAL_NUM]
		,	[CRL].[REPRESENTED_CUSTOMER_ID] 
		,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
		,	[CRL].[CUSTOMER_ROLE_TYPE] 

	into dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] with(nolock) 
		on  [CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1									/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] in ( 1 )						/* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 						/* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	where ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated	/* STS_LIMIT_DEACTIVATED 12 (Деактивиран) */
	';

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 1.10. Prepare Deals Active Proxy Customers */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	;

	select @Sql1 = N'; 
	declare @DealType int = 1 /* Razp deals 1 */
	,	@DateAcc date = '+@AccountDate+'
	,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;
	select	[D].[DEAL_TYPE]
			,	[D].[DEAL_NUM]
			,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
			,	[CRL].[CUSTOMER_ROLE_TYPE]

	into dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] with(nolock) 
		on  [CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1					/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 )	/* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1		/* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	where  ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated 
	and exists
	(
		select * 
		from '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] with(nolock)
		inner join '+@SqlFullDBName+'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] with(nolock)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
		where	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
			and [PS].[CUSTOMER_ROLE_TYPE]		  = [CRL].[CUSTOMER_ROLE_TYPE] 
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] > @DateAcc )
	)'
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 2. Prepare Customers data */

	/* 2.1 Prepare all duplicate customers EGFN */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
	;	

	select @Sql1 = N';
	select  CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT) AS [EGFN]

	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] 
	from '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] WITH (NOLOCK)
	where ISNUMERIC( [C].[IDENTIFIER] ) = 1 
	group by CAST( RIGHT( RTRIM( [C].[IDENTIFIER] ), 13) AS BIGINT) 
	HAVING COUNT(*) > 1 '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 3
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]  Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 2.2 Prepare Customers data */	
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	;

	set @Sql1 = N'
	;
	WITH [CTE_CUST_ID] AS 
	(
		select [A].[CUSTOMER_ID]
		from 
		(
			select DISTINCT CUSTOMER_ID
			from dbo.AGR_CASH_PAYMENTS_DEALS with(nolock)	
			UNIon ALL 
			select DISTINCT REPRESENTATIVE_CUSTOMER_ID
			from dbo.AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS with(nolock)
		) [A]
		group by [CUSTOMER_ID]
	)
	select 	IDENTITY( INT, 1, 1) 					AS [ROW_ID] 
		,	[C].[CUSTOMER_ID]						AS [CUSTOMER_ID]
		,	[M].[CL_CODE]							AS [CLIENT_CODE_MAIN]
		,	RTRIM([C].[IDENTIFIER])					AS [CLIENT_IDENTIFIER]
		,	[C].[IDENTIFIER_TYPE]					AS [CLIENT_IDENTIFIER_TYPE]
		,	[C].[ECONOMIC_SECTOR]					AS [CLIENT_SECTOR]		
		,	[C].[CLIENT_TYPE]						AS [CLIENT_TYPE_DT300_CODE]
		,	[C].[BIRTH_DATE]						AS [CLIENT_BIRTH_DATE]
		,	[TYP].[CUSTOMER_CHARACTERISTIC]			AS [CUSTOMER_CHARACTERISTIC]
		,	[TYP].[IS_FUNCTIONAL_ID]				AS [IS_FUNCTIONAL_ID]
		,	[TYP].[IS_PHISICAL_PERSON]				AS [IS_PHISICAL_PERSON]
		,	[EX_BITS].*
	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	from [CTE_CUST_ID] [F] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] with(nolock)
		on  [F].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	inner join '+@SqlFullDBName+'.dbo.[DT015_MAINCODE_CUSTID] [M] with(nolock)
		on  [M].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	cross apply (
		select	CAST( CASE WHEN [C].[IDENTIFIER_TYPE] IN (5,6,7,8) THEN 1 ELSE 0 END AS BIT)
												AS [IS_FUNCTIONAL_ID]
			,	CAST( CASE WHEN [C].[CUSTOMER_TYPE] = 1 THEN 1 ELSE 0 END AS BIT)  
												AS [IS_PHISICAL_PERSON]
			,	CAST( [C].[CUSTOMER_CHARACTERISTIC] as TINYINT )
												AS [CUSTOMER_CHARACTERISTIC]
	) [TYP] 
	cross apply (
		select	CAST ( 0 AS BIT )				AS [HAS_MANY_CLIENT_CODES]
			,	CAST ( 0 AS BIT )				AS [HAS_DUBL_CLIENT_IDS]
			,	CAST ( 0 AS BIT )				AS [IS_PROXY]
			,	CAST ( 0 AS BIT )				AS [HAS_LOAN]
			,	CAST ( 0 AS BIT )				AS [HAS_VALID_DOCUMENT]
			,	CAST ( 1 AS BIT )				AS [IS_ORIGINAL_EGFN]
			,	CAST ( 0 AS BIT )				AS [HAS_ZAPOR]
			,	CAST ( 0 AS BIT )				AS [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC]			
	) [EX_BITS]
	'
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.2.1 Create Indexes on [AGR_CASH_PAYMENTS_CUSTOMERS] */
	create index IX_AGR_CASH_PAYMENTS_CUSTOMERS_CUSTOMER_ID
		on dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] ( [CUSTOMER_ID] )
	;	

	/* 2.3 Prepare Customers with many client codes  */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	;

	select @Sql1 = N';
	select	[CUST].[CUSTOMER_ID]

	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] with(nolock)
	where EXISTS 
	(
		select [CC].[CUSTOMER_ID] 
		from '+@SqlFullDBName+'.dbo.[DT015] [CC] with(nolock)
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
		group by [CC].[CUSTOMER_ID] 
		HAVING COUNT(*) > 1
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.4 Prepare Customers with Dubl EGFN  */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	;

	select @Sql1 = N';
	select	[C].[CUSTOMER_ID]
		,	[X].[IS_ORIGINAL_EGFN]

	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] with(nolock)
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] [DUBL] with(nolock)
		on [DUBL].[EGFN] = CAST(RIGHT(RTRIM([C].[CLIENT_IDENTIFIER]), 13) AS BIGINT)
	cross apply (
		select CAST( CASE WHEN [DUBL].[EGFN] = CAST( [C].[CLIENT_IDENTIFIER] AS BIGINT )
					THEN 1 ELSE 0 END AS BIT)	AS [IS_ORIGINAL_EGFN]
	) [X]'
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.5 Prepare Customers are proxies */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	;

	select @Sql1 = N';
	select	[C].[CUSTOMER_ID]

	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] with(nolock)
	where EXISTS 
	(
		select *
		from '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] with(nolock)
		WHERE	[PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
			and [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
			and [PS].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 )  /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.6 Prepare Customers with valid IDENTITY DOCUMENTS */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	;

	set @Sql1 = N'
	declare @DateAcc date = '+@AccountDate+'
	;

	select	[C].[CUSTOMER_ID]

	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] with(nolock)
	where EXISTS 
	(
		select *
		from '+@SqlFullDBName+'.dbo.[DT015_IDENTITY_DOCUMENTS] [D] with(nolock)
		WHERE	[D].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
			and [D].[NM405_DOCUMENT_TYPE] IN ( 1, 7, 8  )  /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
			and ( [D].[INDEFINITELY] = 1 OR [D].[EXPIRY_DATE] > @DateAcc )
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.7 Prepare Customers with Active Loas */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	;

	select @Sql1 = N';
	select	[CUST].[CUSTOMER_ID]

	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] with(nolock)
	where EXISTS 
	(
		select *
		from '+@SqlFullDBName+'.dbo.[KRDREG] [L] with(nolock)
		inner join '+@SqlFullDBName+'.dbo.[DT015] [CC] with(nolock)
			on [L].[CLIENT_CODE] =  [CC].[CODE]
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [L].[DATE_END_KREDIT] < 2 /* Is active loan */
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 2.8 Prepare Customers with Distraint */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT]
	;
	
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] ( [CUSTOMER_ID] )
	exec @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName, @OnlineSqlDataBaseName

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 2.9 Prepare Customers with Uncollected tax connected to all customer accounts */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
	;
	
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] ( [CUSTOMER_ID] )
	exec @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName, @OnlineSqlDataBaseName

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 3. update customers: */
	update [D]
	set [HAS_MANY_CLIENT_CODES] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D] 
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] [S] with(nolock)
		on [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	update [D]
	set [HAS_DUBL_CLIENT_IDS] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		on [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	update [D]
	set [HAS_LOAN] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] [S] with(nolock)
		on [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [IS_PROXY] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] [S] with(nolock)
		on [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [HAS_VALID_DOCUMENT] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] [S] with(nolock)
		on [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [IS_ORIGINAL_EGFN] = 0
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		on  [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
		and [S].[IS_ORIGINAL_EGFN] = 0
	;

	update [D]
	set [HAS_ZAPOR] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] [S] with(nolock)
		on  [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] [S] with(nolock)
		on  [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: update bist in [AGR_CASH_PAYMENTS_CUSTOMERS]', @Sql1 = ' update [AGR_CASH_PAYMENTS_CUSTOMERS] set ...' 
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 5. update deals: */
	update [D]
	set [HAS_TAX_UNCOLECTED] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_OTHER_TAX_ACCOUNT] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_LEGAL_REPRESENTATIVE] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_PROXY] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_DISTRAINT] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_GS_INDIVIDUAL_PROGRAMME] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_WNOS_BEL] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [IS_DORMUNT_ACCOUNT] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [PROXY_COUNT] = [S].[CNT]
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join 
	(
		select [P].[DEAL_NUM], COUNT(*) AS [CNT]
		from dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [P] with(nolock)
		where [P].[DEAL_TYPE] = 1
		group by [P].[DEAL_NUM]
	) [S]
		on  [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [D].[DEAL_TYPE] = 1
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: update bist in [AGR_CASH_PAYMENTS_DEALS]', @Sql1 = N' update [AGR_CASH_PAYMENTS_DEALS] set [HAS_VALID_DOCUMENT] = 1 where ...'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 6. Log end procedure: */
	if @LogBegEndProc = 1
	begin
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', AccData: ' + @AccountDate + ', Fileter: ' + @TestAutomationType;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_INIT_DEALS]'
	end

	return 0;
end
go


/********************************************************************************************************/
/* Процедура за зареждане на Клиентски данни от OnLineDB по CustomerID */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_CLIENT_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_CLIENT_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@CurrentAccountDate		datetime
,	@CUSTOMER_ID			int
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @CUSTOMER_ID = ' + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CLIENT_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;
	/************************************************************************************************************/
	/* 3. Load Deals data from OlineDB */
	declare @AccountData varchar(16) = ''''+ convert( varchar(16), @CurrentAccountDate, 23)+ '''';

	select @Sql1 = N'
	Declare @StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	select top (1)  
			[CUST].[CUSTOMER_ID]
		,	[CUST].[IDENTIFIER]				AS [UI_EGFN]
		,	[CUST].[CUSTOMER_NAME]			AS [CUSTOMER_NAME]
		,	[CUST].[COMPANY_EFN]			AS [COMPANY_EFN]	
		,	[MCLC].[CL_CODE]				AS [MAIN_CLIENT_CODE]
		,	[NOTE].[HAS_POPUP_NOTE]			AS [UI_NOTES_EXIST]
		,	[XF].[IS_ZAPOR]					AS [IS_ZAPOR]			/* [IS_ZAPOR] : (дали има съдебен запор някоя от сделките на клиента) */
		,	[DOC].[ID_NUMBER]				AS [ID_NUMBER]			/* [ID_NUMBER] Номера на: лична карта; паспорт; шофьорска книжка ... */
		,	[XF].[SERVICE_GROUP_EGFN]		AS [SERVICE_GROUP_EGFN]	/* TODO: [SERVICE_GROUP_EGFN]: */
		,	[XF].[IS_ACTUAL]				AS [IS_ACTUAL]			/* TODO: [IS_ACTUAL]: ?!?*/
		,	[PR].[PROXY_COUNT]				AS [PROXY_COUNT]
	from '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
	inner join '+@SqlFullDBName+'.dbo.[DT015_MAINCODE_CUSTID] [MCLC] WITH(NOLOCK)
		ON [MCLC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
	cross apply (
		select	0			AS [IS_ZAPOR]	
			,	''''		AS [SERVICE_GROUP_EGFN]
			,	0			AS [IS_ACTUAL]
	) [XF]
	outer apply (
		select top(1) count(distinct [CRL].[REPRESENTATIVE_CUSTOMER_ID]) AS [PROXY_COUNT]
		from '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK)
		inner join '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
			on	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
		inner join '+@SqlFullDBName+'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH(NOLOCK)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] >= '+@AccountData+')
		where [CRL].[REPRESENTED_CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [CRL].[CHANNEL] = 1	
	) [PR]
	outer apply (																					
		select top (1) cast( 1 as bit) as [HAS_POPUP_NOTE]
		from '+@SqlFullDBName+'.dbo.[DT015_NOTES] [n] with(nolock)
		where	[n].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [n].[CLIENT_NOTETYPE] = 1 /* enum ClientNoteType : ClientNoteTypeExtraData = 1 */
			and DATALENGTH([n].[NOTE]) > 1 /* Да има поне един символ освен нулевия терминатор */
	) [NOTE]
	outer apply (
		select top(1) [NM405_DOCUMENT_TYPE]	as [DOCUMENT_TYPE]
			,	[DOCUMENT_NUMBER]			as [ID_NUMBER]
			,	[ISSUER_COUNTRY_CODE]		as [ISSUER_COUNTRY_CODE]
		from '+@SqlFullDBName+'.dbo.[DT015_IDENTITY_DOCUMENTS] [d] with(nolock)
		where [d].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [d].[NM405_DOCUMENT_TYPE] IN (1, 7, 8) /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
		order by [d].[NM405_DOCUMENT_TYPE]
	) [DOC]
	where [CUST].[CUSTOMER_ID] = ' + str(@CUSTOMER_ID,len(@CUSTOMER_ID),0)
	;

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Customer Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @CUSTOMER_ID = ' + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CLIENT_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', CUSTOMER_ID: ' +  + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура за зареждане на Данни за сделка от OnLineDB по номер */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@DEAL_TYPE INT
,	@DEAL_NUM INT
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;
	/************************************************************************************************************/
	/* 3. Load Deals data from OlineDB */

	select @Sql1 = N'
	DECLARE @DealType int = 1 
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	select	[REG].[DEAL_NUM]
		,	[REG].[ACCOUNT]
		,	[REG].[CURRENCY_CODE]	as [ACCOUNT_CURRENCY]
		,	[II].[IBAN]
		,	[BAL].[BEG_SAL]
		,	[BAL].[DAY_MOVE]
		,	[ACC].[BLK_SUMA_MIN]
		,	[BAL].[RAZPOL]
		,	[BAL].[TAX_UNCOLLECTED_SUM]
		,	[BAL].[DISTRAINT_SUM]
		,	[BAL].[HAS_TAX_UNCOLLECTED]

	from '+@SqlFullDBName+'.dbo.[RAZPREG] [REG] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[IBAN_IDENT] [II] with(nolock)
		ON	[II].[ID] = [REG].[ACCOUNT]
		AND [II].[IBAN_TYPE] = 0 /* 0 - eIban_Real*/
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		ON [REG].[ACCOUNT] = [ACC].[PART_ID]
	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		ON [DM].[IDENT] = [REG].[ACCOUNT]
	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
		ON [FM].[IDENT] = [REG].[ACCOUNT]
	cross apply (
		SELECT	CASE WHEN [ACC].[PART_TYPE] IN (1,2,5)
					THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [BEG_SAL]

			,	CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
					THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
							-	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
								+ IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
							-	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
								+ IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
				END AS [DAY_MOVE]
	) [XBAL]
	outer apply 
	(
		select top (1) cast(1 as bit) as [HAS_TAX_UNCOLLECTED]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = [REG].[ACCOUNT]
			and [T].[TAX_STATUS] =  0
	) [TAX]
	outer apply (
		SELECT SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
		FROM '+@SqlFullDBName+'.dbo.[BLOCKSUM] [B] with(nolock)
		INNER JOIN '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock)
			ON	[N].[NOMID] = 136 
			AND [N].[CODE]	= [B].[WHYFREEZED] 
			AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
		WHERE [B].[PARTIDA] = [REG].[ACCOUNT] AND [B].[CLOSED_FROZEN_SUM] = 0
	) [DST]
	cross apply (
		SELECT	ROUND([XBAL].[BEG_SAL], 4)						as [BEG_SAL]
			,	ROUND([XBAL].[DAY_MOVE], 4)						as [DAY_MOVE]
			,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [RAZPOL]
			,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4)		as [DISTRAINT_SUM]
			,	cast(0 as float) 								as [TAX_UNCOLLECTED_SUM]
			,	IsNull([TAX].[HAS_TAX_UNCOLLECTED], 0)			as [HAS_TAX_UNCOLLECTED]
	) [BAL]
	where [REG].[DEAL_NUM] = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select	@Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@DEAL_NUM				int
,	@CORS_ACCOUNT_TYPE		int
,	@CORS_ACCOUNT			varchar(33)
)
AS 
BEGIN

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
					+', @CORS_ACCOUNT_TYPE = '+str(@CORS_ACCOUNT_TYPE,len(@CORS_ACCOUNT_TYPE),0)
					+', @CORS_ACCOUNT = '''+@CORS_ACCOUNT+''''
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;
	/************************************************************************************************************/
	/* 3. Load Deal Corrs data from OlineDB */
	;
	select @Sql1 = N'
	DECLARE @DealType int = 1 
		,	@CorrAccType int = '+str(@CORS_ACCOUNT_TYPE, len(@CORS_ACCOUNT_TYPE),0)+'
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	select	[CORR].[DEAL_TYPE]			AS [DEAL_TYPE]
		,	[CORR].[DEAL_NUMBER]		AS [DEAL_NUMBER]
		,	[CORR].[CORR_TYPE]			AS [CORR_TYPE]		
		,	[ACC].[DEAL_TYPE]			AS [CORR_DEAL_TYPE]
		,	[ACC].[DEAL_NUMBER]			AS [CORR_DEAL_NUMBER]
		,	[CORR].[CORR_ACCOUNT]		AS [CORR_ACCOUNT]
		,	[CCY].[INI]					AS [CORR_ACCOUNT_CCY]
		,	[ACC].[PART_CURRENCY]		AS [CORR_ACC_CCY_CODE]
		,	[ACC].[BLK_SUMA_MIN]		AS [BLK_SUMA_MIN]
		,	[BAL].[AVAILABLE_BAL]		AS [AVAILABLE_BAL]
		,	[BAL].[TAX_UNCOLLECTED_SUM]	AS [TAX_UNCOLLECTED_SUM]
		,	[BAL].[HAS_TAX_UNCOLLECTED]	AS [HAS_TAX_UNCOLLECTED]

	from '+@SqlFullDBName+'.dbo.[DEALS_CORR] [CORR] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC]
		on [ACC].[PART_ID] = [CORR].[CORR_ACCOUNT]
	inner join '+@SqlFullDBName+'.dbo.[DT008] [CCY] with(nolock)
		on	[CCY].[CODE] = [ACC].[PART_CURRENCY]
	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		on [DM].[IDENT] = [CORR].[CORR_ACCOUNT]
	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
		on [FM].[IDENT] = [CORR].[CORR_ACCOUNT]
	cross apply (
		select	CASE WHEN [ACC].[PART_TYPE] IN (1,2,5)
					THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [BEG_SAL]

			,	CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
					THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
							-	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
								+ IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
							-	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
								+ IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
				END AS [DAY_MOVE]
	) [XBAL]
	outer apply 
	(
		select top (1) cast(1 as bit) as [HAS_TAX_UNCOLLECTED]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = [CORR].[CORR_ACCOUNT]
			and [T].[TAX_STATUS] =  0
	) [TAX]
	outer apply (
		select SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
		from '+@SqlFullDBName+'.dbo.[BLOCKSUM] [B] with(nolock)
		inner join '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock)
			on	[N].[NOMID] = 136 
			and [N].[CODE]	= [B].[WHYFREEZED] 
			and([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
		where [B].[PARTIDA] = [CORR].[CORR_ACCOUNT] AND [B].[CLOSED_FROZEN_SUM] = 0
	) [DST]
	cross apply (
		select	ROUND([XBAL].[BEG_SAL], 4)					as [BEG_SAL]
			,	ROUND([XBAL].[DAY_MOVE], 4)					as [DAY_MOVE]
			,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [AVAILABLE_BAL]
			,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4)	as [DISTRAINT_SUM]
			,	ROUND(cast(0 as float), 4)					as [TAX_UNCOLLECTED_SUM]
			,	IsNull([TAX].[HAS_TAX_UNCOLLECTED], 0)		as [HAS_TAX_UNCOLLECTED]
	) [BAL]
	where [CORR].[DEAL_TYPE]		= @DealType
		and [CORR].[DEAL_NUMBER]	= '+str(@DEAL_NUM,len(@DEAL_NUM), 0)+'
		and [CORR].[CORR_TYPE]		= @CorrAccType
		and [CORR].[CORR_ACCOUNT]	= '''+@CORS_ACCOUNT+'''
	';

	if @LogTraceInfo = 1 select @Sql1 as [LOAD_ONLINE_CORS_INFO];

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Cors Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
					+', @CORS_ACCOUNT_TYPE = '+str(@CORS_ACCOUNT_TYPE,len(@CORS_ACCOUNT_TYPE),0)
					+', @CORS_ACCOUNT = '''+@CORS_ACCOUNT+''''
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за зачистване наданните от TA Таблиците */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]
(
	@TestCaseRowID NVARCHAR(16)
)
as 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql1 nvarchar(4000) = N'',	@TA_RowID int = cast ( @TestCaseRowID as int )
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]'


	/************************************************************************************************************/
	-- 2. Get  TA Table Row IDs:
	declare @RAZPREG_TA_RowID int = 0
		,	@DEALS_CORR_TA_RowID int = 0
		,	@DT015_CUSTOMERS_RowID int = 0
		,	@PROXY_CUSTOMERS_RowID int = 0
	;
	select	@RAZPREG_TA_RowID		= [DEAL_ROW_ID]
		,	@DEALS_CORR_TA_RowID	= [CORS_ROW_ID]
		,	@DT015_CUSTOMERS_RowID	= [CUST_ROW_ID]
		,	@PROXY_CUSTOMERS_RowID	= [PROXY_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@RAZPREG_TA_RowID,0) <= 0
	begin  
		select @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 1;
	end
	
	if IsNull(@DT015_CUSTOMERS_RowID,0) <= 0
	begin  
		select @Msg = 'Not found customer from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 2;
	end 

	begin try

		-- Актуализация данните за кореспондиращата сметка
		if IsNull(@DEALS_CORR_TA_RowID,0) > 0
		begin

			UPDATE [D]
			SET		[DEAL_NUM]				= 0		-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
/*				,	[CURRENCY]				= '' 	-- DEALS_CORR_TA	CURRENCY	*/
				,	[UI_CORR_ACCOUNT]		= ''	-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
				,	[TAX_UNCOLLECTED_SUM]	= 0		-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 
			from dbo.[DEALS_CORR_TA] [D]
			where [D].[ROW_ID] = @DEALS_CORR_TA_RowID
			;
		end

		-- Актуализация данните на пълномощника
		if IsNull(@PROXY_CUSTOMERS_RowID,0) > 0
		begin

			UPDATE [D]
			SET		[UI_CUSTOMER_ID]		= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				,	[UI_EGFN]				= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				,	[NAME]					= ''		-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				,	[COMPANY_EFN]			= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				,	[UI_CLIENT_CODE]		= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				,	[UI_NOTES_EXIST]		= 0			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				,	[IS_ZAPOR]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				,	[ID_NUMBER]				= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				,	[SERVICE_GROUP_EGFN]	= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				,	[IS_ACTUAL]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1; 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				,	[PROXY_COUNT]			= 0			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			where [D].[ROW_ID] = @PROXY_CUSTOMERS_RowID
			;
		end

		-- Актуализация данните на сделката
		UPDATE [D]
		SET		[UI_DEAL_NUM]			= 0		-- RAZPREG_TA	UI_DEAL_NUM	
			,	[DB_ACCOUNT]			= ''	-- RAZPREG_TA	DB_ACCOUNT	
			,	[UI_ACCOUNT]			= ''	/* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
			,	[ZAPOR_SUM]				= ''	-- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
			,	[IBAN]					= ''	-- RAZPREG_TA	IBAN	
			,	[TAX_UNCOLLECTED_SUM]	= ''	-- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
		FROM dbo.[RAZPREG_TA] [D]
		WHERE [D].[ROW_ID] = @RAZPREG_TA_RowID
		;

		-- Актуализация данните на клиента
		UPDATE [D]
		SET		[UI_CUSTOMER_ID]		= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
			,	[UI_EGFN]				= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
			,	[NAME]					= ''		-- DT015_CUSTOMERS_ACTIONS_TA	NAME
			,	[COMPANY_EFN]			= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
			,	[UI_CLIENT_CODE]		= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
			,	[UI_NOTES_EXIST]		= 0			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
			,	[IS_ZAPOR]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
			,	[ID_NUMBER]				= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
			,	[SERVICE_GROUP_EGFN]	= '0'		-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
			,	[IS_ACTUAL]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1; 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
			,	[PROXY_COUNT]			= 0			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
		from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
		where [D].[ROW_ID] = @DT015_CUSTOMERS_RowID
		;

	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 3
	end catch 

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]'
	end
	;

	return 0;
end 
go


/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[DEALS_CORR_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@CUSTOMER_ID			int
,	@PROXY_ID				int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogResultTable int = 0, @LogBegEndProc int = 1, @TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql2 nvarchar(4000) = N'',	@TA_RowID int = cast( @TestCaseRowID as int)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]'
	;

	/************************************************************************************************************/
	/* Find Test Case row and Corr Account */
	declare @TBL_ROW_ID int = 0, @DealRowID int = 0
		,	@CorrAccount varchar(64) = N'', @CorrAccType int = 3
	;

	select	@DealRowID = [DEAL_ROW_ID]
		,	@TBL_ROW_ID = [CORS_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found correspondence from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	select	@CorrAccount = [CORR_ACCOUNT]
	from [dbo].[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [C] with(nolock)
	where [DEAL_TYPE] = 1 AND [DEAL_NUM] = @DEAL_NUM
	;	

	if IsNull(@CorrAccount,'') = ''
	begin  
		select @Msg = 'Not found correspondence account TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 1;
	end 

	/************************************************************************************************************/
	-- Load data from OnlinDB: 
	drop table if exists dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
	(	[DEAL_TYPE]			int
	,	[DEAL_NUM]			int	
	,	[CORR_TYPE]			int	
	,	[CORR_DEAL_TYPE]	int
	,	[CORR_DEAL_NUM]		int
	,	[CORR_ACCOUNT]		varchar(64)
	,	[CORR_ACCOUNT_CCY]	varchar(8)
	,	[CORR_ACC_CCY_CODE]	int
	,	[BLK_SUMA_MIN]		float	
	,	[AVAILABLE_BAL]		float	
	,	[TAX_UNCOLLECTED]	float
	,	[HAS_TAX_UNCOLLECTED] int
	);	

	begin try
		insert into dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @DEAL_NUM, @CorrAccType, @CorrAccount
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
								+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
								+ ', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
								+ ', @CORS_ACCOUNT_TYPE = '+str(@CorrAccType,len(@CorrAccType),0)
								+ ', @CORS_ACCOUNT = '''+@CorrAccount+''''
			;

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 2
	end catch

	if @Ret <> 0
		return 3;

	/************************************************************************************************************/
	-- Load tax uncollected amount from OnlinDB:
	declare @Account varchar(64) = N'', @AccCurrency int = 100, @HasTaxUncollected int = 0
	;
	
	select top (1) @Account = [CORR_ACCOUNT], @AccCurrency = [CORR_ACC_CCY_CODE], @HasTaxUncollected = [HAS_TAX_UNCOLLECTED]
	from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] with(nolock)
	;

	if IsNull(@HasTaxUncollected,0) = 1 and IsNull(@Account,'') <> ''
	begin

		drop table if exists dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		;

		create table dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		(	[ACCOUNT]			varchar(64)
		,	[TAX_UNCOLLECTED]	float
		,	[CNT_ITEMS]			int	
		);

		begin try
			insert into dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
			exec @Ret = dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName, @OnlineSqlDataBaseName, @Account, @AccCurrency
		end try
		begin catch
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
									+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
									+ ', @Account = '+@Account
									+ ', @@AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
				;

				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 4
		end catch

		if exists ( select * from dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] with(nolock))
		begin

			update [D]
			set [TAX_UNCOLLECTED] = [s].[TAX_UNCOLLECTED]
			from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] [D]
			inner join dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] [S] with(nolock)
				on	[S].[CORR_ACCOUNT] = [D].[ACCOUNT]
				and [d].[CORR_ACC_CCY_CODE] = @AccCurrency

		end

	end

	/************************************************************************************************************/
	-- UPDATE [DEALS_CORS_TA] 
	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] with(nolock)
	;

	/* Update data in table [DEALS_CORR_TA] */
	if @WithUpdate = 1
	begin
		UPDATE [D]
		SET [DEAL_NUM]				= [S].[CORR_DEAL_NUM]		-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
		,	[CURRENCY]				= [S].[CORR_ACCOUNT_CCY]	-- DEALS_CORR_TA	CURRENCY	
		,	[UI_CORR_ACCOUNT]		= [S].[CORR_ACCOUNT]		-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
		,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]		-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 

		from dbo.[DEALS_CORR_TA] [D]
		inner join dbo.[#TBL_ONLINE_DEALS_CORR_INFO] [S] with(nolock)
			on	[S].[DEAL_TYPE] 	= 1
			and [S].[DEAL_NUM]		= @DEAL_NUM
			and [S].[CORR_TYPE]		= @CorrAccType
			and [S].[CORR_ACCOUNT]	= @CorrAccount
		where [D].[ROW_ID] = @TBL_ROW_ID
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[DEALS_CORR_TA], Rows affected: '+ str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0) 
			,	@Sql2 = 'UPDATE dbo.[DEALS_CORR_TA] [D] SET [UI_CUSTOMER_ID] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]'
	end

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@CurrAccountDate		datetime
,	@TestCaseRowID			nvarchar(16)
,	@OnlineDbCustomer_ID	int
,	@IsProxy				tinyint = 0
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0, @LogResultTable int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		, @Sql2 nvarchar(4000) = N'', @TA_RowID int = cast ( @TestCaseRowID as int )
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA]'
	;

	/************************************************************************************************************/
	-- 	Get TA Customer Row ID:
	declare @TBL_ROW_ID			int = 0	
	;
	select	@TBL_ROW_ID	= case when IsNull(@IsProxy,0) = 0 then [CUST_ROW_ID] else [PROXY_ROW_ID] end
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID
	;

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin 
		select @Msg = 'Not found Customer from TA ROW_ID : ' +@TestCaseRowID
		+'; @OnlineDbCustomer_ID ='+str(@OnlineDbCustomer_ID,len(@OnlineDbCustomer_ID),0)+'; @IsProxy = '+str(@IsProxy,1,0)+' ';
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
	end 

	/************************************************************************************************************/
	-- Update table dbo.[DT015_CUSTOMERS_ACTIONS_TA]: ...
	drop table if exists dbo.[#TBL_ONLINE_DT015_INFO]
	;

	create table dbo.[#TBL_ONLINE_DT015_INFO]
	(
		[CUSTOMR_ID]			int
	,	[UI_EGFN]				varchar(50)
	,	[NAME]					varchar(128)
	,	[COMPANY_EFN]			varchar(50)
	,	[UI_CLIENT_CODE]		varchar(32)
	,	[UI_NOTES_EXIST]		int
	,	[IS_ZAPOR]				int
	,	[ID_NUMBER]				varchar(50)
	,	[SERVICE_GROUP_EGFN]	varchar(50)
	,	[IS_ACTUAL]				int
	,	[PROXY_COUNT]			int
	)
	;

	begin try
		insert into dbo.[#TBL_ONLINE_DT015_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccountDate, @OnlineDbCustomer_ID
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
								+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
								+ ', @Customer_ID = '+str(@OnlineDbCustomer_ID,len(@OnlineDbCustomer_ID),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 2;
	end catch

	if @Ret <> 0 
		return 3;

	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DT015_INFO] with(nolock)
	;

	/* Тези данни ще ги заредим от вече 'кешираниет'  */
	declare @IS_ZAPOR int = 0,	@SERVICE_GROUP_EGFN varchar(16) = N''
	;
	/* Дали клиента има запори по някоя от сделките: */
	select top(1) @IS_ZAPOR = 1 
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] [D] with(nolock)
	where [D].[CUSTOMER_ID] = @OnlineDbCustomer_ID
	;

	/* За клиентите със служебни EGFN-та да заредим Оригиналното: */
	DECLARE @ClientIdentifier varchar(32) = N''
		,	@HasDublClientIDs int = 0
		,	@IsOrioginalID int = 0
	;
	select @ClientIdentifier	= [CLIENT_IDENTIFIER]	
		,	@HasDublClientIDs	= [HAS_DUBL_CLIENT_IDS]
		,	@IsOrioginalID		= [IS_ORIGINAL_EGFN]
	from  dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] with(nolock)
	where [CUST].[CUSTOMER_ID] = @OnlineDbCustomer_ID

	if @HasDublClientIDs = 1
	begin
		set @SERVICE_GROUP_EGFN = @ClientIdentifier;

		if @IsOrioginalID = 0
		begin
			select top(1) @SERVICE_GROUP_EGFN = [EGFN]
			from [AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] with(nolock)
			where [EGFN] = CAST(RIGHT(RTRIM(@ClientIdentifier), 13) as bigint)
		end
	end 

	/* Update data in [RAZPREG_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_CUSTOMER_ID]		= @OnlineDbCustomer_ID			 -- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
			,	[UI_EGFN]				= [S].[UI_EGFN]					 -- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
			,	[NAME]					= [S].[NAME]					 -- DT015_CUSTOMERS_ACTIONS_TA	NAME
			,	[COMPANY_EFN]			= [S].[COMPANY_EFN]				 -- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
			,	[UI_CLIENT_CODE]		= [S].[UI_CLIENT_CODE]			 -- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
			,	[UI_NOTES_EXIST]		= IsNull([S].[UI_NOTES_EXIST],0) -- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
			,	[IS_ZAPOR]				= @IS_ZAPOR						 -- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
			,	[ID_NUMBER]				= IsNull([S].[ID_NUMBER], '')	 -- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
			,	[SERVICE_GROUP_EGFN]	= @SERVICE_GROUP_EGFN			 -- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
			,	[IS_ACTUAL]				= [S].[IS_ACTUAL]				 -- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1; 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
			,	[PROXY_COUNT]			= IsNull([S].[PROXY_COUNT],0)	 -- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
		from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
		inner join dbo.[#TBL_ONLINE_DT015_INFO] [S] with(nolock)
			on [S].[CUSTOMR_ID] = @OnlineDbCustomer_ID
		where [D].[ROW_ID] = @TBL_ROW_ID
		;
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[DT015_CUSTOMERS_ACTIONS_TA], Rows affected: '+str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0)
			,	@Sql2 = 'UPDATE dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D] SET [UI_CUSTOMER_ID] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA]'
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]
(
	@@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@CUSTOMER_ID			int
,	@PROXY_ID				int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0, @LogResultTable int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql2 nvarchar(4000) = N''
		,	@TA_RowID int = cast ( @TestCaseRowID as int );
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]'
	;

	IF LEN(@@OnlineSqlServerName) > 1 AND LEFT(@@OnlineSqlServerName,1) <> N'['
		SELECT @@OnlineSqlServerName = QUOTENAME(@@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(@OnlineSqlDataBaseName,1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)		

	declare @SqlFullDBName sysname = @@OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;

	/************************************************************************************************************/
	-- Get TA Deal Row ID:
	declare @TBL_ROW_ID int = 0
	;
	select	@TBL_ROW_ID = [DEAL_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	/************************************************************************************************************/
	-- UPDATE [RAZPREG_TA]: 
	drop table if exists dbo.[#TBL_ONLINE_DEAL_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEAL_INFO]
	(
		[DEAL_NUM]			int
	,	[ACCOUNT]			varchar(64)
	,	[ACCOUNT_CURRENCY]	int
	,	[IBAN]				varchar(64)
	,	[BEG_SAL]			float
	,	[DAY_MOVE]			float
	,	[BLK_SUMA_MIN]		float
	,	[RAZPOL]			float
	,	[TAX_UNCOLLECTED]	float
	,	[DISTRAINT_SUM]		float
	,	[HAS_TAX_UNCOLLECTED] int
	);


	begin try
		insert into dbo.[#TBL_ONLINE_DEAL_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_DATA] @@OnlineSqlServerName, @OnlineSqlDataBaseName, @DEAL_TYPE, @DEAL_NUM
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()

			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_DATA] @@OnlineSqlServerName = '+@@OnlineSqlServerName+' '
								+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
								+ ', @DEAL_TYPE = 1, @DealNum = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg

			return 2
	end catch

	if @Ret <> 0
		return 3;

	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DEAL_INFO]  with(nolock)
	;

	/************************************************************************************************************/
	-- Load tax uncollected amount from OnlinDB:
	declare @Account varchar(64) = N'', @AccCurrency int = 100, @HasTaxUncollected int = 0
	;
	
	select top (1) @Account = [ACCOUNT], @AccCurrency = [ACCOUNT_CURRENCY], @HasTaxUncollected = [HAS_TAX_UNCOLLECTED]
	from dbo.[#TBL_ONLINE_DEAL_INFO] with(nolock)
	;

	if IsNull(@HasTaxUncollected,0) = 1 and IsNull(@Account,'') <> ''
	begin

		drop table if exists dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		;

		create table dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		(	[ACCOUNT]			varchar(64)
		,	[TAX_UNCOLLECTED]	float
		,	[CNT_ITEMS]			int	
		);

		begin try
			insert into dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
			exec @Ret = dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @@OnlineSqlServerName, @OnlineSqlDataBaseName, @Account, @AccCurrency
		end try
		begin catch
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @@OnlineSqlServerName = '+@@OnlineSqlServerName+' '
									+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
									+ ', @Account = '+@Account
									+ ', @@AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
				;

				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 4
		end catch

		if exists ( select * from dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] with(nolock))
		begin

			update [D]
			set [TAX_UNCOLLECTED] = [s].[TAX_UNCOLLECTED]
			from dbo.[#TBL_ONLINE_DEAL_INFO] [D]
			inner join dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] [S] with(nolock)
				on	[S].[ACCOUNT] = [D].[ACCOUNT]
				and [d].[ACCOUNT_CURRENCY] = @AccCurrency
		end

	end

	/********************************************************************************************************/
	/* Update data in [RAZPREG_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_DEAL_NUM]			= [S].[DEAL_NUM]				-- RAZPREG_TA	UI_DEAL_NUM	
			,	[DB_ACCOUNT]			= [S].[ACCOUNT]					-- RAZPREG_TA	DB_ACCOUNT	
			,	[UI_ACCOUNT]			= [xa].[ACC_WITH_SPACE]			/* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
			,	[ZAPOR_SUM]				= STR([S].[DISTRAINT_SUM],14,2)	-- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
			,	[IBAN]					= [S].[IBAN]					-- RAZPREG_TA	IBAN	
			,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]			-- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
		FROM dbo.[RAZPREG_TA] [D]
		INNER JOIN  dbo.[#TBL_ONLINE_DEAL_INFO] [S] WITH(NOLOCK)
			ON [S].[DEAL_NUM] = @DEAL_NUM
		cross apply (
			select case when left([S].[ACCOUNT], 2) = '17' 
				then left([S].[ACCOUNT],4)+' '+substring([S].[ACCOUNT],5,9)+' '+substring([S].[ACCOUNT],14,2)+' '+right(rtrim([S].[ACCOUNT]),1)
				else left([S].[ACCOUNT],4)+' '+substring([S].[ACCOUNT],5,3)+' '+substring([S].[ACCOUNT],8,9) +' '+substring([S].[ACCOUNT],17,2)+' '+right(rtrim([S].[ACCOUNT]),1)
				end AS  [ACC_WITH_SPACE]
		) [xa]
		WHERE [D].[ROW_ID] = @TBL_ROW_ID
		;
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[RAZPREG_TA], Rows affected: '+str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0) 
			,	@Sql2 = 'UPDATE dbo.[RAZPREG_TA] [D] SET [UI_DEAL_NUM] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]'
	end

	return 0;
end 
GO

/**********************************************************************************************************/
/* Процедура за актуализация данните в на Таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA] за титуляра и Proxy-то*/
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@CurrAccountDate		datetime
,	@TestCaseRowID			nvarchar(16)
,	@Customer_ID			int
,	@ProxyCustomer_ID		int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Sql2 nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Ret int = 0
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]'
	;

	/************************************************************************************************************/
	-- Check customer ID
	if IsNull(@Customer_ID,0) <= 0
	begin  
		select @Msg = N'Incorrect CustomerID : ' + IsNull(@Customer_ID,0) + N', TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return -1;
	end 

	/************************************************************************************************************/
	-- Актуализация на данните за титуляря и Proxy-то...
	-- Първо актуализираме данните на Proxy-то	
	if IsNull(@ProxyCustomer_ID,0) > 0
	begin
		begin try 
			select @Sql2 = N'dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName = '+@OnlineSqlServerName
						+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
						+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
						+', @TestCaseRowID = '+@TestCaseRowID
						+', @OnlineDbCustomer_ID = '+str(@ProxyCustomer_ID,len(@ProxyCustomer_ID),0)
						+', @IsProxy = 1,'
						+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)


			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName, @OnlineSqlDataBaseName
				, @CurrAccountDate, @TestCaseRowID, @ProxyCustomer_ID, 1, @WithUpdate;

			if @Ret <> 0
			begin 
				select @Msg = N'Error exec procedure dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA], error code:'+str(@Ret,len(@Ret),0)
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 1;
			end

		end try
		begin catch
				select @Msg = dbo.FN_GET_EXCEPTION_INFO() 
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 2;
		end catch
	end

	-- Aктуализираме данните на Титуляра
	begin try 
		select @Sql2 = N'dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName = '+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
					+', @TestCaseRowID = '+@TestCaseRowID
					+', @OnlineDbCustomer_ID = '+str(@Customer_ID,len(@Customer_ID),0)
					+', @IsProxy = 0,'
					+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)


		exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName, @OnlineSqlDataBaseName
			, @CurrAccountDate, @TestCaseRowID, @Customer_ID, 0, @WithUpdate;

		if @Ret <> 0
		begin 
			select @Msg = N'Error exec procedure dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA], error code:'+str(@Ret,len(@Ret),0)
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 3;
		end

	end try
	begin catch
			select @Msg = dbo.FN_GET_EXCEPTION_INFO() 
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 4;
	end catch

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: '+@TestCaseRowID
			 + ', @Customer_ID: '+str(@Customer_ID,len(@Customer_ID),0)
			 + ', @ProxyCustomer_ID: '+str(@ProxyCustomer_ID,len(@ProxyCustomer_ID),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]'
	end

	return 0;
end
go

/********************************************************************************************************/
/* Процедура формираща SQL заявката за търсене на подходяща сделка по ID на тестови случай */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]
(
	@TestCaseRowID nvarchar(16)
,	@CurrAccDate datetime
,	@SaveTAConditions tinyint = 0
)
AS 
begin

	declare @LogTraceInfo int = 1, @LogBegEndProc int = 1, @TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql nvarchar(max) = N'', @Sql2 nvarchar(4000) = N'', @CrLf nvarchar(4) = nchar(13) + nchar(10)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]'
	;

	/************************************************************************************************************/
	/* 1.0 Generate Sql for TA Conditions: */
	declare @DateAcc DATE = @CurrAccDate, @StrIntVal varchar(32) = ''
	;

	/* Client conditions [DT015_CUSTOMERS_ACTIONS_TA]: */
	declare @TA_TYPE					sysname = ''	
		,	@SECTOR						int = 0
		,	@UNIFIED					int = -1
		,	@IS_SERVICE					int = -1
		,	@CODE_EGFN_TYPE				int = -1
		,	@DB_CLIENT_TYPE_DT300		int = -1
		,	@VALID_ID					int = -1
		,	@CUSTOMER_CHARACTERISTIC	int = -1
		,	@CUSTOMER_AGE				sysname = '-1'
		,	@CUSTOMER_BIRTH_DATE_MIN	int = 18910101
		,	@CUSTOMER_BIRTH_DATE_MAX	int = 20220101
		,	@IS_PROXY					int = -1
		,	@IS_UNIQUE_CUSTOMER			int = -1
		,	@HAVE_CREDIT				int = -1
		,	@COLLECT_TAX_FROM_ALL_ACC 	int = -1
			/* [PROXY_SPEC_TA]: */
		,	@UI_RAZPOREDITEL			int = -1
		,	@UI_UNLIMITED				int = -1
	;
	/* Deal conditions [RAZPREG_TA]: */
	declare @UI_STD_DOG_CODE			int = 0
		,	@UI_INDIVIDUAL_DEAL			int = 0
		,	@INT_COND_STDCONTRACT		int = 0
		,	@CODE_UI_NM342				int = 0
		,	@CCY_CODE_DEAL				int = 0
		,	@UI_OTHER_ACCOUNT_FOR_TAX	int = 0
		,	@UI_NOAUTOTAX				sysname = '-1'
		,	@UI_DENY_MANUAL_TAX_ASSIGN	sysname = '-1'
		,	@UI_CAPIT_ON_BASE_DATE_OPEN sysname = '-1'
		,	@UI_BANK_RECEIVABLES		sysname = '-1'
		,	@UI_JOINT_TYPE				int = 0
		,	@LIMIT_AVAILABILITY			sysname = '0'
		,	@DEAL_STATUS				int = 0
		,	@LIMIT_TAX_UNCOLLECTED		int = 0
		,	@LIMIT_ZAPOR				int = 0
		,	@IS_CORR					int = 0
		,	@IS_UNIQUE_DEAL				int = 0
		,	@GS_PRODUCT_CODE			int = 0
		,	@CODE_GS_PROGRAMME			int = 0
		,	@CODE_GS_CARD				int = 0
	;
	declare @CCY_CODE_CORS				int = -1
		,	@LIMIT_AVAILABILITY_CORS	sysname = '-1'

		/* Conditions [PREV_COMMON_TA]: */
		,	@RUNNING_ORDER				int = -1
		,	@TYPE_ACTION				varchar(256)
		,	@TAX_CODE					int = -1
		,	@PREF_CODE					sysname = '-1'
		,	@DOC_SUM					float = 0.0
		,	@DOC_TAX_SUM				float = 0.0
	;

	drop table if EXISTS dbo.[#TBL_SQL_CONDITIONS]
	;
	create table dbo.[#TBL_SQL_CONDITIONS]
	(
		[ID] INT IDENTITY(1,1)
	,	[SQL_COND] nvarchar(1000)
	,	[DESCR] nvarchar(2000)
	,	[IS_BASE_SELECT] BIT DEFAULT(0)
	,	[IS_SELECT_COUNT] BIT DEFAULT(0)
	)
	;

	/**********************************************************************************************/

	drop table if EXISTS dbo.[#TBL_TA_CONDITIONS]
	;
	select [V].*
	into dbo.[#TBL_TA_CONDITIONS] 
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [V] with(nolock) where [V].[ROW_ID] = IsNull(@TestCaseRowID, -1)
	;

	select top(1) /* Client conditions: */
			@TA_TYPE					= ''''+ [TA_TYPE] + ''''
		,	@SECTOR						= [SECTOR]
		,	@UNIFIED					= [UNIFIED]
		,	@IS_SERVICE					= [IS_SERVICE]
		,	@CODE_EGFN_TYPE				= [CODE_EGFN_TYPE]
		,	@DB_CLIENT_TYPE_DT300		= [DB_CLIENT_TYPE_DT300]
		,	@VALID_ID					= [VALID_ID]
		,	@CUSTOMER_CHARACTERISTIC	= [CODE_CUSTOMER_CHARACTERISTIC]
		,	@CUSTOMER_AGE				= [CUSTOMER_AGE]
		,	@CUSTOMER_BIRTH_DATE_MIN	= CONVERT( char(8), [CUSTOMER_BIRTH_DATE_MIN], 112)
		,	@CUSTOMER_BIRTH_DATE_MAX	= CONVERT( char(8), [CUSTOMER_BIRTH_DATE_MAX], 112)
		,	@IS_PROXY					= [IS_PROXY]
		,	@IS_UNIQUE_CUSTOMER			= [IS_UNIQUE_CUSTOMER]
		,	@HAVE_CREDIT				= [HAVE_CREDIT]
		,	@COLLECT_TAX_FROM_ALL_ACC	= [COLLECT_TAX_FROM_ALL_ACC]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Conditions [PROXY_SPEC_TA]: */
			@UI_RAZPOREDITEL			= [UI_RAZPOREDITEL]
		,	@UI_UNLIMITED				= [UI_UNLIMITED]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Deal conditions: */
			@UI_STD_DOG_CODE			= cast( [UI_STD_DOG_CODE] as int)
		,	@UI_INDIVIDUAL_DEAL			= cast( [UI_INDIVIDUAL_DEAL] as int)
		,	@INT_COND_STDCONTRACT		= cast( [INT_COND_STDCONTRACT] as int )
		,	@CODE_UI_NM342				= cast( [CODE_UI_NM342]  as int)
		,	@CCY_CODE_DEAL				= [CCY_CODE_DEAL]
		,	@UI_OTHER_ACCOUNT_FOR_TAX	= [UI_OTHER_ACCOUNT_FOR_TAX]
		,	@UI_NOAUTOTAX				= [UI_NOAUTOTAX]
		,	@UI_DENY_MANUAL_TAX_ASSIGN	= [UI_DENY_MANUAL_TAX_ASSIGN]
		,	@UI_CAPIT_ON_BASE_DATE_OPEN = [UI_CAPIT_ON_BASE_DATE_OPEN]
		,	@UI_BANK_RECEIVABLES		= [UI_BANK_RECEIVABLES]
		,	@UI_JOINT_TYPE				= [UI_JOINT_TYPE]
		,	@LIMIT_AVAILABILITY			= [LIMIT_AVAILABILITY]
		,	@DEAL_STATUS				= [DEAL_STATUS]
		,	@LIMIT_TAX_UNCOLLECTED		= [LIMIT_TAX_UNCOLLECTED]
		,	@LIMIT_ZAPOR				= [LIMIT_ZAPOR]
		,	@IS_CORR					= [IS_CORR]
		,	@IS_UNIQUE_DEAL				= [IS_UNIQUE_DEAL]
		,	@GS_PRODUCT_CODE			= [GS_PRODUCT_CODE]
		,	@CODE_GS_PROGRAMME			= [CODE_GS_PROGRAMME]
		,	@CODE_GS_CARD				= [CODE_GS_CARD]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Conditions [DEALS_CORR_TA]: */
			@CCY_CODE_CORS				= [CCY_CODE_CORS]
		,	@LIMIT_AVAILABILITY_CORS	= [LIMIT_AVAILABILITY_CORS]
		,	@TAX_CODE					= [TAX_CODE]
		,	@PREF_CODE					= [PREF_CODE]
		,	@DOC_SUM					= [DOC_SUM]
		,	@DOC_TAX_SUM				= [DOC_TAX_SUM]
				/* Conditions [PREV_COMMON_TA]: */
		,	@RUNNING_ORDER				= [RUNNING_ORDER]
		,	@TYPE_ACTION				= [TYPE_ACTION]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;

	select @Sql2 = N'select DISTINCT TOP (50) ''ID_'+@TestCaseRowID+'_'+REPLACE(@TA_TYPE,'''','')+ ''''
		+ N' AS [TEST_ID], [DEAL].[DEAL_TYPE], [DEAL].[DEAL_NUM], [CUST].[CUSTOMER_ID], [PROXY].[CUSTOMER_ID] AS [REPRESENTATIVE_CUSTOMER_ID] ' + @CrLf
	insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR], [IS_BASE_select] )
	select	@Sql2,	N'SELECT ...', 1
	;
	select @Sql += @Sql2
	;

	--select @Sql2 = N'select COUNT(*) AS [CNT] '+ @CrLf
	--insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR], [IS_select_COUNT] )
	--select	@Sql2,	'select COUNT(*) ...', 1
	--;
	--select @Sql += @Sql2
	--;

	-- @SECTOR and @CCY_CODE_DEAL
	select @Sql2 = N'
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [DEAL] with(nolock)
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] with(nolock)
		on	[CUST].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
		and [DEAL].[CLIENT_SECTOR] = '+str(@SECTOR,len(@SECTOR),0)+N'
		and [DEAL].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+' ';

	-- [DT015_CUSTOMERS_ACTIONS_TA].[SECTOR] and [RAZPREG_TA].[UI_CURRENCY_CODE]
	insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
	select	(@Sql2 + @CrLf), N' BASE join: SECTOR = '+str(@SECTOR,len(@SECTOR),0)+' & [UI_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+' '
	select @Sql += @Sql2

	-- Access Deal throwght with proxy customer
	if @UI_RAZPOREDITEL IS NOT NULL
	begin
		/* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
		declare @CUSTOMER_ROLE_TYPE varchar(32) = N''
		;
		-- 0 - Пълномощник; 1 - Законен представител
		select @CUSTOMER_ROLE_TYPE = case IsNull(@UI_RAZPOREDITEL,-1)	
											when  0 then ' = 2'				/* 2 - Пълномощник*/
											when  1 then ' = 3'				/* 3 - Законен представител */
											when -1 then ' in (2,3) ' end;	/* 2 & 3 */
		select @Sql2 = N'
		inner join dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [PROXY_ID] with(nolock)
			on	[PROXY_ID].[DEAL_TYPE] = 1
			and [PROXY_ID].[DEAL_NUM]  = [DEAL].[DEAL_NUM]
			and [PROXY_ID].[CUSTOMER_ROLE_TYPE] '+@CUSTOMER_ROLE_TYPE+'
		inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [PROXY] with(nolock)
			on	[PROXY].[CUSTOMER_ID] = [PROXY_ID].[REPRESENTATIVE_CUSTOMER_ID]
		';

		-- [DT015_CUSTOMERS_ACTIONS_TA].[UI_RAZPOREDITEL] -- 0 - Пълномощник; 1 - Законен представител
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N'@UI_RAZPOREDITEL: '+STR(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0)+' '
		select @Sql += @Sql2;
	end
	else 
	begin

		select @Sql2 = N'
		inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [PROXY] with(nolock)
			ON	[PROXY].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
		';

		-- Base join clause: 
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N' WITHOUT PROXY: [PROXY].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]'
		select @Sql += @Sql2;
	end

	-- [DT015_CUSTOMERS_ACTIONS_TA].[DB_CLIENT_TYPE] => @DB_CLIENT_TYPE_DT300:
	select @Sql2 = N'
	where [CUST].[CLIENT_TYPE_DT300_CODE] = '+str(@DB_CLIENT_TYPE_DT300,len(@DB_CLIENT_TYPE_DT300),0);
	insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
	select	(@Sql2 + @CrLf), ' BASE @DB_CLIENT_TYPE_DT300 : ' + @Sql2
	select @Sql += @Sql2

	-- enum CustomerSubtypes: (-1) - Без значение; 1 - (над 18г.); 2 - (от 14г. до 18г.); 3 - (до 14г.)
	if  IsNull(@CUSTOMER_AGE, '-1') <> '-1'
	Begin 
		select	@Sql2 = N'AND [PROXY].[CLIENT_BIRTH_DATE] BETWEEN '
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0)+' AND ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0)+' ' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[CUSTOMER_AGE] '+@CUSTOMER_AGE+' - between YEAR : ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0) + ' AND '
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0) + @CrLf;

		select @Sql += @Sql2;
	end

	/*****************************************************/
	-- 0 - не е обединяван (клиент с един кл. код); 3 - обединен, без значение дали е бил главен или подчинен (кл.с повече от един кл.код); -1 - без значение
	if @UNIFIED <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_MANY_CLIENT_CODES] = ' + case when @UNIFIED = 0 THEN '0' ELSE '1' END + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UNIFIED] : ' + str(@UNIFIED,len(@UNIFIED),0 )

		select @Sql += @Sql2
	end

	-- 0 - Не е служебен или свързан със служебен; 1 - Реално ЕГН, има такива служебни; 2 - служебни ЕГН
	if @IS_SERVICE <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_DUBL_CLIENT_IDS] = ' + case when @IS_SERVICE = 0 then '0' else '1' end + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

		select @Sql += @Sql2

		if @IS_SERVICE <> 0
		begin 
			select @Sql2 = ' AND [CUST].[IS_ORIGINAL_EGFN] = ' + case when @IS_SERVICE = 1 then '1' else '0' end + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

			select @Sql += @Sql2
		end 
	end

	-- enum DetailedTypeOfIdentifier : [DT015_CUSTOMERS].[IDENTIFIER_TYPE]
	if IsNull(@CODE_EGFN_TYPE,-1) <> -1
	begin 
		select @Sql2 = ' AND [CUST].[CLIENT_IDENTIFIER_TYPE] = ' + str(@CODE_EGFN_TYPE,len(@CODE_EGFN_TYPE),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_EGFN_TYPE] : ' + str(@CODE_EGFN_TYPE,len(@CODE_EGFN_TYPE),0 )

		select @Sql += @Sql2
	end 

	-- 1 - валидни документи
	if IsNull(@VALID_ID,-1) = 1
	begin
		select @Sql2 = ' AND [PROXY].[HAS_VALID_DOCUMENT] = 1' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[VALID_ID] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end 

	-- @TODO: @IS_PROXY: 
	-- Ако клиента е маркиран като пълномощник, то той няма да се търси като самостоятелен 
	-- клиент, а данните му ще се актуализират при актуализация на данните за титуляра.
	--if IsNull(@IS_PROXY, -1) <> -1
	--	select @Sql += ' AND [CUST].[CUSTOMER_CHARACTERISTIC] = ' + str(@CUSTOMER_CHARACTERISTIC, len(@CUSTOMER_CHARACTERISTIC), 0);

	-- Указва дали клиента да е уникален за таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA]
	if IsNull(@IS_UNIQUE_CUSTOMER, -1) = 1
	begin 
		select @Sql2 = ' AND NOT EXISTS 
		(
			select * from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [TA_CUST] with(nolock)
			where [TA_CUST].[UI_CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
				/* and [TA_CUST].[TA_TYPE] = '+@TA_TYPE+' */
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[VALID_ID] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end
	;

	-- @TODO: @HAVE_CREDIT:
	-- Дали клиента има активен кредит: ;Без допълнителни сметки - ;Всички разплащателни и влогове - 
	-- ;Всички разплащателни - несвързани към друг кредит - ; Всички разплащателни, влогове и депозитни сметки -
	if IsNull(@HAVE_CREDIT, -1) in ( 0, 1 )
	begin
		select @Sql2 = ' AND [CUST].[HAS_LOAN] = '+STR(@HAVE_CREDIT,LEN(@HAVE_CREDIT),0) + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[HAS_LOAN] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end

	-- [COLLECT_TAX_FROM_ALL_ACC] : Клиента има ли непратени такси, който могат да се събират от всички сметки на клиента
	if IsNull(@COLLECT_TAX_FROM_ALL_ACC,-1) not in (0,1)
	begin
		select @StrIntVal = STR(@COLLECT_TAX_FROM_ALL_ACC,LEN(@COLLECT_TAX_FROM_ALL_ACC),0);
		select @Sql2 = ' AND [CUST].[HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC] = ' + @StrIntVal + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[COLLECT_TAX_FROM_ALL_ACC] : ' + @StrIntVal

		select @Sql += @Sql2
	end

	-- 0 - Пълномощник; 1 - Законен представител
	if IsNull(@UI_RAZPOREDITEL,-1) <> -1
	begin 
		if @UI_RAZPOREDITEL = 0
		begin
			select @Sql2 = ' AND [DEAL].[PROXY_COUNT] > 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_RAZPOREDITEL] : ' + str(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0 )

			select @Sql += @Sql2
		end

		-- @TODO: @UI_RAZPOREDITEL: трябва да добавим нова таблица с разпоредителите към сделките !!!
		--if  @UI_RAZPOREDITEL = 1
		--begin 
		--	select @Sql2 = ' AND [CUST].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID] AND [DEAL].[CLIENT_SECTOR] IN ( 5000, 9400 ) ' + @CrLf;

		--	insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		--	select	@Sql2
		--		,	'[UI_RAZPOREDITEL] : ' + str(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0 )

		--	select @Sql += @Sql2
		--end 
	end

	-- 1 - безсрочен; 0 - с крайна дата
	-- @TODO: @UI_UNLIMITED:
	--If IsNull(@UI_UNLIMITED, -1) <> -1
	--	select @Sql += ' ''

	-- Код на стандартен договор
	if IsNull(@UI_STD_DOG_CODE,-1) > 0 and IsNull(@UI_INDIVIDUAL_DEAL,-1) NOT IN (1)
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_STD_DOG_CODE] = '+STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_STD_DOG_CODE] : ' + STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0);

		select @Sql += @Sql2
	end 

	--0 - стандартна сделка, 1 - индивидуална сделка
	if IsNull(@UI_INDIVIDUAL_DEAL,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_INDIVIDUAL_DEAL] = '+STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_INDIVIDUAL_DEAL] : ' + STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0);

		select @Sql += @Sql2

		-- Код на стандартен договор по който е разкрита индивидуалната сделка
		if IsNull(@INT_COND_STDCONTRACT,-1) >= 0
		begin
			select @Sql2 = ' AND [DEAL].[INT_COND_STDCONTRACT] = '+STR(@INT_COND_STDCONTRACT, LEN(@INT_COND_STDCONTRACT),0) + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[INT_COND_STDCONTRACT] : ' + +STR(@INT_COND_STDCONTRACT, LEN(@INT_COND_STDCONTRACT),0);

			select @Sql += @Sql2
		end		

		if IsNull(@UI_STD_DOG_CODE,-1) >= 0
		begin
			select @Sql2 = ' AND [DEAL].[DEAL_STD_DOG_CODE] = '+STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_STD_DOG_CODE] : ' + STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + '/* for individual deal: [UI_INDIVIDUAL_DEAL] = 1 */';

			select @Sql += @Sql2
		end

	end 

	-- 0 - не е комбиниран продукт, код > 0 - да принадлежи към този комбиниран продукт
	if IsNull(@CODE_UI_NM342, -1) > 0
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NM342_BUNDLE_PRODUCT_CODE] = '+ STR(@CODE_UI_NM342,LEN(@CODE_UI_NM342),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_UI_NM342] : ' + STR(@CODE_UI_NM342,LEN(@CODE_UI_NM342),0);

		select @Sql += @Sql2
	end

	-- 0 - сметката се таксува от себе си, 1 - има друга таксуваща сметка, 2 - без проверка дали има друга таксуваща сметка или се таксува от себе си
	if IsNull(@UI_OTHER_ACCOUNT_FOR_TAX,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_OTHER_TAX_ACCOUNT] = 1' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_OTHER_ACCOUNT_FOR_TAX] : ' + str(@UI_OTHER_ACCOUNT_FOR_TAX,len(@UI_OTHER_ACCOUNT_FOR_TAX),0);

		select @Sql += @Sql2
	end

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_NOAUTOTAX,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NO_AUTO_PAY_TAX] = '+@UI_NOAUTOTAX + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_NOAUTOTAX] : ' + @UI_NOAUTOTAX

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_DENY_MANUAL_TAX_ASSIGN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_DENY_MANUAL_TAX_ASSIGN] = '+@UI_DENY_MANUAL_TAX_ASSIGN + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_DENY_MANUAL_TAX_ASSIGN] : ' + @UI_DENY_MANUAL_TAX_ASSIGN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_CAPIT_ON_BASE_DATE_OPEN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_CAPIT_ON_BASE_DATE_OPEN] = '+@UI_CAPIT_ON_BASE_DATE_OPEN + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_CAPIT_ON_BASE_DATE_OPEN] : ' + @UI_CAPIT_ON_BASE_DATE_OPEN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_BANK_RECEIVABLES,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_EXCLUDE_FROM_BANK_COLLECTIONS] = '+@UI_BANK_RECEIVABLES + @CrLf;
		
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_BANK_RECEIVABLES] : ' + @UI_BANK_RECEIVABLES

		select @Sql += @Sql2
	end 

	--0 - не е съвместна сделка, 1 - съвместна сделка от тип "по отделно"
	if IsNull(@UI_JOINT_TYPE,-1) in (0, 1)
	begin

		select @Sql2 = ' AND [DEAL].[DEAL_IS_JOINT_DEAL] = ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_JOINT_TYPE] : ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0);

		select @Sql += @Sql2

		/* enum JointDealsAccessToFundsType: 0 - Separate; 1 - Always Together */	
		if @UI_JOINT_TYPE = 1
		begin 
			select @Sql2 = ' AND [DEAL].[DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] = 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_JOINT_TYPE] (Access type: 0 - Separate; 1 Always Together) : ';

			select @Sql += @Sql2
		end
	end

	-- 0 или долна граница на разполагаемостта ( '<0', '>0' )
	if Left(ltrim(IsNull(@LIMIT_AVAILABILITY,'0')),1) in ('<', '>', '=')
	begin 
		select @Sql2 = ' AND ([DEAL].[ACCOUNT_BEG_DAY_BALANCE] - [DEAL].[BLK_SUMA_MIN]) '+@LIMIT_AVAILABILITY + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[LIMIT_AVAILABILITY] : ' + @LIMIT_AVAILABILITY;

		select @Sql += @Sql2
	end 

	-- 1 - активна; Безусловно ще се търсят сделки които НЕ СА ЗАМРАЗЕНИ
	if IsNull(@DEAL_STATUS,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[IS_DORMUNT_ACCOUNT] = 0' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[DEAL_STATUS] : ' + str(@DEAL_STATUS,len(@DEAL_STATUS),0);

		select @Sql += @Sql2
	end 

	-- 0 - няма несъбрани такси; 1 - има несъбрани такси, -1 без значение от сумата
	if IsNull(@LIMIT_TAX_UNCOLLECTED,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_TAX_UNCOLECTED] = ' + str(@LIMIT_TAX_UNCOLLECTED,len(@LIMIT_TAX_UNCOLLECTED),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[LIMIT_TAX_UNCOLLECTED] : ' + str(@LIMIT_TAX_UNCOLLECTED,len(@LIMIT_TAX_UNCOLLECTED),0);

		select @Sql += @Sql2
	end 

	-- 0 - няма запор; друга сума - има запор над определена сума; (-1) : няма значение;
	if IsNull(@LIMIT_ZAPOR,-1) >= 0
	begin 

		if @LIMIT_ZAPOR = 0
		begin 
			select @Sql2 = ' AND [DEAL].[HAS_DISTRAINT] = 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 

		if @LIMIT_ZAPOR > 0
		begin
			select @Sql2 = ' AND [DEAL].[HAS_DISTRAINT] = 1 AND [DEAL].[BLK_SUMA_MIN] > '+ STR(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0) + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 
	end

	-- Да няма осчетоводено вносни бележки по сделката: @RUNNING_ORDER = 1 and @TYPE_ACTION = ''
	if @TYPE_ACTION = 'CashPayment' and IsNull(@RUNNING_ORDER,-1) >= 1
	begin
		select @Sql2 = ' AND [DEAL].[HAS_WNOS_BEL] = ' + (case when @RUNNING_ORDER > 1 then '1' else '0' end)  + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[TYPE_ACTION] = CashPayment and [RUNNING_ORDER] : ' + str(@RUNNING_ORDER,len(@RUNNING_ORDER),0);

		select @Sql += @Sql2
	end

	-- Да укаже дали сметката е кореспондираща до други сделки: -1 няма значение; 0 не е; 1 да , кореспондираща е
	if IsNull(@IS_CORR,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND '+CASE WHEN @IS_CORR = 0 THEN 'NOT' ELSE '' END+ ' EXISTS (
			select * from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [TAX] with(nolock)
			where  [TAX].[CORR_ACCOUNT] =  [DEAL].[DEAL_ACCOUNT]
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_CORR] : ' + str(@IS_CORR,len(@IS_CORR),0);

		select @Sql += @Sql2
	end 

	-- Указва дали РС да е уникална в таблица [RAZPREG_TA]
	if IsNull(@IS_UNIQUE_DEAL,-1) in ( 1 )
	begin 
		select @Sql2 = ' AND NOT EXISTS (
			select * FROM dbo.[RAZPREG_TA] [TA] with(nolock)
			where  [TA].[UI_DEAL_NUM] = [DEAL].[DEAL_NUM]
				/* and [TA].[TA_TYPE] like '+@TA_TYPE+' */
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_UNIQUE_DEAL] : ' + str(@IS_UNIQUE_DEAL,len(@IS_UNIQUE_DEAL),0)

		select @Sql += @Sql2
	end
	;

	-- Код на програма от Group Sales + Продуктов код на карта + Код на GS договор
	if IsNull(@CODE_GS_PROGRAMME,-1) > 0 AND IsNull(@CODE_GS_CARD,-1) > 0 AND IsNull(@GS_PRODUCT_CODE,-1) > 0
	begin 
		select @Sql2 = ' AND EXISTS (
			select * FROM dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [GS] with(nolock)
			where	[GS].[DEAL_NUM]	 = [DEAL].[DEAL_NUM]
				and [GS].[DEAL_TYPE] = 1
				and [GS].[DEAL_GS_INDIVIDUAL_PROGRAM_CODE] = '+STR(@CODE_GS_PROGRAMME,LEN(@CODE_GS_PROGRAMME),0)+'
				and [GS].[DEAL_GS_INDIVIDUAL_CARDHOLDER_PREMIUM] = '+STR(@CODE_GS_CARD,LEN(@CODE_GS_CARD),0)+'
				and [GS].[DEAL_GS_INDIVIDUAL_PRODUCT_CODE] = '+STR(@GS_PRODUCT_CODE,LEN(@GS_PRODUCT_CODE),0)+'
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_GS_PROGRAMME] : ' + str(@CODE_GS_PROGRAMME,len(@CODE_GS_PROGRAMME),0)
				+', [CODE_GS_CARD] : ' + str(@CODE_GS_CARD,len(@CODE_GS_CARD),0)
				+', [GS_PRODUCT_CODE] : ' + str(@GS_PRODUCT_CODE,len(@GS_PRODUCT_CODE),0)
		select @Sql += @Sql2
	end 

	-- Валута на кореспонденцията
	if IsNull(@CCY_CODE_CORS, -1) > 0
	begin 
		select @Sql2 = ' AND '+CASE WHEN @IS_CORR = 0 THEN 'NOT' ELSE '' END+ ' EXISTS (
			select * FROM dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [TAX] with(nolock)
			where  [TAX].[CORR_ACCOUNT] =  [DEAL].[DEAL_ACCOUNT] ' + @CrLf;

		-- Разполагаемост по сделката 
		if left(ltrim(IsNull(@LIMIT_AVAILABILITY_CORS, '0')),1) in ('<', '>', '=')
				select @Sql2 += ' AND ([TAX].[ACCOUNT_BEG_DAY_BALANCE] - [DEAL].[BLK_SUMA_MIN]) '+@LIMIT_AVAILABILITY_CORS;

		select @Sql2 += ')' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CCY_CODE_CORS] : ' + str(@CCY_CODE_CORS,len(@CCY_CODE_CORS),0) + ', [LIMIT_AVAILABILITY_CORS] : ' + @LIMIT_AVAILABILITY_CORS

		select @Sql += @Sql2
	end 

	if len(@Sql) > 10
	begin 
		select @Sql as [SQL_QUERY]
		select @Msg = 'TA Row ID: ' + @TestCaseRowID + ', successful generated sql query: "'+@Sql+'"'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, @Sql

		begin try
			insert into dbo.[#TBL_RESULT] 
			exec sp_executeSql  @Sql
		end try 
		begin catch 
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
			return 1
		end catch 
	end

	select @Rows = (select count(*) from dbo.[#TBL_RESULT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: insert into dbo.[#TBL_RESULT], Rows affected : ' + str(@Rows,len(@Rows),0) + ', TA ID :'+ @TestCaseRowID;
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
	end

	if @Rows <= 0 and @SaveTAConditions = 1
	begin
		insert into dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
		( [TEST_ID], [SQL_COND], [DESCR], [IS_BASE_SELECT], [IS_SELECT_COUNT] )
		SELECT	@TestCaseRowID	 AS [TEST_ID]
			,	[S].[SQL_COND]
			,	[S].[DESCR]
			,	[S].[IS_BASE_SELECT]
			,	[S].[IS_SELECT_COUNT]
		FROM dbo.[#TBL_SQL_CONDITIONS] [S] WITH(NOLOCK)
	end
		
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]'
	end

	return 0;
end 
go


/********************************************************************************************************/
/* Процедура за актуализация на Таблиците по ID на тестови case */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES]
(
	@TestCaseRowID int
)
AS 
begin

	declare @LogTraceInfo int = 0, @LogResultTable int = 0
		,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql nvarchar(4000) = N''
		,	@RowIdStr nvarchar(8) = STR(@TestCaseRowID,LEN(@TestCaseRowID),0)
	;

	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @RowIdStr, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES]'
	;

	/************************************************************************************************************/
	/* 1. Find TA Conditions: */
	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if not exists (select * from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1))
	begin 
		select  @Msg = N'Error not found condition with [ROW_ID] :' + @RowIdStr
			,	@Sql = N'select * from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull('+@RowIdStr+', -1)'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return -1;
	end
	
	declare @DB_TYPE sysname = N'BETA', @DEALS_CORR_TA_RowID int = 0
	;

	select	@DB_TYPE = [TA_TYPE], @DEALS_CORR_TA_RowID = [CORS_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1)
	;

	select @DB_TYPE = [DB_TYPE] from dbo.[TEST_AUTOMATION_TA_TYPE] with(nolock)
	where  [TA_TYPE] IN ( @DB_TYPE )
	;
	/************************************************************************************************************/
	/* 2. Get Datasources: */
	declare @OnlineSqlServerName sysname = N'',	@OnlineSqlDataBaseName sysname = N'', @DB_ALIAS sysname = N'VCS_OnlineDB'
	;

	exec @Ret = dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE] @DB_TYPE, @DB_ALIAS, @OnlineSqlServerName out, @OnlineSqlDataBaseName out
	if @Ret <> 0
	begin
		select  @Msg = N'Error execute proc, Error code: '+str(@Ret,len(@Ret),0)
					+' ; Result: @OnlineSqlServerName = "'+@OnlineSqlServerName+'", @OnlineSqlDataBaseName = "'+@OnlineSqlDataBaseName+'"'
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -2;
	end

	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE], @OnlineSqlServerName: ' +@OnlineSqlServerName+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end
	
	/*********************************************************************************************************/
	/* 2. Get Account Date */
	declare @CurrAccDate datetime = 0,	@AccountDate sysname = N''
	;

	begin try
		exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate OUT
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnlineSqlServerName+N', '+@OnlineSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -2;
	end catch 

	select @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnlineSqlServerName+N', '+@OnlineSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	/*********************************************************************************************************/
	/* 3. Cleate data before upatede table: dbo.DEALS_CORR_TA; dbo.RAZPREG_TA; dbo.DT015_CUSTOMERS_ACTIONS_TA */
	begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]  @RowIdStr
	end try 	
	begin catch

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] @RowIdStr = '+@RowIdStr;

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return 1;
	end catch

	/*********************************************************************************************************/
	/* 4. Prepare Sql Conditions: */
	drop table if EXISTS dbo.[#TBL_RESULT]
	;
	create table dbo.[#TBL_RESULT]
	(
		[TEST_ID]		NVARCHAR(512) 
	,	[DEAL_TYPE]		SMALLINT
	,	[DEAL_NUM]		INT 	
	,	[CUSTOMER_ID]	INT
	,	[REPRESENTATIVE_CUSTOMER_ID] INT
	)
	;

	exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS] @RowIdStr, @CurrAccDate

	if @Ret <> 0
	begin 
		select  @Msg = N'Error Execute procedure dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS], Online Accoun Date: ' +@AccountDate
			,	@Sql = N'exec dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS] '+@RowIdStr+', '+@AccountDate+N''
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	if @LogResultTable = 1 select * from dbo.[#TBL_RESULT] with(nolock);

	--EXEC @Ret = dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL] @RowIdStr, @CurrAccDate, @Sql
	--begin 
	--	select  @Msg = N'Error Execute procedure dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL], Online Accoun Date: ' +@AccountDate
	--		,	@Sql = N'exec dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL] '+@RowIdStr+', '+@AccountDate+' '
	--	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	--end

	select @Rows = (select count(*) from dbo.[#TBL_RESULT] with(nolock))

	declare @DealNum int = 0, @CustomerID int = 0, @ProxyID int = 0, @WithUpdate int = 1
	;

	select	Top(1)
			@DealNum	= [DEAL_NUM]
		,	@CustomerID	= [CUSTOMER_ID]
		,	@ProxyID	= [REPRESENTATIVE_CUSTOMER_ID]
	from dbo.[#TBL_RESULT] with(nolock);

	if @Rows <= 0 or IsNull(@DealNum,0) <= 0 or IsNull(@CustomerID,0) <= 0
	begin
		select @Msg = 'Not found suitable deal from Test Case with [ROW_ID]: ' + @RowIdStr;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @RowIdStr, @Msg
		return 2;
	end

	/******************************************************************************************************/
	/* 5. Update data in tables: dbo.[DEALS_CORR_TA]; dbo.[RAZPREG_TA]; dbo.[DT015_CUSTOMERS_ACTIONS_TA] */

	/******************************************************************************************************/
	/* 5.1. Updare table dbo.[DEALS_CORR_TA] */
	if IsNull(@DEALS_CORR_TA_RowID,-1) > 0
	begin

		begin try
				exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA] @OnlineSqlServerName, @OnlineSqlDataBaseName
				, @RowIdStr, 1, @DealNum, @CustomerID, @ProxyID, @WithUpdate
		end try 	
		begin catch

			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

			return 3;
		end catch 
	end

	/******************************************************************************************************/
	/* 5.2. Updare table  dbo.[RAZPREG_TA] */
	begin try
			exec dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] @OnlineSqlServerName, @OnlineSqlDataBaseName
			, @RowIdStr, 1, @DealNum, @CustomerID, @ProxyID, @WithUpdate
	end try 	
	begin catch

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

		return 4;
	end catch 

	/******************************************************************************************************/
	/* 5.3. Updare table dbo.[DT015_CUSTOMERS_ACTIONS_TA] for Customer and Proxy */
	begin try
			exec dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate
			, @RowIdStr, @CustomerID, @ProxyID, @WithUpdate
	end try
	begin catch 

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate'
				+', @RowIdStr, @CustomerID, @ProxyID, @WithUpdate'

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

		return 5;
	end catch

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @RowIdStr
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES]'
	end
	
	return 0;
end
go

/********************************************************************************************************/
/* Процедура за определяне на критериите който ни пречат да намерим подходяща сделка за датен TestCase */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]
(
	@TestCaseRowID nvarchar(16)
,	@CurrAccDate datetime
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0,	@Sql nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	;

	/************************************************************************************************************/
	/* @TODO: */
	/**********************************************************************************/
	drop table if EXISTS dbo.[#TBL_RESULT]
	;
	create table dbo.[#TBL_RESULT]
	(
		[TEST_ID]		nvarchar(512) 
	,	[DEAL_TYPE]		smallint
	,	[DEAL_NUM]		INT 	
	,	[CUSTOMER_ID]	INT
	,	[REPRESENTATIVE_CUSTOMER_ID] INT
	)
	;

	declare @CondCount int = 0, @FistCondRowID int = 0, @ScipCondIndex int = 4, @ScipTblRowId int = 0
	;

	select @CondCount = count(*), @FistCondRowID = min([ID])
	from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with (nolock)
	where [TEST_ID] = @TestCaseRowID
	;

	while @Rows = 0 AND @ScipCondIndex < @CondCount
	begin

		truncate table dbo.[#TBL_RESULT]
		;

		select  @Sql = N'', @Rows = 0, @ScipTblRowId = @FistCondRowID + @ScipCondIndex
		;

		-- Prepare Sql to execute: 
		select @Sql += [CND].[COUND] 
		from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] WITH(NOLOCK)
		cross apply (
			select case when [ID] = @ScipTblRowId 
					then '' else [SQL_COND] end	as [COUND] 
		) [CND]
		where [TEST_ID] = @TestCaseRowID 
		order by [ID]

		-- Execute Sql:
		begin try
			insert into dbo.[#TBL_RESULT]
			exec sp_executesql @Sql
		end try

		begin catch
			select @Msg = 'Error execute Sql:' + dbo.FN_GET_EXCEPTION_INFO()
			from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
			where [ID] = @ScipTblRowId

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		end catch

		select @Rows = count(*)
		from dbo.[#TBL_RESULT] with(nolock)

		-- Test Result:
		if @Rows > 0
		begin
			select @Msg = 'Test Case ID:'+[TEST_ID]+'; Found records: '+str(@Rows,3,0)+'; Skiped condition info: "'+[DESCR]+'"; Skiped SQL condition: "'+[SQL_COND]+'";'
			from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
			where [id] = @ScipTblRowId
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		end

		set @ScipCondIndex += 1;
	end
	
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())+', TA Row ID: '+@TestCaseRowID+'; Found Records: '+str(@Rows,2,0)+'.';
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	end

	return 0;
end 
go


/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@Account				sysname
,	@AccCurrency			int
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @Account = '''+@Account+''''
					+', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* 3. Load Tax Uncolected amount by Account from OlineDB */

	select @Sql1 = N'
	declare @Account varchar(64) = '''+@Account+'''
		,	@Account_CCY int = '+str(@AccCurrency,len(@AccCurrency),0)+'
	;
	with TAX_BY_CCY AS 
	(
		select	[T].[ORIGINAL_CURRENCY]									as [CURRENCY_TOT]
			,	SUM ( [T].[AMOUNT] - [T].[COLLECTED_AMOUNT] )			as [TAX_UNCOLLECTED_TOT]
			,	SUM ( [T].[DDS_AMOUNT] - [T].[DDS_COLLECTED_AMOUNT] )	as [DDS_UNCOLLECTED_TOT]
			,	COUNT(*)												as [CNT_ITEMS]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = @Account
			and [T].[TAX_STATUS] = 0
		GROUP BY [T].[ORIGINAL_CURRENCY]
	) 
	, [TAX_BY_ACC] AS 
	(
		SELECT	SUM( dbo.TRANS_CCY_TO_CCY_TA( [T].[TAX_UNCOLLECTED_TOT], [T].[CURRENCY_TOT], @Account_CCY)
				   + dbo.TRANS_CCY_TO_CCY_TA( [T].[DDS_UNCOLLECTED_TOT], 100,  @Account_CCY ) )
									AS [TAX_UNCOLLECTED]
			,	SUM( [CNT_ITEMS] )	AS [CNT_ITEMS]
		FROM TAX_BY_CCY [T]
	)
	SELECT	@Account						as [ACCOUNT]
		,	round([R].[TAX_UNCOLLECTED], 4)	as [TAX_UNCOLLECTED]
		,	[R].[CNT_ITEMS]					as [CNT_ITEMS]
	FROM [TAX_BY_ACC] [R]
	';

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2;
	end catch

	if @LogTraceInfo = 1 select @Sql1 as [LOAD_TAX_UNCOLECTED_BY_ACC];

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Cors Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @Account = '''+@Account+''''
					+', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', @Account: ' + @Account
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
go
