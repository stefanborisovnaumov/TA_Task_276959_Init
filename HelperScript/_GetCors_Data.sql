DECLARE @StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
	,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
;

select	[REG].[DEAL_NUM]
	,	[REG].[ACCOUNT]
	,	[II].[IBAN] 
	,	[BAL].[BEG_SAL]
	,	[BAL].[DAY_MOVE]
	,	[ACC].[BLK_SUMA_MIN]
	,	[BAL].[RAZPOL]
	,	[BAL].[TAX_UNCOLLECTED_SUM]
	,	[BAL].[DISTRAINT_SUM]
--INTO AGR_TMP
from [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.[DEALS_CORRS] [REG] with(nolock)
inner join [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.[IBAN_IDENT] [II] with(nolock)
	ON	[II].[ID] = [REG].[ACCOUNT]
	AND [II].[IBAN_TYPE] = 0 /* 0 - eIban_Real*/
inner join [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.[PARTS] [ACC] with(nolock)
	ON [REG].[ACCOUNT] = [ACC].[PART_ID]
left outer join [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.[DAY_MOVEMENTS] [DM] with(nolock)
	ON [DM].[IDENT] = [REG].[ACCOUNT]
left outer join [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
	ON [FM].[IDENT] = [REG].[ACCOUNT]
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
	from [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.[TAX_UNCOLLECTED] [T]
	WHERE	[T].[TAX_STATUS] =  0
		AND [T].[DEAL_TYPE]	 = 1
		AND [T].[DEAL_NUM]	 = [REG].[DEAL_NUM]
--		AND [T].[ACCOUNT_DT] = [REG].[ACCOUNT]
) [TAX]
outer apply (
	SELECT SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
	FROM [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.BLOCKSUM [B] WITH(NOLOCK) 
	INNER JOIN [TESTSERVER18\SQL2016].[BPB_online_NEXT].dbo.[NOMS] [N] WITH(NOLOCK) 
		ON	[N].[NOMID] = 136 
		AND [N].[CODE]	= [B].[WHYFREEZED] 
		AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint 
	WHERE [B].[PARTIDA] = [REG].[ACCOUNT] 
) [DST]
cross apply (
	SELECT	ROUND([XBAL].[BEG_SAL], 4) AS [BEG_SAL]
		,	ROUND([XBAL].[DAY_MOVE], 4)  AS [DAY_MOVE]
		,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [RAZPOL]
		,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4) as [DISTRAINT_SUM]
		,	ROUND(IsNull([TAX].[TAX_UNCOLLECTED_SUM],0), 4) as [TAX_UNCOLLECTED_SUM]
) [BAL]
where [REG].[DEAL_NUM] = 7646 -- 312421-- 1481712 -- 2345616
GO





DECLARE @StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
	,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
;

select	[REG].[DEAL_NUM]
	,	[REG].[ACCOUNT]
	,	[II].[IBAN] 
	,	[BAL].[BEG_SAL]
	,	[BAL].[DAY_MOVE]
	,	[ACC].[BLK_SUMA_MIN]
	,	[BAL].[RAZPOL]
	,	[BAL].[TAX_UNCOLLECTED_SUM]
	,	[BAL].[DISTRAINT_SUM]
SELECT TOP 
from [BPB_VCSBank_Online].dbo.[DEALS_CORR] [REG]
WHERE [REG].[DEAL_NUMBER] = 