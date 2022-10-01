/********************************************************************************************************/
/* Процедура за първоначална инициализация на сделки */
DROP TABLE IF EXISTS dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
GO

CREATE OR ALTER PROCEDURE dbo.SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS
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
	DECLARE @Sql VARCHAR(max) = N''
		, @Msg NVARCHAR(max) = N''
		, @LogBegEndProc INT = 1
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @TimeBeg DATETIME = GetDate()

	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Sql = 'dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS] @DB_TYPE = ' + @DB_TYPE + N' , @@TestAutomationType = ' + @TestAutomationType + N' , @OnlineSqlServerName = ' + @OnlineSqlServerName + N' , @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName
			, @Msg = '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS]'

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
	/* Prepare BASE conditions */
	
	DROP TABLE IF EXISTS #CSTEMP_TA_DEAL_FILTERS
	
	SELECT
		ROW_ID AS PREV_ROW_ID
		, TA_TYPE AS PREV_TA_TYPE
		, SECTOR AS CUST_CND_SECTOR
		, UI_STD_DOG_CODE AS DEAL_CND_UI_STD_DOG_CODE
		, UI_CURRENCY_CODE AS DEAL_CND_UI_CURRENCY_CODE
		, UI_INDIVIDUAL_DEAL AS UI_INDIVIDUAL_DEAL
	INTO #CSTEMP_TA_DEAL_FILTERS
	FROM VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS WITH(NOLOCK)
	WHERE DB_TYPE = 'AIR'
		AND TA_TYPE LIKE '%AIR%'
	ORDER BY ROW_ID

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: INSERT INTO #CSTEMP_TA_DEAL_FILTERS, Rows Affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestAutomationType
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare deals */

	DROP TABLE IF EXISTS dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
	SET @Sql =
	N'
		DECLARE @DealType int = 1
			,	@DateAcc date = ' + @AccountDateChar + '
		
		DECLARE @StsDeleted						int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
			,	@StsCloased						int	= dbo.SETBIT(cast(0 as binary(4)),  9, 1)
			,	@StsHasIndividualSpecCondPkgs	int = dbo.SETBIT(cast(0 as binary(4)),  5, 1)	/* STS_INDIVIDUAL_SPEC_COND_PKGS (5) */
			,	@StsExcludeFromBankCollection   int = dbo.SETBIT(cast(0 as binary(4)),  8, 1)	/* STS_EXCLUDE_FROM_BANK_COLLECTIONS (8) */
			,	@StsHasOtherTaxAcc				int	= dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* CMN_OTHER_ACCOUNT_FOR_TAX (14) */
			,	@StsIsIndividual				int	= dbo.SETBIT(cast(0 as binary(4)), 16, 1)	/* SD_INDIVIDUAL_DEAL (16) */
			,	@StsNoAutoPayTax				int	= dbo.SETBIT(cast(0 as binary(4)), 29, 1)	/* CMN_NOAUTOTAX (29) */
		
		DECLARE @StsExtJointDeal				int = dbo.SETBIT(cast(0 as binary(4)),  4, 1)	/* STS_EXT_JOINT_DEAL (4) */
			,	@StsExtCapitOnBaseDateOpen		int = dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* STS_EXT_CAPIT_ON_BASE_DATE_OPEN (14) */
			,	@StsExtDenyManualTaxAssign		int = dbo.SETBIT(cast(0 as binary(4)), 20, 1)	/* STS_EXT_DENY_MANUAL_TAX_ASSIGN (20)*/
				/* [BLOCKSUM] */
		
		WITH [X] AS 
		(
			SELECT	[CUST_CND_SECTOR]
				,	[DEAL_CND_UI_CURRENCY_CODE]
				,	count(*) AS CNT
			FROM #CSTEMP_TA_DEAL_FILTERS WITH(NOLOCK)
			GROUP BY [CUST_CND_SECTOR], [DEAL_CND_UI_CURRENCY_CODE]
		)
		SELECT /* Deal info: */
			IDENTITY(INT, 1, 1) AS [ROW_ID]
			, 1 AS [DEAL_TYPE]
			, [REG].[DEAL_NUM] AS [DEAL_NUM]
			, [EXT].[ACCOUNT] AS [DEAL_ACCOUNT]
			, [REG].[CURRENCY_CODE] AS [DEAL_CURRENCY_CODE]
			, [REG].[STD_DOG_CODE] AS [DEAL_STD_DOG_CODE]
			, [REG].[INT_COND_STDCONTRACT] AS [INT_COND_STDCONTRACT]
			, [REG].[NM245_CODE] AS [DEAL_NM245_GROUP_PROGRAM_TYPE_CODE]
			, [REG].[NM342_CODE] AS [DEAL_NM342_BUNDLE_PRODUCT_CODE]
			, [REG].[JOINT_ACCESS_TO_FUNDS_TYPE] AS [DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] /* enum JointDealsAccessToFundsType: 0 - Separate 1 - Always Together */
			, [BAL].[BEG_SALDO] AS [ACCOUNT_BEG_DAY_BALANCE] /* Begin day saldo  */
			, [ACC].[BLK_SUMA_MIN] AS [BLK_SUMA_MIN] /* Block amount for deal */
			, [BAL].[DAY_SALDO] AS [DAY_OPERATION_BALANCE] /* Day operation balance */
			/* Client info: */
			, [REG].[KL_SECTOR] AS [CLIENT_SECTOR]
			, [REG].[CLIENT_CODE] AS [CLIENT_CODE]
			, [CLC].[CUSTOMER_ID] AS [CUSTOMER_ID]
			/* Bits from [STATUS]: */
			, [STS].[IS_ACTIVE_DEAL] AS [DEAL_IS_ACTIVE_DEAL]
			, [STS].[IS_INDIVIDUAL_COND_PKGS] AS [DEAL_IS_INDIVIDUAL_COND_PKGS]
			, [STS].[EXCLUDE_FROM_BANK_COLLECTIONS] AS [DEAL_EXCLUDE_FROM_BANK_COLLECTIONS]
			, [STS].[IS_INDIVIDUAL_DEAL] AS [DEAL_IS_INDIVIDUAL_DEAL]
			, [STS].[HAS_OTHER_TAX_ACC] AS [DEAL_HAS_OTHER_TAX_ACC]
			, [STS].[NO_AUTO_PAY_TAX] AS [DEAL_NO_AUTO_PAY_TAX]
			/* Bits from [STATUS_EXT]: */
			, [STS].[IS_JOINT_DEAL] AS [DEAL_IS_JOINT_DEAL]
			, [STS].[CAPIT_ON_BASE_DATE_OPEN] AS [DEAL_CAPIT_ON_BASE_DATE_OPEN]
			, [STS].[IS_DENY_MANUAL_TAX_ASSIGN] AS [DEAL_IS_DENY_MANUAL_TAX_ASSIGN]
			/* Additional flags */
			, [EXT].[IS_INDIVIDUAL_COMB] AS [DEAL_IS_INDIVIDUAL_COMBINATION]
			, [EX_BITS].*
			, CAST(0 AS SMALLINT) AS [PROXY_COUNT]
		INTO dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
		FROM ' + @SqlFullDBName + '.dbo.[RAZPREG] [REG] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015] [CLC] WITH (NOLOCK)
			ON [CLC].[CODE] = [REG].[CLIENT_CODE]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT008] [CCY] WITH (NOLOCK)
			ON [CCY].[CODE] = [REG].[CURRENCY_CODE]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[PARTS] [ACC] WITH (NOLOCK)
			ON [ACC].[PART_ID] = [REG].[ACCOUNT]
		LEFT JOIN ' + @SqlFullDBName + '.dbo.[DAY_MOVEMENTS] [DM] WITH (NOLOCK)
			ON [DM].[IDENT] = [ACC].[PART_ID]
		LEFT JOIN ' + @SqlFullDBName + '.dbo.[FUTURE_MOVEMENTS] [FM] WITH (NOLOCK)
			ON [FM].[IDENT] = [ACC].[PART_ID]
		INNER JOIN [X]
			ON [X].[CUST_CND_SECTOR] = [REG].[KL_SECTOR]
				AND [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
		CROSS APPLY (
			SELECT CAST(@DealType AS TINYINT) AS [DEAL_TYPE]
				, CAST([REG].[ACCOUNT] AS VARCHAR(33)) AS [ACCOUNT]
				/* Additional flags: */
				, CAST([REG].INDIVIDUAL_COMBINATION_FLAG AS BIT) AS [IS_INDIVIDUAL_COMB]
				, CAST([REG].INDIVIDUAL_PROGRAM_GS_FLAG AS BIT) AS [IS_INDIVIDUAL_PROG]
			) [EXT]
		CROSS APPLY (
			SELECT CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT]
					END AS [BEG_SALDO]
				, CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0) - (IsNull(- [DM].[VNR_DBT], 0) + IsNull(- [FM].[VNR_DBT], 0) + IsNull([DM].[VNB_KRT], 0) + IsNull([FM].[VNB_KRT], 0))
					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0) - (IsNull(- [DM].[VNR_KRT], 0) + IsNull(- [FM].[VNR_KRT], 0) + IsNull([DM].[VNB_DBT], 0) + IsNull([FM].[VNB_DBT], 0))
					END AS [DAY_SALDO]
			) [BAL]
		CROSS APPLY (
			SELECT CAST(0 AS BIT) AS [DEAL_IS_USED]
				, CAST(0 AS BIT) AS [HAS_TAX_UNCOLECTED]
				, CAST(0 AS BIT) AS [HAS_OTHER_TAX_ACCOUNT]
				, CAST(0 AS BIT) AS [HAS_LEGAL_REPRESENTATIVE]
				, CAST(0 AS BIT) AS [HAS_PROXY]
				, CAST(0 AS BIT) AS [HAS_DISTRAINT]
				, CAST(0 AS BIT) AS [HAS_GS_INDIVIDUAL_PROGRAMME]
				, CAST(0 AS BIT) AS [HAS_WNOS_BEL]
				, CAST(0 AS BIT) AS [HAS_NAR_RAZP]
				, CAST(0 AS BIT) AS [IS_DORMUNT_ACCOUNT]
			) [EX_BITS]
		CROSS APPLY (
			SELECT /* Bits from [STATUS]: */
				CAST(CASE 
						WHEN ([REG].[STATUS] & @StsCloased) <> @StsCloased
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_ACTIVE_DEAL]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsHasIndividualSpecCondPkgs) = @StsHasIndividualSpecCondPkgs
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_INDIVIDUAL_COND_PKGS]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsExcludeFromBankCollection) = @StsExcludeFromBankCollection
							THEN 1
						ELSE 0
						END AS BIT) AS [EXCLUDE_FROM_BANK_COLLECTIONS]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsHasOtherTaxAcc) = @StsHasOtherTaxAcc
							THEN 1
						ELSE 0
						END AS BIT) AS [HAS_OTHER_TAX_ACC]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsIsIndividual) = @StsIsIndividual
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_INDIVIDUAL_DEAL]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsNoAutoPayTax) = @StsNoAutoPayTax
							THEN 1
						ELSE 0
						END AS BIT) AS [NO_AUTO_PAY_TAX]
				/* Bits from [STATUS_EXT]: */
				, CAST(CASE 
						WHEN ([REG].[STATUS_EXT] & @StsExtJointDeal) = @StsExtJointDeal
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_JOINT_DEAL]
				, CAST(CASE 
						WHEN ([REG].[STATUS_EXT] & @StsExtCapitOnBaseDateOpen) = @StsExtCapitOnBaseDateOpen
							THEN 1
						ELSE 0
						END AS BIT) AS [CAPIT_ON_BASE_DATE_OPEN]
				, CAST(CASE 
						WHEN ([REG].[STATUS_EXT] & @StsExtDenyManualTaxAssign) = @StsExtDenyManualTaxAssign
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_DENY_MANUAL_TAX_ASSIGN]
			) [STS]
		WHERE ([REG].[STATUS] & @StsDeleted) <> @StsDeleted
			AND ([REG].[STATUS] & @StsCloased) <> @StsCloased
	'
	
	BEGIN TRY
		EXECUTE (@Sql)
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 1
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS, Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Add Indexes on dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS */
	ALTER TABLE dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS ADD CONSTRAINT [PK_AGR_TA_EXISTING_ONLINE_DATA_DEALS] PRIMARY KEY CLUSTERED ([ROW_ID])

	CREATE INDEX IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_NUM_DEAL_TYPE ON dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS (
		[DEAL_NUM]
		, [DEAL_TYPE]
		)

	CREATE INDEX IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_ACCOUNT ON dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS ([DEAL_ACCOUNT])

	/************************************************************************************************************/
	/* Prepare TAX UNCOLECTED  */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @TaxActive INT = 0 /* enum eTaxUncollectedStatus: eTaxActive = 1*/

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM DBO.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[TAX_UNCOLLECTED] [T] WITH (NOLOCK)
				WHERE [T].[DEAL_TYPE] = @DealType
					AND [T].[DEAL_NUM] = [REG].[DEAL_NUM]
					AND [T].[TAX_STATUS] = @TaxActive
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

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with Other Tax Account */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @CorreCapitAccount INT = 1 /* eCapitAccount (1) */
			, @CorrTaxServices INT = 3 /* eTaxServices (3) */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
			, [C].[CORR_ACCOUNT]
			, [ACC].[PART_CURRENCY]
			, [BAL].[ACCOUNT_BEG_DAY_BALANCE]
			, [ACC].[BLK_SUMA_MIN]
			, [BAL].[DAY_SALDO] AS [DAY_OPERATION_BALANCE] /* Day operation balance */
		FROM DBO.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DEALS_CORR] [C] WITH (NOLOCK)
			ON [C].[CORR_TYPE] = @CorrTaxServices
				AND [C].[DEAL_TYPE] = @DealType
				AND [C].[DEAL_NUMBER] = [REG].[DEAL_NUM]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[PARTS] [ACC] WITH (NOLOCK)
			ON [ACC].[PART_ID] = [C].[CORR_ACCOUNT]
		LEFT JOIN ' + @SqlFullDBName + '.dbo.[DAY_MOVEMENTS] [DM] WITH (NOLOCK)
			ON [DM].[IDENT] = [ACC].[PART_ID]
		LEFT JOIN ' + @SqlFullDBName + 
					'.dbo.[FUTURE_MOVEMENTS] [FM] WITH (NOLOCK)
			ON [FM].[IDENT] = [ACC].[PART_ID]
		CROSS APPLY (
			SELECT CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT]
					END AS [ACCOUNT_BEG_DAY_BALANCE]
				, CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0) - (IsNull(- [DM].[VNR_DBT], 0) + IsNull(- [FM].[VNR_DBT], 0) + IsNull([DM].[VNB_KRT], 0) + IsNull([FM].[VNB_KRT], 0))
					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0) - (IsNull(- [DM].[VNR_KRT], 0) + IsNull(- [FM].[VNR_KRT], 0) + IsNull([DM].[VNB_DBT], 0) + IsNull([FM].[VNB_DBT], 0))
					END AS [DAY_SALDO]
			) [BAL]
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with Group Sales INDIVIDUAL PROGRAMME */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @GSActive INT = 1 /* enum eGS_STATUS: GSActive = 1 */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
			, [GSI].[PROGRAMME_CODE] AS [DEAL_GS_INDIVIDUAL_PROGRAM_CODE]
			, [GSI].[PRODUCT_CODE] AS [DEAL_GS_INDIVIDUAL_PRODUCT_CODE]
			, [GSI].[CARD_PRODUCT] AS [DEAL_GS_INDIVIDUAL_CARD_PRODUCT]
		FROM DBO.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[GS_INDIVIDUAL_PROGRAMME] [GSI] WITH (NOLOCK)
			ON [GSI].[DEAL_TYPE] = @DealType
				AND [GSI].[DEAL_NUMBER] = [REG].[DEAL_NUM]
				AND [GSI].[ACTIVITY_STATUS] = @GSActive
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with WNOS BEL*/
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @CurrDate DATE = GetDate()
			, @StsDeleted INT = dbo.SETBIT(cast(0 AS BINARY (4)), 0, 1)
			, @REG_VNOS_BEL_BIS6 INT = 63 /* #define REG_VNOS_BEL_BIS6 63 */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL] (
			[DEAL_TYPE]
			, [DEAL_NUM]
			)
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[TRAITEMS_DAY] [T] WITH (NOLOCK)
				WHERE [T].[DEAL_NUM] = [REG].[DEAL_NUM]
					AND [T].[DEAL_TYPE] = @DealType
					AND [T].[SUM_OPER] > 0
					AND [T].[SYS_DATE] >= @CurrDate
					AND [T].[REG_CODE_DEF] = @REG_VNOS_BEL_BIS6
					AND ([T].[STATUS] & @StsDeleted) <> @StsDeleted
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

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with Distraint */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT]

	SELECT @Sql =
	N'
		DECLARE @StsDeleted INT = dbo.SETBIT(cast(0 AS BINARY (4)), 0, 1)
			, @StsBlockReasonDistraint INT = dbo.SETBIT(cast(0 AS BINARY (4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/
		DECLARE @Tbl_Distraint_Codes TABLE ([CODE] INT)

		INSERT INTO @Tbl_Distraint_Codes
		SELECT [n].[CODE]
		FROM ' + @SqlFullDBName + '.dbo.[NOMS] [n] WITH (NOLOCK)
		WHERE [n].[NOMID] = 136
			AND ([n].[sTATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT TOP (1) *
				FROM ' + @SqlFullDBName + '.dbo.BLOCKSUM [B] WITH (NOLOCK)
				INNER JOIN @Tbl_Distraint_Codes [N]
					ON [N].[CODE] = [B].[WHYFREEZED]
				WHERE [B].[PARTIDA] = [REG].[DEAL_ACCOUNT]
					AND [B].[SUMA] > 0.01
					AND [B].[CLOSED_FROZEN_SUM] = 0
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

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with DORMUNT ACCOUNT */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @StsPART_IsSleepy INT = dbo.SETBIT(cast(0 AS BINARY (4)), 22, 1) /* #define PART_IsSleepy (22) // Партидата е спяща(замразена) */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT TOP (1) *
				FROM ' + @SqlFullDBName + '.dbo.[PARTS] [P] WITH (NOLOCK)
				WHERE [P].[PART_ID] = [REG].[DEAL_ACCOUNT]
					AND ([P].[STATUS] & @StsPART_IsSleepy) = @StsPART_IsSleepy
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

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deals Legal representative */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1 /* Razp deals */
			, @StsDeActivated INT = dbo.SETBIT(cast(0 AS BINARY (4)), 12, 1) /* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE]
		SELECT [D].[DEAL_TYPE]
			, [D].[DEAL_NUM]
			, [CRL].[REPRESENTED_CUSTOMER_ID]
			, [CRL].[REPRESENTATIVE_CUSTOMER_ID]
			, [CRL].[CUSTOMER_ROLE_TYPE]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + 
					'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH (NOLOCK)
			ON [CRL].[DEAL_TYPE] = @DealType
				AND [CRL].[DEAL_NUM] = [D].[DEAL_NUM]
				AND [CRL].[CHANNEL] = 1 /* NM455 (Chanels) : 1 Основна банкова система, ... */
				AND [CRL].[CUSTOMER_ROLE_TYPE] IN (1) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник 3 - Законен представител ... */
				AND [CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
		WHERE ([CRL].[STATUS] & @StsDeActivated) <> @StsDeActivated /* STS_LIMIT_DEACTIVATED 12 (Деактивиран) */
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
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deals Active Proxy Customers */
	DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS]
	SELECT @Sql =
	N' 
		DECLARE @DealType INT = 1 /* Razp deals 1 */
			, @DateAcc DATE = ' + @AccountDateChar + '
			, @StsDeActivated INT = dbo.SETBIT(cast(0 AS BINARY (4)), 12, 1) /* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */

		SELECT [D].[DEAL_TYPE]
			, [D].[DEAL_NUM]
			, [CRL].[REPRESENTATIVE_CUSTOMER_ID]
			, [CRL].[CUSTOMER_ROLE_TYPE]
		INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + 
						'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH (NOLOCK)
			ON [CRL].[DEAL_TYPE] = @DealType
				AND [CRL].[DEAL_NUM] = [D].[DEAL_NUM]
				AND [CRL].[CHANNEL] = 1 /* NM455 (Chanels) : 1 Основна банкова система, ... */
				AND [CRL].[CUSTOMER_ROLE_TYPE] IN (
					2
					, 3
					) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник 3 - Законен представител, ... */
				AND [CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
		WHERE ([CRL].[STATUS] & @StsDeActivated) <> @StsDeActivated
			AND EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[PROXY_SPEC] [PS] WITH (NOLOCK)
				INNER JOIN ' + @SqlFullDBName + 
						'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH (NOLOCK)
					ON [D].[PROXY_SPEC_ID] = [PS].[ID]
				WHERE [PS].[REPRESENTED_CUSTOMER_ID] = [CRL].REPRESENTED_CUSTOMER_ID
					AND [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
					AND [PS].[CUSTOMER_ROLE_TYPE] = [CRL].[CUSTOMER_ROLE_TYPE]
					AND (
						[D].[INDEFINITELY] = 1
						OR [D].[VALIDITY_DATE] > @DateAcc
						)
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
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with NAR RAZP*/
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @CurrDate DATE = GetDate()
			, @StsDeleted INT = dbo.SETBIT(cast(0 AS BINARY (4)), 0, 1)
			, @REG_NAR_RAZSP_BIS6 INT = 63 /* #define REG_NAR_RAZSP_BIS6 64 */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP] (
			[DEAL_TYPE]
			, [DEAL_NUM]
			)
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[TRAITEMS_DAY] [T] WITH (NOLOCK)
				WHERE [T].[DEAL_NUM] = [REG].[DEAL_NUM]
					AND [T].[DEAL_TYPE] = @DealType
					AND [T].[SUM_OPER] > 0
					AND [T].[SYS_DATE] >= @CurrDate
					AND [T].[REG_CODE_DEF] = @REG_NAR_RAZSP_BIS6
					AND ([T].[STATUS] & @StsDeleted) <> @StsDeleted
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

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* update deals */
	UPDATE [D]
	SET [HAS_TAX_UNCOLECTED] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_OTHER_TAX_ACCOUNT] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_LEGAL_REPRESENTATIVE] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_PROXY] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_DISTRAINT] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_GS_INDIVIDUAL_PROGRAMME] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_WNOS_BEL] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_NAR_RAZP] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [IS_DORMUNT_ACCOUNT] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [PROXY_COUNT] = [S].[CNT]
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN (
		SELECT [P].[DEAL_NUM]
			, COUNT(*) AS [CNT]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] [P] WITH (NOLOCK)
		WHERE [P].[DEAL_TYPE] = 1
		GROUP BY [P].[DEAL_NUM]
		) [S] ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [D].[DEAL_TYPE] = 1
		

	/************************************************************************************************************/
	/* Indexes */

	CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_CURRENCY_CODE_DEAL_STD_DOG_CODE_CLIENT_SECTOR_DEAL_IS_JOINT_DEAL]
		ON [dbo].AGR_TA_EXISTING_ONLINE_DATA_DEALS ([DEAL_CURRENCY_CODE] ASC, [DEAL_STD_DOG_CODE] ASC, [CLIENT_SECTOR] ASC, [DEAL_IS_JOINT_DEAL] ASC, [HAS_WNOS_BEL] ASC, [IS_DORMUNT_ACCOUNT] ASC)
		INCLUDE ([DEAL_TYPE], [DEAL_NUM], [DEAL_ACCOUNT], [CUSTOMER_ID])

	CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_CURRENCY_CODE_CUSTOMER_ID_DEAL_NUM]
		ON [dbo].AGR_TA_EXISTING_ONLINE_DATA_DEALS ([DEAL_CURRENCY_CODE], [CUSTOMER_ID], [DEAL_NUM])

	CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS_DEAL_TYPE_DEAL_NUM_CUSTOMER_ROLE_TYPE]
		ON [dbo].[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] ([DEAL_TYPE], [DEAL_NUM], [CUSTOMER_ROLE_TYPE]) INCLUDE ([REPRESENTATIVE_CUSTOMER_ID])

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: update bist in AGR_TA_EXISTING_ONLINE_DATA_DEALS'
			, @Sql = N' update AGR_TA_EXISTING_ONLINE_DATA_DEALS set [HAS_VALID_DOCUMENT] = 1 where ...'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Log end procedure: */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', AccData: ' + @AccountDateChar + ', Fileter: ' + @TestAutomationType

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS'
	END

	RETURN 0
END
GO

