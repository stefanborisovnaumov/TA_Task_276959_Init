DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_TEST_CASES]
GO

CREATE PROCEDURE  dbo.[SP_CASH_PAYMENTS_UPDATE_TEST_CASES]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,   @TestAutomationType		sysname = N'%CashPaymentCA%BETA%'
,	@TestCaseTowId			int	= null
,	@LogTraceInfo			int = 0    
)
AS 
BEGIN
	SELECT @LogTraceInfo = 1

	DECLARE @Sql varchar(max) = N'', @Msg nvarchar(max) = N''
		,	@Rows int = 0, @Err int = 0, @TimeBeg DateTime = GetDate()
		, 	@SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
	;

    if @LogTraceInfo = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @SqlFullDBName, ' *** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TEST_CASES]'
	;

	/************************************************************************************************************/
	/* 1. Init nomenclatures: */
	/* 1.1 enum DetailedTypeOfIdentifier : [DT015_CUSTOMERS].[IDENTIFIER_TYPE] */
	DROP TABLE IF EXISTS #TBL_CUST_ID_TYPE 
	;	

	SELECT [X].*
	INTO #TBL_CUST_ID_TYPE 
	FROM ( 
		VALUES	( 1 , 'ЕГН' )
				, ( 2 , 'ЕИК/БУЛСТАТ' )
				, ( 3 , 'БАЕ' )
				, ( 4 , 'ЛНЧ' )
				, ( 5 , 'Функцоинално ЕГН' )
				, ( 6 , 'Функционално ЛНЧ (ЧФЛ)' )
				, ( 7 , 'Функционално ЕИК (МЮЛ)' ) 
				, ( 8 , 'Функционално ЕИК (ЧЮЛ)' )
				, ( 9 , 'Идентификатор за клиенти по ЗЗКИ' )
	) X([ID], [NAME])
	;

	/* 1.2 Подвид клиент: enum CustomerSubtypes: */
	DROP TABLE IF EXISTS #TBL_Customer_Subtypes
	;	

	SELECT [X].*
	INTO #TBL_Customer_Subtypes 
	FROM ( 
		VALUES	
		  ( 1,	'Пълнолетно физическо лице (над 18г.)' )
		, ( 2,	'Непълнолетно физическо лице (от 14г. до 18г.)' )
		, ( 3,	'Малолетно физическо лице (до 14г.)' )
		, ( 4,	'Външен клиент' )
	) X([ID], [NAME])
	;

	/************************************************************************************************************/
	/* 2.1. Prepare conditions table */
	DROP TABLE IF EXISTS #TBL_TA_CONDITIONS
	;

	SELECT	[PREV].ROW_ID							AS [PREV_ROW_ID]
		,	[CUST].[ROW_ID]							AS [CUST_ROW_ID]
		,	[DREG].ROW_ID							AS [DEAL_ROW_ID]
		,	[CORS].[ROW_ID]							AS [DREAL_CORRS_ROW_ID]		
		,	[PREV].[PROXY_ROW_ID]					AS [PREV_PROXY_ROW_ID]
		,	[PREV].TA_TYPE							AS [PREV_TA_TYPE]

		,	[CUST].[SECTOR]							AS [CUST_CND_SECTOR]
		,	[DREG].UI_STD_DOG_CODE					AS [DEAL_CND_UI_STD_DOG_CODE]
		,	[DREG].UI_CURRENCY_CODE					AS [DEAL_CND_UI_CURRENCY_CODE]

			/* DT015_CUSTOMERS */
		,	[CUST].[UNIFIED]						AS [CUST_CND_UNIFIED]
		,	[CUST].[IS_SERVICE]						AS [CUST_CND_IS_SERVICE]
		,	[CUST].[EGFN_TYPE]						AS [CUST_CND_EGFN_TYPE]
		,	[CUST].[DB_CLIENT_TYPE]					AS [CUST_CND_DB_CLIENT_TYPE_DT300]
		,	[CUST].[VALID_ID]						AS [CUST_CND_VALID_ID]	
		,	[CUST].[CLIENT_SUBTYPE]					AS [CUST_CND_CLIENT_SUBTYPE]
		,	[CUST].[PROXY_COUNT]					AS [CUST_CND_PROXY_COUNT]
		,	[CUST].IS_PROXY							AS [CUST_CND_IS_PROXY]
		,	[CUST].IS_UNIQUE						AS [CUST_CND_IS_UNIQUE]
		,	[CUST].[HAVE_CREDIT]					AS [CUST_CND_HAVE_CREDIT]
			/* Conditions ? */
		,	[CUST].IS_ZAPOR							AS [CUST_IS_ZAPOR]
		,	[CUST].LEGAL_KIND						AS [CUST_LEGAL_KIND]

			/* PROXY_SPEC */
		,	[PSPEC].PROXY_CLIENT_ID					AS [PSPEC_PROXY_CLIENT_ID]
		,	[PSPEC].UI_RAZPOREDITEL					AS [PSPEC_CND_UI_RAZPOREDITEL]
		,	[PSPEC].UI_UNLIMITED					AS [PSPEC_CND_UI_UNLIMITED]
			/* Conditions ? */
		,	[PSPEC].UI_TAKE_BACK					AS [PSPEC__UI_TAKE_BACK]

			/* RAZPREG */
		,	[DREG].UI_INDIVIDUAL_DEAL				AS [DEAL_CND_UI_INDIVIDUAL_DEAL]
		,	[DREG].UI_NM342_CODE					AS [DEAL_CND_UI_NM342_CODE]
		,	[DREG].UI_OTHER_ACCOUNT_FOR_TAX			AS [DEAL_CND_UI_OTHER_ACCOUNT_FOR_TAX]
		,	[DREG].UI_NOAUTOTAX						AS [DEAL_CND_UI_NOAUTOTAX]
		,	[DREG].UI_DENY_MANUAL_TAX_ASSIGN		AS [DEAL_CND_UI_DENY_MANUAL_TAX_ASSIGN]
		,	[DREG].UI_CAPIT_ON_BASE_DATE_OPEN		AS [DEAL_CND_UI_CAPIT_ON_BASE_DATE_OPEN]
		,	[DREG].UI_BANK_RECEIVABLES				AS [DEAL_CND_UI_BANK_RECEIVABLES]
		,	[DREG].UI_JOINT_TYPE					AS [DEAL_CND_UI_JOINT_TYPE]
		,	[DREG].LIMIT_AVAILABILITY				AS [DEAL_CND_LIMIT_AVAILABILITY]
		,	[DREG].DEAL_STATUS						AS [DEAL_CND_DEAL_STATUS]
		,	[DREG].LIMIT_TAX_UNCOLLECTED			AS [DEAL_CND_LIMIT_TAX_UNCOLLECTED]
		,	[DREG].LIMIT_ZAPOR						AS [DEAL_CND_LIMIT_ZAPOR]
		,	[DREG].IS_CORR							AS [DEAL_CND_IS_CORR]
		,	[DREG].IS_UNIQUE						AS [DEAL_CND_IS_UNIQUE]
		,	[DREG].GS_PROGRAMME_CODE				AS [DEAL_CND_GS_PROGRAMME_CODE]
		,	[DREG].GS_CARD_PRODUCT					AS [DEAL_CND_GS_CARD_PRODUCT]
		,	[DREG].GS_PRODUCT_CODE					AS [DEAL_CND_GS_PRODUCT_CODE]
			/* Conditions ? */
		,	[DREG].UI_TAX_FOR_CREATE				AS [DEAL_UI_TAX_FOR_CREATE]
		,	[DREG].TAX_UNCOLLECTED_SUM				AS [DEAL_TAX_UNCOLLECTED_SUM]
		,	[DREG].UI_INDIVIDUAL_COMBINATION_FLAG	AS [DEAL_UI_INDIVIDUAL_COMBINATION_FLAG]


		,	[PREV].RUNNING_ORDER					AS [PREV_CND_RUNNING_ORDER]
		,	[PREV].TAX_CODE							AS [PREV_CND_TAX_CODE]
		,	[PREV].REF_ID							AS [PREV_REF_ID]
			/* Conditions ? */						
		,	[PREV].UI_SUM							AS [PREV_UI_SUM]	
		,	[PREV].UI_OSN1							AS [PREV_UI_OSN1]
		,	[PREV].UI_OSN2							AS [PREV_UI_OSN2]
		,	[PREV].UI_TAX							AS [PREV_UI_TAX]
		,	[PREV].UI_CASH_COMMISSION				AS [PREV_UI_CASH_COMMISSION]
		,	[PREV].UI_UNSORTED_BANKNOTES			AS [PREV_UI_UNSORTED_BANKNOTES]
		,	[PREV].UI_ALBUM_CODE					AS [PREV_UI_ALBUM_CODE]
		,	[PREV].UI_PREVIEW_DOC_PRINT				AS [PREV_UI_PREVIEW_DOC_PRINT]
		,	[PREV].ZMIP								AS [PREV_ZMIP]
		,	[PREV].PREF_CODE						AS [PREV_PREF_CODE]
		,	[PREV].TAX_SUM							AS [PREV_TAX_SUM]

			/* DEALS_CORR */
		,	[CORS].DEAL_ROW_ID						AS [DREAL_CND_CORRS_DEAL_ROW_ID]
		,	[CORS].UI_CORR_TYPE						AS [DREAL_CND_CORRS_UI_CORR_TYPE]

	INTO #TBL_TA_CONDITIONS
	FROM dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
	INNER JOIN dbo.[RAZPREG_TA] [DREG] WITH(NOLOCK)
		on [PREV].REF_ID = [DREG].ROW_ID
	INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
		on [DREG].REF_ID = [CUST].ROW_ID
	LEFT JOIN dbo.[DEALS_CORR_TA] [CORS] WITH(NOLOCK)
		on [CORS].REF_ID = [DREG].ROW_ID		
	LEFT JOIN dbo.[PROXY_SPEC_TA] as [PSPEC] WITH(NOLOCK)
		on [CUST].ROW_ID =[PSPEC].REF_ID
	WHERE [PREV].[TA_TYPE] LIKE @TestAutomationType
		AND [PREV].[ROW_ID] = IsNull( @TestCaseTowId,  [PREV].[ROW_ID] )
		/* TEST TEST TEST TEST */
		AND [CUST].[SECTOR] IN ( 5000, 9400 )
		AND [CUST].[IS_PROXY] = 0
	;

	/* Обединени клиент: CUST_CND_UNIFIED = 3*/
	SELECT * FROM #TBL_TA_CONDITIONS WITH(NOLOCK)
	WHERE [CUST_CND_UNIFIED] = 3
	ORDER BY CAST( [DEAL_CND_UI_STD_DOG_CODE] AS INT) 
		,	[CUST_CND_SECTOR] 	
	;

	SELECT @Rows = @@ROWCOUNT, @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin
		select @Msg = N'After: INSERT INTO [#TBL_TA_CONDITIONS], Rows Affected: '+ str(@Rows,len(@Rows),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestAutomationType, @Msg
	end
	;

	select * from [AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN [AGR_CASH_PAYMENTS_CUSTOMERS] [C]
		ON [D].[DEAL_CUSTOME] = [C].[C]

	/******************************************************************************/
	/* Update dbo.[PREV_COMMON_TA] .... */
    -- SELECT * FROM PREV_COMMON_TA [P] with(nolock)
	-- INNER JOIN #TBL_TA_CONDITIONS [F] with(nolock)
	-- 	ON  [P].[ROW_ID] = [F].[PREV_ROW_ID]

	/******************************************************************************/
	/* Update dbo.[RAZPREG_TA] .... */
    -- SELECT * FROM RAZPREG_TA [D] with(nolock)
	-- INNER JOIN #TBL_TA_CONDITIONS [F] with(nolock)
	-- 	ON  [D].[ROW_ID] = [F].[DEAL_ROW_ID]

	/******************************************************************************/
	/* Update dbo.[DT015_CUSTOMERS_ACTIONS_TA] .... */
    -- SELECT * FROM DT015_CUSTOMERS_ACTIONS_TA [C] with(nolock)
	-- INNER JOIN #TBL_TA_CONDITIONS [F] with(nolock)
	-- 	ON  [C].[ROW_ID] = [F].[CUST_ROW_ID]

	if @LogTraceInfo = 1 
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', Fileter: ' + @TestAutomationType;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TEST_CASES]'
	end
	;
END
GO

EXEC dbo.[SP_CASH_PAYMENTS_UPDATE_TEST_CASES] 'YYANKOV\SQL2016', 'BPB_VCSBank_Online'
GO

