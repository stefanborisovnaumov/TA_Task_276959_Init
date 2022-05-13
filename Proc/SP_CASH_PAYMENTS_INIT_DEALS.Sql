/********************************************************************************************************/
/* Процедура за първоначална инициализация */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
GO

--DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS]
--GO
--DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
--GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@TestAutomationType		sysname = N'%CashPaymentCA%BETA%'
,	@LogTraceInfo			int = 0
)
AS 
BEGIN
	SELECT @LogTraceInfo = 1
	;

	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(@OnleneSqlServerName,1) <> '['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(@OnleneSqlDataBaseName,1) <> '['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)		

	DECLARE @Sql varchar(max) = N'', @Msg nvarchar(max) = N'', @LogBegEndProc int = 1
		,	@AccountDate varchar(32) = N'', @Rows int = 0, @Err int = 0
		, 	@SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N'', @TimeBeg datetime = GetDate()
	;

	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @SqlFullDBName, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_PREPARE_DEALS_BETA]'
	;

	/************************************************************************************************************/
	/* 0.1. Get Account Date */
	DECLARE @CurrAccDate datetime = 0
	;

	BEGIN TRY
		exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurrAccDate OUT
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return -1
	END CATCH 

	SELECT @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnleneSqlServerName+N', '+@OnleneSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 1.1. Prepare BASE conditions */
	DROP TABLE IF EXISTS #TBL_WITH_FILTERS
	;

	SELECT	[PREV].ROW_ID							AS [PREV_ROW_ID]
		,	[PREV].PROXY_ROW_ID						AS [PREV_PROXY_ROW_ID]
		,	[PREV].TA_TYPE							AS [PREV_TA_TYPE]

		,	[CUST].[SECTOR]							AS [CUST_CND_SECTOR]
		,	[DREG].UI_STD_DOG_CODE					AS [DEAL_CND_UI_STD_DOG_CODE]
		,	[DREG].UI_CURRENCY_CODE					AS [DEAL_CND_UI_CURRENCY_CODE]				

	INTO #TBL_WITH_FILTERS
	FROM dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
	INNER JOIN dbo.[RAZPREG_TA] [DREG] WITH(NOLOCK)
		on [PREV].REF_ID = [DREG].ROW_ID
	LEFT JOIN dbo.[DEALS_CORR_TA] [CORS] WITH(NOLOCK)
		on [CORS].REF_ID = [DREG].ROW_ID
	INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
		on [DREG].REF_ID = [CUST].ROW_ID
	LEFT JOIN dbo.[PROXY_SPEC_TA] as [PSPEC] WITH(NOLOCK)
		on [CUST].ROW_ID =[PSPEC].REF_ID
	WHERE [PREV].[TA_TYPE] LIKE @TestAutomationType
	ORDER BY [PREV].ROW_ID
	;

	SELECT @Rows = @@ROWCOUNT, @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin
		select @Msg = N'After: INSERT INTO [#TBL_WITH_FILTERS], Rows Affected: '+ str(@Rows,len(@Rows),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestAutomationType, @Msg
	end
	;

	/* 1.2. Prepare deals  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS]
	;

	set @Sql1 = N'
	DECLARE @DealType int = 1
		,	@DateAcc date = '+@AccountDate+'
	;

	DECLARE @StsDeleted						int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@StsCloased						int	= dbo.SETBIT(cast(0 as binary(4)),  9, 1)
		,	@StsHasIndividualSpecCondPkgs	int = dbo.SETBIT(cast(0 as binary(4)),  5, 1)	/* STS_INDIVIDUAL_SPEC_COND_PKGS (5) */
		,	@StsExcludeFromBankCollection	int = dbo.SETBIT(cast(0 as binary(4)),  8, 1)	/* STS_EXCLUDE_FROM_BANK_COLLECTIONS (8) */
		,	@StsHasOtherTaxAcc				int	= dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* CMN_OTHER_ACCOUNT_FOR_TAX (14) */
		,	@StsIsIndividual				int	= dbo.SETBIT(cast(0 as binary(4)), 16, 1)	/* SD_INDIVIDUAL_DEAL (16) */
		,	@StsNoAutoPayTax				int	= dbo.SETBIT(cast(0 as binary(4)), 29, 1)	/* CMN_NOAUTOTAX (29) */
	;

	DECLARE @StsExtJointDeal				int = dbo.SETBIT(cast(0 as binary(4)),  4, 1)	/* STS_EXT_JOINT_DEAL (4) */
		,	@StsExtCapitOnBaseDateOpen		int = dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* STS_EXT_CAPIT_ON_BASE_DATE_OPEN (14) */
		,	@StsExtDenyManualTaxAssign		int = dbo.SETBIT(cast(0 as binary(4)), 20, 1)	/* STS_EXT_DENY_MANUAL_TAX_ASSIGN (20)*/
			/* [BLOCKSUM] */
	;'

	set @Sql2 = N'
	WITH [X] AS 
	(
		SELECT	[CUST_CND_SECTOR]
			,	[DEAL_CND_UI_STD_DOG_CODE]
			,	[DEAL_CND_UI_CURRENCY_CODE]
			,	count(*) AS CNT
		FROM #TBL_WITH_FILTERS WITH(NOLOCK)
		GROUP BY [CUST_CND_SECTOR], [DEAL_CND_UI_STD_DOG_CODE], [DEAL_CND_UI_CURRENCY_CODE] 
	)
	SELECT	/* Deal info: */
			IDENTITY( INT, 1, 1)					AS [ROW_ID]
		,	1										AS [DEAL_TYPE]
		,	[REG].[DEAL_NUM]						AS [DEAL_NUM]
		,	[EXT].[ACCOUNT]							AS [DEAL_ACCOUNT]
		,	[REG].[CURRENCY_CODE]					AS [DEAL_CURRENCY_CODE]
		,	[REG].[STD_DOG_CODE]					AS [DEAL_STD_DOG_CODE]

		,	[REG].[NM245_CODE]						AS [DEAL_NM245_GROUP_PROGRAM_TYPE_CODE]
		,	[REG].[NM342_CODE]						AS [DEAL_NM342_BUNDLE_PRODUCT_CODE] 
		,	[REG].[JOINT_ACCESS_TO_FUNDS_TYPE]		AS [DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] /* enum JointDealsAccessToFundsType: 0 - Separate; 1 - Always Together */		

		,	[REG].[INT_SUM_DAY]						AS [ACCOUNT_BEG_DAY_BALANCE]		/* Begin day saldo  */
		,	[ACC].[BLK_SUMA_MIN]					AS [BLK_SUMA_MIN] /* Block amount for deal */

			/* Client info: */
		,	[REG].[KL_SECTOR]						AS [CLIENT_SECTOR]
		,	[REG].[CLIENT_CODE]						AS [CLIENT_CODE]
		,	[CLC].[CUSTOMER_ID]						AS [CUSTOMER_ID]

			/* Bits from [STATUS]: */
		,	[STS].[IS_ACTIVE_DEAL]					AS [DEAL_IS_ACTIVE_DEAL]
		,	[STS].[IS_INDIVIDUAL_COND_PKGS]			AS [DEAL_IS_INDIVIDUAL_COND_PKGS]
		,	[STS].[EXCLUDE_FROM_BANK_COLLECTIONS]	AS [DEAL_EXCLUDE_FROM_BANK_COLLECTIONS]
		,	[STS].[IS_INDIVIDUAL_DEAL]				AS [DEAL_IS_INDIVIDUAL_DEAL]
		,	[STS].[HAS_OTHER_TAX_ACC]				AS [DEAL_HAS_OTHER_TAX_ACC]
		,	[STS].[NO_AUTO_PAY_TAX]					AS [DEAL_NO_AUTO_PAY_TAX]

			/* Bits from [STATUS_EXT]: */
		,	[STS].[IS_JOINT_DEAL]					AS [DEAL_IS_JOINT_DEAL]
		,	[STS].[CAPIT_ON_BASE_DATE_OPEN]			AS [DEAL_CAPIT_ON_BASE_DATE_OPEN]
		,	[STS].[IS_DENY_MANUAL_TAX_ASSIGN]		AS [DEAL_IS_DENY_MANUAL_TAX_ASSIGN]

			/* Additional flags */
		,	[EXT].[IS_INDIVIDUAL_COMB]				AS [DEAL_IS_INDIVIDUAL_COMBINATION]

		,	[EX_BITS].*
		,	CAST( 0 AS SMALLINT )					AS [PROXY_COUNT]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS]
	FROM '+@SqlFullDBName+'.dbo.[RAZPREG] [REG] WITH(NOLOCK) 

	INNER JOIN '+@SqlFullDBName+'.dbo.[DT015] [CLC] WITH(NOLOCK)	
		ON  [CLC].[CODE] = [REG].[CLIENT_CODE] 

	INNER JOIN '+@SqlFullDBName+'.dbo.[DT008] [CCY] WITH(NOLOCK) 
		ON  [CCY].[CODE] = [REG].[CURRENCY_CODE]

	INNER JOIN '+@SqlFullDBName+'.dbo.[PARTS] [ACC] WITH(NOLOCK) 
		ON  [ACC].[PART_ID] = [REG].[ACCOUNT]

	INNER  JOIN [X] 
		ON	[X].[CUST_CND_SECTOR]			= [REG].[KL_SECTOR]
		AND [X].[DEAL_CND_UI_STD_DOG_CODE]	= [REG].[STD_DOG_CODE]
		AND [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
	'
	set @Sql3 = N' 
	CROSS APPLY (
		SELECT	CAST(@DealType AS TINYINT)				AS [DEAL_TYPE]
			,	CAST([REG].[ACCOUNT] AS VARCHAR(33))	AS [ACCOUNT]
				/* Additional flags: */
			,	CAST( [REG].INDIVIDUAL_COMBINATION_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_COMB]
			,	CAST( [REG].INDIVIDUAL_PROGRAM_GS_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_PROG]
	) [EXT]
	CROSS APPLY (
		SELECT 	CAST( 0 AS bit ) 						AS [DEAL_IS_USED]
			,	CAST( 0 AS bit ) 						AS [HAS_TAX_UNCOLECTED]
			,	CAST( 0 AS bit ) 						AS [HAS_OTHER_TAX_ACCOUNT]
			,	CAST( 0 AS bit ) 						AS [HAS_LEGAL_REPRESENTATIVE]
			,	CAST( 0 AS bit ) 						AS [HAS_PROXY]
			,	CAST( 0 AS bit ) 						AS [HAS_DISTRAINT]
			,	CAST( 0 AS bit ) 						AS [HAS_GS_INDIVIDUAL_PROGRAMME]
			,	CAST( 0 AS bit ) 						AS [HAS_WNOS_BEL]
			,	CAST( 0 AS bit ) 						AS [IS_DORMUNT_ACCOUNT]
	) [EX_BITS]
	CROSS APPLY (
		SELECT	/* Bits from [STATUS]: */
				CAST(CASE WHEN ([REG].[STATUS] & @StsCloased) <> @StsCloased THEN 1 ELSE 0 END AS BIT)
										AS [IS_ACTIVE_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasIndividualSpecCondPkgs) = @StsHasIndividualSpecCondPkgs THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_COND_PKGS]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasOtherTaxAcc) = @StsHasOtherTaxAcc THEN 1 ELSE 0 END AS BIT)
										AS [HAS_OTHER_TAX_ACC]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsIsIndividual) = @StsIsIndividual THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsNoAutoPayTax) = @StsNoAutoPayTax THEN 1 ELSE 0 END AS BIT)
										AS [NO_AUTO_PAY_TAX]
				/* Bits from [STATUS_EXT]: */
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtJointDeal) = @StsExtJointDeal THEN 1 ELSE 0 END AS BIT)
										AS [IS_JOINT_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExcludeFromBankCollection) = @StsExcludeFromBankCollection THEN 1 ELSE 0 END AS BIT)
										AS [EXCLUDE_FROM_BANK_COLLECTIONS]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtCapitOnBaseDateOpen) = @StsExtCapitOnBaseDateOpen THEN 1 ELSE 0 END AS BIT)
										AS [CAPIT_ON_BASE_DATE_OPEN]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtDenyManualTaxAssign) = @StsExtDenyManualTaxAssign THEN 1 ELSE 0 END AS BIT)
										AS [IS_DENY_MANUAL_TAX_ASSIGN]
	) [STS]
	WHERE	([REG].[STATUS] & @StsDeleted) <> @StsDeleted
		and ([REG].[STATUS] & @StsCloased) <> @StsCloased'
	;

	BEGIN TRY
		EXECUTE( @Sql1 + @Sql2 + @Sql3 );
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO(), @Sql = @Sql1 + @Sql2 + @Sql3;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return 1
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS], Rows affected: ' + str(@Rows,len(@Rows),0), @Sql = @Sql1 + @Sql2 + @Sql3
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end
	;

	/* 1.2.1 Add Indexes on dbo.[AGR_CASH_PAYMENTS_DEALS] */
	ALTER TABLE dbo.[AGR_CASH_PAYMENTS_DEALS]
		ADD CONSTRAINT [PK_AGR_CASH_PAYMENTS_DEALS] 
			PRIMARY KEY CLUSTERED ( [ROW_ID] )
	;

	CREATE INDEX IX_AGR_CASH_PAYMENTS_DEALS_DEAL_NUM_DEAL_TYPE
		ON dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_NUM], [DEAL_TYPE] )
	;

	CREATE INDEX IX_AGR_CASH_PAYMENTS_DEALS_DEAL_ACCOUNT
		ON dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_ACCOUNT] )
	;	

	/* 1.3. Prepare TAX UNCOLECTED  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1
		,	@TaxActive int = 0 /* enum eTaxUncollectedStatus: eTaxActive = 1*/
	;

	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	FROM DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	WHERE EXISTS (
		SELECT	*
		FROM '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] WITH(NOLOCK)
		WHERE	[T].[DEAL_TYPE]		= @DealType
			AND [T].[DEAL_NUM]		= [REG].[DEAL_NUM]
			AND [T].[TAX_STATUS]	= @TaxActive 
	)'
	;
	
	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.4. Prepare Deal with Other Tax Account */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1
		,	@CorreCapitAccount int = 1 /* eCapitAccount (1) */
		,	@CorrTaxServices int = 3 /* eTaxServices (3) */

	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]
		,	[C].[CORR_ACCOUNT]
		,	[ACC].[PART_CURRENCY]
		,	[BAL].[ACCOUNT_BEG_DAY_BALANCE]
		,	[ACC].[BLK_SUMA_MIN]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	FROM DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[DEALS_CORR] [C] WITH(NOLOCK)
		ON	[C].[CORR_TYPE]		= @CorrTaxServices
		and	[C].[DEAL_TYPE]		= @DealType
		and [C].[DEAL_NUMBER]	= [REG].[DEAL_NUM]
	INNER JOIN '+@SqlFullDBName+'.dbo.[PARTS] [ACC] WITH(NOLOCK)
		ON	[ACC].[PART_ID]	= [C].[CORR_ACCOUNT]
	CROSS APPLY (
		SELECT CASE WHEN [ACC].[PART_TYPE] IN ( 1, 2, 5 )
				THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
				ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [ACCOUNT_BEG_DAY_BALANCE]
	) [BAL]
	';

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.5. Prepare Deal with Group Sales INDIVIDUAL PROGRAMME */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1
		,	@GSActive int = 1 /* enum eGS_STATUS: GSActive = 1 */
	;
	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]	
		,	[GSI].[PROGRAMME_CODE]					AS [DEAL_GS_INDIVIDUAL_PROGRAM_CODE]
		,	[GSI].[PRODUCT_CODE]					AS [DEAL_GS_INDIVIDUAL_PRODUCT_CODE]
		,	[GSI].[CARDHOLDER_PREMIUM]				AS [DEAL_GS_INDIVIDUAL_CARDHOLDER_PREMIUM]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
	FROM DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[GS_INDIVIDUAL_PROGRAMME] [GSI] WITH(NOLOCK)
		ON	[GSI].[DEAL_TYPE]		= @DealType
		AND [GSI].[DEAL_NUMBER]		= [REG].[DEAL_NUM]
		AND [GSI].[ACTIVITY_STATUS] = @GSActive
	';

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.6. Prepare Deal with WNOS BEL*/
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType 	int = 1
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@REG_VNOS_BEL_BIS6 int = 63 /* #define REG_VNOS_BEL_BIS6 63 */		
	;

	SELECT	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
	WHERE EXISTS (
		SELECT	*
		FROM '+@SqlFullDBName+'.dbo.[TRAITEMS_DAY] [T] WITH(NOLOCK)
		WHERE	[T].[DEAL_NUM]	= [REG].[DEAL_NUM]
			AND [T].[DEAL_TYPE] = @DealType
			AND	[T].[SUM_OPER] > 0
			AND [T].[REG_CODE_DEF] = @REG_VNOS_BEL_BIS6
			AND ([T].[STATUS] & @StsDeleted) <> @StsDeleted
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.7. Prepare Deal with Distraint */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT]
	;

	SELECT @Sql1 = N';
	DECLARE @StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1)	/* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	SELECT	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] 
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK) 
	WHERE EXISTS ( 
		SELECT TOP (1) *  
		FROM '+@SqlFullDBName+'.dbo.BLOCKSUM [B] WITH(NOLOCK) 
		INNER JOIN '+@SqlFullDBName+'.dbo.[NOMS] [N] WITH(NOLOCK) 
			ON	[N].[NOMID] = 136 
			AND [N].[CODE]	= [B].[WHYFREEZED] 
			AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint 
		WHERE	[B].[PARTIDA] = [REG].[DEAL_ACCOUNT] 
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.8. Prepare Deal with DORMUNT ACCOUNT */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType 	int = 1
		,	@StsPART_IsSleepy int = dbo.SETBIT(cast(0 as binary(4)), 22, 1)	/* #define PART_IsSleepy (22) // пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ пїЅ пїЅпїЅпїЅпїЅпїЅ(пїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅпїЅ) */
	;

	SELECT	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] 
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK) 
	WHERE EXISTS ( 
		SELECT TOP (1) * 
		FROM '+@SqlFullDBName+'.dbo.[PARTS] [P] WITH(NOLOCK) 
		WHERE	[P].[PART_ID] = [REG].[DEAL_ACCOUNT] 
			AND ([P].[STATUS] & @StsPART_IsSleepy) = @StsPART_IsSleepy 		
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end	

	/* 1.9. Prepare Deals Legal representative */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
	;

	SELECT @Sql1 = N';
	DECLARE @DealType int = 1 /* Razp deals */
		,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;
	SELECT	[D].[DEAL_TYPE]
		,	[D].[DEAL_NUM]
		,	[CRL].[REPRESENTED_CUSTOMER_ID] 
		,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
		,	[CRL].[CUSTOMER_ROLE_TYPE] 

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK) 
		ON	[CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1	/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] in ( 1 ) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	WHERE ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated /* STS_LIMIT_DEACTIVATED 12 (Деактивиран) */
	';

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 1.10. Prepare Deals Active Proxy Customers */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	;

	SELECT @Sql1 = N'; 
	DECLARE @DealType int = 1 /* Razp deals 1 */
	,	@DateAcc date = '+@AccountDate+'
	,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;
	SELECT	[D].[DEAL_TYPE]
			,	[D].[DEAL_NUM]
			,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
			,	[CRL].[CUSTOMER_ROLE_TYPE]

	INTO dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK) 
		ON	[CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1	/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 ) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	where  ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated 
	and exists
	(
		select * 
		from '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
		inner join '+@SqlFullDBName+'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH(NOLOCK)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
		where	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
			and [PS].[CUSTOMER_ROLE_TYPE]		  = [CRL].[CUSTOMER_ROLE_TYPE] 
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] > @DateAcc )
	)'
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 2. Prepare Customers data */

	/* 2.1 Prepare all duplicate customers EGFN */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
	;	

	SELECT @Sql1 = N';
	SELECT  IDENTITY( INT, 1, 1) AS [ROW_ID] 
		,	CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT) AS [EGFN]
		,	MIN(CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT)) AS [MIN_EGFN]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] 
	FROM '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] WITH (NOLOCK)
	WHERE ISNUMERIC( [C].[IDENTIFIER] ) = 1 
	GROUP BY CAST( RIGHT( RTRIM( [C].[IDENTIFIER] ), 13) AS BIGINT) 
	HAVING COUNT(*) > 1 '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 3
	END CATCH 

	SELECT @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]  Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 2.2 Prepare Customers data */	
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	;

	set @Sql1 = N'
	;
	WITH [CTE_CUST_ID] AS 
	(
		SELECT [A].[CUSTOMER_ID]
		FROM 
		(
			SELECT DISTINCT CUSTOMER_ID
			FROM dbo.AGR_CASH_PAYMENTS_DEALS WITH(NOLOCK)	
			UNION ALL 
			SELECT DISTINCT REPRESENTATIVE_CUSTOMER_ID
			FROM dbo.AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS WITH(NOLOCK)
		) [A]
		GROUP BY [CUSTOMER_ID]
	)
	SELECT 	IDENTITY( INT, 1, 1) 					AS [ROW_ID] 
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
	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	FROM [CTE_CUST_ID] [F] WITH(NOLOCK)
	INNER JOIN '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] WITH(NOLOCK)
		ON	[F].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	INNER JOIN '+@SqlFullDBName+'.dbo.[DT015_MAINCODE_CUSTID] [M] WITH(NOLOCK)
		ON	[M].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	CROSS APPLY (
		select	CAST( CASE WHEN [C].[IDENTIFIER_TYPE] IN (5,6,7,8) THEN 1 ELSE 0 END AS BIT)
												AS [IS_FUNCTIONAL_ID]
			,	CAST( CASE WHEN [C].[CUSTOMER_TYPE] = 1 THEN 1 ELSE 0 END AS BIT)  
												AS [IS_PHISICAL_PERSON]
			,	CAST( [C].[CUSTOMER_CHARACTERISTIC] as TINYINT )
												AS [CUSTOMER_CHARACTERISTIC]
	) [TYP] 
	CROSS APPLY (
		SELECT	CAST ( 0 AS BIT )				AS [HAS_MANY_CLIENT_CODES]
			,	CAST ( 0 AS BIT )				AS [HAS_DUBL_CLIENT_IDS]
			,	CAST ( 0 AS BIT )				AS [IS_PROXY]
			,	CAST ( 0 AS BIT )				AS [HAS_LOAN]
			,	CAST ( 0 AS BIT )				AS [HAS_VALID_DOCUMENT]
			,	CAST ( 0 AS BIT )				AS [IS_ORIGINAL_EGFN]
	) [EX_BITS]
	'
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.2.1 Create Indexes on [AGR_CASH_PAYMENTS_CUSTOMERS] */
	CREATE INDEX IX_AGR_CASH_PAYMENTS_CUSTOMERS_CUSTOMER_ID
		ON dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] ( [CUSTOMER_ID] )
	;	

	/* 2.3 Prepare Customers with many client codes  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	;

	SELECT @Sql1 = N';
	SELECT	[CUST].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT [CC].[CUSTOMER_ID] 
		FROM '+@SqlFullDBName+'.dbo.[DT015] [CC] WITH(NOLOCK)
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
		GROUP BY [CC].[CUSTOMER_ID] 
		HAVING COUNT(*) > 1
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.4 Prepare Customers with Dubl EGFN  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	;

	SELECT @Sql1 = N';
	SELECT	[C].[CUSTOMER_ID]
		,	[X].[IS_ORIGINAL_EGFN]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] WITH(NOLOCK)
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] [DUBL] WITH(NOLOCK)
		ON [DUBL].[EGFN] = CAST(RIGHT(RTRIM([C].[CLIENT_IDENTIFIER]), 13) AS BIGINT)
	CROSS APPLY (
		SELECT CAST( CASE WHEN [DUBL].[MIN_EGFN] = CAST( [C].[CLIENT_IDENTIFIER] AS BIGINT )
					THEN 1 ELSE 0 END AS BIT)	AS [IS_ORIGINAL_EGFN]
	) [X]'
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.5 Prepare Customers are proxies */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	;

	SELECT @Sql1 = N';
	SELECT	[C].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT *
		FROM '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
		WHERE	[PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
			AND [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
			AND [PS].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 )  /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.6 Prepare Customers with valid IDENTITY DOCUMENTS */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	;

	set @Sql1 = N'
	DECLARE @DateAcc date = '+@AccountDate+'
	;

	SELECT	[C].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT *
		FROM '+@SqlFullDBName+'.dbo.[DT015_IDENTITY_DOCUMENTS] [D] WITH(NOLOCK)
		WHERE	[D].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
			AND [D].[NM405_DOCUMENT_TYPE] IN ( 1, 7, 8  ) /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
			AND ( [D].[INDEFINITELY] = 1 OR [D].[EXPIRY_DATE] > @DateAcc )
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.7 Prepare Customers with Active Loas */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	;

	SELECT @Sql1 = N';
	SELECT	[CUST].[CUSTOMER_ID]

	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] WITH(NOLOCK)
	WHERE EXISTS 
	(
		SELECT *
		FROM '+@SqlFullDBName+'.dbo.[KRDREG] [L] WITH(NOLOCK)
		INNER JOIN '+@SqlFullDBName+'.dbo.[DT015] [CC] WITH(NOLOCK)
			ON [L].[CLIENT_CODE] =  [CC].[CODE]
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			AND [L].[DATE_END_KREDIT] < 2 /* Is active loan */
	) '
	;

	BEGIN TRY
		exec sp_executeSql @Sql1
	END TRY
	BEGIN CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	END CATCH 

	SELECT @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: SELECT * INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/**************************************************************/
	/* 3. Update customers: */
	UPDATE [D]
	SET [HAS_MANY_CLIENT_CODES] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D] 
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] [S] with(nolock)
		ON [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	UPDATE [D]
	SET [HAS_DUBL_CLIENT_IDS] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		ON [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	UPDATE [D]
	SET [HAS_LOAN] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] [S] with(nolock)
		ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	UPDATE [D]
	SET [IS_PROXY] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] [S] with(nolock)
		ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	UPDATE [D]
	SET [HAS_VALID_DOCUMENT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] [S] with(nolock)
		ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	UPDATE [D]
	SET [IS_ORIGINAL_EGFN] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		ON	[S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
		AND [S].[IS_ORIGINAL_EGFN] = 1
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: UPDATE bist in [AGR_CASH_PAYMENTS_CUSTOMERS]', @Sql1 = ' UPDATE [AGR_CASH_PAYMENTS_CUSTOMERS] SET [HAS_VALID_DOCUMENT] = 1 WHERE ...' 
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 5. Update deals: */
	UPDATE [D]
	SET [HAS_TAX_UNCOLECTED] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_OTHER_TAX_ACCOUNT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_LEGAL_REPRESENTATIVE] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_PROXY] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_DISTRAINT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_GS_INDIVIDUAL_PROGRAMME] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [HAS_WNOS_BEL] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [IS_DORMUNT_ACCOUNT] = 1
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] [S] with(nolock)
		ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1
	;

	UPDATE [D]
	SET [PROXY_COUNT] = [S].[CNT]
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	INNER JOIN 
	(
		SELECT [P].[DEAL_NUM], COUNT(*) AS [CNT]
		FROM dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [P] with(nolock)
		WHERE [P].[DEAL_TYPE] = 1
		GROUP BY [P].[DEAL_NUM]
	) [S]
		ON	[S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [D].[DEAL_TYPE] = 1
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: UPDATE bist in [AGR_CASH_PAYMENTS_DEALS]', @Sql1 = ' UPDATE [AGR_CASH_PAYMENTS_DEALS] SET [HAS_VALID_DOCUMENT] = 1 WHERE ...' 
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 6. Log end procedure: */
	if @LogBegEndProc = 1
	begin
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', AccData: ' + @AccountDate + ', Fileter: ' + @TestAutomationType;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_PREPARE_DEALS_BETA]'
	end
	;

	RETURN 0;
END
GO
