/****************************************************************/
-- Clear data 
--EXEC DBO.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA 400049
--GO

DECLARE @Ret int = 0
	,	@TestCaseID int = 400049

/****************************************************************/
-- Find suitable Deal and update TA Tables:
EXEC @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES] @TestCaseID
;

/****************************************************************/
-- View Updated Columns:
select 	[v].[ROW_ID]
	,	[v].[PSPEC_ROW_ID]

	,	[v].[CUST_ROW_ID]
	,	[C].[UI_CUSTOMER_ID]
	,	[C].[UI_EGFN]
	,	[C].[NAME]
	,	[C].[COMPANY_EFN]
	,	[C].[UI_CLIENT_CODE]
	,	[C].[UI_NOTES_EXIST]
	,	[C].[IS_ZAPOR]
	,	[C].[ID_NUMBER]
	,	[C].[SERVICE_GROUP_EGFN]
	,	[C].[IS_ACTUAL]
	,	[C].[PROXY_COUNT]

	,	[v].[DEAL_ROW_ID]
	,	[R].[UI_DEAL_NUM]
	,	[R].[DB_ACCOUNT]
	,	[R].[UI_ACCOUNT]
	,	[R].[ZAPOR_SUM]
	,	[R].[IBAN]
	,	[R].[TAX_UNCOLLECTED_SUM]

	,	[v].[CORS_ROW_ID]
	,	[D].[DEAL_NUM]
	,	[D].[CURRENCY]
	,	[D].[UI_CORR_ACCOUNT]
	,	[D].[TAX_UNCOLLECTED_SUM]

from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] [v]

inner join dbo.[DT015_CUSTOMERS_ACTIONS_TA] [c]
	on [c].[ROW_ID] = [v].[CUST_ROW_ID]
inner join dbo.[RAZPREG_TA] [R]
	on [R].[ROW_ID] = [v].[DEAL_ROW_ID]

left outer join dbo.[DEALS_CORR_TA] [D]
	on [d].[ROW_ID] = [v].[CORS_ROW_ID]

left outer join dbo.[PROXY_SPEC_TA] [S]
	on [S].[ROW_ID] = [v].PSPEC_ROW_ID
WHERE [v].[ROW_ID] = 400049 -- @TestCaseID
GO
