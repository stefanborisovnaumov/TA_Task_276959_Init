--SELECT object_name( object_id ) as obj_name, *  FROM sys.all_columns where name like '%UI_UNLIMITED%'
--go

DROP TABLE IF EXISTS #TBL_WITH_FILTERS
GO

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
from dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
inner join dbo.[RAZPREG_TA] [DREG] WITH(NOLOCK)
	on [PREV].REF_ID = [DREG].ROW_ID
left join dbo.[DEALS_CORR_TA] [CORS] WITH(NOLOCK)
	on [CORS].REF_ID = [DREG].ROW_ID
inner join dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
	on [DREG].REF_ID = [CUST].ROW_ID
left join dbo.[PROXY_SPEC_TA] as [PSPEC] WITH(NOLOCK)
	on [CUST].ROW_ID =[PSPEC].REF_ID
where [PREV].[TA_TYPE] like '%BETA%'
order by [PREV].ROW_ID
GO

SELECT * FROM #TBL_WITH_FILTERS 
-- order by [CUST_CND_EGFN_TYPE]
GO

SELECT [DEAL_CND_UI_STD_DOG_CODE] 
FROM #TBL_WITH_FILTERS
GROUP BY [DEAL_CND_UI_STD_DOG_CODE] 
ORDER BY CAST( [DEAL_CND_UI_STD_DOG_CODE]  AS INT )
GO

/**************************************************************/
DROP TABLE IF EXISTS dbo.[AGR_CASH_PAYMENTS_DEALS]
GO

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

with [x] as 
(
	select [CUST_CND_SECTOR], [DEAL_CND_UI_STD_DOG_CODE], [DEAL_CND_UI_CURRENCY_CODE], count(*) as CNT
	from #TBL_WITH_FILTERS
	group by [CUST_CND_SECTOR], [DEAL_CND_UI_STD_DOG_CODE], [DEAL_CND_UI_CURRENCY_CODE] 
)
SELECT	CAST( 1 AS TINYINT)				AS [DEAL_TYPE]
	,	[REG].[DEAL_NUM]				AS [DEAL_NUM]
	,	[REG].[ACCOUNT]					AS [DEAL_ACCOUNT]
	,	[REG].[CURRENCY_CODE]			AS [DEAL_CURRENCY_CODE]
	,	[REG].[STD_DOG_CODE]			AS [DEAL_STANDART_CONTRACT_NUMBER]
		/* Client info: */
	,	[REG].[KL_SECTOR]				AS [DEAL_CLINET_ECONOMIC_SECTOR]
	,	[REG].[CLIENT_CODE]				AS [DEAL_CLIENT_CODE]

	,	[REG].[NM245_CODE]				AS [DEAL_NM245_GROUP_PROGRAM_TYPE_CODE]
	,	[REG].[NM342_CODE]				AS [DEAL_NM342_BUNDLE_PRODUCT_CODE] 

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

		/* Additional deal flags: */
	,	[EXT].[IS_INDIVIDUAL_COMB]				AS [DEAL_IS_INDIVIDUAL_COMBINATION]
	,	[EXT].[IS_INDIVIDUAL_PROG]				AS [DEAL_IS_INDIVIDUAL_PROGRAM_GS]
	,	IsNull([TAX].[HAS_TAX_UNCOLLECTED], 0)	AS [DEAL_HAS_TAX_UNCOLLECTED]
	,	IsNull([CORR].[HAS_CORRS_FOR_TAX], 0)	AS [DEAL_HAS_CORRS_FOR_TAX]
--	,	IsNull([BLCK].[HAS_ZAPOR], 0)			AS [DEAL_HAS_ZAPOR]
INTO dbo.[AGR_CASH_PAYMENTS_DEALS]
FROM [BPB_VCSBank_Online].dbo.[RAZPREG] [REG] WITH(NOLOCK) 
INNER JOIN [BPB_VCSBank_Online].dbo.DT008 [CCY] WITH(NOLOCK)	
	ON  [CCY].[CODE] = [REG].CURRENCY_CODE
