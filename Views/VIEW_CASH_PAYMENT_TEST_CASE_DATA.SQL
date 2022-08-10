
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
	,	[c].[ID_TYPE]
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

	/* Данни за обслужващата пардита за такси */
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

	/* Данни на Сделката на бенефицента - за някой от тестовите случай за кредитните преводи */
	,	[v].[DEAL_BEN_ROW_ID]
	,	[DBEN].[UI_DEAL_NUM]			AS [UI_DEAL_NUM_BEN]
	,	[DBEN].[DB_ACCOUNT]				AS [DB_ACCOUNT_BEN]
	,	[DBEN].[UI_ACCOUNT]				AS [UI_ACCOUNT_BEN]
	,	[DBEN].[ZAPOR_SUM]				AS [ZAPOR_SUM_BEN]
	,	[DBEN].[IBAN]					AS [IBAN_BEN]
	,	[DBEN].[TAX_UNCOLLECTED_SUM]	AS [TAX_UNCOLLECTED_SUM_BEN]
	,	[DBEN].[UI_STD_DOG_CODE]		AS [UI_STD_DOG_CODE_BEN]

	/* Данни на бенефицента - за някой от тестовите случай за кредитните преводи */
	,	[v].[CUST_BEN_ROW_ID]
	,	[CUST_BEN].[UI_CUSTOMER_ID]		as [UI_CUSTOMER_ID_BEN]
	,	[CUST_BEN].[UI_EGFN]			as [UI_EGFN_BEN]
	,	[CUST_BEN].[NAME]				as [NAME_BEN]
	,	[CUST_BEN].[COMPANY_EFN]		as [COMPANY_EFN_BEN]
	,	[CUST_BEN].[UI_CLIENT_CODE]		as [UI_CLIENT_CODE_BEN]

	/* Данни за таксата */	
	,	[v].[TAX_CODE]					as [TAX_CODE]
	,	[v].[PREF_CODE]					as [PREF_CODE]

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

left outer join dbo.[RAZPREG_TA] [DBEN]
	on [DBEN].[ROW_ID] = [v].[DEAL_BEN_ROW_ID]	

left outer join  dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST_BEN]
	on [CUST_BEN].[ROW_ID] = [DBEN].[REF_ID]
go
