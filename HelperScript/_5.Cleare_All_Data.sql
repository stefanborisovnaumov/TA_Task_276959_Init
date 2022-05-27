declare @TA_MaxRowID	 int = 0
		, @TA_RowID		 int= 0
		, @CustomerRowID int = 0
		, @DealRowID	 int = 0
		, @PSpecRowID	 int = 0
		, @CorsRowID	 int = 0
		, @Count		 int = 0
;

select @TA_MaxRowID = MAX([ROW_ID])
from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS]
;

declare @Ret int = 0
	,	@Msg nvarchar(max) = N'', @Sql nvarchar(max) = N''
;
while @TA_RowID < @TA_MaxRowID
begin 
	select top(1)
			@TA_RowID		= [ROW_ID]
		,	@DealRowID		= [DEAL_ROW_ID]
		,	@CorsRowID		= [CORS_ROW_ID]
		,	@CustomerRowID	= [CUST_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS]
	where [ROW_ID] > @TA_RowID 
	order by [ROW_ID] 
	;

	select @TA_RowID, @DealRowID, @CorsRowID, @CustomerRowID

	EXEC @Ret = DBO.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] @TA_RowID
	select @Ret as [result], @TA_RowID

	select @Msg = 'After Exec DBO.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] @TA_RowID = '+str(@TA_RowID,len(@TA_RowID),0)
		+ '; @DealRowID = '+str(@DealRowID,len(@DealRowID),0)
		+ '; @CorsRowID = '+str(@CorsRowID,len(@CorsRowID),0)
		+ '; @CustomerRowID = '+str(@CustomerRowID,len(@CustomerRowID),0)
	;
	exec dbo.[SP_SYS_LOG_PROC] NULL, 'Exec DBO.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] @TA_RowID', @Msg
	set @Count += 1
end
select @Count as row_count
GO


select 	[v].[ROW_ID]
	,	[v].[PSPEC_ROW_ID]
	/* Данни за потребителя */
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
	,	[D].[TAX_UNCOLLECTED_SUM]

from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [v]

inner join dbo.[DT015_CUSTOMERS_ACTIONS_TA] [c]
	on [c].[ROW_ID] = [v].[CUST_ROW_ID]
inner join dbo.[RAZPREG_TA] [R]
	on [R].[ROW_ID] = [v].[DEAL_ROW_ID]

left outer join dbo.[DEALS_CORR_TA] [D]
	on [d].[ROW_ID] = [v].[CORS_ROW_ID]

left outer join dbo.[PROXY_SPEC_TA] [S]
	on [S].[ROW_ID] = [v].PSPEC_ROW_ID
WHERE [v].[ROW_ID] = 400049
GO

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

from [BPB_TA_NEXT_SS@2022.05.12_v2].dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [v]

inner join [BPB_TA_NEXT_SS@2022.05.12_v2].dbo.[DT015_CUSTOMERS_ACTIONS_TA] [c]
	on [c].[ROW_ID] = [v].[CUST_ROW_ID]
inner join [BPB_TA_NEXT_SS@2022.05.12_v2].dbo.[RAZPREG_TA] [R]
	on [R].[ROW_ID] = [v].[DEAL_ROW_ID]

left outer join [BPB_TA_NEXT_SS@2022.05.12_v2].dbo.[DEALS_CORR_TA] [D]
	on [d].[ROW_ID] = [v].[CORS_ROW_ID]

left outer join dbo.[PROXY_SPEC_TA] [S]
	on [S].[ROW_ID] = [v].PSPEC_ROW_ID
WHERE [v].[ROW_ID] = 400049
GO
