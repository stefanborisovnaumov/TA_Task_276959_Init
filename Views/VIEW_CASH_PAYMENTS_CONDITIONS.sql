
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

		/* Условия за пълномощника dbo.[PROXY_SPEC_TA] */
		,	[PSPEC].[UI_RAZPOREDITEL]						AS [UI_RAZPOREDITEL]
		,	[PSPEC].[UI_UNLIMITED]							AS [UI_UNLIMITED]

		/* Условия за сделката dbo.[RAZPREG_TA] */
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

		/* Условия за кореспондиращи сметки dbo.[DEALS_CORR_TA] */
		,	[CORS].[CURRENCY]								AS [CURRENCY_CORS]
		,	[CCY_CORS].[CCY_CODE_CORS]						AS [CCY_CODE_CORS]
		,	[CORS].[LIMIT_AVAILABILITY]						AS [LIMIT_AVAILABILITY_CORS]
/*		,	[CORS].[LIMIT_TAX_UNCOLLECTED]					AS [LIMIT_TAX_UNCOLLECTED_CORS] */

			/* [PROXY_ACC_TA] */
/*		,	[PROXY_ACC_TA]  Пълномощника, да има права за действието по избраната сметка */

			/* Условия за вносната бележка [PREV_COMMON_TA] */
		,	[PREV].RUNNING_ORDER							AS [RUNNING_ORDER]
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
