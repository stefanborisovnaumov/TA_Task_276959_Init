SELECT * FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
WHERE DEAL_IS_JOINT_DEAL = 1
GO

-- CGSAdditionalInfoC().GetInfoAboutFirmProgram

SELECT * FROM BPB_VCSBank_Online.DBO.DEAL_TO_CUSTOMERS_RELATION
WHERE DEAL_TYPE = 1 AND DEAL_NUMBER = 2437321
GO

SELECT * FROM BPB_VCSBank_Online.DBO.NOMS 
WHERE NOMID = 418
GO

SELECT * FROM BPB_VCSBank_Online.DBO.RAZPREG
WHERE  DEAL_NUM = 2437321
GO

select 'NM' + STR([T].nomid,LEN([T].nomid),0) + ' - ' + RTRIM([T].[NAME]) AS NM
	,	[T].SIZE
	,	[N].CODE
	,	RTRIM([N].[NAME]) AS [NAME]
from BPB_VCSBank_Online.DBO.top_noms [T]
INNER JOIN BPB_VCSBank_Online.DBO.NOMS [N]
	ON	[N].NOMID = [T].nomid
where [T].nomid in ( 455, 620, 622 )  
go

SELECT [D].*
FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
WHERE [D].DEAL_HAS_OTHER_TAX_ACC = 1
GO

SELECT [T].*
FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] [T]
LEFT OUTER JOIN dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	ON [D].DEAL_NUM = [T].DEAL_NUM
WHERE [D].DEAL_NUM  IS NULL
GO

SELECT [D].*
FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
LEFT OUTER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] [T]
	ON [D].DEAL_NUM = [T].DEAL_NUM
WHERE [D].DEAL_HAS_OTHER_TAX_ACC = 1
	AND [T].DEAL_NUM  IS NULL
GO

SELECT [D].*
FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
WHERE [D].DEAL_IS_JOINT_DEAL = 1
	AND [D].DEAL_JOINT_ACCESS_TO_FUNDS_TYPE = 1
GO


SELECT *
FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C]
WHERE EXISTS 
(
	SELECT *
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES] [P]
	WHERE [P].CUSTOMER_ID = [C].CUSTOMER_ID
)
GO

SELECT [cc].code, [p].* 
FROM BPB_VCSBank_Online.dbo.[PROXY_SPEC] [p]
inner join BPB_VCSBank_Online.dbo.[dt015] [cc]
	on [cc].CUSTOMER_ID = [p].REPRESENTED_CUSTOMER_ID
where [p].REPRESENTATIVE_CUSTOMER_ID = 991818
go

select top (10) * 
from BPB_VCSBank_Online.dbo.REPRESENTATIVE_DOCUMENTS
go

SELECT dbo.CheckBitEx(d.[STATUS], 4) as bits
	,	[d].*
FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES] [P]

inner join BPB_VCSBank_Online.dbo.[PROXY_SPEC] [ps]
	on  [ps].REPRESENTATIVE_CUSTOMER_ID  = [p].CUSTOMER_ID
	and [ps].REPRESENTED_CUSTOMER_ID = 1100292

inner join BPB_VCSBank_Online.dbo.REPRESENTATIVE_DOCUMENTS [d]
	on [d].PROXY_SPEC_ID = [ps].id

--DOCUMENT_STATUS
--3
go

