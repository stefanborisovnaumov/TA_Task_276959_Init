/************************************************************************************************************/
DROP PROC IF EXISTS dbo.[SP_CASH_PAYMENTS_PREPARE_DEALS]
GO

CREATE PROC dbo.[SP_CASH_PAYMENTS_PREPARE_DEALS]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@TestAutomationType		sysname = N'%CashPaymentCA%BETA%'
)
AS 
BEGIN

	/************************************************************************************************************/
	/* 1.1. Prepare conditions */
	DROP TABLE IF EXISTS #TBL_WITH_FILTERS
	;

	SELECT	[PREV].ROW_ID							AS [PREV_ROW_ID]
		,	[PREV].PROXY_ROW_ID						AS [PREV_PROXY_ROW_ID]
		,	[PREV].TA_TYPE							AS [PREV_TA_TYPE]

			/* DT015_CUSTOMERS */
		,	[CUST].[SECTOR]							AS [CUST_CND_SECTOR]
		,	[CUST].[UNIFIED]						AS [CUST_CND_UNIFIED]
		,	[CUST].[IS_SERVICE]						AS [CUST_CND_IS_SERVICE]
		,	[CUST].[EGFN_TYPE]						AS [CUST_CND_EGFN_TYPE]
		,	[CUST].[DB_CLIENT_TYPE]					AS [CUST_CND_DB_CLIENT_TYPE_DT300]
		,	[CUST].[VALID_ID]						AS [CUST_CND_VALID_ID]	
		,	[CUST].[CLIENT_SUBTYPE]					AS [CUST_CND_CLIENT_SUBTYPE]
		,	[CUST].[PROXY_COUNT]					AS [CUST_CND_PROXY_COUNT]
		,	[CUST].IS_PROXY							AS [CUST_CND_IS_PROXY]
		,	[CUST].IS_UNIQUE						AS [CUST_CND_IS_UNIQUE]
			/* Conditions ? */
		,	[CUST].IS_ZAPOR							AS [CUST_IS_ZAPOR]
		,	[CUST].LEGAL_KIND						AS [CUST_LEGAL_KIND]

			/* PROXY_SPEC */
		,	[PSPEC].PROXY_CLIENT_ID					AS [PSPEC_PROXY_CLIENT_ID]
		,	[PSPEC].UI_RAZPOREDITEL					AS [PSPEC_CND_UI_RAZPOREDITEL]
		,	[PSPEC].UI_UNLIMITED					AS [PSPEC_CND_UI_UNLIMITED]
			/* Conditions ? */
		,	[PSPEC].UI_TAKE_BACK					AS [PSPEC__UI_TAKE_BACK]

			/* RAZPREG */
		,	[DREG].ROW_ID							AS [DEAL_ROW_ID]
		,	[DREG].UI_STD_DOG_CODE					AS [DEAL_CND_UI_STD_DOG_CODE]
		,	[DREG].UI_INDIVIDUAL_DEAL				AS [DEAL_CND_UI_INDIVIDUAL_DEAL]
		,	[DREG].UI_NM342_CODE					AS [DEAL_CND_UI_NM342_CODE]
		,	[DREG].UI_CURRENCY_CODE					AS [DEAL_CND_UI_CURRENCY_CODE]
		,	[DREG].UI_OTHER_ACCOUNT_FOR_TAX			AS [DEAL_CND_UI_OTHER_ACCOUNT_FOR_TAX]
		,	[DREG].UI_NOAUTOTAX						AS [DEAL_CND_UI_NOAUTOTAX]
		,	[DREG].UI_DENY_MANUAL_TAX_ASSIGN		AS [DEAL_CND_UI_DENY_MANUAL_TAX_ASSIGN]
		,	[DREG].UI_CAPIT_ON_BASE_DATE_OPEN		AS [DEAL_CND_UI_CAPIT_ON_BASE_DATE_OPEN]
		,	[DREG].UI_BANK_RECEIVABLES				AS [DEAL_CND_UI_BANK_RECEIVABLES]
		,	[DREG].UI_JOINT_TYPE					AS [DEAL_CND_UI_JOINT_TYPE]
		,	[DREG].LIMIT_AVAILABILITY				AS [DEAL_CND_LIMIT_AVAILABILITY]
		,	[DREG].DEAL_STATUS						AS [DEAL_CND_DEAL_STATUS]
		,	[DREG].LIMIT_TAX_UNCOLLECTED			AS [DEAL_CND_LIMIT_TAX_UNCOLLECTED]
		,	[DREG].LIMIT_ZAPOR						AS [DEAL_CND_LIMIT_ZAPOR]
		,	[DREG].IS_CORR							AS [DEAL_CND_IS_CORR]
		,	[DREG].IS_UNIQUE						AS [DEAL_CND_IS_UNIQUE]
		,	[DREG].GS_PROGRAMME_CODE				AS [DEAL_CND_GS_PROGRAMME_CODE]
		,	[DREG].GS_CARD_PRODUCT					AS [DEAL_CND_GS_CARD_PRODUCT]
		,	[DREG].GS_PRODUCT_CODE					AS [DEAL_CND_GS_PRODUCT_CODE]
			/* Conditions ? */
		,	[DREG].UI_TAX_FOR_CREATE				AS [DEAL_UI_TAX_FOR_CREATE]
		,	[DREG].TAX_UNCOLLECTED_SUM				AS [DEAL_TAX_UNCOLLECTED_SUM]
		,	[DREG].UI_INDIVIDUAL_COMBINATION_FLAG	AS [DEAL_UI_INDIVIDUAL_COMBINATION_FLAG]


		,	[PREV].RUNNING_ORDER					AS [PREV_CND_RUNNING_ORDER]
		,	[PREV].TAX_CODE							AS [PREV_CND_TAX_CODE]
		,	[PREV].REF_ID							AS [PREV_REF_ID]
			/* Conditions ? */						
		,	[PREV].UI_SUM							AS [PREV_UI_SUM]	
		,	[PREV].UI_OSN1							AS [PREV_UI_OSN1]
		,	[PREV].UI_OSN2							AS [PREV_UI_OSN2]
		,	[PREV].UI_TAX							AS [PREV_UI_TAX]
		,	[PREV].UI_CASH_COMMISSION				AS [PREV_UI_CASH_COMMISSION]
		,	[PREV].UI_UNSORTED_BANKNOTES			AS [PREV_UI_UNSORTED_BANKNOTES]
		,	[PREV].UI_ALBUM_CODE					AS [PREV_UI_ALBUM_CODE]
		,	[PREV].UI_PREVIEW_DOC_PRINT				AS [PREV_UI_PREVIEW_DOC_PRINT]
		,	[PREV].ZMIP								AS [PREV_ZMIP]
		,	[PREV].PREF_CODE						AS [PREV_PREF_CODE]
		,	[PREV].TAX_SUM							AS [PREV_TAX_SUM]

			/* DEALS_CORR */
		,	[CORS].DEAL_ROW_ID						AS [DREAL_CORRS_ROW_ID]
		,	[CORS].UI_CORR_TYPE						AS [DREAL_CND_CORRS_UI_CORR_TYPE]

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

	/**************************************************************/
	/* 1.2. Prepare deals  */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS]
	;

	DECLARE @DealType int = 1
		,	@CorreCapitAccount int = 1 /* eCapitAccount (1) */
		,	@CorrTaxServices int = 3 /* eTaxServices (3) */
		,	@DateAcc date = cast( [BPB_VCSBank_Online].dbo.Get_Cur_Date() as date)
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
		,	@StsBlockReasonDistraint		int = dbo.SETBIT(cast(0 as binary(4)), 20, 1)	/* STS_BLOCK_REASON_DISTRAINT (11)*/
	;

	WITH [x] AS 
	(
		SELECT	[CUST_CND_SECTOR]
			,	[DEAL_CND_UI_STD_DOG_CODE]
			,	[DEAL_CND_UI_CURRENCY_CODE]
			,	count(*) AS CNT
		FROM #TBL_WITH_FILTERS WITH(NOLOCK)
		GROUP BY [CUST_CND_SECTOR], [DEAL_CND_UI_STD_DOG_CODE], [DEAL_CND_UI_CURRENCY_CODE] 
	)
	SELECT	/* Deal info: */
			ROW_NUMBER() OVER( ORDER BY [DEAL_NUM]) AS ROW_ID
		,	1										AS [DEAL_TYPE]
		,	[REG].[DEAL_NUM]						AS [DEAL_NUM]
		,	[EXT].[ACCOUNT]							AS [DEAL_ACCOUNT]
		,	[REG].[CURRENCY_CODE]					AS [DEAL_CURRENCY_CODE]
		,	[REG].[STD_DOG_CODE]					AS [DEAL_STANDART_CONTRACT_NUMBER]

		,	[REG].[NM245_CODE]						AS [DEAL_NM245_GROUP_PROGRAM_TYPE_CODE]
		,	[REG].[NM342_CODE]						AS [DEAL_NM342_BUNDLE_PRODUCT_CODE] 

			/* Client info: */
		,	[REG].[KL_SECTOR]						AS [DEAL_CLINET_ECONOMIC_SECTOR]
		,	[REG].[CLIENT_CODE]						AS [DEAL_CLIENT_CODE]
		,	[CLC].[CUSTOMER_ID]						AS [CUSTOMER_ID]

			/* Additional Codes: */
		-- ,	[GSI].[PROGRAMME_CODE]					AS [DEAL_GS_INDIVIDUAL_PROGRAM_CODE]
		-- ,	[GSI].[PRODUCT_CODE]					AS [DEAL_GS_INDIVIDUAL_PRODUCT_CODE]
		-- ,	[GSI].[CARDHOLDER_PREMIUM]				AS [DEAL_GS_INDIVIDUAL_CARDHOLDER_PREMIUM]

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
		-- ,	IsNull([TAX].[HAS_TAX_UNCOLLECTED], 0)	AS [DEAL_HAS_TAX_UNCOLLECTED]
		-- ,	IsNull([CORR].[HAS_CORRS_FOR_TAX], 0)	AS [DEAL_HAS_CORRS_FOR_TAX]
		,	[EXT].[IS_INDIVIDUAL_COMB]				AS [DEAL_IS_INDIVIDUAL_COMBINATION]
		-- ,	IsNull([KRD].[HAS_LOANS], 0)			AS [CLIENT_HAS_ACTIVE_LOAS]
		-- ,	IsNull([WBEL].HAS_WNOS_BEL, 0)			AS [HAS_WNOS_BEL_ON_INIT]
	INTO dbo.[AGR_CASH_PAYMENTS_DEALS]
	FROM [BPB_VCSBank_Online].dbo.[RAZPREG] [REG] WITH(NOLOCK) 
	INNER JOIN [BPB_VCSBank_Online].dbo.[DT015] [CLC] WITH(NOLOCK)	
		ON  [CLC].[CODE] = [REG].[CLIENT_CODE]
	INNER JOIN [BPB_VCSBank_Online].dbo.DT008 [CCY] WITH(NOLOCK)	
		ON  [CCY].[CODE] = [REG].[CURRENCY_CODE]
	INNER  JOIN [X]
		ON	[X].[CUST_CND_SECTOR]			= [REG].[KL_SECTOR]
		AND [X].[DEAL_CND_UI_STD_DOG_CODE]	= [REG].[STD_DOG_CODE]
		AND [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
	CROSS APPLY (
		select	CAST(@DealType AS TINYINT)				AS [DEAL_TYPE]
			,	CAST([REG].[ACCOUNT] AS VARCHAR(33))	AS [ACCOUNT]
				/* Additional flags: */
			,	CAST( [REG].INDIVIDUAL_COMBINATION_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_COMB]
			,	CAST( [REG].INDIVIDUAL_PROGRAM_GS_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_PROG]
	) [EXT]
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
	-- OUTER APPLY (
	-- 	SELECT	TOP(1) cast(1 as bit) [HAS_TAX_UNCOLLECTED]
	-- 	FROM [BPB_VCSBank_Online].dbo.[TAX_UNCOLLECTED] [T] WITH(NOLOCK)
	-- 	WHERE	[T].[DEAL_TYPE]		= @DealType
	-- 		AND [T].[DEAL_NUM]		= [REG].[DEAL_NUM]
	-- 		AND [T].[TAX_STATUS]	= 0 /* eTaxActive (0) */
	-- ) [TAX]
	-- OUTER APPLY (
	-- 	SELECT	TOP(1) cast(1 as bit) [HAS_CORRS_FOR_TAX]
	-- 	FROM [BPB_VCSBank_Online].dbo.[DEALS_CORR] [C] WITH(NOLOCK)
	-- 	WHERE	[C].[CORR_TYPE]		= @CorrTaxServices
	-- 		and	[C].[DEAL_TYPE]		= @DealType
	-- 		and [C].[DEAL_NUMBER]	= [REG].[DEAL_NUM]
	-- ) [CORR]
	-- OUTER APPLY (
	-- 	SELECT TOP(1) 
	-- 			[T].[PROGRAMME_CODE]
	-- 		,	[T].[PRODUCT_CODE]
	-- 		,	[T].[CARDHOLDER_NORMAL]
	-- 		,	[T].[CARDHOLDER_PREMIUM]
	-- 	FROM [BPB_VCSBank_Online].dbo.[GS_INDIVIDUAL_PROGRAMME] [T] WITH(NOLOCK)
	-- 	WHERE	[T].[DEAL_TYPE]		= @DealType
	-- 		AND [T].[DEAL_NUMBER]	= [REG].[DEAL_NUM]
	-- 		AND [T].[ACTIVITY_STATUS] = 1 /* GSActive (1)*/
	-- ) [GSI]
	-- OUTER APPLY (
	-- 	SELECT TOP(1) cast(1 as bit) [HAS_LOANS]
	-- 	FROM [BPB_VCSBank_Online].dbo.[KRDREG] [L] WITH(NOLOCK)
	-- 	INNER JOIN [BPB_VCSBank_Online].dbo.[DT015] [CC] WITH(NOLOCK)
	-- 		ON [L].[CLIENT_CODE] =  [CC].[CODE]
	-- 	WHERE	[CC].[CUSTOMER_ID] = [CLC].[CUSTOMER_ID]
	-- 		AND [L].[DATE_END_KREDIT] < 2 /* Is active loan */
	-- ) [KRD]
	-- OUTER APPLY (
	-- 	SELECT	TOP(1) CAST( MIN( CASE WHEN [DT_CT] = 1 THEN 1 ELSE 0 END ) AS BIT)
	-- 					AS [HAS_WNOS_BEL]
	-- 	FROM [BPB_VCSBank_Online].dbo.[TRAITEMS_DAY] [T] WITH(NOLOCK)
	-- 	WHERE	[T].[DEAL_NUM]	= [REG].[DEAL_NUM]
	-- 		AND [T].[DEAL_TYPE] = [REG].[DEAL_TYPE]
	-- 		AND	[T].[SUM_OPER] > 0
	-- 		AND [T].[REG_CODE_DEF] = 12 /* #define REG_WNOS_BEL 12 */
	-- 		AND ([REG].[STATUS] & @StsDeleted) <> @StsDeleted
	-- ) [WBEL]
	WHERE	([REG].[STATUS] & @StsDeleted) <> @StsDeleted
		and ([REG].[STATUS] & @StsCloased) <> @StsCloased
	;

	CREATE INDEX [IX_AGR_CASH_PAYMENTS_DEALS_DEAL_NUM_DEAL_TYPE]
		ON dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_NUM], [DEAL_TYPE] )
	;

	CREATE INDEX [IX_AGR_CASH_PAYMENTS_DEALS_ACCOUNT]
		ON dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_ACCOUNT] )
	;

	/**************************************************************/
	/* 2. Prepare Customers data */

	/* 2.1 Prepare all duplicate customers EGFN */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	;	

	SELECT	ROW_NUMBER() OVER( ORDER BY [EGFN]) AS ROW_ID
		,	[D].[EGFN] AS [EGFN]
		,	MIN( [D].[EGFN] )	AS [MIN_EGFN]
		,	COUNT(*) AS [CNT]
	INTO dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	FROM [BPB_VCSBank_Online].dbo.DT015_CUSTOMERS [C] WITH(NOLOCK)
	CROSS APPLY (
		SELECT CAST( RIGHT(RTRIM(IDENTIFIER), 13) AS BIGINT) AS [EGFN]
	) [D]
	GROUP BY [D].[EGFN]
	HAVING COUNT(*) > 1
	;

	/* 2.2 Prepare Customers data */	
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	;

	WITH [CTE_CUST_ID] AS 
	(
		SELECT [CUSTOMER_ID]
		FROM [AGR_CASH_PAYMENTS_DEALS]
		GROUP BY [CUSTOMER_ID]
	)
	select	ROW_NUMBER() OVER(ORDER BY [C].[CUSTOMER_ID]) 
													AS [ROW_ID]
		,	[C].[CUSTOMER_ID]						AS [CUSTOMER_ID]
		,	[M].[CL_CODE]							AS [CLIENT_CODE_MAIN]
		,	RTRIM([C].[IDENTIFIER])					AS [CLIENT_IDENTIFIER]
		,	[C].[IDENTIFIER_TYPE]					AS [CLIENT_IDENTIFIER_TYPE]
		,	[C].[CLIENT_TYPE]						AS [CLIENT_TYPE_DT300_CODE]
		,	[C].[BIRTH_DATE]						AS [CLIENT_BIRTH_DATE]
		,	[TYP].[CUSTOMER_CHARACTERISTIC]			AS [CUSTOMER_CHARACTERISTIC]
		,	[TYP].[IS_FUNCTIONAL_ID]				AS [IS_FUNCTIONAL_ID]
		,	[TYP].[IS_PHISICAL_PERSON]				AS [IS_PHISICAL_PERSON]
		,	IsNull([EXT].HAS_MANY_CLIENT_CODES, 0)	AS [HAS_MANY_CLIENT_CODES]
		,	IsNull([PS].[IS_PROXY],0)				AS [IS_PROXY]
		,	IsNull([SRV].HAS_DUBL_EGFN, 0)			AS [HAS_DUBL_EGFN]
		,	IsNull([SRV].IS_DUBL_ORIG_EGFN, 0)		AS [IS_DUBL_ORIG_EGFN]
	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	from [CTE_CUST_ID] [F] WITH(NOLOCK)
	INNER JOIN [BPB_VCSBank_Online].dbo.[DT015_CUSTOMERS] [C] WITH(NOLOCK)
		ON	[F].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	INNER JOIN [BPB_VCSBank_Online].dbo.[DT015_MAINCODE_CUSTID] [M] WITH(NOLOCK)
		ON	[M].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	CROSS APPLY (
		select	CAST( CASE WHEN [C].[IDENTIFIER_TYPE] IN (5,6,7,8) THEN 1 ELSE 0 END AS BIT)
												AS [IS_FUNCTIONAL_ID]
			,	CAST( CASE WHEN [C].[CUSTOMER_TYPE] = 1 THEN 1 ELSE 0 END AS BIT)  
												AS [IS_PHISICAL_PERSON]
			,	CAST( [C].[CUSTOMER_CHARACTERISTIC] as TINYINT )
												AS [CUSTOMER_CHARACTERISTIC]
	) [TYP]
	OUTER APPLY (
		select top(1) CAST( 1 AS BIT ) AS [HAS_MANY_CLIENT_CODES]
		from [BPB_VCSBank_Online].dbo.[DT015] [CC] WITH(NOLOCK)
		where	[CC].[CUSTOMER_ID] = [F].[CUSTOMER_ID]
			AND [CC].[CODE] <> [M].[CL_CODE]
	) [EXT]
	OUTER APPLY (
		select top(1) CAST( 1 AS BIT ) AS [IS_PROXY]
		from [BPB_VCSBank_Online].dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
		where	[PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
			AND [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
			AND [PS].[CUSTOMER_ROLE_TYPE] IN ( 2 /*Пълномощник*/ )
	) [PS]
	OUTER APPLY (
		SELECT	TOP(1) 	CAST( 1 AS BIT )		AS [HAS_DUBL_EGFN]
			,	CAST( CASE WHEN [DUBL].MIN_EGFN = CAST([C].IDENTIFIER AS BIGINT)
					THEN 1 ELSE 0 END AS BIT)	AS [IS_DUBL_ORIG_EGFN]
		FROM [AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [DUBL] WITH(NOLOCK)
			WHERE [DUBL].EGFN = CAST([C].IDENTIFIER AS BIGINT)
	) [SRV]
	;

	/**************************************************************/
	/* 3. Prepare Proxy Customers account access data */
	DECLARE @StsProxyAccessDbt 	int = dbo.SETBIT(cast(0 as binary(4)),  0, 1 ) /* STS_ACCESS_CHK_OUT	1 */
		,	@StsProxyAccessKdt 	int = dbo.SETBIT(cast(0 as binary(4)),  0, 2 ) /* STS_ACCESS_CHK_IN		2 */
		,	@StsProxyAccessView int = dbo.SETBIT(cast(0 as binary(4)),  0, 4 ) /* STS_ACCESS_VIEW		4 */
		,	@StsProxyAccessPrev int = dbo.SETBIT(cast(0 as binary(4)),  0, 5 ) /* STS_ACCESS_PREVOD		5 */
		,	@StsProxyAccessIncs int = dbo.SETBIT(cast(0 as binary(4)),  0, 6 ) /* STS_ACCESS_INKASO		6 */
		,	@StsProxyAccessWork int = dbo.SETBIT(cast(0 as binary(4)),  0, 7 ) /* STS_ACCESS_WORKID		7 */
	;

	/* 3.2 Prepare Proxy Customers account access data */
	DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_PROXY_ACCOUNT_ACCESS]
	;

	SELECT	ROW_NUMBER() OVER(ORDER BY [PA].[PROXY_CUSTOMER_ID], [REG].[DEAL_NUM] ) 
										AS [ROW_ID]
		,	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]
		,	[REG].[DEAL_ACCOUNT]
		,	[PA].[PROXY_CUSTOMER_ID]
		,	[ACS].[HAS_ACCESS_DEBIT]
		,	[ACS].[HAS_ACCESS_CREDIT]
		,	[ACS].[HAS_ACCESS_VIEW]
		,	[ACS].[HAS_ACCESS_PREVOD]
		,	[ACS].[HAS_ACCESS_INKASO]
		,	[ACS].[HAS_ACCESS_WORK]
	INTO dbo.[AGR_CASH_PAYMENTS_PROXY_ACCOUNT_ACCESS]
	FROM [BPB_VCSBank_Online].dbo.[PROXY_ACC] [PA] WITH(NOLOCK)
	INNER JOIN dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] WITH(NOLOCK)
		ON	[REG].[CUSTOMER_ID]	 = [PA].[CLCODE]
		AND [REG].[DEAL_ACCOUNT] = [PA].[PR_PART]
	CROSS APPLY (
		SELECT	CAST(CASE WHEN ([PA].[STATUS] & @StsProxyAccessDbt) = @StsProxyAccessDbt THEN 1 ELSE 0 END AS BIT)
									AS [HAS_ACCESS_DEBIT]
			,	CAST(CASE WHEN ([PA].[STATUS] & @StsProxyAccessKdt) = @StsProxyAccessKdt THEN 1 ELSE 0 END AS BIT)
									AS [HAS_ACCESS_CREDIT]
			,	CAST(CASE WHEN ([PA].[STATUS] & @StsProxyAccessView) = @StsProxyAccessView THEN 1 ELSE 0 END AS BIT)
									AS [HAS_ACCESS_VIEW]
			,	CAST(CASE WHEN ([PA].[STATUS] & @StsProxyAccessPrev) = @StsProxyAccessPrev THEN 1 ELSE 0 END AS BIT)
									AS [HAS_ACCESS_PREVOD]
			,	CAST(CASE WHEN ([PA].[STATUS] & @StsProxyAccessIncs) = @StsProxyAccessIncs THEN 1 ELSE 0 END AS BIT)
									AS [HAS_ACCESS_INKASO]
			,	CAST(CASE WHEN ([PA].[STATUS] & @StsProxyAccessWork) = @StsProxyAccessWork THEN 1 ELSE 0 END AS BIT)
									AS [HAS_ACCESS_WORK]
	) [ACS]
	;

	RETURN 0
END
GO

/************************************************************************************************************/
/************************************************************************************************************/
/* Test proc: */
EXEC [SP_CASH_PAYMENTS_PREPARE_DEALS] '', ''
GO
