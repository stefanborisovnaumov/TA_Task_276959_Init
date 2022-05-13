/*************************************************************************************/
-- Създаваме временна таблица за ресултата
drop table if exists dbo.[#TBL_ONLINE_DEAL_INFO]
go

create table dbo.[#TBL_ONLINE_DEAL_INFO]
(
	[DEAL_NUM]			int
,	[ACCOUNT]			varchar(64)
,	[IBAN]				varchar(64)
,	[BEG_SAL]			float
,	[DAY_MOVE]			float
,	[BLK_SUMA_MIN]		float
,	[RAZPOL]			float
,	[TAX_UNCOLLECTED]	float
,	[DISTRAINT_SUM]		float
)
go

/*************************************************************************************/
-- Попълване на времената талица
declare @OnleneSqlServerName sysname = 'YYANKOV\SQL2016'
	,	@OnleneSqlDataBaseName sysname = 'BPB_VCSBank_Online' 
	,	@DEAL_TYPE	int = 1
	,	@DEAL_NUM	int = 312421
	,	@Ret		int = 0;

exec @Ret = dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @DEAL_TYPE, @DEAL_NUM
go

/*************************************************************************************/
-- Прегледа на резултата 
select * 
from dbo.[#TBL_ONLINE_DEAL_INFO]
go

select TOP 10 [DM].*, [P].DEAL_NUMBER, [P].DEAL_TYPE
from BPB_VCSBank_Online.dbo.DAY_MOVEMENTS [DM]
INNER JOIN BPB_VCSBank_Online.dbo.FUTURE_MOVEMENTS [FM]
	ON	[FM].IDENT = [DM].IDENT
	AND LEFT( [FM].IDENT, 4) IN (1714, 1832)
INNER JOIN BPB_VCSBank_Online.dbo.PARTS [P]
	ON [P].[PART_ID] = [DM].IDENT
INNER JOIN BPB_VCSBank_Online.dbo.BLOCKSUM [B]
	ON [B].[PARTIDA] = [DM].IDENT
WHERE [FM].[VNB_DBT] > 0
GO
