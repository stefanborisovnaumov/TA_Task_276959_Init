/*************************************************************************************/
-- Създаваме временна таблица за ресултата
drop table if exists dbo.[#TBL_ONLINE_DT015_INFO]
;

create table dbo.[#TBL_ONLINE_DT015_INFO]
(
	[CUSTOMR_ID]			int
,	[UI_EGFN]				varchar(50)
,	[NAME]					varchar(128)
,	[COMPANY_EFN]			varchar(50)
,	[UI_CLIENT_CODE]		varchar(32)
,	[UI_NOTES_EXIST]		int
,	[IS_ZAPOR]				int
,	[ID_NUMBER]				varchar(50)
,	[SERVICE_GROUP_EGFN]	varchar(50)
,	[IS_ACTUAL]				int
,	[PROXY_COUNT]			int
)
;
/*************************************************************************************/
-- Попълване на времената талица
declare @OnleneSqlServerName sysname = 'YYANKOV\SQL2016'
	,	@OnleneSqlDataBaseName sysname = 'BPB_VCSBank_Online' 
	,	@CurAccData datetime = GetDate()
	,	@CUSTOMER_ID	int =  1500015 -- 992751

	,	@Ret			int = 0;

exec @Ret = dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @CurAccData, @CUSTOMER_ID
select @Ret as [EXEC_RESULT]
go

/*************************************************************************************/
-- Прегледа на резултата 
select *
from dbo.[#TBL_ONLINE_DT015_INFO]
go
