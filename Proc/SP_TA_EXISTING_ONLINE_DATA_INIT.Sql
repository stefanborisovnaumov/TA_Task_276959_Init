/********************************************************************************************************/
/* Процедура за първоначална инициализация */
CREATE OR ALTER PROCEDURE dbo.SP_TA_EXISTING_ONLINE_DATA_INIT
(
	@DB_TYPE SYSNAME = N'AIR'
	, @TestAutomationType SYSNAME = N'%AIR%'
	, @LogTraceInfo INT = 1
)
AS
BEGIN
	DECLARE @Sql VARCHAR(max) = N''
		, @Msg NVARCHAR(max) = N''
		, @LogBegEndProc INT = 1
		, @AccountDateChar VARCHAR(32) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @TimeBeg DATETIME = GetDate()

	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestAutomationType
			, '*** Begin Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_INIT'

	/************************************************************************************************************/
	/* Get Datasources: */
	DECLARE @OnlineSqlServerName SYSNAME = N''
		, @OnlineSqlDataBaseName SYSNAME = N''
		, @DB_ALIAS SYSNAME = N'VCS_OnlineDB'

	EXEC @Ret = dbo.[SP_TA_GET_DATASOURCE] @DB_TYPE
		, @DB_ALIAS
		, @OnlineSqlServerName OUTPUT
		, @OnlineSqlDataBaseName OUTPUT

	IF @Ret <> 0
	BEGIN
		SELECT @Msg = N'Error execute proc, Error code: ' + str(@Ret, len(@Ret), 0) + '  Result: @OnlineSqlServerName = "' + @OnlineSqlServerName + '", @OnlineSqlDataBaseName = "' + @OnlineSqlDataBaseName + '"'
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = ' + @DB_TYPE + N', @DB_ALIAS = ' + @DB_ALIAS + N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 1
	END

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_GET_DATASOURCE], @OnlineSqlServerName: ' + @OnlineSqlServerName + ', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + ' '
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = ' + @DB_TYPE + N', @DB_ALIAS = ' + @DB_ALIAS + N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	DECLARE @SqlFullDBName SYSNAME = @OnlineSqlServerName + '.' + @OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* Get Account Date: */
	DECLARE @CurrAccDate DATETIME = 0

	BEGIN TRY
		EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @CurrAccDate OUTPUT
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = N'EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR
		, @AccountDateChar = '''' + convert(CHAR(10), @CurrAccDate, 120) + ''''

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' + @AccountDateChar
			, @Sql = N'EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Init customers data: */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS] @DB_TYPE
			, @TestAutomationType
			, @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @AccountDateChar
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS], @DB_TYPE = ' + @DB_TYPE + N', @TestAutomationType = ' + @TestAutomationType + N', @OnlineSqlServerName = ' + @OnlineSqlServerName + N', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + N', @AccountDateChar = ' + @AccountDateChar
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @DB_TYPE + ', ' + @TestAutomationType + ', ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Init customers data: */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS] @DB_TYPE
			, @TestAutomationType
			, @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @AccountDateChar
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS], @DB_TYPE = ' + @DB_TYPE + N', @TestAutomationType = ' + @TestAutomationType + N', @OnlineSqlServerName = ' + @OnlineSqlServerName + N', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + N', @AccountDateChar = ' + @AccountDateChar
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @DB_TYPE + ', ' + @TestAutomationType + ', ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	-- /************************************************************************************************************/
	-- /* Customers - Deals cross tables */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]

	INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] (
		[CUSTOMER_ID]
		, [DEAL_TYPE]
		, [CURRENCY_CODE]
		, [DEAL_COUNT]
		)
	SELECT [s].[CUSTOMER_ID] AS [CUSTOMER_ID]
		, 1 AS [DEAL_TYPE]
		, [s].[DEAL_CURRENCY_CODE] AS [CURRENCY_CODE]
		, COUNT(*) AS [DEAL_COUNT]
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [s] WITH (NOLOCK)
	GROUP BY [s].[CUSTOMER_ID]
		, [s].[DEAL_CURRENCY_CODE]
		/* having count(*) > 1 */

	/**************************************************************/
	/* Log end procedure: */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', AccData: ' + @AccountDateChar + ', Fileter: ' + @TestAutomationType

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_INIT'
	END

	RETURN 0
END
GO