select [C].CUSTOMER_ID
FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
WHERE EXISTS 
(
	SELECT *
	FROM BPB_VCSBank_Online.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
	WHERE	[PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
		AND [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
		AND [PS].[CUSTOMER_ROLE_TYPE] IN ( 2 /* NM622: 2 - ����������� */ )
) 
go

select	[C].CUSTOMER_ID
	,	[C].CLIENT_CODE_MAIN
	,	[x].*
FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
cross apply (
	SELECT	[PS].[REPRESENTATIVE_CUSTOMER_ID]
		,	[PS].[REPRESENTED_CUSTOMER_ID]
		,	[d].DOCUMENT_STATUS
		,	[d].INDEFINITELY
		,	[d].VALIDITY_DATE
	FROM BPB_VCSBank_Online.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
	inner join BPB_VCSBank_Online.dbo.REPRESENTATIVE_DOCUMENTS [d] WITH(NOLOCK)
		on [d].PROXY_SPEC_ID = [ps].id
	WHERE	[PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
		AND [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
		AND [PS].[CUSTOMER_ROLE_TYPE] IN ( 2 /* NM622: 2 - ����������� */ )
) [x]
go

select top 10 * 
from BPB_VCSBank_Online.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK) 
go
select * from BPB_VCSBank_Online.dbo.noms where nomid = 622
go

DECLARE @DealType int = 1 /* Razp deals */
		,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */

SELECT	[D].[DEAL_TYPE]
		,	[D].[DEAL_NUM]
		,	[CRL].[REPRESENTED_CUSTOMER_ID] 
		,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
		,	[CRL].[CUSTOMER_ROLE_TYPE] 

FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] WITH(NOLOCK)
INNER JOIN BPB_VCSBank_Online.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK) 
	ON	[CRL].[DEAL_TYPE]	= @DealType 
	AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
	AND	[CRL].[CHANNEL]		= 1	/* NM455 (Chanels) : 1 ������� ������� �������, ... */
	AND	[CRL].[CUSTOMER_ROLE_TYPE] in (1, 3) /* NM622 (client roles): 1 - �������, 3 - ������� ������������, ... */
	AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - ������, 2 - �������, ... */
WHERE ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated /* STS_LIMIT_DEACTIVATED 12 (�����������) */
go

drop table if exists #AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS 
go

DECLARE @DealType int = 1 /* Razp deals 1 */
	,	@DateAcc date = '2022-05-01'
	,	@RoleProxy int = 2 /* NM622 (client roles): 1 - �������, 2- �����������; 3 - ������� ������������, ... */
	,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
;
SELECT	[D].[DEAL_TYPE]
		,	[D].[DEAL_NUM]
		,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 

into #AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS 
FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] WITH(NOLOCK)
INNER JOIN BPB_VCSBank_Online.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK) 
	ON	[CRL].[DEAL_TYPE]	= @DealType 
	AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
	AND	[CRL].[CHANNEL]		= 1	/* NM455 (Chanels) : 1 ������� ������� �������, ... */
	AND	[CRL].[CUSTOMER_ROLE_TYPE] = @RoleProxy
	AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - ������, 2 - �������, ... */
where  ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated 
and exists
(
	select * 
	FROM BPB_VCSBank_Online.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
	inner join BPB_VCSBank_Online.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH(NOLOCK)
		on [d].[PROXY_SPEC_ID] = [ps].id
	where	[PS].[REPRESENTED_CUSTOMER_ID] = [CRL].REPRESENTED_CUSTOMER_ID
		and [PS].[REPRESENTED_CUSTOMER_ID] = [CRL].REPRESENTED_CUSTOMER_ID
		and [PS].[CUSTOMER_ROLE_TYPE] = @RoleProxy
		and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] > @DateAcc)
)
go

select DEAL_NUM, count(*) as cnt
from #AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS 
group by [DEAL_NUM]
having count(*) > 1
order by cnt desc
go


SELECT * FROM AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS
WHERE REPRESENTATIVE_CUSTOMER_ID = 1187188
GO

SELECT REPRESENTATIVE_CUSTOMER_ID, COUNT(*) AS CNT
FROM  AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS 
GROUP BY REPRESENTATIVE_CUSTOMER_ID
HAVING COUNT(*) > 1
ORDER BY CNT DESC
GO


WITH PROXY_CUST_ID AS 
(
	SELECT REPRESENTATIVE_CUSTOMER_ID AS CUST_ID
	FROM  AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS 
	GROUP BY REPRESENTATIVE_CUSTOMER_ID
)
SELECT [X].*
FROM PROXY_CUST_ID [P]
INNER JOIN AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS [X]
	ON [P].CUST_ID = [X].REPRESENTATIVE_CUSTOMER_ID
LEFT OUTER JOIN  AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS [C]
	ON [C].CUSTOMER_ID = [P].CUST_ID
WHERE [C].CUSTOMER_ID IS NULL
ORDER BY [X].DEAL_NUM
GO

SELECT * FROM AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS
WHERE DEAL_NUM = 52060
GO

SELECT DISTINCT [CUSTOMER_ID]
FROM 
(
	SELECT DISTINCT CUSTOMER_ID
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS WITH(NOLOCK)
	UNION ALL 
	SELECT DISTINCT REPRESENTATIVE_CUSTOMER_ID
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS WITH(NOLOCK)
) 
[A] 
GO

SELECT * FROM AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS
WHERE CUSTOMER_ID = 4655500
GO