INNER  JOIN [X]
	ON	[X].[CUST_CND_SECTOR]			= [REG].[KL_SECTOR]
	AND [X].[DEAL_CND_UI_STD_DOG_CODE]	= [REG].[STD_DOG_CODE]
	AND [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
CROSS APPLY (
	select	CAST(@DealType AS TINYINT)	AS [DEAL_TYPE]
		,	CAST([REG].[ACCOUNT] AS VARCHAR(33)) 
										AS [ACCOUNT]
			/* Additional flags: */
		,	CAST( [REG].INDIVIDUAL_COMBINATION_FLAG AS bit ) 
										AS [IS_INDIVIDUAL_COMB]
		,	CAST( [REG].INDIVIDUAL_PROGRAM_GS_FLAG AS bit ) 
										AS [IS_INDIVIDUAL_PROG]
) [EXT]
CROSS APPLY (
	select	/* Bits from [STATUS]: */
			CAST(CASE WHEN ([REG].[STATUS] & @StsCloased) <>  @StsCloased THEN 1 ELSE 0 END AS BIT)
									AS [IS_ACTIVE_DEAL]
		,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasIndividualSpecCondPkgs) =  @StsHasIndividualSpecCondPkgs THEN 1 ELSE 0 END AS BIT)
									AS [IS_INDIVIDUAL_COND_PKGS]
		,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasOtherTaxAcc) =  @StsHasOtherTaxAcc THEN 1 ELSE 0 END AS BIT)
									AS [HAS_OTHER_TAX_ACC]
		,	CAST(CASE WHEN ([REG].[STATUS] & @StsIsIndividual) =  @StsIsIndividual THEN 1 ELSE 0 END AS BIT)
									AS [IS_INDIVIDUAL_DEAL]
		,	CAST(CASE WHEN ([REG].[STATUS] & @StsNoAutoPayTax) =  @StsNoAutoPayTax THEN 1 ELSE 0 END AS BIT)
									AS [NO_AUTO_PAY_TAX]
			/* Bits from [STATUS_EXT]: */
		,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtJointDeal) =  @StsExtJointDeal THEN 1 ELSE 0 END AS BIT)
									AS [IS_JOINT_DEAL]
		,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExcludeFromBankCollection) =  @StsExcludeFromBankCollection THEN 1 ELSE 0 END AS BIT)
									AS [EXCLUDE_FROM_BANK_COLLECTIONS]
		,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtCapitOnBaseDateOpen) =  @StsExtCapitOnBaseDateOpen THEN 1 ELSE 0 END AS BIT)
									AS [CAPIT_ON_BASE_DATE_OPEN]
		,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtDenyManualTaxAssign) =  @StsExtDenyManualTaxAssign THEN 1 ELSE 0 END AS BIT)
									AS [IS_DENY_MANUAL_TAX_ASSIGN]

) [STS]
OUTER APPLY (
	select	top(1) cast(1 as bit) [HAS_TAX_UNCOLLECTED]
	from [BPB_VCSBank_Online].dbo.[TAX_UNCOLLECTED] [T] WITH(NOLOCK)
	where [T].[DEAL_TYPE]  = @DealType
		AND [T].[DEAL_NUM] = [REG].[DEAL_NUM]
		AND [T].[TAX_STATUS] = 0 /* eTaxActive (0) */
) [TAX]
OUTER APPLY (
	select	top(1) cast(1 as bit) [HAS_CORRS_FOR_TAX]
	from [BPB_VCSBank_Online].dbo.[DEALS_CORR] [C] WITH(NOLOCK)
	where [C].[CORR_TYPE] = @CorrTaxServices
		and	[C].[DEAL_TYPE] = @DealType
		and [C].[DEAL_NUMBER] = [REG].[DEAL_NUM]
) [CORR]
--OUTER APPLY (
--	select top(1) cast(1 as bit) [HAS_ZAPOR]
--	FROM [BPB_VCSBank_Online].dbo.[BLOCKSUM] [B] WITH(NOLOCK)
--	INNER JOIN [BPB_VCSBank_Online].dbo.[NOMS] [N] WITH(NOLOCK)
--		ON	[N].[NOMID] = 136 /* FRZSUMREASON (136) */
--		AND [N].[CODE]	= [B].[WHYFREEZED]
--		AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
--	WHERE [B].[PARTIDA] = [REG].[ACCOUNT]
--		AND [B].[ENDDATE] > @DateAcc
--		AND ([B].[STATUS] & @StsDeleted) <> @StsDeleted
--		AND ([B].[STATUS] & @StsCloased) <> @StsCloased
--) [BLCK]
WHERE	([REG].[STATUS] & @StsDeleted) <> @StsDeleted
	and ([REG].[STATUS] & @StsCloased) <> @StsCloased
