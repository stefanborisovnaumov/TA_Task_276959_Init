
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

DECLARE @DB_TYPE varchar(64)		= N'AIR'
	,	@TA_Type_Lile varchar(64)	= N'%AIR%'
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


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] 
(
	 [CUSTOMER_ID] int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] 
(
	 [CUSTOMER_ID] int
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
(
	[CUSTOMER_ID]	int
,	[DEAL_TYPE] 	smallint
,	[CURRENCY_CODE]	smallint
,	[DEAL_COUNT]	int
)
go

DROP INDEX IF EXISTS [IX_AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] 
GO
CREATE NONCLUSTERED INDEX [IX_AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] 
		([DEAL_TYPE],[CURRENCY_CODE],[DEAL_COUNT])
	INCLUDE ( [CUSTOMER_ID] )
GO

DROP INDEX IF EXISTS [IX_AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_CUSTOMER_ID_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] 
GO
CREATE NONCLUSTERED INDEX [IX_AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_CUSTOMER_ID_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] ([CUSTOMER_ID],[DEAL_TYPE],[CURRENCY_CODE],[DEAL_COUNT])
GO


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
(
	[DEAL_TYPE] 	smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
,	[DEAL_GS_INDIVIDUAL_PROGRAM_CODE]	int 
,	[DEAL_GS_INDIVIDUAL_PRODUCT_CODE]	int 
,	[DEAL_GS_INDIVIDUAL_CARD_PRODUCT]	int

)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
(
	[DEAL_TYPE] 		smallint
,	[DEAL_NUM]			int
,	[CORR_ACCOUNT]		varchar(64)
,	[PART_CURRENCY]		int
,	[ACCOUNT_BEG_DAY_BALANCE]	float
,	[BLK_SUMA_MIN]				float
,	[DAY_OPERATION_BALANCE]		float
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
(
	[DEAL_TYPE]						smallint
,	[DEAL_NUM]						int
,	[REPRESENTED_CUSTOMER_ID] 		int 
,	[REPRESENTATIVE_CUSTOMER_ID] 	int 
,	[CUSTOMER_ROLE_TYPE] 			int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
go

create table dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
(
	[DEAL_TYPE]						smallint
,	[DEAL_NUM]						int
,	[REPRESENTATIVE_CUSTOMER_ID]	int 
,	[CUSTOMER_ROLE_TYPE] 			int
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
(
	[EGFN] 		BIGINT
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
(
	[CUSTOMER_ID] int 
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
(
	[CUSTOMER_ID] int 
,	[IS_ORIGINAL_EGFN] bit
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
(
	[CUSTOMER_ID] int 
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
(
	[CUSTOMER_ID] int 
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
go

create table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
(
	[CUSTOMER_ID] int 
)
go

/*****************************************************************************/
-- Create INDEX ON table dbo.[AGR_CASH_PAYMENTS_DEALS]
--DROP INDEX IF EXISTS [IX_AGR_CASH_PAYMENTS_DEALS_DEAL_CURRENCY_CODE_CUSTOMER_ID_DEAL_NUM] 
--	ON [dbo].[AGR_CASH_PAYMENTS_DEALS]
--go

--CREATE NONCLUSTERED INDEX [IX_AGR_CASH_PAYMENTS_DEALS_DEAL_CURRENCY_CODE_CUSTOMER_ID_DEAL_NUM]
--	ON [dbo].[AGR_CASH_PAYMENTS_DEALS] ([DEAL_CURRENCY_CODE],[CUSTOMER_ID],[DEAL_NUM])
--go

