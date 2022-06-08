
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
