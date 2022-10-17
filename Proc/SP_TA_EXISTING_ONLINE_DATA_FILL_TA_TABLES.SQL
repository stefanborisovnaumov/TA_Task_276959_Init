/********************************************************************************************************/
/* Процедура за актуализация на Таблиците по ID на тестови case */
/* 2022/06/98 - v2.6.3 -> актуализация на TA таблиците за навързаните документи се извършва само за първия тестови случай */
CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES]
(
	@TestCaseRowID INT
	, @REGISTER_TYPE NVARCHAR(256)
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 1
		, @LogResultTable INT = 1
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate()
	DECLARE @Msg NVARCHAR(max) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @Sql NVARCHAR(4000) = N''
		, @RowIdStr NVARCHAR(8) = STR(@TestCaseRowID, LEN(@TestCaseRowID), 0)

	/************************************************************************************************************/
	/* Log Begining of Procedure execution */

	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @RowIdStr
			, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES]'

	/************************************************************************************************************/
	/* Find TA Conditions */

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR

	IF NOT EXISTS (
			SELECT *
			FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
			WHERE [ROW_ID] = IsNull(@TestCaseRowID, - 1)
				AND REGISTER_TYPE = @REGISTER_TYPE
			)
	BEGIN
		SELECT @Msg = N'Error not found condition with [ROW_ID] :' + @RowIdStr
			, @Sql = N'select * from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(' + @RowIdStr + ', -1)'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 1
	END

	DECLARE @DB_TYPE SYSNAME
		, @DEALS_CORR_TA_RowID INT = 0
		, @TYPE_ACTION VARCHAR(128) = ''
		, @RUNNING_ORDER INT = 0

	SELECT @DB_TYPE = [DB_TYPE]
		, @DEALS_CORR_TA_RowID = [CORS_ROW_ID]
		, @TYPE_ACTION = [TYPE_ACTION]
		, @RUNNING_ORDER = IsNull([RUNNING_ORDER], 1)
	FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
	WHERE [ROW_ID] = IsNull(@TestCaseRowID, - 1)
		AND REGISTER_TYPE = @REGISTER_TYPE

	IF @RUNNING_ORDER > 1
	BEGIN
		SELECT @Msg = N'Update with [ROW_ID] ' + @RowIdStr + ' and  [RUNNING_ORDER] <> 1 not allowed.'
			, @Sql = @TestCaseRowID + ', ' + @REGISTER_TYPE

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 0
	END

	-- SELECT @DB_TYPE = [DB_TYPE]
	-- FROM dbo.[TEST_AUTOMATION_TA_TYPE] WITH (NOLOCK)
	-- WHERE [TA_TYPE] IN (@DB_TYPE)

	/************************************************************************************************************/
	/* Get Datasources */

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

		RETURN - 2
	END

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_GET_DATASOURCE], @OnlineSqlServerName: ' + @OnlineSqlServerName + ', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + ' '
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = ' + @DB_TYPE + N', @DB_ALIAS = ' + @DB_ALIAS + N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/*********************************************************************************************************/
	/* Get Account Date */

	DECLARE @CurrAccDate DATETIME = 0
		, @AccountDate SYSNAME = N''

	BEGIN TRY
		EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @CurrAccDate OUTPUT
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR
		, @AccountDate = '''' + convert(CHAR(10), @CurrAccDate, 120) + ''''

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' + @AccountDate
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/*********************************************************************************************************/
	/* Clear data before update table: dbo.DEALS_CORR_TA, dbo.RAZPREG_TA, dbo.DT015_CUSTOMERS_ACTIONS_TA */

	BEGIN TRY
		EXEC @Ret = dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA @RowIdStr, @REGISTER_TYPE
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = ' exec dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA @RowIdStr = ' + @RowIdStr

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 1
	END CATCH

	/************************************************************************************************************/
	/* Prepare Sql Conditions */
	
	DROP TABLE IF EXISTS dbo.[#TBL_RESULT]
	CREATE TABLE dbo.[#TBL_RESULT] (
		[TEST_ID] NVARCHAR(512)
		, [DEAL_TYPE] SMALLINT
		, [DEAL_NUM] INT
		, [CUSTOMER_ID] INT
		, [REPRESENTATIVE_CUSTOMER_ID] INT
		, [DEAL_TYPE_BEN] SMALLINT
		, [DEAL_NUM_BEN] INT
		)

	EXEC @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS] @RowIdStr, @REGISTER_TYPE, @CurrAccDate

	IF @Ret <> 0
	BEGIN
		SELECT @Msg = N'Error Execute procedure dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS], Online Accoun Date: ' + @AccountDate
			, @Sql = N'exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS] ' + @RowIdStr + ', ' + @AccountDate + N''

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	IF @LogResultTable = 1
		SELECT *
		FROM dbo.[#TBL_RESULT] WITH (NOLOCK)

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[#TBL_RESULT] WITH (NOLOCK)
			)

	DECLARE @DealType INT = 0
		, @DealNum INT = 0
		, @CustomerID INT = 0
		, @ProxyID INT = 0
		, @WithUpdate INT = 1
		, @DealTypBen INT = - 1
		, @DealNumBen INT = - 1

	SELECT TOP (1) @DealNum = [DEAL_NUM]
		, @DealType = [DEAL_TYPE]
		, @CustomerID = [CUSTOMER_ID]
		, @ProxyID = [REPRESENTATIVE_CUSTOMER_ID]
		, @DealNumBen = IsNull([DEAL_NUM_BEN], - 1)
		, @DealTypBen = IsNull([DEAL_TYPE_BEN], - 1)
	FROM dbo.[#TBL_RESULT] WITH (NOLOCK)

	IF @Rows <= 0
		OR IsNull(@DealNum, 0) <= 0
		OR IsNull(@CustomerID, 0) <= 0
	BEGIN
		SELECT @Msg = 'Not found suitable deal from Test Case with [ROW_ID]: ' + @RowIdStr

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @RowIdStr
			, @Msg

		RETURN 2
	END

	/************************************************************************************************************/
	/* Update table dbo.[DEALS_CORR_TA] */
	IF IsNull(@DEALS_CORR_TA_RowID, - 1) > 0
	BEGIN
		BEGIN TRY
			EXEC @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS] @OnlineSqlServerName
				, @OnlineSqlDataBaseName
				, @RowIdStr
				, @REGISTER_TYPE
				, 1
				, @DealNum
				, @CustomerID
				, @ProxyID
				, @WithUpdate
		END TRY

		BEGIN CATCH
			SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
				, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg

			RETURN 3
		END CATCH
	END

	/************************************************************************************************************/
	/* Update table dbo.[RAZPREG_TA] */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @RowIdStr
			, @REGISTER_TYPE
			, 1
			, @DealNum
			, 0
			, @WithUpdate
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @RowIdStr, @CurrAccDate, 1, @DealNum, 0 '

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	/************************************************************************************************************/
	/* Update Ben deal: */
	IF @DealNumBen > 1
		AND @DealTypBen > 0
	BEGIN
		BEGIN TRY
			EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @OnlineSqlServerName
				, @OnlineSqlDataBaseName
				, @RowIdStr
				, @REGISTER_TYPE
				, 1
				, @DealNumBen
				, 1
				, @WithUpdate
		END TRY

		BEGIN CATCH
			SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
				, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @RowIdStr, @CurrAccDate, 1, @DealNumBen, 1 '

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg

			RETURN 5
		END CATCH
	END

	/************************************************************************************************************/
	/* Update table dbo.[DT015_CUSTOMERS_ACTIONS_TA] for Customer and Proxy */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @CurrAccDate
			, @RowIdStr
			, @REGISTER_TYPE
			, @CustomerID
			, @ProxyID
			, @WithUpdate
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate' + ', @RowIdStr, @CustomerID, @ProxyID, @WithUpdate'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 6
	END CATCH

	/******************************************************************************************************/
	/* 5.4. Update table dbo.[PREV_COMMON_TA] for Tax and Preferencial codes  */
	-- @TODO: UPDATE TAX CODE - SP_CASH_PAYMENTS_UPDATE_TAXED_INFO
	-- begin try
	-- 		exec dbo.[SP_CASH_PAYMENTS_UPDATE_TAXED_INFO] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate
	-- 			, @RowIdStr, @WithUpdate
	-- end try
	-- begin catch 
	-- 	select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
	-- 		,	@Sql = N' exec dbo.[SP_CASH_PAYMENTS_UPDATE_TAXED_INFO] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate'
	-- 				 + N', @RowIdStr, @WithUpdate'
	-- 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	-- 	return 7
	-- end catch
	
	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', TA Row ID: ' + @RowIdStr

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES]'
	END

	RETURN 0
END
GO

