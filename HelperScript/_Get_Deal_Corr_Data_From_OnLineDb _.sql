declare @DealType		int = 1
	,	@DealNum		int = 268741
	,	@CorrAccType	int = 3
	,	@CorrAccount	varchar(33) = '1713320642638004'
;

DECLARE @DealType int = 1 
	,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
	,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
;

select	[ACC].[DEAL_TYPE]			AS [CORR_DEAL_TYPE]
	,	[ACC].[DEAL_NUMBER]			AS [CORR_DEAL_NUMBER]
	,	[CORR].[CORR_ACCOUNT]		AS [CORR_ACCOUNT]
	,	[ACC].[PART_CURRENCY]		AS [CORR_ACCOUNT_CCY]
	,	[ACC].[BLK_SUMA_MIN]		AS [BLK_SUMA_MIN]
	,	[BAL].[AVAILABLE_BAL]		AS [AVAILABLE_BAL]
	,	[BAL].[TAX_UNCOLLECTED_SUM]	AS [TAX_UNCOLLECTED_SUM]

from dbo.[DEALS_CORR] [CORR] with(nolock)
inner join dbo.[PARTS] [ACC]
	on [ACC].[PART_ID] = [CORR].[CORR_ACCOUNT]
left outer join dbo.[DAY_MOVEMENTS] [DM] with(nolock)
	ON [DM].[IDENT] = [CORR].[CORR_ACCOUNT]
left outer join dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
	ON [FM].[IDENT] = [CORR].[CORR_ACCOUNT]
cross apply (
	SELECT	CASE WHEN [ACC].[PART_TYPE] IN (1,2,5)
				THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
				ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
			END AS [BEG_SAL]

		,	CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
				THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
						-	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
							+ IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

				ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
						-	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
							+ IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
			END AS [DAY_MOVE]
) [XBAL]
outer apply 
(
	select SUM( [T].[AMOUNT] - [T].[COLLECTED_AMOUNT] ) AS [TAX_UNCOLLECTED_SUM]
	from dbo.[TAX_UNCOLLECTED] [T] with(nolock)
	WHERE	[T].[ACCOUNT_DT] = [CORR].[CORR_ACCOUNT]
		/* AND [T].[DEAL_TYPE]	= @DealType */
		/* AND [T].[DEAL_NUM]	= [REG].[DEAL_NUM] */
		AND [T].[TAX_STATUS] =  0
) [TAX]
outer apply (
	SELECT SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
	FROM dbo.[BLOCKSUM] [B] with(nolock)
	INNER JOIN dbo.[NOMS] [N] with(nolock)
		ON	[N].[NOMID] = 136 
		AND [N].[CODE]	= [B].[WHYFREEZED] 
		AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
	WHERE [B].[PARTIDA] = [CORR].[CORR_ACCOUNT] AND [B].[CLOSED_FROZEN_SUM] = 0
) [DST]
cross apply (
	SELECT	ROUND([XBAL].[BEG_SAL], 4)	 AS [BEG_SAL]
		,	ROUND([XBAL].[DAY_MOVE], 4)  AS [DAY_MOVE]
		,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [AVAILABLE_BAL]
		,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4) as [DISTRAINT_SUM]
		,	ROUND(IsNull([TAX].[TAX_UNCOLLECTED_SUM],0), 4) as [TAX_UNCOLLECTED_SUM]
) [BAL]
where [CORR].[DEAL_TYPE]		= @DealType
	and [CORR].[DEAL_NUMBER]	= @DEAL_NUM
	and [CORR].[CORR_TYPE]		= @CorrAccType
	and [CORR].[CORR_ACCOUNT]	= '1713320642638004'
go
