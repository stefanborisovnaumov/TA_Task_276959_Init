/* Вид на картата: VISA, MS, AMEX, Борика, ... */
select [n].CODE, [n].NAME, dbo.CheckBitEx( STATUS, 4) AS BITS
from noms [n] 
WHERE [n].NOMID = 221
	AND [n].CODE = 1
order by [n].CODE
go

/* Вид на карта */
select [n].NAME
	, [e].* 
from DT138 [e]
inner join DETS [n] 
	on	[n].DETID = [e].DETID
	and [n].[CODE] = [e].CODE
WHERE [e].CODE = 18 /**/
order by [e].CODE
go

/* Получател: */
select [n].NAME
	, [e].* 
from NM191 [e]
inner join noms [n] 
	on	[n].NOMID = [e].NOMID
	and [n].[CODE] = [e].CODE
where [n].NAME like '%VISA%Classic%'
	AND [E].CODE = 404
order by [n].NAME
go

/* Тип на карта: */
select [n].NAME
	, [e].* 
from NM204 [e]
inner join noms [n] 
	on	[n].NOMID = [e].NOMID
	and [n].[CODE] = [e].CODE
where [E].SECTOR = 5000
	AND TYPE_VID = 18
order by [n].NAME
go


/* GS Programs : */
select [n].NAME
	, [e].* 
from NM245 [e]
inner join noms [n] 
	on	[n].NOMID = [e].NOMID
	and [n].[CODE] = [e].CODE
where [E].CODE = 26
order by [n].NAME
go

select top (10) * 
from GS_INDIVIDUAL_PROGRAMME [p] with(nolock)
where PROGRAMME_CODE = 26
	and CARD_PRODUCT = 54
go

select top (10) * 
from dbo.[GS_PRODUCTS] with(nolock)
WHERE DEAL_TYPE = 1
	and  TYPE_CARDHOLDER_STD <> 0
	and  TYPE_CARDHOLDER_PREMIUM <> 0
GO

select top (10) [s].SALE_CODE, [s].PRODUCT_CODE, [s].DEAL_NUMBER, [s].CLIENT_CODE, [s].DEAL_TYPE
	, dbo.CheckBitEx([s].[STATUS], 4) AS BITS
	,	P.*
from dbo.[GS_SALES] [s] with(nolock)
inner join dbo.[GS_PRODUCTS] [p]  with(nolock)
	on [s].[PRODUCT_CODE] = [p].[CODE]
GO

/* Тип клиент (ДТ300)*/
select	'DT'+STR([t].DETID,LEN([t].DETID), 0) + ' - ' + rtrim([T].NAME) AS NOM_NAME
	,	[e].CODE
	,	rtrim([n].NAME) as [NAME]
from DT300 [e]
inner join DETS [n] 
	on	[n].DETID = [e].DETID
	and [n].[CODE] = [e].CODE
inner join TOP_DETS [t]
	on	[t].DETID = [n].DETID
	and [t].DETID = [e].DETID
order by [e].CODE
go

-- (1269 rows affected)
WITH CTE AS 
(
	SELECT	LEFT(LTRIM(IDENTIFIER), 13) AS CLIENT_ID
		,	COUNT(*) AS CNT 
	FROM DT015_CUSTOMERS [R]
	GROUP BY LEFT(LTRIM(IDENTIFIER), 13)
	HAVING COUNT(*) > 1
) 
SELECT * FROM CTE
ORDER BY CNT DESC
GO

-- 2 896 777
select COUNT(*) 
FROM DT015_CUSTOMERS
GO

/* Видове клиентски роли: */
select	[t].NOMID 
	,	RTRIM([t].[NAME]) as NOM_NAME
	,	[n].CODE
	,	RTRIM([n].NAME) AS [NAME]
	,	DBO.CheckBitEx( [n].[STATUS], 4) AS Bits
from noms [n] 
inner join TOP_NOMS [t]
	on	[t].NOMID = [n].NOMID
	and [t].NOMID = 622
go


/* NM612 - Вид клиент: */
select	'NM'+STR([t].NOMID,LEN([t].NOMID), 0) + ' - ' + rtrim([T].NAME) AS NOM_NAME
	,	RTRIM([t].[NAME]) as NOM_NAME
	,	[n].CODE
	,	RTRIM([n].NAME) AS [NAME]
	,	DBO.CheckBitEx( [n].[STATUS], 4) AS Bits
from noms [n] 
inner join TOP_NOMS [t]
	on	[t].NOMID = [n].NOMID
	and [t].NOMID = 612
go



/* NM614 - Вид клиент: */
select	'NM'+STR([t].NOMID,LEN([t].NOMID), 0) + ' - ' + rtrim([T].NAME) AS NOM_NAME
	,	RTRIM([t].[NAME]) as NOM_NAME
	,	[n].CODE
	,	RTRIM([n].NAME) AS [NAME]
	,	DBO.CheckBitEx( [n].[STATUS], 4) AS Bits
	,	[e].*
from noms [n] with(nolock)
inner join NM614 [e] with(nolock)
	on	[e].[NOMID] = [n].[NOMID]
	and [e].[CODE]	= [n].[CODE]
inner join TOP_NOMS [t]
	on	[t].NOMID = [n].NOMID
go
