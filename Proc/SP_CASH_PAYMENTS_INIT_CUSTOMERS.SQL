
/********************************************************************************************************/
/* Процедура за първоначална инициализация на клиентите */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_INIT_CUSTOMERS]
GO

drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_INIT_CUSTOMERS]
(
	@DB_TYPE				sysname = N'AIR'
,	@TestAutomationType		sysname = N'%AIR%'
,	@OnlineSqlServerName	sysname = ''
,	@OnlineSqlDataBaseName	sysname = ''
,	@AccountDate			varchar(32) 
,	@LogTraceInfo			int = 0

)
as 
begin

	select @LogTraceInfo = 1
	;

	declare @Sql varchar(max) = N'', @Msg nvarchar(max) = N'', @LogBegEndProc int = 1,	@Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @TimeBeg datetime = GetDate()
	;

	/************************************************************************************************************/
	/* 1. Prepare */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_CASH_PAYMENTS_INIT_CUSTOMERS] @DB_TYPE = '+@DB_TYPE
					+ N' , @@TestAutomationType = '+@TestAutomationType
					+ N' , @OnlineSqlServerName = '+@OnlineSqlServerName
					+ N' , @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_INIT_CUSTOMERS]'
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
	/* 2.1 Prepare all duplicate customers EGFN */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
	;	

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] 
	select  CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT) AS [EGFN]

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
	DROP TABLE IF EXISTS #TBL_CLINETS_FILTER
	;
	select [SECTOR], [DB_CLIENT_TYPE_DT300] as [CLIENT_TYPE], COUNT(*) AS [CNT] 
	INTO #TBL_CLINETS_FILTER
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] WITH(NOLOCK)
	where [DB_TYPE] = N'AIR' and [TA_TYPE] LIKE @TestAutomationType
	GROUP BY [SECTOR], [DB_CLIENT_TYPE_DT300]
	;

	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	;

	set @Sql1 = N'
	;
	WITH [CTE_FILTER] AS 
	(
		select [SECTOR], [CLIENT_TYPE]
		from #TBL_CLINETS_FILTER with(nolock)
	)
	select 	IDENTITY(INT, 1, 1) 					AS [ROW_ID]
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
	from [CTE_FILTER] [F] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] with(nolock)
		on  [F].[SECTOR] = [C].[ECONOMIC_SECTOR]
		and [F].[CLIENT_TYPE] = [C].[CLIENT_TYPE]
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
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]	
	select	[CUST].[CUSTOMER_ID]

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
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]	
	select	[C].[CUSTOMER_ID]
		,	[X].[IS_ORIGINAL_EGFN]

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
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]	
	select	[C].[CUSTOMER_ID]

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
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	;

	set @Sql1 = N'
	declare @DateAcc date = '+@AccountDate+'
	;

	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	select	[C].[CUSTOMER_ID]

	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] with(nolock)
	where EXISTS 
	(
		select *
		from '+@SqlFullDBName+'.dbo.[DT015_IDENTITY_DOCUMENTS] [D] with(nolock)
		WHERE	[D].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
			and [D].[NM405_DOCUMENT_TYPE] IN ( 1, 7, 8  )  /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
			and ( [D].[INDEFINITELY] = 1 OR [D].[EXPIRY_DATE] > @DateAcc )
			and [D].[ISSUER_COUNTRY_CODE] > 0
			and [D].[ISSUE_DATE] > ''1970-12-31''
			and len([D].[ISSUER_NAME]) > 0
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
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]	
	select	[CUST].[CUSTOMER_ID]

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
	/* 6. Log end procedure: */
	if @LogBegEndProc = 1
	begin
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
				+ ', AccData: ' + @AccountDate 
				+ ', @OnlineSqlServerName = '+@OnlineSqlServerName
				+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_INIT_CUSTOMERS]'
	end

	return 0;
end
go

