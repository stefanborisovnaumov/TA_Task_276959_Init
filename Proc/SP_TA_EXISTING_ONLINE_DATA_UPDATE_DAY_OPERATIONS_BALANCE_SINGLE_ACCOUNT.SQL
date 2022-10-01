/********************************************************************************************************/
/* Процедура за актуализация на дневните салда в TA базата, след обработка на тестови случай */
CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT]
(
	@OnlineSqlServerName SYSNAME
	, @OnlineSqlDataBaseName SYSNAME
	, @TestCaseRowID INT
	, @DEAL_ROW_ID INT
	, @REG_NAME SYSNAME = N''
	, @UPDATE_MODE INT = 1
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 0
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate();;
	DECLARE @Msg NVARCHAR(max) = N''
		, @Sql NVARCHAR(4000) = N''
		, @Ret INT = 0
		, @RowIdStr NVARCHAR(8) = STR(@TestCaseRowID, LEN(@TestCaseRowID), 0);

	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Sql = 'dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @OnlineSqlServerName = ''' + @OnlineSqlServerName + '''' + N', @OnlineSqlDataBaseName = ''' + @OnlineSqlDataBaseName + '''' + N', @TestCaseRowID = ' + @RowIdStr + N', @DEAL_ROW_ID = ' + str(@DEAL_ROW_ID, len(@DEAL_ROW_ID), 0) + N', @REG_NAME = ''' + @REG_NAME + '''' + N', @UPDATE_MODE = ' + str(@UPDATE_MODE, len(@UPDATE_MODE), 0)
			, @Msg = '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT]';

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* 2. Load Account from ROW_ID */
	DECLARE @Row_id INT = - 1
		, @Deal_Type INT = 1
		, @Deal_Num INT = - 1
		, @Account VARCHAR(64) = N''
		, @Acc_Type INT = 3 /* Pasive */
		, @UpdAccont INT = @UPDATE_MODE
		, @DayAccBal FLOAT = 0.0;;
	DECLARE @OutputUpdateTbl TABLE (
		[ACCOUNT] VARCHAR(64)
		, [DAY_SALDO] FLOAT
		);

	/* 2.1. Find Account by ROW_ID */
	IF IsNull(@DEAL_ROW_ID, - 1) > 0
	BEGIN
		IF @REG_NAME = N'RAZPREG_TA'
		BEGIN
			SELECT @Row_id = [ROW_ID]
				, @Deal_Type = 1
				, @Deal_Num = [UI_DEAL_NUM]
				, @Account = replace([DB_ACCOUNT], ' ', '')
				, @Acc_Type = 3 /* Pasive */
			FROM dbo.[RAZPREG_TA] [REG] WITH (NOLOCK)
			WHERE [REG].[ROW_ID] IN (@DEAL_ROW_ID);
		END
		ELSE IF @REG_NAME = N'DEALS_CORR_TA'
		BEGIN
			SELECT @Row_id = [ROW_ID]
				, @Deal_Type = [UI_DEAL_TYPE]
				, @Deal_Num = [DEAL_NUM]
				, @Account = replace([UI_CORR_ACCOUNT], ' ', '')
				, @Acc_Type = 3 /* Pasive */
			FROM dbo.[DEALS_CORR_TA] [REG] WITH (NOLOCK)
			WHERE [REG].[ROW_ID] IN (@DEAL_ROW_ID);
		END
	END

	IF IsNull(@Row_id, - 1) <= 0
	BEGIN
		SELECT @Msg = 'Can''t find account by ROW_ID: ' + str(@Row_id, len(@Row_id), 0) + ', Register: ' + @REG_NAME + '.'
			, @Sql = 'select  @Account = .. from ' + @REG_NAME + ' where [ROW_ID] IN (' + str(@Row_id, len(@Row_id), 0) + ') '

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg;

		RETURN 1;
	END

	/* 2.2. Get day operation balance from OnlineDb: */
	BEGIN TRY
		INSERT INTO #TBL_RESULT (
			[ACCOUNT]
			, [PART_TYPE]
			, [DAY_SALDO]
			)
		EXEC @Ret = dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @Account
			, @Acc_Type
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO();

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, 'insert into #TBL_RESULT  ... for Main account'
			, @Msg;

		RETURN 2;
	END CATCH

	IF @Ret <> 0
	BEGIN
		SELECT @Sql = 'exec @Ret = Sql: dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] ' + '@OnlineSqlServerName = ' + @OnlineSqlServerName + '@OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + '@Account = ' + @Account + '@AccType = ' + str(@Acc_Type, len(@Acc_Type), 0) + '@LogTrace = 1'
			, @Msg = 'Error ' + str(@Ret, len(@Ret), 0) + ' execute sql for test case ID: ' + @RowIdStr + ', Account: ' + @Account + ', @DEAL_ROW_ID = ' + str(@DEAL_ROW_ID, len(@DEAL_ROW_ID), 0);

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2;
	END

	/* 2.3. Update Account day operation balance in table: */
	IF @UpdAccont = 1
		AND EXISTS (
			SELECT *
			FROM #TBL_RESULT
			WHERE [ACCOUNT] = @Account
			)
		UPDATE [D]
		SET [DAY_OPERATION_BALANCE] = [S].[DAY_SALDO]
		OUTPUT [S].[ACCOUNT]
			, INSERTED.[DAY_OPERATION_BALANCE]
		INTO @OutputUpdateTbl
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
		INNER JOIN #TBL_RESULT [S]
			ON [S].[ACCOUNT] = [D].[DEAL_ACCOUNT];

	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @DayAccBal = [DAY_SALDO]
		FROM #TBL_RESULT
		WHERE [ACCOUNT] = @Account;

		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + '; TA Row ID: ' + @RowIdStr + '; Account: ' + @Account + '; balance: ' + str(@DayAccBal, 12, 2) + '; Upate mode: ' + str(@UpdAccont, len(@UpdAccont), 0);

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT]'
	END

	RETURN 0;
END
GO