GO

select * from dbo.[AGR_CASH_PAYMENTS_DEALS]
go

select * from dbo.[AGR_CASH_PAYMENTS_DEALS]
WHERE [DEAL_HAS_CORRS_FOR_TAX] = 1
go

/*********************************************/
--1		Титуляр                                               
--2		Пълномощник                                           
--3		Законен представител                                  
--4		Действителен собственик                               
--5		Трето лице                                            
--6		Картодържател                                         
--100	Наследник                                             
--101	Трето лице-представляващ   

WITH [CL_CODES] AS 
(
	SELECT [DEAL_CLIENT_CODE] AS CLIENT_CODE
	FROM dbo.[AGR_CASH_PAYMENTS_DEALS] [S] WITH(NOLOCK)
	GROUP BY [DEAL_CLIENT_CODE]
)
SELECT  [D].[CUSTOMER_ID]
	,	[P].*
from [CL_CODES] [X] 
INNER JOIN [BPB_VCSBank_Online].dbo.[DT015] [D] WITH(NOLOCK)
	ON [D].[CODE] = [X].[CLIENT_CODE]
INNER JOIN [BPB_VCSBank_Online].dbo.[PROXY_SPEC] [P] WITH(NOLOCK)
	ON [P].[REPRESENTED_CUSTOMER_ID] = [D].[CUSTOMER_ID]
GO

select [REG].DEAL_TYPE, [REG].DEAL_NUM
	, [c].*
from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
cross apply (

	select	TOP (1) [T].*
		from [BPB_VCSBank_Online].dbo.[CSC_CARDS] [T] WITH(NOLOCK)
		where [REG].[DEAL_TYPE]  = 1
			AND [T].[PART_ID] = [REG].[DEAL_ACCOUNT]
) [c]
GO

--select * from [BPB_VCSBank_Online].dbo.[noms] where nomid = 622

SELECT TOP (10) * 
FROM [BPB_VCSBank_Online].dbo.[PROXY_SPEC] WITH(NOLOCK)

/*
DEAL_IS_INDIVIDUAL_COND_PKGS
DEAL_NO_AUTO_PAY_TAX
DEAL_HAS_OTHER_TAX_ACC
DEAL_IS_INDIVIDUAL_DEAL
DEAL_IS_JOINT_DEAL
DEAL_EXCLUDE_FROM_BANK_COLLECTIONS
DEAL_CAPIT_ON_BASE_DATE_OPEN
DEAL_IS_DENY_MANUAL_TAX_ASSIGN
DEAL_IS_INDIVIDUAL_COMBINATION
DEAL_IS_INDIVIDUAL_PROGRAM_GS
*/
select *
from dbo.[AGR_CASH_PAYMENTS_DEALS] WITH(NOLOCK)
where [DEAL_HAS_TAX_UNCOLLECTED] = 0
go

/* DEAL_IS_INDIVIDUAL_PROGRAM_GS */
select [P].*
from dbo.[AGR_CASH_PAYMENTS_DEALS] [A] WITH(NOLOCK)
INNER JOIN [BPB_VCSBank_Online].dbo.[GS_INDIVIDUAL_PROGRAMME] [P]
	ON	[A].DEAL_TYPE	= [P].[DEAL_TYPE]
	AND [A].DEAL_NUM	= [P].[DEAL_NUMBER]
go

select *
from dbo.[AGR_CASH_PAYMENTS_DEALS] WITH(NOLOCK)
go
