
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
	,	[ID_DOCUMENT_TYPE]		int
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
			,	[ID_TYPE]				= [S].[ID_DOCUMENT_TYPE]		-- DT015_CUSTOMERS_ACTIONS_TA  ID_TYPE типа на документа за самоличност 
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
