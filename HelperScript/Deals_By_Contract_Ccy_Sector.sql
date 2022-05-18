/*******************************************************************************************************/
/* Скрипт за OnlineDb */
/* Брой на активните сделки по No на договори, валита и сектор: */
DECLARE @StsClosed int = dbo.SetBit( cast( 0 as binary(4)), 9, 1)
;
select [R].[STD_DOG_CODE], [R].[CURRENCY_CODE]
	,	min([C].[INI] ) as [CCY_ISO_CODE]
	,	[R].[KL_SECTOR] as [CLIENT_SECTOR]
	,	COUNT(*) AS [COUNT_DEALS]
INTO #TMP_CONTRACTS
from dbo.[RAZPREG] [R] with(nolock)
inner join dbo.[DT008] [C] with(nolock)
	on [C].[CODE] = [R].[CURRENCY_CODE]
where ([R].[STATUS] & @StsClosed) <> @StsClosed
GROUP BY [R].[STD_DOG_CODE], [R].[CURRENCY_CODE], [R].[KL_SECTOR]
ORDER BY [STD_DOG_CODE], [CURRENCY_CODE], [CLIENT_SECTOR]
GO

/*******************************************************************************************************/
/* Извеждаме само групите с повече от 1000 бройки: */
declare @MinCount int = 1000
SELECT * FROM #TMP_CONTRACTS
WHERE [COUNT_DEALS] > @MinCount
ORDER BY [STD_DOG_CODE], [CURRENCY_CODE], [CLIENT_SECTOR]
GO
