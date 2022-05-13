DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_CLEARE_TEST_CASE]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_CLEARE_TEST_CASE]
(
	@RowID			INT = -1
,	@TA_TYPE_LIKE	nvarchar(126) = N'CashPayment%Beta%'
)
as 
begin

	if IsNull( @RowID, - 1) < 0 and Len(Ltrim(Rtrim(IsNull(@TA_TYPE_LIKE, '')))) < 5
	begin
		print ('Incorrect input parameters: @RowID < 0 and LEN(@TA_TYPE_LIKE) < 5 ');
		return -1;
	end 

	Declare @TaTypeCashPaymentBeta nvarchar(126) = N'CashPayment%Beta%'
		,	@RecordID int = IsNull( @RowID, -1 )
	;

	DROP TABLE IF EXISTS #TBL_PRIMARY_KEY_IDS
	;
	
	SELECT	[PREV].[ROW_ID]			AS [PREV_ROW_ID]
		,	[REG].[ROW_ID]			AS [DEAL_ROW_ID]
		,	[CUST].[ROW_ID]			AS [CUST_ROW_ID]
		,	[PREV].[PROXY_ROW_ID]	AS [PROXY_ROW_ID_FROM_PREV]
		,	[PSEC].PROXY_CLIENT_ID	AS [PROXY_CLIENT_ID]
		,	[PROXY].[ROW_ID]		AS [PROXY_ROW_ID]
		,	[CORS].[ROW_ID]			AS [CORS_ROW_ID]
	INTO #TBL_PRIMARY_KEY_IDS
	FROM dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
	/* Сделки */
	INNER JOIN [RAZPREG_TA] [REG] WITH(NOLOCK)
		ON [REG].[ROW_ID] = [PREV].[REF_ID]
	/* Титуляр */
	INNER JOIN [DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
		ON	[CUST].[ROW_ID] = [REG].[REF_ID]
		AND [CUST].[IS_PROXY] = 0
		AND [PREV].[TA_TYPE] LIKE @TaTypeCashPaymentBeta	/* TODO: Remove this !!! */ 
	/* Пълномощник */
	LEFT OUTER JOIN dbo.[PROXY_SPEC_TA] [PSEC] WITH(NOLOCK)
		ON [PSEC].[REF_ID] = [CUST].[ROW_ID]
	/* Данни за пълномощника */
	LEFT OUTER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [PROXY] WITH(NOLOCK)
		ON	[PROXY].[ROW_ID] = [PSEC].[PROXY_CLIENT_ID]
		AND [PROXY].[IS_PROXY] = 1
	/* Кореспонденции */
	LEFT OUTER JOIN dbo.[DEALS_CORR_TA] [CORS] WITH(NOLOCK)
		ON [CORS].[REF_ID] = [REG].[ROW_ID]
	WHERE [PREV].[TA_TYPE] like IsNull(@TA_TYPE_LIKE, [PREV].[TA_TYPE]) 
		AND [PREV].[ROW_ID] = ( CASE WHEN @RowID < 0 AND @TaTypeCashPaymentBeta IS NOT NULL THEN [PREV].[ROW_ID] ELSE @RowID END)
	ORDER BY [CUST].[ROW_ID], [PSEC].[REF_ID]
	;

	SELECT N'#TBL_PRIMARY_KEY_IDS' AS REG_NAME
		,	* 
	FROM #TBL_PRIMARY_KEY_IDS WITH(NOLOCK)
	;

	SELECT N'PREV_COMMON_TA' AS REG_NAME
		,	[D].*
	FROM #TBL_PRIMARY_KEY_IDS [F] WITH(NOLOCK)
	INNER JOIN dbo.[PREV_COMMON_TA] [D] WITH(NOLOCK)
		ON	[D].[ROW_ID] = [F].[PREV_ROW_ID]
	;

	SELECT N'RAZPREG_TA' AS REG_NAME
--		,	[D].[UI_DEAL_NUM]
--		,	[D].[DB_ACCOUNT]
--		,	[D].[UI_ACCOUNT]
--		,	[D].[TAX_UNCOLLECTED_SUM]
--/*	,	[D].[ZAPOR_SUM] */
--		,	[D].[IBAN]
		,	[D].*
	FROM #TBL_PRIMARY_KEY_IDS [F] WITH(NOLOCK)
	INNER JOIN dbo.[RAZPREG_TA] [D] WITH(NOLOCK)
		ON	[D].[ROW_ID] = [F].[DEAL_ROW_ID]
	;

	SELECT N'DT015_CUSTOMERS_ACTIONS_TA' AS REG_NAME
		--,	[D].[UI_EGFN]
		--,	[D].[NAME]
		--,	[D].[COMPANY_EFN]
		--,	[D].[UI_CLIENT_CODE]
		--,	[D].[UI_CUSTOMER_ID]
		--,	[D].[UI_NOTES_EXIST]
		--,	[D].[IS_ZAPOR]	--  (дали има съдебен запор някоя от сделките на клиента) 
		--,	[D].[ID_NUMBER]
		--,	[D].[COMPANY_EFN]
		--,	[D].[SERVICE_GROUP_EGFN]
		--,	[D].[IS_ACTUAL] -- (1; 0)
		--,	[D].[PROXY_COUNT] 
		,	[D].*
	FROM #TBL_PRIMARY_KEY_IDS [F] WITH(NOLOCK)
	INNER JOIN [DT015_CUSTOMERS_ACTIONS_TA] [D] WITH(NOLOCK)
		ON	[D].[ROW_ID] = [F].[CUST_ROW_ID]
	;

	SELECT N'PROXY_SPEC_TA' AS REG_NAME
		,	[D].*
	FROM #TBL_PRIMARY_KEY_IDS [F]
	INNER JOIN dbo.[PROXY_SPEC_TA] [D] WITH(NOLOCK)
		ON	[D].[REF_ID] = [F].[CUST_ROW_ID]
	;

	SELECT 'PROXY_SPEC_TA (DT015_CUSTOMERS_ACTIONS_TA)' 
	REG_NAME
		,	[D].*
	FROM #TBL_PRIMARY_KEY_IDS [F]
	INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D] WITH(NOLOCK)
		ON	[D].[REF_ID] = [F].[PROXY_ROW_ID]
	;

	SELECT N'DEALS_CORR_TA' as REG_NAME
		--,	[D].[DEAL_NUM]
		--,	[D].[CURRENCY]
		--,	[D].[UI_CORR_ACCOUNT]
		--,	[D].[TAX_UNCOLLECTED_SUM]
		,	[D].*
	FROM #TBL_PRIMARY_KEY_IDS [F]
	INNER JOIN dbo.[DEALS_CORR_TA] [D] WITH(NOLOCK)
		ON	[D].[ROW_ID] = [F].CORS_ROW_ID
	;

	RETURN 0;
