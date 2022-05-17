
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

	declare @LogTraceInfo int = 0, @LogResultTable int = 0,	@LogSqlCondition int = 0
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
	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if not exists (select * from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1))
	begin 
		select  @Msg = N'Error not found condition with [ROW_ID] :' + @RowIdStr
			,	@Sql = N'select * from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull('+@RowIdStr+', -1)'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return -1;
	end
	
	declare @DB_TYPE sysname = N'BETA', @DEALS_CORR_TA_RowID int = 0
	;

	select	@DB_TYPE = [TA_TYPE], @DEALS_CORR_TA_RowID = [CORS_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1)
	;

	select @DB_TYPE = [DB_TYPE] from dbo.[TEST_AUTOMATION_TA_TYPE] with(nolock)
	where  [TA_TYPE] IN ( @DB_TYPE )
	;
	/************************************************************************************************************/
	/* 2. Get Datasources: */
	declare @OnleneSqlServerName sysname = N'',	@OnleneSqlDataBaseName sysname = N'', @DB_ALIAS sysname = N'VCS_OnlineDB'
	;

	exec @Ret = dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE] @DB_TYPE, @DB_ALIAS, @OnleneSqlServerName out, @OnleneSqlDataBaseName out
	if @Ret <> 0
	begin
		select  @Msg = N'Error execute proc, Error code: '+str(@Ret,len(@Ret),0)
					+' ; Result: @OnleneSqlServerName = "'+@OnleneSqlServerName+'", @OnleneSqlDataBaseName = "'+@OnleneSqlDataBaseName+'"'
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnleneSqlServerName OUT, @OnleneSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -2;
	end

	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE], @OnleneSqlServerName: ' +@OnleneSqlServerName+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+' '
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnleneSqlServerName OUT, @OnleneSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end
	
	/*********************************************************************************************************/
	/* 2. Get Account Date */
	declare @CurrAccDate datetime = 0,	@AccountDate sysname = N''
	;

	begin try
		exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate OUT
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -2;
	end catch 

	select @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	/*********************************************************************************************************/
	/* 3. Cleate data before upatede table: dbo.DEALS_CORR_TA; dbo.RAZPREG_TA; dbo.DT015_CUSTOMERS_ACTIONS_TA */
	begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]  @RowIdStr
	end try 	
	begin catch

		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] @RowIdStr = '+@RowIdStr;

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return 1;
	end catch

	/*********************************************************************************************************/
	/* 4. Prepare Sql Conditions: */
	drop table if EXISTS dbo.[#TBL_SQL_CONDITIONS]
	;
	create table dbo.[#TBL_SQL_CONDITIONS]
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

	if @LogSqlCondition = 1 select * from dbo.[#TBL_SQL_CONDITIONS] with(nolock);

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

	if @Rows <= 0 or IsNull(@DealNum,0) <= 0 or IsNull(@CustomerID,0) <= 0
	begin
		select @Msg = 'Not found suitable deal from Test Case with [ROW_ID]: ' + @RowIdStr;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @RowIdStr, @Msg
		return 2;
	end

	/******************************************************************************************************/
	/* 5. Update data in tables: dbo.[DEALS_CORR_TA]; dbo.[RAZPREG_TA]; dbo.[DT015_CUSTOMERS_ACTIONS_TA] */

	/******************************************************************************************************/
	/* 5.1. Updare table dbo.[DEALS_CORR_TA] */
	if IsNull(@DEALS_CORR_TA_RowID,-1) > 0
	begin

		begin try
				exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA] @OnleneSqlServerName, @OnleneSqlDataBaseName
				, @RowIdStr, 1, @DealNum, @CustomerID, @ProxyID, @WithUpdate
		end try 	
		begin catch

			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql = ' exec dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg

			return 3;
		end catch 
	end

	/******************************************************************************************************/
	/* 5.2. Updare table  dbo.[RAZPREG_TA] */
	begin try
			exec dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] @OnleneSqlServerName, @OnleneSqlDataBaseName
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
			exec dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate
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
