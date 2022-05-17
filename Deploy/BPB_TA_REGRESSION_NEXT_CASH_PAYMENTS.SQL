/***************************************************************************************************************/
-- Име          : Янко Янков
-- Дата и час   : 04.05.2022
-- Задача       : Task 276959
-- Класификация : Test Automation
-- Описание     : Автоматизация на тестовете за вснони бележки с използване на наличните данни от Online базата
-- Параметри    : Няма
/***************************************************************************************************************/

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

/********************************************************************************************************/
/* Създаване на помощно view */
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
			VALUES ( 36, 'AUD'), (100, 'BGN'), (124, 'CAD'), (756, 'CHF')
				,  (826, 'GBP'), (840, 'USD'), (946, 'RON'), (978, 'EUR')
		) X([ID], [NAME])		
	)
	SELECT	DISTINCT
			[PREV].[ROW_ID]									AS [ROW_ID]
		,	[PREV].[TA_TYPE]								AS [TA_TYPE]
		,	[CUST].[ROW_ID]									AS [CUST_ROW_ID]
		,	[PSPEC].[ROW_ID]								AS [PSPEC_ROW_ID]
		,	[DREG].[ROW_ID]									AS [DEAL_ROW_ID]
		,	[CORS].[ROW_ID]									AS [CORS_ROW_ID]		

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
		,	cast(IsNull([NM3].[CUSTOMER_BIRTH_DATE_MAX], 999)as DATE)
															AS [CUSTOMER_BIRTH_DATE_MAX]
		,	[CUST].[IS_PROXY]								AS [IS_PROXY]
		,	[CUST].[IS_UNIQUE]								AS [IS_UNIQUE_CUSTOMER]
		,	[CUST].[HAVE_CREDIT]							AS [HAVE_CREDIT]
		,	[CUST].[PROXY_COUNT]							AS [PROXY_COUNT]

		,	[PSPEC].[UI_RAZPOREDITEL]						AS [UI_RAZPOREDITEL]
		,	[PSPEC].[UI_UNLIMITED]							AS [UI_UNLIMITED]

			/* RAZPREG */
		,	[DREG].UI_STD_DOG_CODE							AS [UI_STD_DOG_CODE]
		,	[DREG].[UI_INDIVIDUAL_DEAL]						AS [UI_INDIVIDUAL_DEAL]
		,	[DREG].UI_NM342_CODE							AS [UI_NM342_CODE]
		,	[NM_ID].[CODE_UI_NM342]
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

			/* DEALS_CORR */
		,	[CORS].[CURRENCY]								AS [CURRENCY_CORS]
		,	[CCY_CORS].[CCY_CODE_CORS]						AS [CCY_CODE_CORS]
		,	[CORS].[LIMIT_AVAILABILITY]						AS [LIMIT_AVAILABILITY_CORS]
		,	[CORS].[LIMIT_TAX_UNCOLLECTED]					AS [LIMIT_TAX_UNCOLLECTED_CORS]

			/* [PROXY_ACC_TA] */