END
GO

/******************************************************************************************************/
--REF_ID	MIN_ROW_ID	CNT
--200004	400027	1
--200021	400029	1
--200041	400021	1
--200013	400018	4
--200007	400019	5

EXEC [SP_CASH_PAYMENTS_CLEARE_TEST_CASE] 400019
GO

select top(20) * 
from [PREV_COMMON_TA] WITH(NOLOCK)
where [ROW_ID] = 400019
go

select top(20) * 
from [RAZPREG_TA] WITH(NOLOCK)
where [ROW_ID] = 200007
go

select top(20) * 
from [DT015_CUSTOMERS_ACTIONS_TA] WITH(NOLOCK)
where [ROW_ID] = 100038
go

select top(20) * 
from [PROXY_SPEC_TA] WITH(NOLOCK)
where [REF_ID] = 100038
go


select top(20) * 
from [DT015_CUSTOMERS_ACTIONS_TA] WITH(NOLOCK)
where [ROW_ID] = 100416
go
select top(20) * 
from [DT015_CUSTOMERS_ACTIONS_TA] WITH(NOLOCK)
where [ROW_ID]= 100429
go



--select top(2) * from [PREV_COMMON_TA] WITH(NOLOCK)
--select top(2) * from [DT015_CUSTOMERS_ACTIONS_TA] WITH(NOLOCK)
--select top(2) * from [RAZPREG_TA] WITH(NOLOCK)
--select top(2) * from [RAZPREG_TA] WITH(NOLOCK)
--select top(2) * from [PROXY_SPEC_TA] WITH(NOLOCK)

/* Имаме няколко записа в [PREV_COMMON_TA] и по един в останалите регистри: */
WITH [RUN_ORDER] AS 
(
	select	[REF_ID]
		,	MIN([ROW_ID])	AS [MIN_ROW_ID]
		,	COUNT(*)		AS [CNT]
	from dbo.[PREV_COMMON_TA] with(nolock)
	where IsNull([RUNNING_ORDER],0) > 1
		AND [TA_TYPE] LIKE N'CashPayment%Beta%'
	group by [REF_ID] -- order by [CNT]
)
SELECT	ROW_NUMBER() OVER( PARTITION BY [T].[REF_ID] ORDER BY [T].[RUNNING_ORDER] ) AS [RECOR_ID]
	,	[T].[RUNNING_ORDER] as [RUN_ORDER]
	,	[T].* 
FROM dbo.[PREV_COMMON_TA] [T] with(nolock)
INNER JOIN [RUN_ORDER] [X] with(nolock)
	ON [X].[REF_ID] = [T].[REF_ID]
ORDER BY [T].[REF_ID], [RECOR_ID]
GO
