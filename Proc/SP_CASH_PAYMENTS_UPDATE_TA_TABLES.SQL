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

	declare @LogTraceInfo int = 1, @LogResultTable int = 0,	@LogSqlCondition int = 0
		,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql nvarchar(4000) = N''
		,	@RowIdStr nvarchar(8) = STR(@TestCaseRowID,LEN(@TestCaseRowID),0)
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
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [V] with(nolock) where [V].[ROW_ID] = IsNull(@TestCaseRowID, -1);

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[#TBL_TA_CONDITIONS], Rows affected: ' + STR(@Rows ,LEN(@Rows),0)
			,	@Sql = N'SELECT * INTO dbo.[#TBL_TA_CONDITIONS] FROM FROM dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [V] WHERE [V].[ROW_ID] = ' + @RowIdStr
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
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
	where [DB_TYPE] = @DB_TYPE and [UNIQUE_ALIAS] = @DB_ALIAS
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
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -1
	end catch 

	select @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
	;

	/*********************************************************************************************************/
	/* 3. Cleate data before upatede table: dbo.DEALS_CORR_TA; dbo.RAZPREG_TA; dbo.DT015_CUSTOMERS_ACTIONS_TA */
	begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]  @RowIdStr
	end try 	
	begin catch

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] @RowIdStr = '+@RowIdStr;

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return 2;
	end catch

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
			,	@Sql = N'exec dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS] '+@RowIdStr+', '+@AccountDate+N''
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	if @LogResultTable = 1 select * from dbo.[#TBL_RESULT] with(nolock);

	if @LogSqlCondition = 1 select * from dbo.[#TBL_SQL_CNDITIONS] with(nolock);

	--EXEC @Ret = dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL] @RowIdStr, @CurrAccDate, @Sql
	--begin 
	--	select  @Msg = N'Error Execute procedure dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL], Online Accoun Date: ' +@AccountDate
	--		,	@Sql = N'exec dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL] '+@RowIdStr+', '+@AccountDate+' '
	--	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
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

	/******************************************************************************************************/
	/* 5.1. Updare table dbo.[DEALS_CORR_TA] */
	begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]  @OnleneSqlServerName, @OnleneSqlDataBaseName
			, @RowIdStr, 1, @DealNum, @CustomerID, @ProxyID, @WithUpdate
	end try 	
	begin catch

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

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

		return 4;
	end catch 

	/******************************************************************************************************/
	/* 5.3. Updare table dbo.[DT015_CUSTOMERS_ACTIONS_TA] for Customer and Proxy */
	begin try
			exec dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]  @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate
			, @RowIdStr, @CustomerID, @ProxyID, @WithUpdate
	end try
	begin catch 

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate'
				+', @RowIdStr, @CustomerID, @ProxyID, @WithUpdate'

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

		return 5;
	end catch

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