/*		,	[PROXY_ACC_TA]  Пълномощника, да има права за действието по избраната сметка */
			/* PREV */
		,	[PREV].RUNNING_ORDER							AS [RUNNING_ORDER]
		,	[PREV].TAX_CODE									AS [TAX_CODE]
		,	[PREV].PREF_CODE								AS [PREF_CODE]		

			/* Conditions ? */						
		,	[NM_ID].[DOC_SUM]								AS [DOC_SUM]
		,	[PREV].[TAX_SUM]								AS [DOC_TAX_SUM]

	FROM dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
	INNER JOIN dbo.[RAZPREG_TA] [DREG] WITH(NOLOCK)
		on [PREV].[REF_ID] = [DREG].[ROW_ID]
	INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
		on [DREG].[REF_ID] = [CUST].ROW_ID
	LEFT JOIN dbo.[DEALS_CORR_TA] [CORS] WITH(NOLOCK)
		on [CORS].REF_ID = [DREG].ROW_ID		
	LEFT JOIN dbo.[PROXY_SPEC_TA] as [PSPEC] WITH(NOLOCK)
		on [CUST].ROW_ID =[PSPEC].REF_ID
	CROSS APPLY (
		SELECT	LEN(RTRIM(ltrim(IsNull([DREG].[UI_NM342_CODE],''))))			AS [LEN_UI_NM342]
			,	charindex(N' ',ltrim(IsNull([DREG].[UI_NM342_CODE],'')),0)		AS [POS_UI_NM342]

			,	LEN(RTRIM(ltrim(IsNull([DREG].[GS_PROGRAMME_CODE],''))))		AS [LEN_GS_PROGRAMME]
			,	charindex(N' ',ltrim(IsNull([DREG].[GS_PROGRAMME_CODE],'')),0)	AS [POS_GS_PROGRAMME]

			,	LEN(RTRIM(ltrim(IsNull([DREG].[GS_CARD_PRODUCT],''))))			AS [LEN_GS_CARD]
			,	charindex(N' ',ltrim(IsNull([DREG].[GS_CARD_PRODUCT],'')),0)	AS [POS_GS_CARD]
	) [POS]
	CROSS APPLY (
		SELECT	CASE WHEN [POS].[POS_UI_NM342] > 0 AND [POS].[LEN_UI_NM342] > 0 
					THEN LEFT(ltrim([DREG].[UI_NM342_CODE]), [POS].[POS_UI_NM342]) 
					ELSE '' END 	AS [CODE_UI_NM342]

			,	CASE WHEN [POS].[POS_GS_PROGRAMME] > 0 AND [POS].[LEN_GS_PROGRAMME] > 0 
					THEN LEFT(ltrim([DREG].[GS_PROGRAMME_CODE]), [POS].[POS_GS_PROGRAMME]) 
					ELSE '' END 	AS [CODE_GS_PROGRAMME]

			,	CASE WHEN [POS].[POS_GS_CARD] > 0 AND [POS].[LEN_GS_CARD] > 0 
					THEN LEFT(ltrim([DREG].[GS_CARD_PRODUCT]), [POS].[POS_GS_CARD]) 
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
/* Процедура за първоначална инициализация */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
GO

DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS]
GO
DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@TestAutomationType		sysname = N'%CashPaymentCA%BETA%'
,	@LogTraceInfo			int = 0
)
AS 
BEGIN
	SELECT @LogTraceInfo = 1
	;

	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(@OnleneSqlServerName,1) <> '['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(@OnleneSqlDataBaseName,1) <> '['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)		

	DECLARE @Sql varchar(max) = N'', @Msg nvarchar(max) = N'', @LogBegEndProc int = 1
		,	@AccountDate varchar(32) = N'', @Rows int = 0, @Err int = 0
		, 	@SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N'', @TimeBeg datetime = GetDate()
	;

	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @SqlFullDBName, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_INIT_DEALS]'
	;

	/************************************************************************************************************/
	/* 0.1. Get Account Date */
	DECLARE @CurrAccDate datetime = 0
	;

	BEGIN TRY
		exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate OUT
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return -1
	END CATCH 

	SELECT @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 1.1. Prepare BASE conditions */
	DROP TABLE IF EXISTS #TBL_WITH_FILTERS
	;

	SELECT	[PREV].ROW_ID							AS [PREV_ROW_ID]
		,	[PREV].PROXY_ROW_ID						AS [PREV_PROXY_ROW_ID]
		,	[PREV].TA_TYPE							AS [PREV_TA_TYPE]

		,	[CUST].[SECTOR]							AS [CUST_CND_SECTOR]
		,	[DREG].UI_STD_DOG_CODE					AS [DEAL_CND_UI_STD_DOG_CODE]
		,	[DREG].UI_CURRENCY_CODE					AS [DEAL_CND_UI_CURRENCY_CODE]				

	INTO #TBL_WITH_FILTERS
	FROM dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
	INNER JOIN dbo.[RAZPREG_TA] [DREG] WITH(NOLOCK)
		on [PREV].REF_ID = [DREG].ROW_ID
	LEFT JOIN dbo.[DEALS_CORR_TA] [CORS] WITH(NOLOCK)
		on [CORS].REF_ID = [DREG].ROW_ID
	INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
		on [DREG].REF_ID = [CUST].ROW_ID
	LEFT JOIN dbo.[PROXY_SPEC_TA] as [PSPEC] WITH(NOLOCK)
		on [CUST].ROW_ID =[PSPEC].REF_ID
	WHERE [PREV].[TA_TYPE] LIKE @TestAutomationType
	ORDER BY [PREV].ROW_ID
	;

	SELECT @Rows = @@ROWCOUNT, @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin
		select @Msg = N'After: INSERT INTO [#TBL_WITH_FILTERS], Rows Affected: '+ str(@Rows,len(@Rows),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestAutomationType, @Msg
	end
	;

	/* 1.2. Prepare deals  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS]
	;

	set @Sql1 = N'
	DECLARE @DealType int = 1
		,	@DateAcc date = '+@AccountDate+'
	;

	DECLARE @StsDeleted						int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@StsCloased						int	= dbo.SETBIT(cast(0 as binary(4)),  9, 1)
		,	@StsHasIndividualSpecCondPkgs	int = dbo.SETBIT(cast(0 as binary(4)),  5, 1)	/* STS_INDIVIDUAL_SPEC_COND_PKGS (5) */
		,	@StsExcludeFromBankCollection	int = dbo.SETBIT(cast(0 as binary(4)),  8, 1)	/* STS_EXCLUDE_FROM_BANK_COLLECTIONS (8) */
		,	@StsHasOtherTaxAcc				int	= dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* CMN_OTHER_ACCOUNT_FOR_TAX (14) */
		,	@StsIsIndividual				int	= dbo.SETBIT(cast(0 as binary(4)), 16, 1)	/* SD_INDIVIDUAL_DEAL (16) */
		,	@StsNoAutoPayTax				int	= dbo.SETBIT(cast(0 as binary(4)), 29, 1)	/* CMN_NOAUTOTAX (29) */
	;

	DECLARE @StsExtJointDeal				int = dbo.SETBIT(cast(0 as binary(4)),  4, 1)	/* STS_EXT_JOINT_DEAL (4) */
		,	@StsExtCapitOnBaseDateOpen		int = dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* STS_EXT_CAPIT_ON_BASE_DATE_OPEN (14) */
		,	@StsExtDenyManualTaxAssign		int = dbo.SETBIT(cast(0 as binary(4)), 20, 1)	/* STS_EXT_DENY_MANUAL_TAX_ASSIGN (20)*/
			/* [BLOCKSUM] */
	;'

	set @Sql2 = N'
	WITH [X] AS 
	(
		SELECT	[CUST_CND_SECTOR]
			,	[DEAL_CND_UI_STD_DOG_CODE]
			,	[DEAL_CND_UI_CURRENCY_CODE]
			,	count(*) AS CNT
		FROM #TBL_WITH_FILTERS WITH(NOLOCK)
		GROUP BY [CUST_CND_SECTOR], [DEAL_CND_UI_STD_DOG_CODE], [DEAL_CND_UI_CURRENCY_CODE] 
	)
	SELECT	/* Deal info: */
			IDENTITY( INT, 1, 1)					AS [ROW_ID]
		,	1										AS [DEAL_TYPE]
		,	[REG].[DEAL_NUM]						AS [DEAL_NUM]
		,	[EXT].[ACCOUNT]							AS [DEAL_ACCOUNT]
		,	[REG].[CURRENCY_CODE]					AS [DEAL_CURRENCY_CODE]
		,	[REG].[STD_DOG_CODE]					AS [DEAL_STD_DOG_CODE]

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

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS]
	FROM '+@SqlFullDBName+'.dbo.[RAZPREG] [REG] WITH(NOLOCK) 

	INNER JOIN '+@SqlFullDBName+'.dbo.[DT015] [CLC] WITH(NOLOCK)	
		ON  [CLC].[CODE] = [REG].[CLIENT_CODE] 

	INNER JOIN '+@SqlFullDBName+'.dbo.[DT008] [CCY] WITH(NOLOCK) 
		ON  [CCY].[CODE] = [REG].[CURRENCY_CODE]

	INNER JOIN '+@SqlFullDBName+'.dbo.[PARTS] [ACC] WITH(NOLOCK) 
		ON  [ACC].[PART_ID] = [REG].[ACCOUNT]

	INNER  JOIN [X] 
		ON	[X].[CUST_CND_SECTOR]			= [REG].[KL_SECTOR]
		AND [X].[DEAL_CND_UI_STD_DOG_CODE]	= [REG].[STD_DOG_CODE]
		AND [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
	'
	set @Sql3 = N' 
	CROSS APPLY (
		SELECT	CAST(@DealType AS TINYINT)				AS [DEAL_TYPE]
			,	CAST([REG].[ACCOUNT] AS VARCHAR(33))	AS [ACCOUNT]
				/* Additional flags: */
			,	CAST( [REG].INDIVIDUAL_COMBINATION_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_COMB]
			,	CAST( [REG].INDIVIDUAL_PROGRAM_GS_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_PROG]
	) [EXT]
	CROSS APPLY (
		SELECT 	CAST( 0 AS bit ) 						AS [DEAL_IS_USED]
			,	CAST( 0 AS bit ) 						AS [HAS_TAX_UNCOLECTED]
			,	CAST( 0 AS bit ) 						AS [HAS_OTHER_TAX_ACCOUNT]
			,	CAST( 0 AS bit ) 						AS [HAS_LEGAL_REPRESENTATIVE]
			,	CAST( 0 AS bit ) 						AS [HAS_PROXY]
			,	CAST( 0 AS bit ) 						AS [HAS_DISTRAINT]
			,	CAST( 0 AS bit ) 						AS [HAS_GS_INDIVIDUAL_PROGRAMME]
			,	CAST( 0 AS bit ) 						AS [HAS_WNOS_BEL]
			,	CAST( 0 AS bit ) 						AS [IS_DORMUNT_ACCOUNT]
	) [EX_BITS]
	CROSS APPLY (
		SELECT	/* Bits from [STATUS]: */
				CAST(CASE WHEN ([REG].[STATUS] & @StsCloased) <> @StsCloased THEN 1 ELSE 0 END AS BIT)
										AS [IS_ACTIVE_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasIndividualSpecCondPkgs) = @StsHasIndividualSpecCondPkgs THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_COND_PKGS]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasOtherTaxAcc) = @StsHasOtherTaxAcc THEN 1 ELSE 0 END AS BIT)
										AS [HAS_OTHER_TAX_ACC]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsIsIndividual) = @StsIsIndividual THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsNoAutoPayTax) = @StsNoAutoPayTax THEN 1 ELSE 0 END AS BIT)
										AS [NO_AUTO_PAY_TAX]
				/* Bits from [STATUS_EXT]: */
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtJointDeal) = @StsExtJointDeal THEN 1 ELSE 0 END AS BIT)
										AS [IS_JOINT_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExcludeFromBankCollection) = @StsExcludeFromBankCollection THEN 1 ELSE 0 END AS BIT)
										AS [EXCLUDE_FROM_BANK_COLLECTIONS]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtCapitOnBaseDateOpen) = @StsExtCapitOnBaseDateOpen THEN 1 ELSE 0 END AS BIT)
										AS [CAPIT_ON_BASE_DATE_OPEN]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtDenyManualTaxAssign) = @StsExtDenyManualTaxAssign THEN 1 ELSE 0 END AS BIT)
										AS [IS_DENY_MANUAL_TAX_ASSIGN]
	) [STS]
	WHERE	([REG].[STATUS] & @StsDeleted) <> @StsDeleted
		and ([REG].[STATUS] & @StsCloased) <> @StsCloased'
	;

	BEGIN TRY
		EXECUTE( @Sql1 + @Sql2 + @Sql3 );
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO(), @Sql = @Sql1 + @Sql2 + @Sql3;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return 1
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS], Rows affected: ' + str(@Rows,len(@Rows),0), @Sql = @Sql1 + @Sql2 + @Sql3
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end
	;

	/* 1.2.1 Add Indexes on dbo.[AGR_CASH_PAYMENTS_DEALS] */
	ALTER TABLE dbo.[AGR_CASH_PAYMENTS_DEALS]
		ADD CONSTRAINT [PK_AGR_CASH_PAYMENTS_DEALS] 
			PRIMARY KEY CLUSTERED ( [ROW_ID] )
	;

	CREATE INDEX IX_AGR_CASH_PAYMENTS_DEALS_DEAL_NUM_DEAL_TYPE
		ON dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_NUM], [DEAL_TYPE] )
	;

	CREATE INDEX IX_AGR_CASH_PAYMENTS_DEALS_DEAL_ACCOUNT
		ON dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_ACCOUNT] )
	;	

	/* 1.3. Prepare TAX UNCOLECTED  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1
		,	@TaxActive int = 0 /* enum eTaxUncollectedStatus: eTaxActive = 1*/
	;

	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	FROM DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	WHERE EXISTS (
		SELECT	*
		FROM '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] WITH(NOLOCK)
		WHERE	[T].[DEAL_TYPE]		= @DealType
			AND [T].[DEAL_NUM]		= [REG].[DEAL_NUM]
			AND [T].[TAX_STATUS]	= @TaxActive 
	)'
	;
	
	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.4. Prepare Deal with Other Tax Account */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1
		,	@CorreCapitAccount int = 1 /* eCapitAccount (1) */
		,	@CorrTaxServices int = 3 /* eTaxServices (3) */

	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]
		,	[C].[CORR_ACCOUNT]
		,	[ACC].[PART_CURRENCY]
		,	[BAL].[ACCOUNT_BEG_DAY_BALANCE]
		,	[ACC].[BLK_SUMA_MIN]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	FROM DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[DEALS_CORR] [C] WITH(NOLOCK)
		ON	[C].[CORR_TYPE]		= @CorrTaxServices
		and	[C].[DEAL_TYPE]		= @DealType
		and [C].[DEAL_NUMBER]	= [REG].[DEAL_NUM]
	INNER JOIN '+@SqlFullDBName+'.dbo.[PARTS] [ACC] WITH(NOLOCK)
		ON	[ACC].[PART_ID]	= [C].[CORR_ACCOUNT]
	CROSS APPLY (
		SELECT CASE WHEN [ACC].[PART_TYPE] IN ( 1, 2, 5 )
				THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
				ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [ACCOUNT_BEG_DAY_BALANCE]
	) [BAL]
	';

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.5. Prepare Deal with Group Sales INDIVIDUAL PROGRAMME */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1
		,	@GSActive int = 1 /* enum eGS_STATUS: GSActive = 1 */
	;
	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]	
		,	[GSI].[PROGRAMME_CODE]					AS [DEAL_GS_INDIVIDUAL_PROGRAM_CODE]
		,	[GSI].[PRODUCT_CODE]					AS [DEAL_GS_INDIVIDUAL_PRODUCT_CODE]
		,	[GSI].[CARDHOLDER_PREMIUM]				AS [DEAL_GS_INDIVIDUAL_CARDHOLDER_PREMIUM]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
	FROM DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[GS_INDIVIDUAL_PROGRAMME] [GSI] WITH(NOLOCK)
		ON	[GSI].[DEAL_TYPE]		= @DealType
		AND [GSI].[DEAL_NUMBER]		= [REG].[DEAL_NUM]
		AND [GSI].[ACTIVITY_STATUS] = @GSActive
	';

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.6. Prepare Deal with WNOS BEL*/
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType 	int = 1
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@REG_VNOS_BEL_BIS6 int = 63 /* #define REG_VNOS_BEL_BIS6 63 */		
	;

	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	WHERE EXISTS (
		SELECT	*
		FROM '+@SqlFullDBName+'.dbo.[TRAITEMS_DAY] [T] WITH(NOLOCK)
		WHERE	[T].[DEAL_NUM]	= [REG].[DEAL_NUM]
			AND [T].[DEAL_TYPE] = @DealType
			AND	[T].[SUM_OPER] > 0
			AND [T].[REG_CODE_DEF] = @REG_VNOS_BEL_BIS6
			AND ([T].[STATUS] & @StsDeleted) <> @StsDeleted
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.7. Prepare Deal with Distraint */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT]
	;

	SELECT @Sql1 = N';
	DECLARE @StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1)	/* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	SELECT	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] 
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK) 
	WHERE EXISTS ( 
		SELECT TOP (1) *  
		FROM '+@SqlFullDBName+'.dbo.BLOCKSUM [B] WITH(NOLOCK) 
		INNER JOIN '+@SqlFullDBName+'.dbo.[NOMS] [N] WITH(NOLOCK) 
			ON	[N].[NOMID] = 136 
			AND [N].[CODE]	= [B].[WHYFREEZED] 
			AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint 
		WHERE	[B].[PARTIDA] = [REG].[DEAL_ACCOUNT] 
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.8. Prepare Deal with DORMUNT ACCOUNT */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType 	int = 1
		,	@StsPART_IsSleepy int = dbo.SETBIT(cast(0 as binary(4)), 22, 1)	/* #define PART_IsSleepy (22) // пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅ пїЅпїЅпїЅпїЅпїЅ(пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ) */
	;

	SELECT	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] 
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK) 
	WHERE EXISTS ( 
		SELECT TOP (1) * 
		FROM '+@SqlFullDBName+'.dbo.[PARTS] [P] WITH(NOLOCK) 
		WHERE	[P].[PART_ID] = [REG].[DEAL_ACCOUNT] 
			AND ([P].[STATUS] & @StsPART_IsSleepy) = @StsPART_IsSleepy 		
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end	

	/* 1.9. Prepare Deals Legal representative */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1 /* Razp deals */
		,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;
	SELECT	[D].[DEAL_TYPE]
		,	[D].[DEAL_NUM]
		,	[CRL].[REPRESENTED_CUSTOMER_ID] 
		,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
		,	[CRL].[CUSTOMER_ROLE_TYPE] 

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK) 
		ON	[CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1	/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] in ( 1 ) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	WHERE ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated /* STS_LIMIT_DEACTIVATED 12 (Деактивиран) */
	';

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 1.10. Prepare Deals Active Proxy Customers */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	;

	SELECT @Sql1 = N'; 
	DECLARE @DealType int = 1 /* Razp deals 1 */
	,	@DateAcc date = '+@AccountDate+'
	,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;
	SELECT	[D].[DEAL_TYPE]
			,	[D].[DEAL_NUM]
			,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
			,	[CRL].[CUSTOMER_ROLE_TYPE]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK) 
		ON	[CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1	/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 ) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	where  ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated 
	and exists
	(
		select * 
		from '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
		inner join '+@SqlFullDBName+'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH(NOLOCK)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
		where	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
			and [PS].[CUSTOMER_ROLE_TYPE]		  = [CRL].[CUSTOMER_ROLE_TYPE] 
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] > @DateAcc )
	)'
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 2. Prepare Customers data */

	/* 2.1 Prepare all duplicate customers EGFN */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
	;	

	SELECT @Sql1 = N';
	SELECT  IDENTITY( INT, 1, 1) AS [ROW_ID] 
		,	CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT) AS [EGFN]
		,	MIN(CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT)) AS [MIN_EGFN]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] 
	FROM '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] WITH (NOLOCK)
	WHERE ISNUMERIC( [C].[IDENTIFIER] ) = 1 
	GROUP BY CAST( RIGHT( RTRIM( [C].[IDENTIFIER] ), 13) AS BIGINT) 
	HAVING COUNT(*) > 1 '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 3
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]  Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 2.2 Prepare Customers data */	
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	;

	set @Sql1 = N'
	;
	WITH [CTE_CUST_ID] AS 
	(
		SELECT [A].[CUSTOMER_ID]
		FROM 
		(
			SELECT DISTINCT CUSTOMER_ID
			FROM dbo.AGR_CASH_PAYMENTS_DEALS WITH(NOLOCK)	
			UNION ALL 
			SELECT DISTINCT REPRESENTATIVE_CUSTOMER_ID
			FROM dbo.AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS WITH(NOLOCK)
		) [A]
		GROUP BY [CUSTOMER_ID]
	)
	SELECT 	IDENTITY( INT, 1, 1) 					AS [ROW_ID] 
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
	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	FROM [CTE_CUST_ID] [F] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] WITH(NOLOCK)
		ON	[F].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	INNER JOIN '+@SqlFullDBName+'.dbo.[DT015_MAINCODE_CUSTID] [M] WITH(NOLOCK)
		ON	[M].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	CROSS APPLY (
		select	CAST( CASE WHEN [C].[IDENTIFIER_TYPE] IN (5,6,7,8) THEN 1 ELSE 0 END AS BIT)
												AS [IS_FUNCTIONAL_ID]
			,	CAST( CASE WHEN [C].[CUSTOMER_TYPE] = 1 THEN 1 ELSE 0 END AS BIT)  
												AS [IS_PHISICAL_PERSON]
			,	CAST( [C].[CUSTOMER_CHARACTERISTIC] as TINYINT )
												AS [CUSTOMER_CHARACTERISTIC]
	) [TYP] 
	CROSS APPLY (
		SELECT	CAST ( 0 AS BIT )				AS [HAS_MANY_CLIENT_CODES]
			,	CAST ( 0 AS BIT )				AS [HAS_DUBL_CLIENT_IDS]
			,	CAST ( 0 AS BIT )				AS [IS_PROXY]
			,	CAST ( 0 AS BIT )				AS [HAS_LOAN]
			,	CAST ( 0 AS BIT )				AS [HAS_VALID_DOCUMENT]
			,	CAST ( 0 AS BIT )				AS [IS_ORIGINAL_EGFN]
	) [EX_BITS]
	'
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.2.1 Create Indexes on [AGR_CASH_PAYMENTS_CUSTOMERS] */
	CREATE INDEX IX_AGR_CASH_PAYMENTS_CUSTOMERS_CUSTOMER_ID
		ON dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] ( [CUSTOMER_ID] )
	;	

	/* 2.3 Prepare Customers with many client codes  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	;

	SELECT @Sql1 = N';
	SELECT	[CUST].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT [CC].[CUSTOMER_ID] 
		FROM '+@SqlFullDBName+'.dbo.[DT015] [CC] WITH(NOLOCK)
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
		GROUP BY [CC].[CUSTOMER_ID] 
		HAVING COUNT(*) > 1
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.4 Prepare Customers with Dubl EGFN  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	;

	SELECT @Sql1 = N';
	SELECT	[C].[CUSTOMER_ID]
		,	[X].[IS_ORIGINAL_EGFN]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] WITH(NOLOCK)
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] [DUBL] WITH(NOLOCK)
		ON [DUBL].[EGFN] = CAST(RIGHT(RTRIM([C].[CLIENT_IDENTIFIER]), 13) AS BIGINT)
	CROSS APPLY (
		SELECT CAST( CASE WHEN [DUBL].[MIN_EGFN] = CAST( [C].[CLIENT_IDENTIFIER] AS BIGINT )
					THEN 1 ELSE 0 END AS BIT)	AS [IS_ORIGINAL_EGFN]
	) [X]'
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.5 Prepare Customers are proxies */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	;

	SELECT @Sql1 = N';
	SELECT	[C].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT *
		FROM '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
		WHERE	[PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
			AND [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
			AND [PS].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 )  /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.6 Prepare Customers with valid IDENTITY DOCUMENTS */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	;

	set @Sql1 = N'
	DECLARE @DateAcc date = '+@AccountDate+'
	;

	SELECT	[C].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT *
		FROM '+@SqlFullDBName+'.dbo.[DT015_IDENTITY_DOCUMENTS] [D] WITH(NOLOCK)
		WHERE	[D].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
			AND [D].[NM405_DOCUMENT_TYPE] IN ( 1, 7, 8  ) /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
			AND ( [D].[INDEFINITELY] = 1 OR [D].[EXPIRY_DATE] > @DateAcc )
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.7 Prepare Customers with Active Loas */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	;

	SELECT @Sql1 = N';
	SELECT	[CUST].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT *
		FROM '+@SqlFullDBName+'.dbo.[KRDREG] [L] WITH(NOLOCK)
		INNER JOIN '+@SqlFullDBName+'.dbo.[DT015] [CC] WITH(NOLOCK)
			ON [L].[CLIENT_CODE] =  [CC].[CODE]
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			AND [L].[DATE_END_KREDIT] < 2 /* Is active loan */
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/**************************************************************/
	/* 3. Update customers: */
	UPDATE [D]
	SET [HAS_MANY_CLIENT_CODES] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D] 
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] [S] with(nolock)
		ON [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	UPDATE [D]
	SET [HAS_DUBL_CLIENT_IDS] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		ON [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	UPDATE [D]
	SET [HAS_LOAN] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] [S] with(nolock)
		ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	UPDATE [D]
	SET [IS_PROXY] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] [S] with(nolock)
		ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	UPDATE [D]
	SET [HAS_VALID_DOCUMENT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] [S] with(nolock)
		ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	UPDATE [D]
	SET [IS_ORIGINAL_EGFN] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		ON	[S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
		AND [S].[IS_ORIGINAL_EGFN] = 1
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: UPDATE bist in [AGR_CASH_PAYMENTS_CUSTOMERS]', @Sql1 = ' UPDATE [AGR_CASH_PAYMENTS_CUSTOMERS] SET [HAS_VALID_DOCUMENT] = 1 WHERE ...' 
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 5. Update deals: */
	UPDATE [D]
	SET [HAS_TAX_UNCOLECTED] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_OTHER_TAX_ACCOUNT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_LEGAL_REPRESENTATIVE] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_PROXY] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_DISTRAINT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_GS_INDIVIDUAL_PROGRAMME] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_WNOS_BEL] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [IS_DORMUNT_ACCOUNT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [PROXY_COUNT] = [S].[CNT]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN 
	(
		SELECT [P].[DEAL_NUM], COUNT(*) AS [CNT]
		FROM dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [P] with(nolock)
		WHERE [P].[DEAL_TYPE] = 1
		GROUP BY [P].[DEAL_NUM]
	) [S]
		ON	[S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [D].[DEAL_TYPE] = 1
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: UPDATE bist in [AGR_CASH_PAYMENTS_DEALS]', @Sql1 = ' UPDATE [AGR_CASH_PAYMENTS_DEALS] SET [HAS_VALID_DOCUMENT] = 1 WHERE ...' 
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
	;

	RETURN 0;
END
GO

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
	;
	select	@RAZPREG_TA_RowID		= [DEAL_ROW_ID]
		,	@DEALS_CORR_TA_RowID	= [CORS_ROW_ID]
		,	@DT015_CUSTOMERS_RowID	= [CUST_ROW_ID]
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

		if @DEALS_CORR_TA_RowID > 0
		begin

			UPDATE [D]
			SET		[DEAL_NUM]				= 0		-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
				,	[CURRENCY]				= '' 	-- DEALS_CORR_TA	CURRENCY	
				,	[UI_CORR_ACCOUNT]		= ''	-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
				,	[TAX_UNCOLLECTED_SUM]	= 0		-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 
			from dbo.[DEALS_CORR_TA] [D]
			where [D].[ROW_ID] = @DEALS_CORR_TA_RowID
			;
		end

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

		UPDATE [D]
		SET		[UI_CUSTOMER_ID]		= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
			,	[UI_EGFN]				= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
			,	[NAME]					= ''		-- DT015_CUSTOMERS_ACTIONS_TA	NAME
			,	[COMPANY_EFN]			= ''		-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
			,	[UI_CLIENT_CODE]		= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
			,	[UI_NOTES_EXIST]		= 0			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
			,	[IS_ZAPOR]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
			,	[ID_NUMBER]				= ''		-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
			,	[SERVICE_GROUP_EGFN]	= ''		-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
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
/* Процедура формираща SQL заявката за търсене на подходяща сделка по ID на тестови случай */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]
(
	@TestCaseRowID nvarchar(16)
,	@CurrAccDate datetime
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql nvarchar(max) = N'', @Sql2 nvarchar(4000) = N'', @CrLf nvarchar(4) = nchar(13) + nchar(10)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]'
	;

	/************************************************************************************************************/
	/* 1.0 Generate Sql for TA Conditions: */
	declare @DateAcc DATE = @CurrAccDate
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
			/* [PROXY_SPEC_TA]: */
		,	@UI_RAZPOREDITEL			int = -1
		,	@UI_UNLIMITED				int = -1
	;
	/* Deal conditions [RAZPREG_TA]: */
	declare @UI_STD_DOG_CODE			int = 0
		,	@UI_INDIVIDUAL_DEAL			int = 0
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
		,	@LIMIT_TAX_UNCOLLECTED_CORS	sysname = '-1'
		/* Conditions [PREV_COMMON_TA]: */
		,	@TAX_CODE					int = -1
		,	@PREF_CODE					sysname = '-1'
		,	@DOC_SUM					float = 0.0
		,	@DOC_TAX_SUM				float = 0.0
	;

	/**********************************************************************************************/

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
		,	@LIMIT_TAX_UNCOLLECTED_CORS	= [LIMIT_TAX_UNCOLLECTED_CORS]
		,	@TAX_CODE					= [TAX_CODE]
		,	@PREF_CODE					= [PREF_CODE]
		,	@DOC_SUM					= [DOC_SUM]
		,	@DOC_TAX_SUM				= [DOC_TAX_SUM]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;

	select @Sql2 = N'select DISTINCT TOP (50) ''ID_'+@TestCaseRowID+'_'+REPLACE(@TA_TYPE,'''','')+ ''''
		+ N' AS [TEST_ID], [DEAL].[DEAL_TYPE], [DEAL].[DEAL_NUM], [CUST].[CUSTOMER_ID], [PROXY].[CUSTOMER_ID] AS [REPRESENTATIVE_CUSTOMER_ID] ' + @CrLf
	insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR], [IS_BASE_select] )
	select	@Sql2,	N'select ...', 1
	;
	select @Sql += @Sql2
	;

	--select @Sql2 = N'select COUNT(*) AS [CNT] '+ @CrLf
	--insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR], [IS_select_COUNT] )
	--select	@Sql2,	'select COUNT(*) ...', 1
	--;
	--select @Sql += @Sql2
	--;

	if (@SECTOR in (5000, 9400) OR (@SECTOR in (7999) AND @DB_CLIENT_TYPE_DT300 IN (4, 6, 7))) /* 4 клиент 'C'; 6 клиент 'E' 7 клиент 'F' */
	begin

		select @Sql2 = N'
		FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [DEAL] WITH (NOLOCK)
		INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] WITH (NOLOCK)
			ON	[CUST].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
			AND [DEAL].[CLIENT_SECTOR] = '+str(@SECTOR,len(@SECTOR),0)+N'
			AND [DEAL].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+ ' ';

		-- 0 - Пълномощник; 1 - Законен представител
		if IsNull(@UI_RAZPOREDITEL,-1) = 0
			select @Sql2 += N'
			INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [PROXY_ID] WITH (NOLOCK)
				ON	[PROXY_ID].[DEAL_NUM] = [DEAL].[DEAL_NUM]
				AND [PROXY_ID].[DEAL_TYPE] = 1
			INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [PROXY] WITH (NOLOCK)
				ON	[PROXY].[CUSTOMER_ID] = [PROXY_ID].[REPRESENTATIVE_CUSTOMER_ID]
			WHERE [CUST].[CLIENT_TYPE_DT300_CODE]		= '+str(@DB_CLIENT_TYPE_DT300,len(@DB_CLIENT_TYPE_DT300),0)+ ' ';
		else 
			select @Sql2 += N'
			INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [PROXY] WITH (NOLOCK)
				ON	[PROXY].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
			WHERE [CUST].[CLIENT_TYPE_DT300_CODE]		= '+str(@DB_CLIENT_TYPE_DT300,len(@DB_CLIENT_TYPE_DT300),0)+ ' ';
	end
	else 
	begin

		select @Sql2 = N'
		FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [DEAL] WITH (NOLOCK)
		INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] WITH (NOLOCK)
			ON	[CUST].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
			AND [DEAL].[CLIENT_SECTOR] = '+str(@SECTOR,len(@SECTOR),0)+N'
			AND [DEAL].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+N'
		INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [PROXY_ID] WITH (NOLOCK)
			ON	[PROXY_ID].[DEAL_NUM] = [DEAL].[DEAL_NUM]
			AND [PROXY_ID].[DEAL_TYPE] = 1
		INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [PROXY] WITH (NOLOCK)
			ON	[PROXY].[CUSTOMER_ID] = [PROXY_ID].[REPRESENTATIVE_CUSTOMER_ID]
		WHERE [CUST].[CLIENT_TYPE_DT300_CODE]		= '+str(@DB_CLIENT_TYPE_DT300,len(@DB_CLIENT_TYPE_DT300),0);

	end

	insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
	select	(@Sql2 + @CrLf), ' BASE WHERE : ' + @Sql2

	select @Sql += @Sql2

	-- enum CustomerSubtypes: (-1) - Без значение; 1 - (над 18г.); 2 - (от 14г. до 18г.); 3 - (до 14г.)
	if  IsNull(@CUSTOMER_AGE, '-1') <> '-1'
	Begin 
		select	@Sql2 = N'AND [PROXY].[CLIENT_BIRTH_DATE] BETWEEN '
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0)+' AND ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0)+' ' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[CUSTOMER_AGE] '+@CUSTOMER_AGE+' - between YEAR : ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0) + ' AND '
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0) + @CrLf;

		select @Sql += @Sql2
	end

	/*****************************************************/
	-- 0 - не е обединяван (клиент с един кл. код); 3 - обединен, без значение дали е бил главен или подчинен (кл.с повече от един кл.код); -1 - без значение
	if @UNIFIED <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_MANY_CLIENT_CODES] = ' + case when @UNIFIED = 0 THEN '0' ELSE '1' END + @CrLf;
		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UNIFIED] : ' + str(@UNIFIED,len(@UNIFIED),0 )

		select @Sql += @Sql2
	end

	-- 0 - Не е служебен или свързан със служебен; 1 - Реално ЕГН, има такива служебни; 2 - служебни ЕГН
	if @IS_SERVICE <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_DUBL_CLIENT_IDS] = ' + case when @IS_SERVICE = 0 then '0' else '1' end + @CrLf;
		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

		select @Sql += @Sql2

		if @IS_SERVICE <> 0
		begin 
			select @Sql2 = ' AND [CUST].[IS_ORIGINAL_EGFN] = ' + case when @IS_SERVICE = 1 then '1' else '0' end + @CrLf;

			insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

			select @Sql += @Sql2
		end 
	end

	-- enum DetailedTypeOfIdentifier : [DT015_CUSTOMERS].[IDENTIFIER_TYPE]
	if IsNull(@CODE_EGFN_TYPE,-1) <> -1
	begin 
		select @Sql2 = ' AND [CUST].[CUSTOMER_CHARACTERISTIC] = ' + str(@CUSTOMER_CHARACTERISTIC,len(@CUSTOMER_CHARACTERISTIC),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_EGFN_TYPE] : ' + str(@CUSTOMER_CHARACTERISTIC,len(@CUSTOMER_CHARACTERISTIC),0 )

		select @Sql += @Sql2
	end 

	-- DT300 
	--if IsNull(@DB_CLIENT_TYPE_DT300,-1) <> -1
	--	select @Sql += ' AND [CUST].[CLIENT_TYPE_DT300_CODE] = ' + str(@DB_CLIENT_TYPE_DT300,len(@DB_CLIENT_TYPE_DT300),0);

	-- 1 - валидни документи
	if IsNull(@VALID_ID,-1) = 1
	begin
		select @Sql2 = ' AND [PROXY].[HAS_VALID_DOCUMENT] = 1' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
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
			select * FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [TA_CUST] WITH(NOLOCK)
			WHERE [TA_CUST].[UI_CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
				AND [TA_CUST].[TA_TYPE] = '+@TA_TYPE+' 
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
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
		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[HAS_LOAN] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end

	-- 0 - Пълномощник; 1 - Законен представител
	if IsNull(@UI_RAZPOREDITEL,-1) <> -1
	begin 
		if @UI_RAZPOREDITEL = 0
		begin
			select @Sql2 = ' AND [DEAL].[PROXY_COUNT] > 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_RAZPOREDITEL] : ' + str(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0 )

			select @Sql += @Sql2
		end

		-- @TODO: @UI_RAZPOREDITEL: трябва да добавим нова таблица с разпоредителите към сделките !!!
		--if  @UI_RAZPOREDITEL = 1
		--begin 
		--	select @Sql2 = ' AND [CUST].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID] AND [DEAL].[CLIENT_SECTOR] IN ( 5000, 9400 ) ' + @CrLf;

		--	insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
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

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_STD_DOG_CODE] : ' + STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0);

		select @Sql += @Sql2
	end 

	--0 - стандартна сделка, 1 - индивидуална сделка
	if IsNull(@UI_INDIVIDUAL_DEAL,-1) IN (0, 1)
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_INDIVIDUAL_DEAL] = '+STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_INDIVIDUAL_DEAL] : ' + STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0);

		select @Sql += @Sql2
	end 

	-- 0 - не е комбиниран продукт, код > 0 - да принадлежи към този комбиниран продукт
	if IsNull(@CODE_UI_NM342, -1) > 0
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NM342_BUNDLE_PRODUCT_CODE] = '+ @CODE_UI_NM342 + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_UI_NM342] : ' + @CODE_UI_NM342;

		select @Sql += @Sql2
	end

	-- 0 - сметката се таксува от себе си, 1 - има друга таксуваща сметка, 2 - без проверка дали има друга таксуваща сметка или се таксува от себе си
	if IsNull(@UI_OTHER_ACCOUNT_FOR_TAX,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_OTHER_TAX_ACCOUNT] = 1' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_OTHER_ACCOUNT_FOR_TAX] : ' + str(@UI_OTHER_ACCOUNT_FOR_TAX,len(@UI_OTHER_ACCOUNT_FOR_TAX),0);

		select @Sql += @Sql2
	end

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_NOAUTOTAX,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NO_AUTO_PAY_TAX] = '+@UI_NOAUTOTAX + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_NOAUTOTAX] : ' + @UI_NOAUTOTAX

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_DENY_MANUAL_TAX_ASSIGN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_DENY_MANUAL_TAX_ASSIGN] = '+@UI_DENY_MANUAL_TAX_ASSIGN + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_DENY_MANUAL_TAX_ASSIGN] : ' + @UI_DENY_MANUAL_TAX_ASSIGN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_CAPIT_ON_BASE_DATE_OPEN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_CAPIT_ON_BASE_DATE_OPEN] = '+@UI_CAPIT_ON_BASE_DATE_OPEN + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_CAPIT_ON_BASE_DATE_OPEN] : ' + @UI_CAPIT_ON_BASE_DATE_OPEN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_BANK_RECEIVABLES,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_EXCLUDE_FROM_BANK_COLLECTIONS] = '+@UI_BANK_RECEIVABLES + @CrLf;
		
		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_BANK_RECEIVABLES] : ' + @UI_BANK_RECEIVABLES

		select @Sql += @Sql2
	end 

	--0 - не е съвместна сделка, 1 - съвместна сделка от тип "по отделно"
	if IsNull(@UI_JOINT_TYPE,-1) in (0, 1)
	begin
		/* enum JointDealsAccessToFundsType: 0 - Separate; 1 - Always Together */	
		if @UI_JOINT_TYPE = 0
		begin 
			select @Sql2 = ' AND [DEAL].[DEAL_IS_JOINT_DEAL] = 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_JOINT_TYPE] : ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0);

			select @Sql += @Sql2
		end 

		if @UI_JOINT_TYPE = 1
		begin 
			select @Sql2 = ' AND [DEAL].[DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] = 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_JOINT_TYPE] : ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0);

			select @Sql += @Sql2
		end 
	end

	-- 0 или долна граница на разполагаемостта ( '<0', '>0' )
	if IsNull(@LIMIT_AVAILABILITY,'0') not in ('0')
	begin 
		select @Sql2 = ' AND ([DEAL].[ACCOUNT_BEG_DAY_BALANCE] - [DEAL].[BLK_SUMA_MIN]) '+@LIMIT_AVAILABILITY + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[LIMIT_AVAILABILITY] : ' + @LIMIT_AVAILABILITY;

		select @Sql += @Sql2
	end 

	-- 1 - активна; Безусловно ще се търсят сделки които НЕ СА ЗАМРАЗЕНИ
	if IsNull(@DEAL_STATUS,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[IS_DORMUNT_ACCOUNT] = 0' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[DEAL_STATUS] : ' +  str(@DEAL_STATUS,len(@DEAL_STATUS),0);

		select @Sql += @Sql2
	end 

	-- 0 - няма несъбрани такси; 1 - има несъбрани такси, -1 без значение от сумата
	if IsNull(@LIMIT_TAX_UNCOLLECTED,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_TAX_UNCOLECTED] = ' + str(@LIMIT_TAX_UNCOLLECTED,len(@LIMIT_TAX_UNCOLLECTED),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
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

			insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 

		if @LIMIT_ZAPOR > 0
		begin
			select @Sql2 = ' AND [DEAL].[HAS_DISTRAINT] = 1 AND [DEAL].[BLK_SUMA_MIN] > '+ STR(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0) + @CrLf;

			insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 
	end

	-- Да укаже дали сметката е кореспондираща до други сделки: -1 няма значение; 0 не е; 1 да , кореспондираща е
	if IsNull(@IS_CORR,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND '+CASE WHEN @IS_CORR = 0 THEN 'NOT' ELSE '' END+ ' EXISTS (
			select * FROM dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [TAX] with(nolock)
			WHERE  [TAX].[CORR_ACCOUNT] =  [DEAL].[DEAL_ACCOUNT]
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_CORR] : ' + str(@IS_CORR,len(@IS_CORR),0);

		select @Sql += @Sql2
	end 

	-- Указва дали РС да е уникална в таблица [RAZPREG_TA]
	if IsNull(@IS_UNIQUE_DEAL,-1) in ( 1 )
	begin 
		select @Sql2 = ' AND NOT EXISTS (
			select * FROM dbo.[RAZPREG_TA] [TA] with(nolock)
			WHERE  [TA].[UI_DEAL_NUM] = [DEAL].[DEAL_NUM]
				AND [TA].[TA_TYPE] = '+@TA_TYPE+' 
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
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
			WHERE	[GS].[DEAL_NUM]	 = [DEAL].[DEAL_NUM]
				AND [GS].[DEAL_TYPE] = 1
				AND [GS].[DEAL_GS_INDIVIDUAL_PROGRAM_CODE] = '+STR(@CODE_GS_PROGRAMME,LEN(@CODE_GS_PROGRAMME),0)+'
				AND [GS].[DEAL_GS_INDIVIDUAL_CARDHOLDER_PREMIUM] = '+STR(@CODE_GS_CARD,LEN(@CODE_GS_CARD),0)+'
				AND [GS].[DEAL_GS_INDIVIDUAL_PRODUCT_CODE] = '+STR(@GS_PRODUCT_CODE,LEN(@GS_PRODUCT_CODE),0)+'
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
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
			WHERE  [TAX].[CORR_ACCOUNT] =  [DEAL].[DEAL_ACCOUNT] ' + @CrLf;

		-- Разполагаемост по сделката 
		if IsNull(@LIMIT_AVAILABILITY_CORS, -1) not in ( '0' )
				select @Sql2 += ' AND ([TAX].[ACCOUNT_BEG_DAY_BALANCE] - [DEAL].[BLK_SUMA_MIN]) '+@LIMIT_AVAILABILITY_CORS;

		select @Sql2 += ')' + @CrLf;

		insert into dbo.[#TBL_SQL_CNDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CCY_CODE_CORS] : ' + str(@CCY_CODE_CORS,len(@CCY_CODE_CORS),0)
				+', [LIMIT_AVAILABILITY_CORS] : ' + @LIMIT_AVAILABILITY_CORS

		select @Sql += @Sql2
	end 

	-- @TODO: @LIMIT_TAX_UNCOLLECTED_CORS:
	-- Несъбрана такса 
	--if IsNull(@LIMIT_TAX_UNCOLLECTED_CORS, -1) not in ( '0' )
	--		select @Sql += ' AND ([TAX].[ACCOUNT_BEG_DAY_BALANCE] - [DEAL].[BLK_SUMA_MIN]) '+@LIMIT_TAX_UNCOLLECTED_CORS;

	if len(@Sql) > 10
	begin 
		select @Sql as [SQL_QUERY]
		select @Msg = 'TA Row ID: ' + @TestCaseRowID + ', successful generated sql query: "'+@Sql+'"'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, @Sql

		BEGIN TRY 
			insert into dbo.[#TBL_RESULT] 
			exec sp_executeSql  @Sql
		END TRY 
		BEGIN CATCH 
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
			return 1
		END CATCH 
	end
		
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]'
	end
	;

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за определяне на критериите който ни пречат да намерим подходяща сделка за датен TestCase */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]
(
	@TestCaseRowID NVARCHAR(16)
,	@CurrAccDate DateTime
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	;

	/************************************************************************************************************/
	/* @TODO: */
	
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	end
	;

	return 0;
end 
go


/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@DEAL_NUM				INT
,	@DEAL_CORS_ACCOUNT		VARCHAR(33)
)
AS 
BEGIN

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @@DEAL_CORS_ACCOUNT = '+@DEAL_CORS_ACCOUNT
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(RTRIM(@OnleneSqlServerName),1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnleneSqlDataBaseName),1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
	;
	/************************************************************************************************************/
	/* 3. Load Deals data from OlineDB; @TODO: */
	;

	select @Sql1 = N'
	DECLARE @StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	select xxx from xxx
	';

	if @LogTraceInfo = 1 select @Sql1 as [LOAD_ONLINE_CORS_INFO];

	begin try
		exec sp_executeSql @Sql1
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
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @@DEAL_CORS_ACCOUNT = '+@DEAL_CORS_ACCOUNT
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end
	;

	return 0;
END 
GO

/********************************************************************************************************/
/* Процедура за зареждане на Данни за сделка от OnLineDB по номер */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_DATA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@DEAL_TYPE INT
,	@DEAL_NUM INT
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0,	@Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(RTRIM(@OnleneSqlServerName),1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnleneSqlDataBaseName),1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
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
		,	[II].[IBAN]
		,	[BAL].[BEG_SAL]
		,	[BAL].[DAY_MOVE]
		,	[ACC].[BLK_SUMA_MIN]
		,	[BAL].[RAZPOL]
		,	[BAL].[TAX_UNCOLLECTED_SUM]
		,	[BAL].[DISTRAINT_SUM]
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
		select SUM( [T].[AMOUNT] - [T].[COLLECTED_AMOUNT] ) AS [TAX_UNCOLLECTED_SUM]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		WHERE	[T].[ACCOUNT_DT] = [REG].[ACCOUNT]
			/* AND [T].[DEAL_TYPE]	= @DealType */
			/* AND [T].[DEAL_NUM]	= [REG].[DEAL_NUM] */
			AND [T].[TAX_STATUS] =  0
	) [TAX]
	outer apply (
		SELECT SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
		FROM '+@SqlFullDBName+'.dbo.BLOCKSUM [B] with(nolock)
		INNER JOIN '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock)
			ON	[N].[NOMID] = 136 
			AND [N].[CODE]	= [B].[WHYFREEZED] 
			AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint 
		WHERE [B].[PARTIDA] = [REG].[ACCOUNT] 
	) [DST]
	cross apply (
		SELECT	ROUND([XBAL].[BEG_SAL], 4) AS [BEG_SAL]
			,	ROUND([XBAL].[DAY_MOVE], 4)  AS [DAY_MOVE]
			,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [RAZPOL]
			,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4) as [DISTRAINT_SUM]
			,	ROUND(IsNull([TAX].[TAX_UNCOLLECTED_SUM],0), 4) as [TAX_UNCOLLECTED_SUM]
	) [BAL]
	where [REG].[DEAL_NUM] = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

	begin try
		exec sp_executeSql @Sql1
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
		select	@Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end
	;

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура за зареждане на Клиентски данни от OnLineDB по CustomerID */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_CLIENT_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_CLIENT_DATA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@CurrentAccountDate		datetime
,	@CUSTOMER_ID			INT
)
AS 
BEGIN

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @CUSTOMER_ID = ' + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CLIENT_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(RTRIM(@OnleneSqlServerName),1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnleneSqlDataBaseName),1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
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
		from '+@SqlFullDBName+'.dbo.CUSTOMERS_RIGHTS_AND_LIMITS [CRL] WITH(NOLOCK)
		inner join '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
			on	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
		inner join '+@SqlFullDBName+'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH(NOLOCK)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] >= '+@AccountData+')
		where [CRL].REPRESENTED_CUSTOMER_ID = [CUST].[CUSTOMER_ID]
			and [CRL].[CHANNEL] = 1	
	) [PR]
	outer apply (																					
		select top (1) cast( 1 as bit) as [HAS_POPUP_NOTE]
		from '+@SqlFullDBName+'.dbo.[DT015_NOTES] [n] with(nolock)
		where	[n].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [n].[CLIENT_NOTETYPE] = 1 /* enum ClientNoteType : ClientNoteTypeExtraData = 1 */
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
		exec sp_executeSql @Sql1
	end try
	begin CATCH 
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
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @CUSTOMER_ID = ' + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CLIENT_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', CUSTOMER_ID: ' +  + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end
	;

	return 0;
END 
GO

/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[DEALS_CORR_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@CUSTOMER_ID			int
,	@PROXY_ID				int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql2 nvarchar(4000) = N'',	@TA_RowID int = cast( @TestCaseRowID as int)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]'
	;

	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(@OnleneSqlServerName,1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(@OnleneSqlDataBaseName,1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)		

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
	;
	/************************************************************************************************************/
	-- TODO: UPDATE [DEALS_CORS_TA] 
	declare @TBL_ROW_ID int = 0, @DealRowID int = 0
		,	@CorrAccount varchar(64), @CorrAccCurrency varchar(8) = 'BGL'
	;
	select	@DealRowID = [DEAL_ROW_ID]
		,	 @TBL_ROW_ID = [CORS_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found correspondence from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	;
	with [CTE_CCY] as 
	(
		select [X].*
		from ( 
			values	( 36,	'AUD' )	,	(100,	'BGN' )	,	(124,	'CAD' )	,	(756,	'CHF' )
				,	(826,	'GBP' )	,	(840,	'USD' )	,	(946,	'RON' )	,	(978,	'EUR' )
		) X([ID], [NAME])		
	)
	select	@CorrAccount = [CORR_ACCOUNT]
		,	@CorrAccCurrency = IsNull([CCY].[NAME], 'BGN')
	from [dbo].[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [C] with(nolock)
	OUTER APPLY( 
		select [NM].*
		from [CTE_CCY] [NM]
		where [NM].[ID] = [C].[PART_CURRENCY]
	) [CCY]
	where [DEAL_TYPE] = 1 AND [DEAL_NUM] = @DEAL_NUM
	;

	select @DEAL_NUM as [DEAL_NUM], 0 as [TAX_UNCOLLECTED], @CorrAccCurrency as [CCY], @CorrAccount as [ACC], @DealRowID as [DEAL_ROW_ID]
	;
	SELECT [DEAL_NUM], [TAX_UNCOLLECTED_SUM], [CURRENCY], [UI_CORR_ACCOUNT], [ROW_ID]
	FROM dbo.[DEALS_CORR_TA] [D]
	WHERE [D].[ROW_ID] = @TBL_ROW_ID
	;

	/* Update data in table [DEALS_CORR_TA] */
	if @WithUpdate = 1
	begin
		UPDATE [D]
		SET [DEAL_NUM]				= @DEAL_NUM			-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
		,	[CURRENCY]				= @CorrAccCurrency	-- DEALS_CORR_TA	CURRENCY	
		,	[UI_CORR_ACCOUNT]		= @CorrAccount		-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
		,	[TAX_UNCOLLECTED_SUM]	= 0					-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 
--		,	[DEAL_ROW_ID] =  @DealRowID					-- /* Това ще ви трябва ли */
		from dbo.[DEALS_CORR_TA] [D]
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
/* Процедура за актуализация на Таблица dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@CUSTOMER_ID			int
,	@PROXY_ID				int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql2 nvarchar(4000) = N''
		,	@TA_RowID int = cast ( @TestCaseRowID as int );
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]'
	;

	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(@OnleneSqlServerName,1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(@OnleneSqlDataBaseName,1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)		

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
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
	-- TODO: UPDATE [RAZPREG_TA]: 
	drop table if exists dbo.[#TBL_ONLINE_DEAL_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEAL_INFO]
	(
		[DEAL_NUM]			int
	,	[ACCOUNT]			varchar(64)
	,	[IBAN]				varchar(64)
	,	[BEG_SAL]			float
	,	[DAY_MOVE]			float
	,	[BLK_SUMA_MIN]		float
	,	[RAZPOL]			float
	,	[TAX_UNCOLLECTED]	float
	,	[DISTRAINT_SUM]		float
	);


	begin try
		insert into dbo.[#TBL_ONLINE_DEAL_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @DEAL_TYPE, @DEAL_NUM
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()

			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName = '+@OnleneSqlServerName+' '
								+ ', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+' '
								+ ', @DEAL_TYPE = 1, @DealNum = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg

			return 2
	end catch

	if @Ret <> 0
		return 3;

	if @LogTraceInfo = 1 select * from dbo.[#TBL_ONLINE_DEAL_INFO]  with(nolock)
	;

	/* Update data in [RAZPREG_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_DEAL_NUM]			= [S].[DEAL_NUM]				-- RAZPREG_TA	UI_DEAL_NUM	
			,	[DB_ACCOUNT]			= [S].[ACCOUNT]					-- RAZPREG_TA	DB_ACCOUNT	
			,	[UI_ACCOUNT]			= [S].[ACCOUNT]					/* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
			,	[ZAPOR_SUM]				= STR([S].[DISTRAINT_SUM],14,2)	-- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
			,	[IBAN]					= [S].[IBAN]					-- RAZPREG_TA	IBAN	
			,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]			-- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
		FROM dbo.[RAZPREG_TA] [D]
		INNER JOIN  dbo.[#TBL_ONLINE_DEAL_INFO] [S] WITH(NOLOCK)
			ON [S].[DEAL_NUM] = @DEAL_NUM
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

/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@CurrAccountDate		datetime
,	@TestCaseRowID			nvarchar(16)
,	@Customer_ID			int
,	@PROXY_ID				int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
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
	declare @TBL_ROW_ID int = 0
	;
	select	@TBL_ROW_ID = [CUST_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID
	;

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found Customer from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
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
		exec  @Ret = dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccountDate, @Customer_ID
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnleneSqlServerName = '+@OnleneSqlServerName+' '
								+ ', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+' '
								+ ', @Customer_ID = '+str(@Customer_ID,len(@Customer_ID),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 2;
	end catch

	if @Ret <> 0 
		return 3;

	if @LogTraceInfo = 1 select * from dbo.[#TBL_ONLINE_DT015_INFO] with(nolock)
	;

	/* Тези данни ще ги заредим от вече 'кешираниет'  */
	declare @IS_ZAPOR int = 0,	@SERVICE_GROUP_EGFN varchar(16) = N''
	;
	/* Дали клиента има запори по някоя от сделките: */
	select top(1) @IS_ZAPOR = 1 
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D] with(nolock)
	where [D].[CUSTOMER_ID] =  @CUSTOMER_ID
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
	where [CUST].[CUSTOMER_ID] = @CUSTOMER_ID

	select @ClientIdentifier, @HasDublClientIDs, @IsOrioginalID

	if @HasDublClientIDs = 1
	begin
		set @SERVICE_GROUP_EGFN = @ClientIdentifier;

		if @IsOrioginalID = 0
		begin
			select top(1) @SERVICE_GROUP_EGFN = [EGFN]
			from [AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] with(nolock)
			where [EGFN] = CAST(RIGHT(RTRIM(@ClientIdentifier), 13) AS BIGINT)
		end
	end 

	/* Update data in [RAZPREG_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_CUSTOMER_ID]	= [S].[CUSTOMR_ID]				 -- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
			,	[UI_EGFN]			= [S].[UI_EGFN]					 -- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
			,	[NAME]				= [S].[NAME]					 -- DT015_CUSTOMERS_ACTIONS_TA	NAME
			,	[COMPANY_EFN]		= [S].[COMPANY_EFN]				 -- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
			,	[UI_CLIENT_CODE]	= [S].[UI_CLIENT_CODE]			 -- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
			,	[UI_NOTES_EXIST]	= IsNull([S].[UI_NOTES_EXIST],0) -- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
			,	[IS_ZAPOR]			= @IS_ZAPOR						 -- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
			,	[ID_NUMBER]			= IsNull([S].[ID_NUMBER], '')	 -- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
			,	[SERVICE_GROUP_EGFN]= @SERVICE_GROUP_EGFN			 -- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
			,	[IS_ACTUAL]			= [S].[IS_ACTUAL]				 -- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1; 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
			,	[PROXY_COUNT]		= IsNull([S].[PROXY_COUNT],0)	 -- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
		from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
		inner join dbo.[#TBL_ONLINE_DT015_INFO] [S] with(nolock)
			on [S].[CUSTOMR_ID] = @CUSTOMER_ID
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
GO

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

	declare @LogTraceInfo int = 1
		,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
	;

	declare @LogSqlCondition int = 0, @LogResultTable int = 0
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql nvarchar(max) = N'', @Sql1 nvarchar(4000) = N''
		,	@RowId int = IsNull(@TestCaseRowID, -1), @RowIdStr nvarchar(8) = STR(@TestCaseRowID,LEN(@TestCaseRowID),0)
	;

	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @RowIdStr, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES]'
	;

	/************************************************************************************************************/
	/* 1. Find TA Conditions: */
	drop table if EXISTS dbo.[#TBL_TA_CONDITIONS]
	;

	select [V].*
	into dbo.[#TBL_TA_CONDITIONS] 
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [V] with(nolock) where [V].[ROW_ID] = @RowId;

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[#TBL_TA_CONDITIONS], Rows affected: ' + STR(@Rows ,LEN(@Rows),0)
			,	@Sql1 = N'SELECT * INTO dbo.[#TBL_TA_CONDITIONS] FROM FROM dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [V] WHERE [V].[ROW_ID] = ' + @RowIdStr
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end 

	/*********************************************************************************************************/
	/* 2. Get Account Date */
	declare @CurrAccDate datetime = 0
		,	@AccountDate sysname = N''
		,	@DB_TYPE sysname = N'BETA', @DB_ALIAS sysname = N'VCS_OnlineDB'
		,	@OnleneSqlServerName sysname = N'', @OnleneSqlDataBaseName sysname = N''
	;

	select @OnleneSqlServerName		= [SERVER_INSTANCE_NAME]
		,	@OnleneSqlDataBaseName	= [DATABASE_NAME]
	from dbo.[TEST_AUTOMATION_DATASOURCES] [DS] with(nolock)
	where UNIQUE_ALIAS = @DB_ALIAS
	;

	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(@OnleneSqlServerName,1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	if LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(@OnleneSqlDataBaseName,1) <> N'['
		select @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)		

	begin try
		exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate OUT
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return -1
	end catch 

	select @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
	;

	/*********************************************************************************************************/
	/* 3. Cleate data before upatede table: dbo.DEALS_CORR_TA; dbo.RAZPREG_TA; dbo.DT015_CUSTOMERS_ACTIONS_TA */
	Begin Transaction tr0;

	begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]  @RowIdStr
	end try 	
	begin catch

		if @@TRANCOUNT > 0 
			Rollback Transaction tr0;

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] @RowIdStr = '+@RowIdStr;

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return 2;
	end catch

	if @@TRANCOUNT > 0
	begin 
		if @Ret <> 0 Rollback Transaction tr0;
		else		 Commit Transaction tr0;
	end 

	/*********************************************************************************************************/
	/* 4. Prepare Sql Conditions: */
	drop table if EXISTS dbo.[#TBL_SQL_CONDITIONS]
	;
	create table dbo.[#TBL_SQL_CNDITIONS]
	(
		[ID] INT IDENTITY(1,1)
	,	[SQL_COND] nvarchar(1000)
	,	[DESCR] nvarchar(2000)
	,	[IS_BASE_SELECT] BIT DEFAULT(0)
	,	[IS_SELECT_COUNT] BIT DEFAULT(0)
	)
	;

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
			,	@Sql1 = N'exec dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS] '+@RowIdStr+', '+@AccountDate+N''
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	if @LogResultTable = 1 select * from dbo.[#TBL_RESULT] with(nolock);

	if @LogSqlCondition = 1 select * from dbo.[#TBL_SQL_CNDITIONS] with(nolock);

	--EXEC @Ret = dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL] @RowIdStr, @CurrAccDate, @Sql
	--begin 
	--	select  @Msg = N'Error Execute procedure dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL], Online Accoun Date: ' +@AccountDate
	--		,	@Sql1 = N'exec dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL] '+@RowIdStr+', '+@AccountDate+' '
	--	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	--end

	declare @DealNum int = 0, @CustomerID int = 0, @ProxyID int = 0, @WithUpdate int = 1
	;

	select	@DealNum	= [DEAL_NUM]
		,	@CustomerID	= [CUSTOMER_ID]
		,	@ProxyID	= [REPRESENTATIVE_CUSTOMER_ID]
	from dbo.[#TBL_RESULT] with(nolock);

	select @Rows = (select count(*) from dbo.[#TBL_RESULT] with(nolock))

	if @Rows <= 0 or IsNull(@DealNum,0) <=0 or IsNull(@CustomerID,0) <= 0
	begin
		select @Msg = 'Not found suitable deal from Test Case with [ROW_ID]: ' + @RowIdStr;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @RowIdStr, @Msg
		return 1;
	end

	/******************************************************************************************************/
	/* 5. Update data in tables: dbo.[DEALS_CORR_TA]; dbo.[RAZPREG_TA]; dbo.[DT015_CUSTOMERS_ACTIONS_TA] */
	Begin Transaction tr1;

	/******************************************************************************************************/
	/* 5.1. Updare table dbo.[DEALS_CORR_TA] */
	begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]  @OnleneSqlServerName, @OnleneSqlDataBaseName
			, @RowIdStr, 1, @DealNum, @CustomerID, @ProxyID, @WithUpdate
	end try 	
	begin catch

		if @@TRANCOUNT > 0 
			Rollback Transaction tr1;

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

		return 3;
	end catch 

	/******************************************************************************************************/
	/* 5.2. Updare table  dbo.[RAZPREG_TA] */
	begin try
			exec dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]  @OnleneSqlServerName, @OnleneSqlDataBaseName
			, @RowIdStr, 1, @DealNum, @CustomerID, @ProxyID, @WithUpdate
	end try 	
	begin catch

		if @@TRANCOUNT > 0 
			Rollback Transaction tr1;

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

		return 4;
	end catch 

	/******************************************************************************************************/
	/* 5.3. Updare table  dbo.[DT015_CUSTOMERS_ACTIONS_TA] */
	begin try
			exec dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA]  @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate
			, @RowIdStr, @CustomerID, @ProxyID, @WithUpdate
	end try
	begin catch 

		if @@TRANCOUNT > 0
			Rollback Transaction tr1;

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

		return 5;
	end catch

	if @@TRANCOUNT > 0
		commit transaction tr1;

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
