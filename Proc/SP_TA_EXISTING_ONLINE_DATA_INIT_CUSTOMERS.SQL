/********************************************************************************************************/
/* Процедура за първоначална инициализация на клиенти */
DROP TABLE IF EXISTS dbo.AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS
GO

CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS]
(
	@DB_TYPE SYSNAME = N'AIR'
	, @TestAutomationType SYSNAME = N'%AIR%'
	, @OnlineSqlServerName SYSNAME = ''
	, @OnlineSqlDataBaseName SYSNAME = ''
	, @AccountDateChar VARCHAR(32)
	, @LogTraceInfo INT = 1
)
AS
BEGIN
	DECLARE @Sql NVARCHAR(max) = N''
		, @Msg NVARCHAR(max) = N''
		, @LogBegEndProc INT = 1
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @TimeBeg DATETIME = GetDate()

	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Sql = 'dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS] @DB_TYPE = ' + @DB_TYPE + N' , @@TestAutomationType = ' + @TestAutomationType + N' , @OnlineSqlServerName = ' + @OnlineSqlServerName + N' , @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName
			, @Msg = '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS]'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Format full Online DB name */

	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName), 1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName), 1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	DECLARE @SqlFullDBName SYSNAME = @OnlineSqlServerName + '.' + @OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* Prepare all duplicate customers EGFN */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] 
		SELECT
			CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT) AS [EGFN]
		FROM ' + @SqlFullDBName + '.dbo.[DT015_CUSTOMERS] [C] WITH (NOLOCK)
		WHERE ISNUMERIC( [C].[IDENTIFIER] ) = 1 
		GROUP BY CAST( RIGHT( RTRIM( [C].[IDENTIFIER] ), 13) AS BIGINT) 
		HAVING COUNT(*) > 1
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 3
	END CATCH

	SELECT @Rows = (SELECT count(*) FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] WITH (NOLOCK))
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers data */

	DROP TABLE IF EXISTS #CSTEMP_TA_CLIENT_FILTERS

	SELECT SECTOR
		, DB_CLIENT_TYPE_DT300 AS CLIENT_TYPE
	INTO #CSTEMP_TA_CLIENT_FILTERS
	FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
	WHERE [DB_TYPE] = @DB_TYPE
		AND [TA_TYPE] LIKE @TestAutomationType
	GROUP BY [SECTOR]
		, [DB_CLIENT_TYPE_DT300]

	DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS]
	SET @Sql =
	N'
		WITH [CTE_FILTER] AS 
		(
			SELECT [SECTOR], [CLIENT_TYPE]
			FROM #CSTEMP_TA_CLIENT_FILTERS WITH(NOLOCK)
		)
		SELECT 	IDENTITY(INT, 1, 1) 				AS [ROW_ID]
			, [C].[CUSTOMER_ID]						AS [CUSTOMER_ID]
			, [M].[CL_CODE]							AS [CLIENT_CODE_MAIN]
			, RTRIM([C].[IDENTIFIER])				AS [CLIENT_IDENTIFIER]
			, [C].[IDENTIFIER_TYPE]					AS [CLIENT_IDENTIFIER_TYPE]
			, [C].[ECONOMIC_SECTOR]					AS [CLIENT_SECTOR]		
			, [C].[CLIENT_TYPE]						AS [CLIENT_TYPE_DT300_CODE]
			, [C].[BIRTH_DATE]						AS [CLIENT_BIRTH_DATE]
			, [TYP].[CUSTOMER_CHARACTERISTIC]		AS [CUSTOMER_CHARACTERISTIC]
			, [TYP].[IS_FUNCTIONAL_ID]				AS [IS_FUNCTIONAL_ID]
			, [TYP].[IS_PHISICAL_PERSON]			AS [IS_PHISICAL_PERSON]
			, [EX_BITS].*
		INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS]
		FROM [CTE_FILTER] [F] WITH(NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015_CUSTOMERS] [C] WITH(NOLOCK)
			ON  [F].[SECTOR] = [C].[ECONOMIC_SECTOR]
			AND [F].[CLIENT_TYPE] = [C].[CLIENT_TYPE]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015_MAINCODE_CUSTID] [M] WITH(NOLOCK)
			ON  [M].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
		CROSS APPLY (
			SELECT	CAST( CASE WHEN [C].[IDENTIFIER_TYPE] IN (5,6,7,8) THEN 1 ELSE 0 END AS BIT)
													AS [IS_FUNCTIONAL_ID]
				,	CAST( CASE WHEN [C].[CUSTOMER_TYPE] = 1 THEN 1 ELSE 0 END AS BIT)  
													AS [IS_PHISICAL_PERSON]
				,	CAST( [C].[CUSTOMER_CHARACTERISTIC] as TINYINT )
													AS [CUSTOMER_CHARACTERISTIC]
		) [TYP] 
		CROSS APPLY (
			SELECT CAST ( 0 AS BIT )			AS [HAS_MANY_CLIENT_CODES]
				, CAST ( 0 AS BIT )				AS [HAS_DUBL_CLIENT_IDS]
				, CAST ( 0 AS BIT )				AS [IS_PROXY]
				, CAST ( 0 AS BIT )				AS [HAS_LOAN]
				, CAST ( 0 AS BIT )				AS [HAS_VALID_DOCUMENT]
				, CAST ( 1 AS BIT )				AS [IS_ORIGINAL_EGFN]
				, CAST ( 0 AS BIT )				AS [HAS_ZAPOR]
				, CAST ( 0 AS BIT )				AS [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC]			
		) [EX_BITS]
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Create Indexes ON [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] */

	CREATE INDEX IX_AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_CUSTOMER_ID ON dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] ([CUSTOMER_ID])

	/************************************************************************************************************/
	/* Prepare Customers with multiple client codes */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES]	
		SELECT
			[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] WITH(NOLOCK)
		where EXISTS 
		(
			SELECT [CC].[CUSTOMER_ID] 
			FROM ' + @SqlFullDBName + '.dbo.[DT015] [CC] WITH(NOLOCK)
			WHERE [CC].[CUSTOMER_ID] = [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS].[CUSTOMER_ID]
			GROUP BY [CC].[CUSTOMER_ID] 
			HAVING COUNT(*) > 1
		)
	'
	
	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY
	
	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH
	
	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with duplicated EGFN */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN]	
		SELECT
			[C].[CUSTOMER_ID]
			, [X].[IS_ORIGINAL_EGFN]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
		INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] [DUBL] WITH(NOLOCK)
			ON [DUBL].[EGFN] = CAST(RIGHT(RTRIM([C].[CLIENT_IDENTIFIER]), 13) AS BIGINT)
		CROSS APPLY
		(
			SELECT CAST( CASE WHEN [DUBL].[EGFN] = CAST( [C].[CLIENT_IDENTIFIER] AS BIGINT )
						THEN 1 ELSE 0 END AS BIT)	AS [IS_ORIGINAL_EGFN]
		) [X]
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers who are proxies */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES]	
		SELECT
			[C].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM ' + @SqlFullDBName + '.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
			WHERE [PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
				AND [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
				AND [PS].[CUSTOMER_ROLE_TYPE] IN (2, 3)  /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник 3 - Законен представител, ... */
		)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with valid IDENTITY DOCUMENTS */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]

	SET @Sql =
	N'
		DECLARE @DateAcc date = ' + @AccountDateChar + '
		
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
		SELECT	[C].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM ' + @SqlFullDBName + '.dbo.[DT015_IDENTITY_DOCUMENTS] [D] WITH(NOLOCK)
			WHERE	[D].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
				AND [D].[NM405_DOCUMENT_TYPE] IN (1, 7, 8)  /* 1 - Лична карта 7 - Паспорт 8 - Шофьорска книжка */
				AND ( [D].[INDEFINITELY] = 1 OR [D].[EXPIRY_DATE] > @DateAcc )
				AND [D].[ISSUER_COUNTRY_CODE] > 0
				AND [D].[ISSUE_DATE] > ''1970-12-31''
				AND len([D].[ISSUER_NAME]) > 0
		)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with Active Loas */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS]	
		SELECT [CUST].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [CUST] WITH(NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM ' + @SqlFullDBName + '.dbo.[KRDREG] [L] WITH(NOLOCK)
			INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015] [CC] WITH(NOLOCK)
				ON [L].[CLIENT_CODE] =  [CC].[CODE]
			WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
				AND [L].[DATE_END_KREDIT] < 2 /* Is active loan */
		)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with Distraint */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT]

	INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] ([CUSTOMER_ID])
	EXEC @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName
		, @OnlineSqlDataBaseName

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with Uncollected tax connected to all customer accounts */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]

	INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] ([CUSTOMER_ID])
	EXEC @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName
		, @OnlineSqlDataBaseName

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Update customers */

	UPDATE [D]
	SET [HAS_MANY_CLIENT_CODES] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES] [S] WITH (NOLOCK) ON [S].CUSTOMER_ID = [D].CUSTOMER_ID

	UPDATE [D]
	SET [HAS_DUBL_CLIENT_IDS] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN] [S] WITH (NOLOCK) ON [S].CUSTOMER_ID = [D].CUSTOMER_ID

	UPDATE [D]
	SET [IS_ORIGINAL_EGFN] = 0
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
		AND [S].[IS_ORIGINAL_EGFN] = 0

	UPDATE [D]
	SET [HAS_LOAN] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [IS_PROXY] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [HAS_VALID_DOCUMENT] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [HAS_ZAPOR] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: update bits in [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS]'
			, @Sql = ' update [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] SET ...'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Log END procedure */

	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', AccData: ' + @AccountDateChar + ', @OnlineSqlServerName = ' + @OnlineSqlServerName + ', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS]'
	END

	RETURN 0
END
GO

