/********************************************************************************************************/
/* Процедура за определяне на критериите който ни пречат да намерим подходяща сделка за датен TestCase */
CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_TEST_PROCEDURES_FIND_SUITABLE_DEAL]
(
	@TestCaseRowID NVARCHAR(16)
	, @CurrAccDate DATETIME
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 1
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate()
	DECLARE @Msg NVARCHAR(max) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Sql NVARCHAR(4000) = N''

	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_TEST_PROCEDURES_FIND_SUITABLE_DEAL]'

	/************************************************************************************************************/
	/* @TODO: */
	/**********************************************************************************/
	DROP TABLE IF EXISTS dbo.[#TBL_RESULT]
	CREATE TABLE dbo.[#TBL_RESULT]
	(
		[TEST_ID] NVARCHAR(512)
		, [DEAL_TYPE] SMALLINT
		, [DEAL_NUM] INT
		, [CUSTOMER_ID] INT
		, [REPRESENTATIVE_CUSTOMER_ID] INT
		, [DEAL_TYPE_BEN] SMALLINT
		, [DEAL_NUM_BEN] INT
	)

	DECLARE @CondCount INT = 0
		, @FistCondRowID INT = 0
		, @ScipCondIndex INT = 4
		, @ScipTblRowId INT = 0

	SELECT @CondCount = count(*)
		, @FistCondRowID = min([ID])
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
	WHERE [TEST_ID] = @TestCaseRowID

	WHILE @Rows = 0
		AND @ScipCondIndex < @CondCount
	BEGIN
		TRUNCATE TABLE dbo.[#TBL_RESULT]

		SELECT @Sql = N''
			, @Rows = 0
			, @ScipTblRowId = @FistCondRowID + @ScipCondIndex

		-- Prepare Sql to execute: 
		SELECT @Sql += [CND].[COUND]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
		CROSS APPLY (
			SELECT CASE 
					WHEN [ID] = @ScipTblRowId
						THEN ''
					ELSE [SQL_COND]
					END AS [COUND]
			) [CND]
		WHERE [TEST_ID] = @TestCaseRowID
		ORDER BY [ID]

		-- Execute Sql:
		BEGIN TRY
			INSERT INTO dbo.[#TBL_RESULT]
			EXEC sp_executesql @Sql
		END TRY

		BEGIN CATCH
			SELECT @Msg = 'Error execute Sql:' + dbo.FN_GET_EXCEPTION_INFO()
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
			WHERE [ID] = @ScipTblRowId

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg
		END CATCH

		SELECT @Rows = count(*)
		FROM dbo.[#TBL_RESULT] WITH (NOLOCK)

		-- Test Result:
		IF @Rows > 0
		BEGIN
			SELECT @Msg = 'Test Case ID:' + [TEST_ID] + ' Found records: ' + str(@Rows, 3, 0) + ' Skiped condition info: "' + [DESCR] + '" Skiped SQL condition: "' + [SQL_COND] + '"'
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
			WHERE [id] = @ScipTblRowId

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg
		END

		SET @ScipCondIndex += 1
	END

	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', TA Row ID: ' + @TestCaseRowID + ' Found Records: ' + str(@Rows, 2, 0) + '.'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_TEST_PROCEDURES_FIND_SUITABLE_DEAL]'
	END

	RETURN 0
END
GO

