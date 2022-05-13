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
from BPB_VCSBank_Online.dbo.[RAZPREG] [REG] with(nolock)
inner join BPB_VCSBank_Online.dbo.[IBAN_IDENT] [II] with(nolock)
	ON	[II].[ID] = [REG].[ACCOUNT]
	AND [II].[IBAN_TYPE] = 0 /* 0 - eIban_Real*/
inner join BPB_VCSBank_Online.dbo.[DT008] [ACC_FIX] with(nolock)
	on [ACC_FIX].[CODE] = [REG].[CURRENCY_CODE]
inner join BPB_VCSBank_Online.dbo.[PARTS] [ACC] with(nolock)
	ON [REG].[ACCOUNT] = [ACC].[PART_ID]
left outer join BPB_VCSBank_Online.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
	ON [DM].[IDENT] = [REG].[ACCOUNT]
left outer join BPB_VCSBank_Online.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
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
	from BPB_VCSBank_Online.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
	WHERE	[T].[TAX_STATUS] =  0
		AND [T].[ACCOUNT_DT] = [REG].[ACCOUNT]
		--AND [T].[DEAL_TYPE]	 = 1
		--AND [T].[DEAL_NUM]	 = [REG].[DEAL_NUM]

) [TAX]
outer apply (
	SELECT SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
	FROM BPB_VCSBank_Online.dbo.BLOCKSUM [B] WITH(NOLOCK) 
	INNER JOIN BPB_VCSBank_Online.dbo.[NOMS] [N] WITH(NOLOCK) 
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

select	SUM( [T].[AMOUNT] - [T].[COLLECTED_AMOUNT] ) AS [TAX_UNCOLLECTED_SUM]
	,	SUM([T].DDS_AMOUNT) AS [TAX_DDS]
from BPB_VCSBank_Online.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
inner join 
WHERE	[T].[TAX_STATUS] =  0
	and [t].DEAL_TYPE = 1
	and [t].DEAL_NUM = 312421
go
	
/******************************************************************/
select ([AMOUNT] * [F].[FIXING])  - ([COLLECTED_AMOUNT] * [F].[FIXING]) AS [TAX_SUM]
	,	[AMOUNT], [COLLECTED_AMOUNT],  [F].[FIXING]
SELECT TOP (10) *
from BPB_VCSBank_Online.dbo.[TAX_UNCOLLECTED] [TAX]
cross join  (
	select top (1) [C].[CODE] AS [CCY]
		,	[C].[BNB_EXCHANGE_RATE] as [FIXING]
	from BPB_VCSBank_Online.dbo.dt008 [c] with(nolock)
	where [C].[CODE] = 978
) [ACC_FIX]
WHERE [DEAL_TYPE] = 1
	AND [DEAL_NUM] = 1481712
	AND [TAX_STATUS] =  0
	and ORIGINAL_CURRENCY <> 100
--	[ACCOUNT_DT] = '1714940627373038'
GO

SELECT TOP (10) *
from BPB_VCSBank_Online.dbo.[TAX_UNCOLLECTED]
where ORIGINAL_CURRENCY <> 100
	and DDS_AMOUNT <> 0
	and DDS_COLLECTED_AMOUNT <> 0
go

SELECT CODE, [BNB_EXCHANGE_RATE]
FROM BPB_VCSBank_Online.dbo.DT008

SELECT * FROM  BPB_VCSBank_Online.SYS.TABLES WHERE NAME LIKE '%DT008%'

SELECT TOP 10 [ACCOUNT_DT], [DEAL_NUM], COUNT(*) AS CNT 
from [TAX_UNCOLLECTED] [TAX]
WHERE TAX_STATUS =  0
	AND [DEAL_TYPE] = 1
GROUP BY [ACCOUNT_DT], [DEAL_NUM]
HAVING COUNT(*) > 0
ORDER BY CNT -- DESC
GO

/******************************************************************/
-- Сделки с много такси
-- 9182533
--ACCOUNT_DT			DEAL_NUM	CNT
--1714947604290025      227689		5619
--1714924749387013      1867933		4465
--1714938554940027      309896		2665
--1713947630727037      1883177		2419
--1815978942750944024   1481712		2146
--1714898229404014      1641996		1945
--1714601505184007      9373826		1914
--1713940551452014      312421		1725
--1714940756765023      1556753		1702
--1714898181927016      1688017		1454

/******************************************************************/
-- Сделки с малко такси 1
--ACCOUNT_DT	DEAL_NUM	CNT
--1714170032206012                 	2151537	2
--1714898051444010                 	2413509	2
--1714940904680026                 	2416992	2
--1714942535195010                 	506236	2
--1714942621037038                 	389303	2
--1714937191098026                 	1577455	2
--1714947887735019                 	169377	2
--1714941756569039                 	1056351	2
--1714932597609019                 	1384494	2
--1714948620369010                 	2345616	2

/******************************************************************/
-- Сделки с малко такси 2
--ACCOUNT_DT	DEAL_NUM	CNT
--1714937275802013                 	2430799	1
--1714943756114038                 	89395	1
--1714942751960013                 	1108767	1
--1714922133515015                 	582063	1
--1815978945872360018              	652227	1
--1714942577734043                 	1518640	1
--1714942780101010                 	557697	1
--1714937693326024                 	225216	1
--1714159224398015                 	9531989	1
--1714940625130026                 	1211239	1