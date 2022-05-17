
/*****************************************************************************/
-- Init table dbo.[TEST_AUTOMATION_TA_TYPE]
drop table if exists dbo.[TEST_AUTOMATION_TA_TYPE]
go

create table dbo.[TEST_AUTOMATION_TA_TYPE]
(
	[ID] int identity(1,1)
,	[TA_TYPE] varchar(64)
,	[DB_TYPE] varchar(64)
	constraint [PK_TEST_AUTOMATION_TA_TYPE] 
		primary key clustered( [ID] )
)
go

create unique index [IX_TEST_AUTOMATION_TA_TYPE]
	on dbo.[TEST_AUTOMATION_TA_TYPE] ( [TA_TYPE], [DB_TYPE] )
go

DECLARE @DB_TYPE varchar(64)		= N'BETA'
	,	@TA_Type_Lile varchar(64)	= N'%CashPay%BETA%'
;
insert into dbo.[TEST_AUTOMATION_TA_TYPE]
( [TA_TYPE], [DB_TYPE] )
select distinct 
		[a].[TA_TYPE]	as [TA_TYPE]
	,	@DB_TYPE		as [DB_TYPE]
from 
(
	select distinct [TA_TYPE] as [TA_TYPE]
	from dbo.[DT015_CUSTOMERS_ACTIONS_TA]
	where TA_TYPE like @TA_Type_Lile
	union all
	select distinct [TA_TYPE] 
	from dbo.[PREV_COMMON_TA] with(nolock)
	where [TA_TYPE] like @TA_Type_Lile
) [a]
left outer join dbo.[TEST_AUTOMATION_TA_TYPE] [d] with(nolock)
	on	[d].[TA_TYPE] = [a].[TA_TYPE]
	and [d].[DB_TYPE] = @DB_TYPE
where [d].[ID] is null
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
drop table if exists dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
go

create table dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
(
	[ID]				int identity(1,1)
,	[TEST_ID]			nvarchar(512) 
,	[SQL_COND]			nvarchar(1000)
,	[DESCR]				nvarchar(2000)
,	[IS_BASE_SELECT]	bit constraint _DF_AGR_CASH_PAYMENTS_SQL_CONDITIONS_IS_BASE_SELECT DEFAULT(0)
,	[IS_SELECT_COUNT]	bit constraint _DF_AGR_CASH_PAYMENTS_SQL_CONDITIONS_IS_SELECT_COUNT DEFAULT(0)
	
	CONSTRAINT [PK_AGR_AGR_CASH_PAYMENTS_SQL_CONDITIONS]
		PRIMARY KEY CLUSTERED ( [ID] )
)
go
