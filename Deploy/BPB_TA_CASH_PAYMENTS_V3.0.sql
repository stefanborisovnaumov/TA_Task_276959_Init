/***************************************************************************************************************/
-- Име          : Янко Янков
-- Дата и час   : 10.08.2022
-- Задача       : Task 282617 (v2.9.3)
-- Класификация : Test Automation
-- Описание     : Автоматизация на тестовете за Кредитните преводи с използване на наличните данни от Online базата
-- Параметри    : Няма
/***************************************************************************************************************/
-- /*****************************************************************************/
-- -- Init table dbo.[TEST_AUTOMATION_TA_TYPE]
-- drop table if exists dbo.[TEST_AUTOMATION_TA_TYPE]
-- go

-- create table dbo.[TEST_AUTOMATION_TA_TYPE]
-- (
-- 	[ID] int identity(1,1)
-- ,	[TA_TYPE] varchar(64)
-- ,	[DB_TYPE] varchar(64)
-- 	constraint [PK_TEST_AUTOMATION_TA_TYPE] 
-- 		primary key clustered( [ID] )
-- )
-- go

-- create unique index [IX_TEST_AUTOMATION_TA_TYPE]
-- 	on dbo.[TEST_AUTOMATION_TA_TYPE] ( [TA_TYPE], [DB_TYPE] )
-- go

-- DECLARE @DB_TYPE varchar(64)		= N'AIR'
-- 	,	@TA_Type_Lile varchar(64)	= N'%AIR%'
-- ;
-- insert into dbo.[TEST_AUTOMATION_TA_TYPE]
-- ( [TA_TYPE], [DB_TYPE] )
-- select distinct 
-- 		[a].[TA_TYPE]	as [TA_TYPE]
-- 	,	@DB_TYPE		as [DB_TYPE]
-- from 
-- (
-- 	select distinct [TA_TYPE] as [TA_TYPE]
-- 	from dbo.[DT015_CUSTOMERS_ACTIONS_TA]
-- 	where TA_TYPE like @TA_Type_Lile
-- 	union all
-- 	select distinct [TA_TYPE] 
-- 	from dbo.[PREV_COMMON_TA] with(nolock)
-- 	where [TA_TYPE] like @TA_Type_Lile
-- ) [a]
-- left outer join dbo.[TEST_AUTOMATION_TA_TYPE] [d] with(nolock)
-- 	on	[d].[TA_TYPE] = [a].[TA_TYPE]
-- 	and [d].[DB_TYPE] = @DB_TYPE
-- where [d].[ID] is null
-- go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS]
DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS]
GO

CREATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS]
(
	[ID]				int identity(1,1)
,	[TEST_ID]			nvarchar(512) 
,	[SQL_COND]			nvarchar(1000)
,	[DESCR]				nvarchar(2000)
,	[IS_BASE_SELECT]	bit constraint _DF_AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS_IS_BASE_SELECT DEFAULT(0)
,	[IS_SELECT_COUNT]	bit constraint _DF_AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS_IS_SELECT_COUNT DEFAULT(0)
	
	CONSTRAINT [PK_AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS_ID]
		PRIMARY KEY CLUSTERED ( [ID] )
)
GO


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT]
DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT]
GO

CREATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] 
(
	 [CUSTOMER_ID] int
)
GO

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
GO

CREATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] 
(
	 [CUSTOMER_ID] int
)
GO


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
GO

CREATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
(
	[CUSTOMER_ID]	int
,	[DEAL_TYPE] 	smallint
,	[CURRENCY_CODE]	smallint
,	[DEAL_COUNT]	int
)
GO

DROP INDEX IF EXISTS [IX_AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] 
GO
CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] 
		([DEAL_TYPE],[CURRENCY_CODE],[DEAL_COUNT])
	INCLUDE ( [CUSTOMER_ID] )
GO

DROP INDEX IF EXISTS [IX_AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_CUSTOMER_ID_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] 
GO
CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY_CUSTOMER_ID_DEAL_TYPE_CURRENCY_CODE_DEAL_COUNT]
	ON [dbo].[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] ([CUSTOMER_ID],[DEAL_TYPE],[CURRENCY_CODE],[DEAL_COUNT])
GO


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL]
(
	[DEAL_TYPE] 	smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
,	[DEAL_GS_INDIVIDUAL_PROGRAM_CODE]	int 
,	[DEAL_GS_INDIVIDUAL_PRODUCT_CODE]	int 
,	[DEAL_GS_INDIVIDUAL_CARD_PRODUCT]	int

)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT]
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
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT]
(
	[DEAL_TYPE] smallint
,	[DEAL_NUM]	int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE]
(
	[DEAL_TYPE]						smallint
,	[DEAL_NUM]						int
,	[REPRESENTED_CUSTOMER_ID] 		int 
,	[REPRESENTATIVE_CUSTOMER_ID] 	int 
,	[CUSTOMER_ROLE_TYPE] 			int
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS]
(
	[DEAL_TYPE]						smallint
,	[DEAL_NUM]						int
,	[REPRESENTATIVE_CUSTOMER_ID]	int 
,	[CUSTOMER_ROLE_TYPE] 			int
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN]
DROP TABLE IF EXISTS DBO.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN]
GO

CREATE TABLE DBO.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN]
(
	[EGFN] BIGINT
)
GO


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES]
(
	[CUSTOMER_ID] int 
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN]
(
	[CUSTOMER_ID] int 
,	[IS_ORIGINAL_EGFN] bit
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES]
(
	[CUSTOMER_ID] int 
)
go


/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
(
	[CUSTOMER_ID] int 
)
go

/*****************************************************************************/
-- Create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS]
drop table if exists dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS]
go

create table dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS]
(
	[CUSTOMER_ID] int 
)
go

/*****************************************************************************/
-- Create INDEX ON table dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
--DROP INDEX IF EXISTS [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_CURRENCY_CODE_CUSTOMER_ID_DEAL_NUM] 
--	ON [dbo].AGR_TA_EXISTING_ONLINE_DATA_DEALS
--go

--CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_CURRENCY_CODE_CUSTOMER_ID_DEAL_NUM]
--	ON [dbo].AGR_TA_EXISTING_ONLINE_DATA_DEALS ([DEAL_CURRENCY_CODE],[CUSTOMER_ID],[DEAL_NUM])
--go

/********************************************************************************************************/
/* Създаване на помощно view за Условията към тестовите сценарии */
CREATE OR ALTER VIEW dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS]
AS
	WITH [CTE_CUST_EGFN_TYPE] AS 
	(
		SELECT [X].*
		FROM ( 
			VALUES	( 1 , 'ЕГН' )
				,	( 2 , 'ЕИК/БУЛСТАТ' )
				,	( 3 , 'БАЕ' )
				,	( 4 , 'ЛНЧ' )
				,	( 5 , 'Функционално ЕГН' )
				,	( 6 , 'Функционално ЛНЧ (ЧФЛ)' )
				,	( 7 , 'Функционално ЕИК (МЮЛ)' ) 
				,	( 8 , 'Функционално ЕИК (ЧЮЛ)' )
				,	( 9 , 'Идентификатор за клиенти по ЗЗКИ' )
		) X([ID], [NAME])
	)
	, [CTE_CUSTOMER_CHARACTERISTIC] AS 
	(
		SELECT [X].*
		FROM ( 
			VALUES	(0,	'Банков клиент' )
				,	(1,	'Външен клиент' )
				,	(2,	'Prospect клиент' )
				,	(3,	'Действителен собственик' )
				,	(4,	'Клиент без активни продукти' )
		) X([ID], [NAME])
	)
	, [CTE_CUSTOMER_AGE] AS 
	(
		SELECT [X].*, GetDate() as [SYS_DATE]
		FROM (
			VALUES	(-1, 00, 190, 'Без значение' )
				,	( 1, 18, 190, 'Пълнолетно лице (над 18г.)' )
				,	( 2, 14,  17, 'Непълнолетно физическо лице (от 14г. до 18г.)' )
				,	( 3, 00,  13, 'Малолетно физическо лице (до 14г.)' )
				,	( 4, 00, 190, 'Външен клиент' )
		) X([ID], [AGE_MIN], [AGE_MAX], [NAME])
	)
	, [CTE_CCY] AS 
	(
		SELECT [X].*
		FROM ( 
			VALUES ( 36, 'AUD'), (100, 'BGN'), (124, 'CAD'), (756,	'CHF')
				,  (826, 'GBP'), (840,	'USD'), (946, 'RON'), (978,	'EUR')
		) X([ID], [NAME])		
	)
	SELECT DISTINCT
		COALESCE([PREV].[ROW_ID], BLOCKSUM_TA.ROW_ID) AS [ROW_ID]
		, COALESCE([PREV].[TA_TYPE], BLOCKSUM_TA.TA_TYPE) AS [TA_TYPE]
		, COALESCE([PREV].[DB_TYPE], BLOCKSUM_TA.DB_TYPE) AS [DB_TYPE]
		, [CUST].[ROW_ID] AS [CUST_ROW_ID]
		, [DREG].[ROW_ID] AS [DEAL_ROW_ID]
		, [CORS].[ROW_ID] AS [CORS_ROW_ID]
		, [PSPEC].[ROW_ID] AS [PSPEC_ROW_ID]
		, [PROXY].[ROW_ID] AS [PROXY_ROW_ID]
		, [CUST_BEN].[ROW_ID] AS [CUST_BEN_ROW_ID]
		, [DBEN].[ROW_ID] AS [DEAL_BEN_ROW_ID]
		/* Условия за титуляра dbo.[DT015_CUSTOMERS_ACTIONS_TA] */
		, [CUST].[SECTOR] AS [SECTOR]
		, [CUST].[UNIFIED] AS [UNIFIED]
		, [CUST].[IS_SERVICE] AS [IS_SERVICE]
		, [CUST].[EGFN_TYPE] AS [EGFN_TYPE]
		, IsNull([CTE_CUST_EGFN_TYPE].[ID], - 1) AS [CODE_EGFN_TYPE]
		, [CUST].[DB_CLIENT_TYPE] AS [DB_CLIENT_TYPE_DT300]
		, [CUST].[VALID_ID] AS [VALID_ID]
		, [CUST].[CUSTOMER_CHARACTERISTIC] AS [CUSTOMER_CHARACTERISTIC]
		, IsNull(CTE_CUSTOMER_CHARACTERISTIC.ID, - 1) AS [CODE_CUSTOMER_CHARACTERISTIC]
		, [CUST].[CUSTOMER_AGE] AS [CUSTOMER_AGE]
		, cast(IsNull(DATEADD(yy, - CTE_CUSTOMER_AGE.[AGE_MAX], CTE_CUSTOMER_AGE.[SYS_DATE]), 0) AS DATE) AS [CUSTOMER_BIRTH_DATE_MIN]
		, cast(IsNull(DATEADD(yy, - CTE_CUSTOMER_AGE.[AGE_MIN], CTE_CUSTOMER_AGE.[SYS_DATE]), 999) AS DATE) AS [CUSTOMER_BIRTH_DATE_MAX]
		, [CUST].[IS_PROXY] AS [IS_PROXY]
		, [CUST].[IS_UNIQUE] AS [IS_UNIQUE_CUSTOMER]
		, [CUST].[HAVE_CREDIT] AS [HAVE_CREDIT]
		, [CUST].[PROXY_COUNT] AS [PROXY_COUNT]
		, [CUST].[COLLECT_TAX_FROM_ALL_ACC] AS [COLLECT_TAX_FROM_ALL_ACC]
		/* Условия за пълномощника dbo.[PROXY_SPEC_TA] */
		, [PSPEC].[UI_RAZPOREDITEL] AS [UI_RAZPOREDITEL]
		, [PSPEC].[UI_UNLIMITED] AS [UI_UNLIMITED]
		/* Условия за сделката dbo.[RAZPREG_TA] */
		, [DREG].UI_STD_DOG_CODE AS [UI_STD_DOG_CODE]
		, [DREG].[UI_INDIVIDUAL_DEAL] AS [UI_INDIVIDUAL_DEAL]
		, [DREG].[INT_COND_STDCONTRACT] AS [INT_COND_STDCONTRACT]
		, [DREG].UI_NM342_CODE AS [UI_NM342_CODE]
		, CASE WHEN IsNumeric([DREG].[UI_NM342_CODE]) = 1 THEN cast([DREG].[UI_NM342_CODE] AS INT) ELSE 0 END AS [CODE_UI_NM342]
		, [DREG].UI_CURRENCY_CODE AS [UI_CURRENCY_CODE]
		, [CCY_DEAL].[ID] AS [CCY_CODE_DEAL]
		, [DREG].UI_OTHER_ACCOUNT_FOR_TAX AS [UI_OTHER_ACCOUNT_FOR_TAX]
		, [DREG].UI_NOAUTOTAX AS [UI_NOAUTOTAX]
		, [DREG].UI_DENY_MANUAL_TAX_ASSIGN AS [UI_DENY_MANUAL_TAX_ASSIGN]
		, [DREG].UI_CAPIT_ON_BASE_DATE_OPEN AS [UI_CAPIT_ON_BASE_DATE_OPEN]
		, [DREG].UI_BANK_RECEIVABLES AS [UI_BANK_RECEIVABLES]
		, [DREG].UI_JOINT_TYPE AS [UI_JOINT_TYPE]
		, [DREG].LIMIT_AVAILABILITY AS [LIMIT_AVAILABILITY]
		, [DREG].DEAL_STATUS AS [DEAL_STATUS]
		, [DREG].LIMIT_TAX_UNCOLLECTED AS [LIMIT_TAX_UNCOLLECTED]
		, [DREG].LIMIT_ZAPOR AS [LIMIT_ZAPOR]
		, [DREG].IS_CORR AS [IS_CORR]
		, [DREG].IS_UNIQUE AS [IS_UNIQUE_DEAL]
		, [DREG].GS_PROGRAMME_CODE AS [GS_PROGRAMME_CODE]
		, [DREG].GS_CARD_PRODUCT AS [GS_CARD_PRODUCT]
		, [DREG].GS_PRODUCT_CODE AS [GS_PRODUCT_CODE]
		, CASE WHEN IsNumeric([DREG].[GS_PROGRAMME_CODE]) = 1 THEN cast([DREG].[GS_PROGRAMME_CODE] AS INT) ELSE 0 END AS CODE_GS_PROGRAMME
		, CASE WHEN IsNumeric([DREG].[GS_CARD_PRODUCT]) = 1 THEN cast([DREG].[GS_CARD_PRODUCT] AS INT) ELSE 0 END AS CODE_GS_CARD
		/* Условия за кореспондиращи сметки dbo.[DEALS_CORR_TA] */
		, [CORS].[CURRENCY] AS [CURRENCY_CORS]
		, [CCY_CORS].[ID] AS [CCY_CODE_CORS]
		, [CORS].[LIMIT_AVAILABILITY] AS [LIMIT_AVAILABILITY_CORS]
		/*,	[CORS].[LIMIT_TAX_UNCOLLECTED] AS [LIMIT_TAX_UNCOLLECTED_CORS] */
		/*,	[PROXY_ACC_TA]  Пълномощника, да има права за действието по избраната сметка */
		/* Условия за вносната бележка [PREV_COMMON_TA] */
		, [PREV].[RUNNING_ORDER] AS [RUNNING_ORDER]
		, [PREV].[TYPE_ACTION] AS [TYPE_ACTION]
		, [PREV].TAX_CODE AS [TAX_CODE]
		, [PREV].PREF_CODE AS [PREF_CODE]
		/* Зададената сума на документа и очакванета сума на таксата */
		, CASE WHEN IsNumeric([PREV].[UI_SUM]) = 0 THEN 0.0 ELSE cast([PREV].[UI_SUM] AS FLOAT) END AS DOC_SUM
		, [PREV].[TAX_SUM] AS [DOC_TAX_SUM]
		/* Условия за кореспондиращата за документ кредитен превод */
		, [PREV].[UI_INOUT_TRANSFER]
		, [PREV].[BETWEEN_OWN_ACCOUNTS]
		/* Вида на валутата на кореспондирашата партида от dbo.[RAZPREG_TA] */
		, [DBEN].[UI_CURRENCY_CODE] AS [UI_CURRENCY_CODE_BEN]
		, [CCY_DEAL_BEN].[ID] AS [CCY_CODE_DEAL_BEN]
		, [DBEN].[UI_STD_DOG_CODE] AS [UI_STD_DOG_CODE_BEN]
	FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH (NOLOCK)
	INNER JOIN dbo.[RAZPREG_TA] [DREG] WITH (NOLOCK)
		ON [DREG].[REF_ID] = [CUST].[ROW_ID]
	LEFT JOIN dbo.[PREV_COMMON_TA] [PREV] WITH (NOLOCK)
		ON [PREV].[REF_ID] = [DREG].[ROW_ID]
	LEFT JOIN BLOCKSUM_TA WITH(NOLOCK)
		ON BLOCKSUM_TA.REF_ID = DREG.ROW_ID
	LEFT JOIN dbo.[DEALS_CORR_TA] [CORS] WITH (NOLOCK)
		ON [CORS].REF_ID = [DREG].[ROW_ID]
	LEFT JOIN dbo.[PROXY_SPEC_TA] AS [PSPEC] WITH (NOLOCK)
		ON [CUST].[ROW_ID] = [PSPEC].[REF_ID]
	LEFT JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [PROXY] WITH (NOLOCK)
		ON [PROXY].[ROW_ID] = [PSPEC].[PROXY_CLIENT_ID]
	LEFT JOIN dbo.[RAZPREG_TA] [DBEN] WITH (NOLOCK)
		ON [PREV].[REF_ID_BEN] = [DBEN].[ROW_ID]
	LEFT JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST_BEN] WITH (NOLOCK)
		ON [CUST_BEN].[ROW_ID] = [DBEN].[REF_ID]
	LEFT JOIN CTE_CUST_EGFN_TYPE WITH(NOLOCK)
		ON CTE_CUST_EGFN_TYPE.NAME = CUST.EGFN_TYPE
	LEFT JOIN CTE_CUSTOMER_CHARACTERISTIC WITH(NOLOCK)
		ON CTE_CUSTOMER_CHARACTERISTIC.NAME = [CUST].[CUSTOMER_CHARACTERISTIC]
	LEFT JOIN CTE_CUSTOMER_AGE WITH(NOLOCK)
		ON CTE_CUSTOMER_AGE.NAME = [CUST].[CUSTOMER_AGE]
	LEFT JOIN CTE_CCY CCY_DEAL WITH(NOLOCK)
		ON CCY_DEAL.NAME = DREG.UI_CURRENCY_CODE
	LEFT JOIN CTE_CCY CCY_CORS WITH(NOLOCK)
		ON CCY_CORS.NAME = [CORS].[CURRENCY]
	LEFT JOIN CTE_CCY CCY_DEAL_BEN WITH(NOLOCK)
		ON CCY_DEAL_BEN.NAME = [DBEN].[UI_CURRENCY_CODE]
	WHERE ([PREV].[DB_TYPE] = 'AIR' AND [PREV].[TA_TYPE] LIKE N'%AIR%')
		OR (BLOCKSUM_TA.DB_TYPE = 'AIR' AND BLOCKSUM_TA.TA_TYPE LIKE N'%AIR%')

GO

/********************************************************************************************************/
/* Помощно view за визуализация на данните от TA таблиците, който подлежат на актуализация */
CREATE OR ALTER VIEW dbo.[VIEW_TA_EXISTING_ONLINE_DATA_TEST_CASE_DATA]
AS
	SELECT [v].[ROW_ID]
		, [v].TA_TYPE
		/* Данни за Титуляра */
		, [v].[CUST_ROW_ID]
		, [c].[UI_CUSTOMER_ID]
		, [c].[UI_EGFN]
		, [c].[NAME]
		, [c].[COMPANY_EFN]
		, [c].[UI_CLIENT_CODE]
		, [c].[UI_NOTES_EXIST]
		, [c].[IS_ZAPOR]
		, [c].[ID_TYPE]
		, [c].[ID_NUMBER]
		, [c].[SERVICE_GROUP_EGFN]
		, [c].[IS_ACTUAL]
		, [c].[PROXY_COUNT]
		, [c].[IS_PROXY]
		/* Данни на Сделката */
		, [v].[DEAL_ROW_ID]
		, [R].[UI_DEAL_NUM]
		, [R].[DB_ACCOUNT]
		, [R].[UI_ACCOUNT]
		, [R].[ZAPOR_SUM]
		, [R].[IBAN]
		, [R].[TAX_UNCOLLECTED_SUM]
		/* Данни за обслужващата пардита за такси */
		, [v].[CORS_ROW_ID]
		, [D].[DEAL_NUM]
		, [D].[CURRENCY]
		, [D].[UI_CORR_ACCOUNT]
		, [D].[TAX_UNCOLLECTED_SUM] AS [TAX_UNCOLLECTED_SUM_CORS]
		/* Данни за пълномощника */
		, [v].[PSPEC_ROW_ID]
		, [v].[PROXY_ROW_ID]
		, [p].[UI_CUSTOMER_ID] AS [UI_CUSTOMER_ID_PROXY]
		, [p].[UI_EGFN] AS [UI_EGFN_PROXY]
		, [p].[NAME] AS [NAME_PROXY]
		, [p].[COMPANY_EFN] AS [COMPANY_EFN_PROXY]
		, [p].[UI_CLIENT_CODE] AS [UI_CLIENT_CODE_PROXY]
		, [p].[UI_NOTES_EXIST] AS [UI_NOTES_EXIST_PROXY]
		, [p].[IS_ZAPOR] AS [IS_ZAPOR_PROXY]
		, [p].[ID_NUMBER] AS [ID_NUMBER_PROXY]
		, [p].[SERVICE_GROUP_EGFN] AS [SERVICE_GROUP_EGFN_PROXY]
		, [p].[IS_ACTUAL] AS [IS_ACTUAL_PROXY]
		, [p].[PROXY_COUNT] AS [PROXY_COUNT_PROXY]
		, [p].[IS_PROXY] AS [PROXY_IS_PROXY]
		/* Данни на Сделката на бенефицента - за някой от тестовите случай за кредитните преводи */
		, [v].[DEAL_BEN_ROW_ID]
		, [DBEN].[UI_DEAL_NUM] AS [UI_DEAL_NUM_BEN]
		, [DBEN].[DB_ACCOUNT] AS [DB_ACCOUNT_BEN]
		, [DBEN].[UI_ACCOUNT] AS [UI_ACCOUNT_BEN]
		, [DBEN].[ZAPOR_SUM] AS [ZAPOR_SUM_BEN]
		, [DBEN].[IBAN] AS [IBAN_BEN]
		, [DBEN].[TAX_UNCOLLECTED_SUM] AS [TAX_UNCOLLECTED_SUM_BEN]
		, [DBEN].[UI_STD_DOG_CODE] AS [UI_STD_DOG_CODE_BEN]
		/* Данни на бенефицента - за някой от тестовите случай за кредитните преводи */
		, [v].[CUST_BEN_ROW_ID]
		, [CUST_BEN].[UI_CUSTOMER_ID] AS [UI_CUSTOMER_ID_BEN]
		, [CUST_BEN].[UI_EGFN] AS [UI_EGFN_BEN]
		, [CUST_BEN].[NAME] AS [NAME_BEN]
		, [CUST_BEN].[COMPANY_EFN] AS [COMPANY_EFN_BEN]
		, [CUST_BEN].[UI_CLIENT_CODE] AS [UI_CLIENT_CODE_BEN]
		/* Данни за таксата */
		, [v].[TAX_CODE] AS [TAX_CODE]
		, [v].[PREF_CODE] AS [PREF_CODE]
	FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] [v]
	INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [c]
		ON [c].[ROW_ID] = [v].[CUST_ROW_ID]
	INNER JOIN dbo.[RAZPREG_TA] [R]
		ON [R].[ROW_ID] = [v].[DEAL_ROW_ID]
	LEFT JOIN dbo.[DEALS_CORR_TA] [D]
		ON [d].[ROW_ID] = [v].[CORS_ROW_ID]
	LEFT JOIN dbo.[PROXY_SPEC_TA] [S]
		ON [S].[ROW_ID] = [v].PSPEC_ROW_ID
	LEFT JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [p]
		ON [p].[ROW_ID] = [S].[PROXY_CLIENT_ID]
	LEFT JOIN dbo.[RAZPREG_TA] [DBEN]
		ON [DBEN].[ROW_ID] = [v].[DEAL_BEN_ROW_ID]
	LEFT JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST_BEN]
		ON [CUST_BEN].[ROW_ID] = [DBEN].[REF_ID]
GO

/********************************************************************************************************/
/* Процедура за визличане на Sql Online Server name и Onle Database name */
DROP PROCEDURE IF EXISTS dbo.[SP_TA_GET_DATASOURCE]
GO

CREATE PROCEDURE dbo.[SP_TA_GET_DATASOURCE]
(
	@DB_TYPE				sysname = N'BETA'
,	@DB_ALIAS				sysname = N'VCS_OnlineDB'
,	@OnlineSqlServerName	sysname = N'' out
,	@OnlineSqlDataBaseName	sysname = N'' out
)
as
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Sql nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin
		select @Sql = 'dbo.[SP_TA_GET_DATASOURCE] @DB_TYPE = '''+@DB_TYPE+''', @DB_ALIAS = '''+@DB_ALIAS+''''
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, N'*** Begin Execute Proc ***: dbo.[SP_TA_GET_DATASOURCE]'
	end 
	;

	/************************************************************************************************************/
	/* @TODO: */
	select	@OnlineSqlServerName	= [SERVER_INSTANCE_NAME]
		,	@OnlineSqlDataBaseName	= [DATABASE_NAME]
	from dbo.[TEST_AUTOMATION_DATASOURCES] [DS] with(nolock)
	where [DB_TYPE] = @DB_TYPE and [UNIQUE_ALIAS] = @DB_ALIAS
	;

	if IsNull(@OnlineSqlServerName,'') = '' or IsNull(@OnlineSqlServerName,'') = ''
	begin
		select	@Msg = N'Can find datasource for [DB_TYPE] ='+@DB_TYPE+' AND [UNIQUE_ALIAS] = '+@DB_ALIAS+' '
			,	@Sql = N' SELECT [SERVER_INSTANCE_NAME], [DATABASE_NAME] from dbo.[TEST_AUTOMATION_DATASOURCES] [DS] with(nolock)'
					+  N'	where [DB_TYPE] = '+@DB_TYPE+' and [UNIQUE_ALIAS] = '+@DB_ALIAS+' '
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return 1;
	end

	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = N'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
			+ N'; @OnlineSqlServerName = '''+ @OnlineSqlServerName+''' out '
			+ N'; @OnlineSqlDataBaseName = '''+ @OnlineSqlDataBaseName+''' out ';
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, N'*** End Execute Proc ***: dbo.dbo.[SP_TA_GET_DATASOURCE]'
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за зареждане на дневните обороти от OnLineDB по сметка */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@Account                varchar(64)
,	@PartType               tinyint = 3
)
AS 
begin

	declare @LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Sql1 nvarchar(4000) = N'', @Ret int = 0
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName = '''+@OnlineSqlServerName+''''
					+', @OnlineSqlDataBaseName = '''+@OnlineSqlDataBaseName+''''
                    +', @Account = ''' + @Account+'''' 
                    +', @PartType = ' + str(@PartType,len(@PartType),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
    ;
	/************************************************************************************************************/
	/* 3. Prepare Sql statement */
    declare @AccountParam varchar(64) = ''''+ @Account+ '''';

	select @Sql1 = 
    N'DECLARE @Account varchar(32) = '+@AccountParam+'
        ,	@PartType int = '+str(@PartType,len(@PartType),0)+'
    ;
    with [ACC] AS (
        SELECT	[ACC].[ACCOUNT]
            ,	[ACC].[PART_TYPE]
        FROM ( VALUES (@Account, @PartType) ) as [ACC]( [ACCOUNT], [PART_TYPE] )
    ) 
    select	[ACC].[ACCOUNT]
        ,	[ACC].[PART_TYPE]
        ,	cast([BAL].[DAY_SALDO] as float)	as [DAY_OPERATION_BALANCE]
    from [ACC] with(nolock)
    left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
        on	[DM].[IDENT] = [ACC].[ACCOUNT]
    left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
        on	[FM].[IDENT] = [ACC].[ACCOUNT]
    cross apply (
        SELECT CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
                        THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
                                -	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
                                    + IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

                        ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
                                -	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
                                    + IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
                    END AS [DAY_SALDO]	
    ) [BAL]
    ';

	/************************************************************************************************************/
	/* 4. Execute SQL statement */
	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		if @@TRANCOUNT > 1 ROLLBACK;
		return 1;
	end catch

    if @Ret <> 0
    begin 
		select  @Msg = N'Error '+str(@Ret,len(@Ret),0)+' execute Sql';
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg            
		return 2;
    end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())+'; @Account: '+ @Account + '; @PartType = '+str(@PartType,len(@PartType),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]'
	end

	return 0;
end
GO

/********************************************************************************************************/
/* Процедура за зареждане на Клиентски данни от OnLineDB по CustomerID */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_CLIENT_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_CLIENT_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@CurrentAccountDate		datetime
,	@CUSTOMER_ID			int
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @CUSTOMER_ID = ' + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CLIENT_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;
	/************************************************************************************************************/
	/* 3. Load Deals data from OlineDB */
	declare @AccountData varchar(16) = ''''+ convert( varchar(16), @CurrentAccountDate, 23)+ '''';

	select @Sql1 = N'
	Declare @StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	select top (1)  
			[CUST].[CUSTOMER_ID]
		,	[CUST].[IDENTIFIER]					AS [UI_EGFN]
		,	[CUST].[CUSTOMER_NAME]				AS [CUSTOMER_NAME]
		,	[CUST].[COMPANY_EFN]				AS [COMPANY_EFN]	
		,	[MCLC].[CL_CODE]					AS [MAIN_CLIENT_CODE]
		,	[NOTE].[HAS_POPUP_NOTE]				AS [UI_NOTES_EXIST]
		,	[XF].[IS_ZAPOR]						AS [IS_ZAPOR]			/* [IS_ZAPOR] : (дали има съдебен запор някоя от сделките на клиента) */
		,	IsNull([DOC].[DOCUMENT_TYPE],-1)	AS [ID_DOCUMENT_TYPE]	/* Тип на личния документ - код от NM405 */
		,	IsNull([DOC].[ID_NUMBER], '''')		AS [ID_NUMBER]			/* [ID_NUMBER] Номера на: лична карта; паспорт; шофьорска книжка ... */
		,	[XF].[SERVICE_GROUP_EGFN]			AS [SERVICE_GROUP_EGFN]	/* TODO: [SERVICE_GROUP_EGFN]: */
		,	[XF].[IS_ACTUAL]					AS [IS_ACTUAL]			/* TODO: [IS_ACTUAL]: ?!?*/
		,	[PR].[PROXY_COUNT]					AS [PROXY_COUNT]
	from '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
	inner join '+@SqlFullDBName+'.dbo.[DT015_MAINCODE_CUSTID] [MCLC] WITH(NOLOCK)
		ON [MCLC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
	cross apply (
		select	0			AS [IS_ZAPOR]	
			,	''''		AS [SERVICE_GROUP_EGFN]
			,	0			AS [IS_ACTUAL]
	) [XF]
	outer apply (
		select top(1) count(distinct [CRL].[REPRESENTATIVE_CUSTOMER_ID]) AS [PROXY_COUNT]
		from '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH(NOLOCK)
		inner join '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
			on	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
		inner join '+@SqlFullDBName+'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH(NOLOCK)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] >= '+@AccountData+')
		where [CRL].[REPRESENTED_CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [CRL].[CHANNEL] = 1	
	) [PR]
	outer apply (																					
		select top (1) cast( 1 as bit) as [HAS_POPUP_NOTE]
		from '+@SqlFullDBName+'.dbo.[DT015_NOTES] [n] with(nolock)
		where	[n].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [n].[CLIENT_NOTETYPE] = 1 /* enum ClientNoteType : ClientNoteTypeExtraData = 1 */
			and DATALENGTH([n].[NOTE]) > 1 /* Да има поне един символ освен нулевия терминатор */
	) [NOTE]
	outer apply (
		select top(1) [NM405_DOCUMENT_TYPE]	as [DOCUMENT_TYPE]
			,	[DOCUMENT_NUMBER]			as [ID_NUMBER]
			,	[ISSUER_COUNTRY_CODE]		as [ISSUER_COUNTRY_CODE]
		from '+@SqlFullDBName+'.dbo.[DT015_IDENTITY_DOCUMENTS] [d] with(nolock)
		where [d].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [d].[NM405_DOCUMENT_TYPE] IN (1, 7, 8) /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
		order by [d].[NM405_DOCUMENT_TYPE]
	) [DOC]
	where [CUST].[CUSTOMER_ID] = ' + str(@CUSTOMER_ID,len(@CUSTOMER_ID),0)
	;

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Customer Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @CUSTOMER_ID = ' + STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CLIENT_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', CUSTOMER_ID: ' +  STR(@CUSTOMER_ID,LEN(@CUSTOMER_ID),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от Online базата с активни запори */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
(
	@OnlineSqlServerName	sysname 
,	@OnlineSqlDataBaseName	sysname 
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
        ,   @Sql1 nvarchar(2000) = N'', @Msg nvarchar(2000) = N''
    ;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	/************************************************************************************************************/
	/* 2.1. Prepare Online Database FullName */
	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	declare @Sql nvarchar(4000) = N'', @Ret int = 0
		,	@SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;
	;

	/************************************************************************************************************/
	/* 2.2. Prepare SQL statement */
	select @Sql = 
	'declare @Ret int = 0
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	
	declare @Tbl_Distraint_Codes TABLE ( [CODE] INT )
	;

	insert into @Tbl_Distraint_Codes
	SELECT [n].[CODE]
	from '+@SqlFullDBName+'.dbo.[NOMS] [n] with(nolock)
	where	[n].[NOMID] = 136
		and ([n].[sTATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
	;
	WITH [CTE_X] AS
	(
		SELECT [CODE] 
		FROM @Tbl_Distraint_Codes 
	)
	SELECT distinct [CLC].[CUSTOMER_ID]
	FROM '+@SqlFullDBName+'.dbo.[BLOCKSUM] [BLK] with(nolock)
	inner join [CTE_X] [X] with(nolock)
		on	[BLK].[WHYFREEZED] = [X].[CODE]
		and [BLK].[CLOSED_FROZEN_SUM] <> 1
		and [BLK].[SUMA] > 0.0
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		on [ACC].[PART_ID] = [BLK].[PARTIDA]
	inner join '+@SqlFullDBName+'.dbo.[dt015] [CLC] with(nolock)
		on [CLC].[CODE] = [ACC].[CLIENT_ID]
	';

	/************************************************************************************************************/
	/* 3. Execute SQL statement */
	begin try
        exec @Ret = sp_executesql @Sql
    end try
	begin catch
		select @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go

/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от OnlineDb с неплатени такси към всички кл. сметки */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
(
	@OnlineSqlServerName	sysname 
,	@OnlineSqlDataBaseName	sysname 
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
        ,   @Sql1 nvarchar(2000) = N'', @Msg nvarchar(2000) = N''
    ;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end   

    /************************************************************************************************************/
	/* 2.1. Prepare Online Database FullName */
	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	declare @Sql nvarchar(4000) = N'', @Ret int = 0
		,	@SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;
	;

	/************************************************************************************************************/
	/* 2.2. Prepare SQL statement */
	select @Sql = '
    select distinct [C].[CUSTOMER_ID] 
    from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
    inner join '+@SqlFullDBName+'.dbo.[PARTS] [A] with(nolock)
        on [a].[PART_ID] = [T].[ACCOUNT_DT]
    inner join '+@SqlFullDBName+'.dbo.[DT015] [C] with(nolock)
        on [C].[CODE] = [A].[CLIENT_ID]
    where	[T].[TAX_STATUS] =  0 /* eTaxActive = 0 // Действаща такса */
        and [T].[COLLECT_FROM_ALL_CUSTOMER_ACCOUNTS] = 1
    ';

	/************************************************************************************************************/
	/* 3. Execute SQL statement */
	begin try
        exec @Ret = sp_executesql @Sql
    end try
	begin catch
		select @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch    

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go

/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@DEAL_NUM				int
,	@CORS_ACCOUNT_TYPE		int
,	@CORS_ACCOUNT			varchar(33)
)
AS 
BEGIN

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
					+', @CORS_ACCOUNT_TYPE = '+str(@CORS_ACCOUNT_TYPE,len(@CORS_ACCOUNT_TYPE),0)
					+', @CORS_ACCOUNT = '''+@CORS_ACCOUNT+''''
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;
	/************************************************************************************************************/
	/* 3. Load Deal Corrs data from OlineDB */
	;
	select @Sql1 = N'
	DECLARE @DealType int = 1 
		,	@CorrAccType int = '+str(@CORS_ACCOUNT_TYPE, len(@CORS_ACCOUNT_TYPE),0)+'
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	select	[CORR].[DEAL_TYPE]			AS [DEAL_TYPE]
		,	[CORR].[DEAL_NUMBER]		AS [DEAL_NUMBER]
		,	[CORR].[CORR_TYPE]			AS [CORR_TYPE]		
		,	[ACC].[DEAL_TYPE]			AS [CORR_DEAL_TYPE]
		,	[ACC].[DEAL_NUMBER]			AS [CORR_DEAL_NUMBER]
		,	[CORR].[CORR_ACCOUNT]		AS [CORR_ACCOUNT]
		,	[CCY].[INI]					AS [CORR_ACCOUNT_CCY]
		,	[ACC].[PART_CURRENCY]		AS [CORR_ACC_CCY_CODE]
		,	[ACC].[BLK_SUMA_MIN]		AS [BLK_SUMA_MIN]
		,	[BAL].[AVAILABLE_BAL]		AS [AVAILABLE_BAL]
		,	[BAL].[TAX_UNCOLLECTED_SUM]	AS [TAX_UNCOLLECTED_SUM]
		,	[BAL].[HAS_TAX_UNCOLLECTED]	AS [HAS_TAX_UNCOLLECTED]

	from '+@SqlFullDBName+'.dbo.[DEALS_CORR] [CORR] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC]
		on [ACC].[PART_ID] = [CORR].[CORR_ACCOUNT]
	inner join '+@SqlFullDBName+'.dbo.[DT008] [CCY] with(nolock)
		on	[CCY].[CODE] = [ACC].[PART_CURRENCY]
	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		on [DM].[IDENT] = [CORR].[CORR_ACCOUNT]
	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
		on [FM].[IDENT] = [CORR].[CORR_ACCOUNT]
	cross apply (
		select	CASE WHEN [ACC].[PART_TYPE] IN (1,2,5)
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
		select top (1) cast(1 as bit) as [HAS_TAX_UNCOLLECTED]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = [CORR].[CORR_ACCOUNT]
			and [T].[TAX_STATUS] =  0
	) [TAX]
	outer apply (
		select SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
		from '+@SqlFullDBName+'.dbo.[BLOCKSUM] [B] with(nolock)
		inner join '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock)
			on	[N].[NOMID] = 136 
			and [N].[CODE]	= [B].[WHYFREEZED] 
			and([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
		where [B].[PARTIDA] = [CORR].[CORR_ACCOUNT] AND [B].[CLOSED_FROZEN_SUM] = 0
	) [DST]
	cross apply (
		select	ROUND([XBAL].[BEG_SAL], 4)					as [BEG_SAL]
			,	ROUND([XBAL].[DAY_MOVE], 4)					as [DAY_MOVE]
			,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [AVAILABLE_BAL]
			,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4)	as [DISTRAINT_SUM]
			,	ROUND(cast(0 as float), 4)					as [TAX_UNCOLLECTED_SUM]
			,	IsNull([TAX].[HAS_TAX_UNCOLLECTED], 0)		as [HAS_TAX_UNCOLLECTED]
	) [BAL]
	where [CORR].[DEAL_TYPE]		= @DealType
		and [CORR].[DEAL_NUMBER]	= '+str(@DEAL_NUM,len(@DEAL_NUM), 0)+'
		and [CORR].[CORR_TYPE]		= @CorrAccType
		and [CORR].[CORR_ACCOUNT]	= '''+@CORS_ACCOUNT+'''
	';

	if @LogTraceInfo = 1 select @Sql1 as [LOAD_ONLINE_CORS_INFO];

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Cors Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
					+', @CORS_ACCOUNT_TYPE = '+str(@CORS_ACCOUNT_TYPE,len(@CORS_ACCOUNT_TYPE),0)
					+', @CORS_ACCOUNT = '''+@CORS_ACCOUNT+''''
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за зареждане на Данни за сделка от OnLineDB по номер */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@DEAL_TYPE INT
,	@DEAL_NUM INT
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;
	/************************************************************************************************************/
	/* 3. Load Deals data from OlineDB */

	select @Sql1 = N'
	DECLARE @DealType int = 1 
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	select	[REG].[DEAL_NUM]
		,	[REG].[ACCOUNT]
		,	[REG].[CURRENCY_CODE]	as [ACCOUNT_CURRENCY]
		,	[II].[IBAN]
		,	[BAL].[BEG_SAL]
		,	[BAL].[DAY_MOVE]
		,	[ACC].[BLK_SUMA_MIN]
		,	[BAL].[RAZPOL]
		,	[BAL].[TAX_UNCOLLECTED_SUM]
		,	[BAL].[DISTRAINT_SUM]
		,	[BAL].[HAS_TAX_UNCOLLECTED]

	from '+@SqlFullDBName+'.dbo.[RAZPREG] [REG] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[IBAN_IDENT] [II] with(nolock)
		ON	[II].[ID] = [REG].[ACCOUNT]
		AND [II].[IBAN_TYPE] = 0 /* 0 - eIban_Real*/
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		ON [REG].[ACCOUNT] = [ACC].[PART_ID]
	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		ON [DM].[IDENT] = [REG].[ACCOUNT]
	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
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
		SELECT TOP (1) cast(1 as bit) as [HAS_TAX_UNCOLLECTED]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = [REG].[ACCOUNT]
			and [T].[TAX_STATUS] =  0
	) [TAX]
	outer apply (
		SELECT TOP (1) [B].[SUMA] as [DISTRAINT_SUM]
		FROM '+@SqlFullDBName+'.dbo.[BLOCKSUM] [B] with(nolock)
		INNER JOIN '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock)
			ON	[N].[NOMID] = 136 
			AND [N].[CODE]	= [B].[WHYFREEZED] 
			AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
		WHERE [B].[PARTIDA] = [REG].[ACCOUNT] AND [B].[CLOSED_FROZEN_SUM] = 0 AND [B].[SUMA] >= 0.01
	) [DST]
	cross apply (
		SELECT	ROUND([XBAL].[BEG_SAL], 4)						as [BEG_SAL]
			,	ROUND([XBAL].[DAY_MOVE], 4)						as [DAY_MOVE]
			,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [RAZPOL]
			,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4)		as [DISTRAINT_SUM]
			,	cast(0 as float) 								as [TAX_UNCOLLECTED_SUM]
			,	IsNull([TAX].[HAS_TAX_UNCOLLECTED], 0)			as [HAS_TAX_UNCOLLECTED]
	) [BAL]
	where [REG].[DEAL_NUM] = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select	@Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@Account				sysname
,	@AccCurrency			int
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @Account = '''+@Account+''''
					+', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* 3. Load Tax Uncolected amount by Account from OlineDB */

	select @Sql1 = N'
	declare @Account varchar(64) = '''+@Account+'''
		,	@Account_CCY int = '+str(@AccCurrency,len(@AccCurrency),0)+'
	;
	with TAX_BY_CCY AS 
	(
		select	[T].[ORIGINAL_CURRENCY]									as [CURRENCY_TOT]
			,	SUM ( [T].[AMOUNT] - [T].[COLLECTED_AMOUNT] )			as [TAX_UNCOLLECTED_TOT]
			,	SUM ( [T].[DDS_AMOUNT] - [T].[DDS_COLLECTED_AMOUNT] )	as [DDS_UNCOLLECTED_TOT]
			,	COUNT(*)												as [CNT_ITEMS]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = @Account
			and [T].[TAX_STATUS] = 0
		GROUP BY [T].[ORIGINAL_CURRENCY]
	) 
	, [TAX_BY_ACC] AS 
	(
		SELECT	SUM( dbo.TRANS_CCY_TO_CCY_TA( [T].[TAX_UNCOLLECTED_TOT], [T].[CURRENCY_TOT], @Account_CCY)
				   + dbo.TRANS_CCY_TO_CCY_TA( [T].[DDS_UNCOLLECTED_TOT], 100,  @Account_CCY ) )
									AS [TAX_UNCOLLECTED]
			,	SUM( [CNT_ITEMS] )	AS [CNT_ITEMS]
		FROM TAX_BY_CCY [T]
	)
	SELECT	@Account						as [ACCOUNT]
		,	round([R].[TAX_UNCOLLECTED], 4)	as [TAX_UNCOLLECTED]
		,	[R].[CNT_ITEMS]					as [CNT_ITEMS]
	FROM [TAX_BY_ACC] [R]
	';

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2;
	end catch

	if @LogTraceInfo = 1 select @Sql1 as [LOAD_TAX_UNCOLECTED_BY_ACC];

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Cors Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @Account = '''+@Account+''''
					+', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', @Account: ' + @Account
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Help function: */
DROP FUNCTION IF EXISTS  [dbo].[FN_GET_EXCEPTION_INFO]
GO

/********************************************************************************************************/
/* Help function: Get Exception information */
CREATE FUNCTION [dbo].[FN_GET_EXCEPTION_INFO]()
	returns VARCHAR(MAX)
AS
BEGIN
	DECLARE @OUT_MSG VARCHAR(MAX)
	DECLARE @ERR_NUM		INT 			= ERROR_NUMBER()
	DECLARE @ERR_SEVERITY	INT 			= ERROR_SEVERITY()
	DECLARE @ERR_STATE		INT 			= ERROR_STATE()
	DECLARE @ERR_LINE		INT				= ERROR_LINE()
	DECLARE @ERR_PROCEDURE  sysname			= ERROR_PROCEDURE()
	DECLARE @ERR_MSG		nvarchar(2048)	= ERROR_MESSAGE()

	SET @OUT_MSG = 'Exception caught during ' + CASE	WHEN @ERR_PROCEDURE IS NULL 
														THEN 'script' 
														ELSE 'Stored Procedure' 
														END 
				+ ' execution. Details: ' + CHAR(13) + CHAR(10)
				
	IF @ERR_PROCEDURE IS NOT NULL
		SET @OUT_MSG += '[ERROR_PROCEDURE]: "' + @ERR_PROCEDURE + '"' + CHAR(13) + CHAR(10)
	IF @ERR_MSG IS NOT NULL
		SET @OUT_MSG += '[ERROR_MESSAGE]: "' + @ERR_MSG + '"' + CHAR(13) + CHAR(10)
	IF @ERR_LINE IS NOT NULL
		SET @OUT_MSG += '[ERROR_LINE]: ' + LTRIM(STR(@ERR_LINE)) + CHAR(13) + CHAR(10)
	IF @ERR_NUM IS NOT NULL
		SET @OUT_MSG += '[ERROR_NUMBER]: ' + LTRIM(STR(@ERR_NUM)) + CHAR(13) + CHAR(10)
	IF @ERR_SEVERITY IS NOT NULL
		SET @OUT_MSG += '[ERROR_SEVERITY]: ' + LTRIM(STR(@ERR_SEVERITY)) + CHAR(13) + CHAR(10)
	IF @ERR_STATE IS NOT NULL
		SET @OUT_MSG += '[ERROR_STATE]: ' + LTRIM(STR(@ERR_STATE)) + CHAR(13) + CHAR(10)
	
	RETURN @OUT_MSG
END
GO

/********************************************************************************************************/
DROP FUNCTION IF EXISTS dbo.FN_GET_TIME_DIFF
GO

/********************************************************************************************************/
/* Help function: Get Time Diff as string in format: d:hh:mi:ss.mmm */
CREATE FUNCTION dbo.FN_GET_TIME_DIFF( @TimeBeg DateTime, @TimeEnd DateTime )
	RETURNS VARCHAR(64)
AS 
BEGIN
	declare @Result		varchar(32) = ''
		,	@MiliSec	bigint		= 0
		,	@DiffDais	bigint		= DATEDIFF(dd, @TimeBeg, @TimeEnd)
	;
	if abs(@DiffDais) > 1
		select @TimeBeg = cast(@TimeBeg as time), @TimeEnd = cast(@TimeEnd as time)
	;
	select @MiliSec = datediff(ms, @TimeBeg, @TimeEnd) 
	;
	select @Result = str(@DiffDais,len(@DiffDais),0) 
		+ ':' + right(convert(varchar(32), dateadd(ms, @MiliSec, 0), 121),12)
	;

    return @Result;
END
GO

/*****************************************************************************/
-- Create table dbo.[CURRENCIES_TA] for currency rate
drop table if exists dbo.[CURRENCIES_TA]
GO

CREATE TABLE [dbo].[CURRENCIES_TA](
	[ROW_ID] [int] IDENTITY(1, 1),
	[CODE] [char](3) NULL,
	[FIXING] [FLOAT] NULL,
	[BASE] [int] NULL,
	[CCY_CODE] [int] NULL,
	CONSTRAINT [PK_CURRENCIES_TA] PRIMARY KEY CLUSTERED ([ROW_ID])
)
GO

INSERT INTO dbo.[CURRENCIES_TA]
	([CODE], [FIXING], [BASE], [CCY_CODE]) 
VALUES
('BGN', 1.00000, 1, 100),
('USD', 1.75348, 1, 840),
('EUR', 1.95583, 1, 978),
('GBP', 2.47768, 1, 826)
GO

/********************************************************************************************************/
DROP FUNCTION IF EXISTS dbo.[TRANS_CCY_TO_CCY_TA]
GO

/********************************************************************************************************/
/* Help function: Convert amount from one currency to another */
CREATE OR ALTER FUNCTION [dbo].[TRANS_CCY_TO_CCY_TA]( @SUMA AS FLOAT, @SUM_CCY AS INT, @TO_CCY AS INT )
RETURNS FLOAT
AS
BEGIN
	IF( @SUMA IS NULL OR @SUMA = 0.0 )
		RETURN 0.0

	DECLARE @FIXING_FROM AS FLOAT, @BASE_FROM AS INT
		,	@FIXING_TO AS FLOAT, @BASE_TO AS INT, @PRE_TO AS SMALLINT

	SELECT	@FIXING_TO = [FIXING], @BASE_TO = [BASE] , @PRE_TO = NULL
	FROM 	dbo.[CURRENCIES_TA] WITH (NOLOCK)
	WHERE	[CCY_CODE] = @TO_CCY

	/* Ако двете валути са еднакви връщаме входната сума */
	IF( @SUM_CCY IS NULL OR @SUM_CCY = @TO_CCY )
		RETURN ROUND( ISNULL( @SUMA, 0.0 ), ISNULL(@PRE_TO, 2) )

	SELECT	@FIXING_FROM = [FIXING], @BASE_FROM = [BASE]
	FROM 	dbo.[CURRENCIES_TA] WITH (NOLOCK)
	WHERE	[CCY_CODE] = @SUM_CCY

	IF ( ISNULL ( @BASE_FROM, 0.0 ) = 0.0 OR ISNULL ( @BASE_TO, 0.0 ) = 0.0 
		OR ISNULL ( @FIXING_FROM, 0.0 ) = 0.0 OR ISNULL ( @FIXING_TO, 0.0 ) = 0.0 )
		RETURN 0.0

	RETURN ROUND( ( @FIXING_FROM / @BASE_FROM ) * @SUMA / ( @FIXING_TO / @BASE_TO ),  ISNULL( @PRE_TO, 2 ) )
END
GO



/********************************************************************************************************/
/* Help procedure: */
DROP PROCEDURE IF EXISTS  dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB]
GO

/********************************************************************************************************/
/* Help procedure: Get account data from OnlineDB */
CREATE PROCEDURE dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB]
(
	@SqlServerName		sysname
,	@SqlDatabase		sysname
,	@CUR_ACCOUNT_DATE	DateTime OUT
)
AS 
BEGIN 

	DECLARE @SqlStms NVARCHAR(4000) = N'', @Msg nvarchar(max) = N'', @Ret int = -1
		,	@StmsParmams NVARCHAR(500) = N'@CUR_DATE_OUT datetime OUTPUT'
	;

	select	@StmsParmams = N'@CUR_DATE_OUT DateTime OUTPUT'
		,	@SqlStms = N'SELECT @CUR_DATE_OUT = CAST( CAST( CAST( REVERSE( SUBSTRING( DATA, 5, 4 ) ) AS BINARY(4) ) AS INT ) AS CHAR(8) )
	FROM ' + @SqlServerName + '.' + @SqlDatabase + '.dbo.CSOFT_SYS	WHERE CODE = 1'
	
	begin try
		exec @Ret = sp_executesql @SqlStms, @StmsParmams, @CUR_DATE_OUT = @CUR_ACCOUNT_DATE OUTPUT
	end try
	begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, @SqlStms, @Msg
			return 1;
	end catch

	return @Ret;
END
GO

/********************************************************************************************************/
/* Table: SYS_LOG_PROC */
DROP TABLE IF EXISTS [dbo].[SYS_LOG_PROC]
GO

CREATE TABLE [dbo].[SYS_LOG_PROC]
(
	[ID]		[int] IDENTITY(1,1) NOT NULL
,	[DATE]		[datetime] NULL    
,	[PROC_NAME]	SYSNAME NULL
,	[MSG]		nvarchar(max) NULL
,	[SQL]		nvarchar(max) NULL
    CONSTRAINT [PK_SYS_LOG_PROC] 
        PRIMARY KEY CLUSTERED ([ID])
)
GO

ALTER TABLE dbo.[SYS_LOG_PROC]
	ADD CONSTRAINT _DF_SYS_LOG_PROC_DATE_  DEFAULT (getdate()) FOR [Date]
GO


/****** Object:  StoredProcedure dbo.[sp_log_proc]    Script Date: 03.05.2022 Рі. 14:44:11 ******/
DROP PROCEDURE IF EXISTS dbo.[SP_SYS_LOG_PROC]
GO

/********************************************************************************************************/
/* Help proc: SP_SYS_LOG_PROC log trace information */
CREATE PROCEDURE dbo.[SP_SYS_LOG_PROC]
	@ProcID int
,	@Sql	nvarchar(max)
,	@Msg	nvarchar(max)
AS
	INSERT INTO dbo.[SYS_LOG_PROC] ( [proc_name], [sql], [Msg], [Date]  )
		VALUES( OBJECT_NAME( @ProcID ), @Sql, @Msg, GetDate() )
GO




/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от Online базата с активни запори */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
(
	@OnlineSqlServerName	sysname 
,	@OnlineSqlDataBaseName	sysname 
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
        ,   @Sql1 nvarchar(2000) = N'', @Msg nvarchar(2000) = N''
    ;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	/************************************************************************************************************/
	/* 2.1. Prepare Online Database FullName */
	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	declare @Sql nvarchar(4000) = N'', @Ret int = 0
		,	@SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;
	;

	/************************************************************************************************************/
	/* 2.2. Prepare SQL statement */
	select @Sql = 
	'declare @Ret int = 0
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	
	declare @Tbl_Distraint_Codes TABLE ( [CODE] INT )
	;

	insert into @Tbl_Distraint_Codes
	SELECT [n].[CODE]
	from '+@SqlFullDBName+'.dbo.[NOMS] [n] with(nolock)
	where	[n].[NOMID] = 136
		and ([n].[sTATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
	;
	WITH [CTE_X] AS
	(
		SELECT [CODE] 
		FROM @Tbl_Distraint_Codes 
	)
	SELECT distinct [CLC].[CUSTOMER_ID]
	FROM '+@SqlFullDBName+'.dbo.[BLOCKSUM] [BLK] with(nolock)
	inner join [CTE_X] [X] with(nolock)
		on	[BLK].[WHYFREEZED] = [X].[CODE]
		and [BLK].[CLOSED_FROZEN_SUM] <> 1
		and [BLK].[SUMA] > 0.0
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		on [ACC].[PART_ID] = [BLK].[PARTIDA]
	inner join '+@SqlFullDBName+'.dbo.[dt015] [CLC] with(nolock)
		on [CLC].[CODE] = [ACC].[CLIENT_ID]
	';

	/************************************************************************************************************/
	/* 3. Execute SQL statement */
	begin try
        exec @Ret = sp_executesql @Sql
    end try
	begin catch
		select @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go

/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от OnlineDb с неплатени такси към всички кл. сметки */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
(
	@OnlineSqlServerName	sysname 
,	@OnlineSqlDataBaseName	sysname 
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
        ,   @Sql1 nvarchar(2000) = N'', @Msg nvarchar(2000) = N''
    ;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end   

    /************************************************************************************************************/
	/* 2.1. Prepare Online Database FullName */
	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	declare @Sql nvarchar(4000) = N'', @Ret int = 0
		,	@SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;
	;

	/************************************************************************************************************/
	/* 2.2. Prepare SQL statement */
	select @Sql = '
    select distinct [C].[CUSTOMER_ID] 
    from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
    inner join '+@SqlFullDBName+'.dbo.[PARTS] [A] with(nolock)
        on [a].[PART_ID] = [T].[ACCOUNT_DT]
    inner join '+@SqlFullDBName+'.dbo.[DT015] [C] with(nolock)
        on [C].[CODE] = [A].[CLIENT_ID]
    where	[T].[TAX_STATUS] =  0 /* eTaxActive = 0 // Действаща такса */
        and [T].[COLLECT_FROM_ALL_CUSTOMER_ACCOUNTS] = 1
    ';

	/************************************************************************************************************/
	/* 3. Execute SQL statement */
	begin try
        exec @Ret = sp_executesql @Sql
    end try
	begin catch
		select @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch    

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go

/********************************************************************************************************/
/* Процедура за актуализация на Таблиците по ID на тестови case */
/* 2022/06/98 - v2.6.3 -> актуализация на TA таблиците за навързаните документи се извършва само за първия тестови случай */
CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES]
(
	@TestCaseRowID INT
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 1
		, @LogResultTable INT = 1
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate()
	DECLARE @Msg NVARCHAR(max) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @Sql NVARCHAR(4000) = N''
		, @RowIdStr NVARCHAR(8) = STR(@TestCaseRowID, LEN(@TestCaseRowID), 0)

	/************************************************************************************************************/
	/* Log Begining of Procedure execution */

	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @RowIdStr
			, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES]'

	/************************************************************************************************************/
	/* Find TA Conditions */

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR

	IF NOT EXISTS (
			SELECT *
			FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
			WHERE [ROW_ID] = IsNull(@TestCaseRowID, - 1)
			)
	BEGIN
		SELECT @Msg = N'Error not found condition with [ROW_ID] :' + @RowIdStr
			, @Sql = N'select * from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(' + @RowIdStr + ', -1)'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 1
	END

	DECLARE @DB_TYPE SYSNAME
		, @DEALS_CORR_TA_RowID INT = 0
		, @TYPE_ACTION VARCHAR(128) = ''
		, @RUNNING_ORDER INT = 0

	SELECT @DB_TYPE = [DB_TYPE]
		, @DEALS_CORR_TA_RowID = [CORS_ROW_ID]
		, @TYPE_ACTION = [TYPE_ACTION]
		, @RUNNING_ORDER = IsNull([RUNNING_ORDER], 1)
	FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
	WHERE [ROW_ID] = IsNull(@TestCaseRowID, - 1)

	IF /* @TYPE_ACTION = 'CashPayment' and */ @RUNNING_ORDER > 1
	BEGIN
		SELECT @Msg = N'Update cash payment with [ROW_ID] ' + @RowIdStr + ' and  [RUNNING_ORDER] <> 1 not allowed.'
			, @Sql = @TestCaseRowID

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 0
	END

	-- SELECT @DB_TYPE = [DB_TYPE]
	-- FROM dbo.[TEST_AUTOMATION_TA_TYPE] WITH (NOLOCK)
	-- WHERE [TA_TYPE] IN (@DB_TYPE)

	/************************************************************************************************************/
	/* Get Datasources */

	DECLARE @OnlineSqlServerName SYSNAME = N''
		, @OnlineSqlDataBaseName SYSNAME = N''
		, @DB_ALIAS SYSNAME = N'VCS_OnlineDB'

	EXEC @Ret = dbo.[SP_TA_GET_DATASOURCE] @DB_TYPE
		, @DB_ALIAS
		, @OnlineSqlServerName OUTPUT
		, @OnlineSqlDataBaseName OUTPUT

	IF @Ret <> 0
	BEGIN
		SELECT @Msg = N'Error execute proc, Error code: ' + str(@Ret, len(@Ret), 0) + '  Result: @OnlineSqlServerName = "' + @OnlineSqlServerName + '", @OnlineSqlDataBaseName = "' + @OnlineSqlDataBaseName + '"'
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = ' + @DB_TYPE + N', @DB_ALIAS = ' + @DB_ALIAS + N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_GET_DATASOURCE], @OnlineSqlServerName: ' + @OnlineSqlServerName + ', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + ' '
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = ' + @DB_TYPE + N', @DB_ALIAS = ' + @DB_ALIAS + N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/*********************************************************************************************************/
	/* Get Account Date */

	DECLARE @CurrAccDate DATETIME = 0
		, @AccountDate SYSNAME = N''

	BEGIN TRY
		EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @CurrAccDate OUTPUT
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR
		, @AccountDate = '''' + convert(CHAR(10), @CurrAccDate, 120) + ''''

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' + @AccountDate
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/*********************************************************************************************************/
	/* Clear data before update table: dbo.DEALS_CORR_TA, dbo.RAZPREG_TA, dbo.DT015_CUSTOMERS_ACTIONS_TA */

	BEGIN TRY
		EXEC @Ret = dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA @RowIdStr
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = ' exec dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA @RowIdStr = ' + @RowIdStr

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 1
	END CATCH

	/************************************************************************************************************/
	/* Prepare Sql Conditions */
	
	DROP TABLE IF EXISTS dbo.[#TBL_RESULT]
	CREATE TABLE dbo.[#TBL_RESULT] (
		[TEST_ID] NVARCHAR(512)
		, [DEAL_TYPE] SMALLINT
		, [DEAL_NUM] INT
		, [CUSTOMER_ID] INT
		, [REPRESENTATIVE_CUSTOMER_ID] INT
		, [DEAL_TYPE_BEN] SMALLINT
		, [DEAL_NUM_BEN] INT
		)

	EXEC @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS] @RowIdStr
		, @CurrAccDate

	IF @Ret <> 0
	BEGIN
		SELECT @Msg = N'Error Execute procedure dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS], Online Accoun Date: ' + @AccountDate
			, @Sql = N'exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS] ' + @RowIdStr + ', ' + @AccountDate + N''

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	IF @LogResultTable = 1
		SELECT *
		FROM dbo.[#TBL_RESULT] WITH (NOLOCK)

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[#TBL_RESULT] WITH (NOLOCK)
			)

	DECLARE @DealType INT = 0
		, @DealNum INT = 0
		, @CustomerID INT = 0
		, @ProxyID INT = 0
		, @WithUpdate INT = 1
		, @DealTypBen INT = - 1
		, @DealNumBen INT = - 1

	SELECT TOP (1) @DealNum = [DEAL_NUM]
		, @DealType = [DEAL_TYPE]
		, @CustomerID = [CUSTOMER_ID]
		, @ProxyID = [REPRESENTATIVE_CUSTOMER_ID]
		, @DealNumBen = IsNull([DEAL_NUM_BEN], - 1)
		, @DealTypBen = IsNull([DEAL_TYPE_BEN], - 1)
	FROM dbo.[#TBL_RESULT] WITH (NOLOCK)

	IF @Rows <= 0
		OR IsNull(@DealNum, 0) <= 0
		OR IsNull(@CustomerID, 0) <= 0
	BEGIN
		SELECT @Msg = 'Not found suitable deal from Test Case with [ROW_ID]: ' + @RowIdStr

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @RowIdStr
			, @Msg

		RETURN 2
	END

	/************************************************************************************************************/
	/* Update table dbo.[DEALS_CORR_TA] */
	IF IsNull(@DEALS_CORR_TA_RowID, - 1) > 0
	BEGIN
		BEGIN TRY
			EXEC @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS] @OnlineSqlServerName
				, @OnlineSqlDataBaseName
				, @RowIdStr
				, 1
				, @DealNum
				, @CustomerID
				, @ProxyID
				, @WithUpdate
		END TRY

		BEGIN CATCH
			SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
				, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS] @RowIdStr, @CurrAccDate, 1, @DealNum, @CustID, @ProxyID'

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg

			RETURN 3
		END CATCH
	END

	/************************************************************************************************************/
	/* Update table dbo.[RAZPREG_TA] */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @RowIdStr
			, 1
			, @DealNum
			, 0
			, @WithUpdate
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @RowIdStr, @CurrAccDate, 1, @DealNum, 0 '

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	/************************************************************************************************************/
	/* Update Ben deal: */
	IF @DealNumBen > 1
		AND @DealTypBen > 0
	BEGIN
		BEGIN TRY
			EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @OnlineSqlServerName
				, @OnlineSqlDataBaseName
				, @RowIdStr
				, 1
				, @DealNumBen
				, 1
				, @WithUpdate
		END TRY

		BEGIN CATCH
			SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
				, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] @RowIdStr, @CurrAccDate, 1, @DealNumBen, 1 '

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg

			RETURN 5
		END CATCH
	END

	/************************************************************************************************************/
	/* Update table dbo.[DT015_CUSTOMERS_ACTIONS_TA] for Customer and Proxy */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @CurrAccDate
			, @RowIdStr
			, @CustomerID
			, @ProxyID
			, @WithUpdate
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = ' exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate' + ', @RowIdStr, @CustomerID, @ProxyID, @WithUpdate'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 6
	END CATCH

	/******************************************************************************************************/
	/* 5.4. Update table dbo.[PREV_COMMON_TA] for Tax and Preferencial codes  */
	-- @TODO: UPDATE TAX CODE - SP_CASH_PAYMENTS_UPDATE_TAXED_INFO
	-- begin try
	-- 		exec dbo.[SP_CASH_PAYMENTS_UPDATE_TAXED_INFO] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate
	-- 			, @RowIdStr, @WithUpdate
	-- end try
	-- begin catch 
	-- 	select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
	-- 		,	@Sql = N' exec dbo.[SP_CASH_PAYMENTS_UPDATE_TAXED_INFO] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate'
	-- 				 + N', @RowIdStr, @WithUpdate'
	-- 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	-- 	return 7
	-- end catch
	
	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', TA Row ID: ' + @RowIdStr

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES]'
	END

	RETURN 0
END
GO

/********************************************************************************************************/
/* Процедура за зачистване наданните от TA Таблиците */
/* 2022/06/98 - v2.6.3 -> актуализацията на сделките с навързаните документи се извършва само за първия тестови случай */

CREATE OR ALTER PROCEDURE dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA
(
	@TestCaseRowID NVARCHAR(16)
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 1
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate()
	DECLARE @Msg NVARCHAR(max) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Sql1 NVARCHAR(4000) = N''
		, @TA_RowID INT = cast(@TestCaseRowID AS INT)

	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, '*** Begin Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA'

	/************************************************************************************************************/
	-- 2. Get  TA Table Row IDs:
	DECLARE @RUNNING_ORDER INT = 0
		, @TYPE_ACTION VARCHAR(128) = ''
		, @RAZPREG_TA_RowID INT = 0
		, @DEALS_CORR_TA_RowID INT = 0
		, @DT015_CUSTOMERS_RowID INT = 0
		, @PROXY_CUSTOMERS_RowID INT = 0
		, @CUSTOMER_BEN_ROW_ID INT = 0
		, @RAZPREG_TA_BEN_RowID INT = 0

	SELECT @RAZPREG_TA_RowID = [DEAL_ROW_ID]
		, @DEALS_CORR_TA_RowID = [CORS_ROW_ID]
		, @DT015_CUSTOMERS_RowID = [CUST_ROW_ID]
		, @PROXY_CUSTOMERS_RowID = [PROXY_ROW_ID]
		, @PROXY_CUSTOMERS_RowID = [PROXY_ROW_ID]
		, @RUNNING_ORDER = [RUNNING_ORDER]
		, @CUSTOMER_BEN_ROW_ID = IsNull([CUST_BEN_ROW_ID], - 1)
		, @RAZPREG_TA_BEN_RowID = IsNull([DEAL_BEN_ROW_ID], - 1)
	FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
	WHERE [ROW_ID] = @TA_RowID

	DECLARE @IsNotFirstCashPaymentWithAccumulatedTax BIT = 0

	IF IsNull(@TYPE_ACTION, '') = 'CashPayment'
		AND IsNull(@RUNNING_ORDER, - 1) > 1
		SELECT @IsNotFirstCashPaymentWithAccumulatedTax = 1

	IF IsNull(@RAZPREG_TA_RowID, 0) <= 0
	BEGIN
		SELECT @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, @Msg

		RETURN 1
	END

	IF IsNull(@DT015_CUSTOMERS_RowID, 0) <= 0
	BEGIN
		SELECT @Msg = 'Not found customer from TA ROW_ID : ' + @TestCaseRowID

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, @Msg

		RETURN 2
	END

	BEGIN TRY
		-- Актуализация данните за кореспондиращата сметка
		IF IsNull(@DEALS_CORR_TA_RowID, 0) > 0
			AND @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [DEAL_NUM] = 0 					-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
				, [UI_CORR_ACCOUNT] = '' 		-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
				, [TAX_UNCOLLECTED_SUM] = 0 	-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 
			FROM dbo.[DEALS_CORR_TA] [D]
			WHERE [D].[ROW_ID] = @DEALS_CORR_TA_RowID
		END

		-- Актуализация данните на пълномощника
		IF IsNull(@PROXY_CUSTOMERS_RowID, 0) > 0
			AND @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_CUSTOMER_ID] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				, [UI_EGFN] = '0' 					-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				, [NAME] = '' 						-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				, [COMPANY_EFN] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				, [UI_CLIENT_CODE] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				, [UI_NOTES_EXIST] = 0				-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				, [IS_ZAPOR] = 0 					-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				, [ID_NUMBER] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				, [SERVICE_GROUP_EGFN] = '0' 		-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				, [IS_ACTUAL] = 0 					-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				, [PROXY_COUNT] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			WHERE [D].[ROW_ID] = @PROXY_CUSTOMERS_RowID
		END

		-- Актуализация данните на сделката
		IF @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_DEAL_NUM] = 0 -- RAZPREG_TA	UI_DEAL_NUM	
				, [DB_ACCOUNT] = '' -- RAZPREG_TA	DB_ACCOUNT	
				, [UI_ACCOUNT] = '' /* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
				, [ZAPOR_SUM] = '' -- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
				, [IBAN] = '' -- RAZPREG_TA	IBAN	
				, [TAX_UNCOLLECTED_SUM] = '' -- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
			FROM dbo.[RAZPREG_TA] [D]
			WHERE [D].[ROW_ID] IN (
					@RAZPREG_TA_RowID
					, @RAZPREG_TA_BEN_RowID
					)
		END

		-- Актуализация данните на клиента
		IF @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_CUSTOMER_ID] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				, [UI_EGFN] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				, [NAME] = '' 					-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				, [COMPANY_EFN] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				, [UI_CLIENT_CODE] = '0' 		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				, [UI_NOTES_EXIST] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				, [IS_ZAPOR] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				, [ID_TYPE] = 0
				, [ID_NUMBER] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				, [SERVICE_GROUP_EGFN] = '0' 	-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				, [IS_ACTUAL] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				, [PROXY_COUNT] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			WHERE [D].[ROW_ID] = @DT015_CUSTOMERS_RowID
		END

		-- Актуализация данните за документа ( за сега само код на такса и преференция )
		IF @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [TAX_CODE] = 0 /* код на такса */
				, [PREF_CODE] = 0 /* код на преференция */
			FROM dbo.[PREV_COMMON_TA] [D]
			WHERE [D].[ROW_ID] = @TA_RowID
		END

		-- Зануляваме данните за бенефициена 
		IF IsNull(@CUSTOMER_BEN_ROW_ID, 0) > 0
			AND @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_CUSTOMER_ID] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				, [UI_EGFN] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				, [NAME] = '' 					-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				, [COMPANY_EFN] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				, [UI_CLIENT_CODE] = '0' 		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				, [UI_NOTES_EXIST] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				, [IS_ZAPOR] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				, [ID_TYPE] = 0
				, [ID_NUMBER] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				, [SERVICE_GROUP_EGFN] = '0' 	-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				, [IS_ACTUAL] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				, [PROXY_COUNT] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			WHERE [D].[ROW_ID] = @CUSTOMER_BEN_ROW_ID
		END
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql1
			, @Msg

		RETURN 3
	END CATCH

	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', TA Row ID: ' + @TestCaseRowID

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA'
	END

	RETURN 0
END
GO

/**********************************************************************************************************/
/* Процедура за актуализация данните в на Таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA] за титуляра и Proxy-то*/
DROP PROCEDURE IF EXISTS dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS]
GO

CREATE PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@CurrAccountDate		datetime
,	@TestCaseRowID			nvarchar(16)
,	@Customer_ID			int
,	@ProxyCustomer_ID		int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Sql2 nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Ret int = 0, @TA_RowID int = cast(@TestCaseRowID as int)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS]'
	;

	/************************************************************************************************************/
	-- Check customer ID
	if IsNull(@Customer_ID,0) <= 0
	begin  
		select @Msg = N'Incorrect CustomerID : ' + str(@Customer_ID,len(@Customer_ID),0) + N', TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return -1;
	end

	/************************************************************************************************************/
	-- Find customer row id:
	declare @CUSTOMER_ROW_ID int = 0
		,	@CUST_PROXY_ROW_ID int = 0
		,	@CUST_BEN_ROW_ID int = 0
		,	@DEAL_BEN_ROW_ID int = 0
	;

	select	@CUSTOMER_ROW_ID	= IsNull([CUST_ROW_ID],-1)
		,	@CUST_PROXY_ROW_ID	= IsNull([PROXY_ROW_ID],-1)
		,	@CUST_BEN_ROW_ID	= IsNull([CUST_BEN_ROW_ID],-1)
		,	@DEAL_BEN_ROW_ID	= IsNull([DEAL_BEN_ROW_ID],-1)
	from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID
	;

	if IsNull(@CUSTOMER_ROW_ID,-1) <= 0 
	begin  
		select @Msg = N'Not found TA Customer ROW_ID : ' + str(@CUSTOMER_ROW_ID,len(@CUSTOMER_ROW_ID),0) 
			+ N', CustomerID : ' + str(@Customer_ID,len(@Customer_ID),0)
			+ N', TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return -1;
	end

	/************************************************************************************************************/
	-- Find customer row id:
	declare @Ben_Customer_ID int = 0 /* Customer ID on OnlineDb for Beneficiary */
	;
	if IsNull(@DEAL_BEN_ROW_ID,0) > 0 
	begin 
		select @Ben_Customer_ID = IsNull([S].[CUSTOMER_ID],-1)
		from dbo.[RAZPREG_TA] [R] with(nolock)
		inner join dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [S] with(nolock)
			on	[S].[DEAL_TYPE] = 1
			and [R].[UI_DEAL_NUM] = [S].[DEAL_NUM] 
		where [R].[ROW_ID] = @DEAL_BEN_ROW_ID
	end

	/************************************************************************************************************/
	-- Актуализация на данните за титуляря и Proxy-то...
	-- Първо актуализираме данните на Proxy-то	
	if IsNull(@ProxyCustomer_ID,0) > 0 and IsNull(@CUST_PROXY_ROW_ID,0) > 0
	begin
		begin try 

			select @Sql2 = N'dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS] @OnlineSqlServerName = '+@OnlineSqlServerName
						+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
						+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
						+', @TestCaseRowID = '+@TestCaseRowID
						+', @OnlineDbCustomer_ID = '+str(@ProxyCustomer_ID,len(@ProxyCustomer_ID),0)
						+', @TA_CUST_ROW_ID = ' +str(@CUST_PROXY_ROW_ID,len(@CUST_PROXY_ROW_ID),0)+ '/* for Proxy */'
						+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)

			exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS] @OnlineSqlServerName, @OnlineSqlDataBaseName
				, @CurrAccountDate, @TestCaseRowID, @ProxyCustomer_ID, @CUST_PROXY_ROW_ID, @WithUpdate;

			if @Ret <> 0
			begin 
				select @Msg = N'Error exec procedure dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS], error code:'+str(@Ret,len(@Ret),0)
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 1;
			end

		end try
		begin catch
			select @Msg = dbo.FN_GET_EXCEPTION_INFO() 
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 2;
		end catch
	end

	-- Aктуализираме данните на Титуляра
	begin try 
		select @Sql2 = N'dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS] @OnlineSqlServerName = '+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
					+', @TestCaseRowID = '+@TestCaseRowID
					+', @OnlineDbCustomer_ID = '+str(@Customer_ID,len(@Customer_ID),0)
					+', @TA_CUST_ROW_ID = ' +str(@CUSTOMER_ROW_ID,len(@CUSTOMER_ROW_ID),0)+ '/* for Main Customer */'
					+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)

		exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS] @OnlineSqlServerName, @OnlineSqlDataBaseName
			, @CurrAccountDate, @TestCaseRowID, @Customer_ID, @CUSTOMER_ROW_ID, @WithUpdate;

		if @Ret <> 0
		begin 
			select @Msg = N'Error exec procedure dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS], error code:'+str(@Ret,len(@Ret),0)
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 3;
		end
	end try
	begin catch
			select @Msg = dbo.FN_GET_EXCEPTION_INFO() 
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 4;
	end catch

	-- Aктуализираме данните на Бенефициента
	if IsNull(@Ben_Customer_ID,0) > 0 and IsNull(@CUST_BEN_ROW_ID,0) > 0
	begin
		begin try 
			select @Sql2 = N'dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS] @OnlineSqlServerName = '+@OnlineSqlServerName
						+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
						+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
						+', @TestCaseRowID = '+@TestCaseRowID
						+', @OnlineDbCustomer_ID = '+str(@Ben_Customer_ID,len(@Ben_Customer_ID),0)
						+', @TA_CUST_ROW_ID = ' +str(@CUST_BEN_ROW_ID,len(@CUST_BEN_ROW_ID),0)+ '/* for Beneficiary */'
						+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)


			exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS] @OnlineSqlServerName, @OnlineSqlDataBaseName
				, @CurrAccountDate, @TestCaseRowID, @Ben_Customer_ID, @CUST_BEN_ROW_ID, @WithUpdate;

			if @Ret <> 0
			begin 
				select @Msg = N'Error exec procedure dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS], error code:'+str(@Ret,len(@Ret),0)+ ' /* for Beneficiary */ '
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 5;
			end
		end try
		begin catch
				select @Msg = dbo.FN_GET_EXCEPTION_INFO() + ' /* for Beneficiary */ '
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 6;
		end catch	
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: '+@TestCaseRowID
			 + ', @Customer_ID: '+str(@Customer_ID,len(@Customer_ID),0)
			 + ', @ProxyCustomer_ID: '+str(@ProxyCustomer_ID,len(@ProxyCustomer_ID),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS]'
	end

	return 0;
end
go

/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS]
GO

CREATE PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@CurrAccountDate		datetime
,	@TestCaseRowID			nvarchar(16)
,	@OnlineDbCustomer_ID	int
,	@TA_CUST_ROW_ID			int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0, @LogResultTable int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		, @Sql2 nvarchar(4000) = N'', @TA_RowID int = cast ( @TestCaseRowID as int )
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS]'
	;

	/************************************************************************************************************/
	-- 	Get TA Customer Row ID:
	declare @TBL_ROW_ID int = @TA_CUST_ROW_ID	
	;

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin 
		select @Msg = 'Incorrect Customer from TA ROW_ID : ' +@TestCaseRowID
			+'; @OnlineDbCustomer_ID ='+str(@OnlineDbCustomer_ID,len(@OnlineDbCustomer_ID),0)
			+'; @TA_CUST_ROW_ID = '+str(@TA_CUST_ROW_ID,LEN(@TA_CUST_ROW_ID),0)+' ';
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
	end

	/************************************************************************************************************/
	-- Update table dbo.[DT015_CUSTOMERS_ACTIONS_TA]: ...
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
	,	[ID_DOCUMENT_TYPE]		int
	,	[ID_NUMBER]				varchar(50)
	,	[SERVICE_GROUP_EGFN]	varchar(50)
	,	[IS_ACTUAL]				int
	,	[PROXY_COUNT]			int
	)
	;

	begin try
		insert into dbo.[#TBL_ONLINE_DT015_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccountDate, @OnlineDbCustomer_ID
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_CLIENT_DATA] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
								+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
								+ ', @Customer_ID = '+str(@OnlineDbCustomer_ID,len(@OnlineDbCustomer_ID),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 2;
	end catch

	if @Ret <> 0 
		return 3;

	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DT015_INFO] with(nolock)
	;

	/* Тези данни ще ги заредим от вече 'кешираниет'  */
	declare @IS_ZAPOR int = 0,	@SERVICE_GROUP_EGFN varchar(16) = N''
	;
	/* Дали клиента има запори по някоя от сделките: */
	select top(1) @IS_ZAPOR = 1 
	from dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] [D] with(nolock)
	where [D].[CUSTOMER_ID] = @OnlineDbCustomer_ID
	;

	/* За клиентите със служебни EGFN-та да заредим Оригиналното: */
	DECLARE @ClientIdentifier varchar(32) = N''
		,	@HasDublClientIDs int = 0
		,	@IsOrioginalID int = 0
	;
	select @ClientIdentifier	= [CLIENT_IDENTIFIER]	
		,	@HasDublClientIDs	= [HAS_DUBL_CLIENT_IDS]
		,	@IsOrioginalID		= [IS_ORIGINAL_EGFN]
	from  dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [CUST] with(nolock)
	where [CUST].[CUSTOMER_ID] = @OnlineDbCustomer_ID

	if @HasDublClientIDs = 1
	begin
		set @SERVICE_GROUP_EGFN = @ClientIdentifier;

		if @IsOrioginalID = 0
		begin
			select top(1) @SERVICE_GROUP_EGFN = [EGFN]
			from [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] with(nolock)
			where [EGFN] = CAST(RIGHT(RTRIM(@ClientIdentifier), 13) as bigint)
		end
	end 

	/* Update data in [DT015_CUSTOMERS_ACTIONS_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_CUSTOMER_ID]		= @OnlineDbCustomer_ID			 -- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
			,	[UI_EGFN]				= [S].[UI_EGFN]					 -- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
			,	[NAME]					= [S].[NAME]					 -- DT015_CUSTOMERS_ACTIONS_TA	NAME
			,	[COMPANY_EFN]			= [S].[COMPANY_EFN]				 -- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
			,	[UI_CLIENT_CODE]		= [S].[UI_CLIENT_CODE]			 -- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
			,	[UI_NOTES_EXIST]		= IsNull([S].[UI_NOTES_EXIST],0) -- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
			,	[IS_ZAPOR]				= @IS_ZAPOR						 -- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
			,	[ID_TYPE]				= [S].[ID_DOCUMENT_TYPE]		-- DT015_CUSTOMERS_ACTIONS_TA  ID_TYPE типа на документа за самоличност 
			,	[ID_NUMBER]				= IsNull([S].[ID_NUMBER], '')	 -- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
			,	[SERVICE_GROUP_EGFN]	= @SERVICE_GROUP_EGFN			 -- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
			,	[IS_ACTUAL]				= [S].[IS_ACTUAL]				 -- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1; 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
			,	[PROXY_COUNT]			= IsNull([S].[PROXY_COUNT],0)	 -- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
		from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
		inner join dbo.[#TBL_ONLINE_DT015_INFO] [S] with(nolock)
			on [S].[CUSTOMR_ID] = @OnlineDbCustomer_ID
		where [D].[ROW_ID] = @TBL_ROW_ID
		;
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[DT015_CUSTOMERS_ACTIONS_TA], Rows affected: '+str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0)
			,	@Sql2 = 'UPDATE dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D] SET [UI_CUSTOMER_ID] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CUSTOMERS_ACTIONS]'
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[DEALS_CORR_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS]
GO

CREATE PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@CUSTOMER_ID			int
,	@PROXY_ID				int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogResultTable int = 0, @LogBegEndProc int = 1, @TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql2 nvarchar(4000) = N'',	@TA_RowID int = cast( @TestCaseRowID as int)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS]'
	;

	/************************************************************************************************************/
	/* Find Test Case row and Corr Account */
	declare @TBL_ROW_ID int = 0, @DealRowID int = 0
		,	@CorrAccount varchar(64) = N'', @CorrAccType int = 3
	;

	select	@DealRowID = [DEAL_ROW_ID]
		,	@TBL_ROW_ID = [CORS_ROW_ID]
	from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found correspondence from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	select	@CorrAccount = [CORR_ACCOUNT]
	from [dbo].[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] [C] with(nolock)
	where [DEAL_TYPE] = 1 AND [DEAL_NUM] = @DEAL_NUM
	;	

	if IsNull(@CorrAccount,'') = ''
	begin  
		select @Msg = 'Not found correspondence account TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 1;
	end 

	/************************************************************************************************************/
	-- Load data from OnlinDB: 
	drop table if exists dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
	(	[DEAL_TYPE]			int
	,	[DEAL_NUM]			int	
	,	[CORR_TYPE]			int	
	,	[CORR_DEAL_TYPE]	int
	,	[CORR_DEAL_NUM]		int
	,	[CORR_ACCOUNT]		varchar(64)
	,	[CORR_ACCOUNT_CCY]	varchar(8)
	,	[CORR_ACC_CCY_CODE]	int
	,	[BLK_SUMA_MIN]		float	
	,	[AVAILABLE_BAL]		float	
	,	[TAX_UNCOLLECTED]	float
	,	[HAS_TAX_UNCOLLECTED] int
	);	

	begin try
		insert into dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @DEAL_NUM, @CorrAccType, @CorrAccount
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
								+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
								+ ', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
								+ ', @CORS_ACCOUNT_TYPE = '+str(@CorrAccType,len(@CorrAccType),0)
								+ ', @CORS_ACCOUNT = '''+@CorrAccount+''''
			;

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 2
	end catch

	if @Ret <> 0
		return 3;

	/************************************************************************************************************/
	-- Load tax uncollected amount from OnlinDB:
	declare @Account varchar(64) = N'', @AccCurrency int = 100, @HasTaxUncollected int = 0
	;
	
	select top (1) @Account = [CORR_ACCOUNT], @AccCurrency = [CORR_ACC_CCY_CODE], @HasTaxUncollected = [HAS_TAX_UNCOLLECTED]
	from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] with(nolock)
	;

	if IsNull(@HasTaxUncollected,0) = 1 and IsNull(@Account,'') <> ''
	begin

		drop table if exists dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		;

		create table dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		(	[ACCOUNT]			varchar(64)
		,	[TAX_UNCOLLECTED]	float
		,	[CNT_ITEMS]			int	
		);

		begin try
			insert into dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
			exec @Ret = dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName, @OnlineSqlDataBaseName, @Account, @AccCurrency
		end try
		begin catch
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
									+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
									+ ', @Account = '+@Account
									+ ', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
				;

				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 4
		end catch

		if exists ( select * from dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] with(nolock))
		begin

			update [D]
			set [TAX_UNCOLLECTED] = [s].[TAX_UNCOLLECTED]
			from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] [D]
			inner join dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] [S] with(nolock)
				on	[S].[CORR_ACCOUNT] = [D].[ACCOUNT]
				and [d].[CORR_ACC_CCY_CODE] = @AccCurrency

		end

	end

	/************************************************************************************************************/
	-- UPDATE [DEALS_CORS_TA] 
	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] with(nolock)
	;

	/* Update data in table [DEALS_CORR_TA] */
	if @WithUpdate = 1
	begin
		UPDATE [D]
		SET [DEAL_NUM]				= [S].[CORR_DEAL_NUM]		-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
		,	[CURRENCY]				= [S].[CORR_ACCOUNT_CCY]	-- DEALS_CORR_TA	CURRENCY	
		,	[UI_CORR_ACCOUNT]		= [S].[CORR_ACCOUNT]		-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
		,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]		-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 

		from dbo.[DEALS_CORR_TA] [D]
		inner join dbo.[#TBL_ONLINE_DEALS_CORR_INFO] [S] with(nolock)
			on	[S].[DEAL_TYPE] 	= 1
			and [S].[DEAL_NUM]		= @DEAL_NUM
			and [S].[CORR_TYPE]		= @CorrAccType
			and [S].[CORR_ACCOUNT]	= @CorrAccount
		where [D].[ROW_ID] = @TBL_ROW_ID
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[DEALS_CORR_TA], Rows affected: '+ str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0) 
			,	@Sql2 = 'UPDATE dbo.[DEALS_CORR_TA] [D] SET [UI_CUSTOMER_ID] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_DEALS_CORS]'
	end

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура формираща SQL заявката за търсене на подходяща сделка по ID на тестови случай */
/* 2022/06/98 - v2.6.3 -> търсена на подходящи сделките за навързаните документи се извършва само за първия тестови случай */
DROP PROCEDURE IF EXISTS dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS]
GO

CREATE PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS]
(
	@TestCaseRowID nvarchar(16)
,	@CurrAccDate datetime
,	@SaveTAConditions tinyint = 0
)
AS 
begin

	declare @LogTraceInfo int = 1, @LogBegEndProc int = 1, @TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql nvarchar(max) = N'', @Sql2 nvarchar(4000) = N'', @CrLf nvarchar(4) = nchar(13) + nchar(10)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS]'
	;

	/************************************************************************************************************/
	/* 1.0 Generate Sql for TA Conditions: */
	declare @DateAcc DATE = @CurrAccDate, @StrIntVal varchar(32) = ''
	;

	/* Client conditions [DT015_CUSTOMERS_ACTIONS_TA]: */
	declare @TA_TYPE					sysname = ''	
		,	@SECTOR						int = 0
		,	@UNIFIED					int = -1
		,	@IS_SERVICE					int = -1
		,	@CODE_EGFN_TYPE				int = -1
		,	@DB_CLIENT_TYPE_DT300		int = -1
		,	@VALID_ID					int = -1
		,	@CUSTOMER_CHARACTERISTIC	int = -1
		,	@CUSTOMER_AGE				sysname = '-1'
		,	@CUSTOMER_BIRTH_DATE_MIN	int = 18910101
		,	@CUSTOMER_BIRTH_DATE_MAX	int = 20220101
		,	@IS_PROXY					int = -1
		,	@IS_UNIQUE_CUSTOMER			int = -1
		,	@HAVE_CREDIT				int = -1
		,	@COLLECT_TAX_FROM_ALL_ACC 	int = -1
			/* [PROXY_SPEC_TA]: */
		,	@UI_RAZPOREDITEL			int = -1
		,	@UI_UNLIMITED				int = -1
	;
	/* Deal conditions [RAZPREG_TA]: */
	declare @UI_STD_DOG_CODE			int = 0
		,	@UI_INDIVIDUAL_DEAL			int = 0
		,	@INT_COND_STDCONTRACT		int = 0
		,	@CODE_UI_NM342				int = 0
		,	@CCY_CODE_DEAL				int = 0
		,	@UI_OTHER_ACCOUNT_FOR_TAX	int = 0
		,	@UI_NOAUTOTAX				sysname = '-1'
		,	@UI_DENY_MANUAL_TAX_ASSIGN	sysname = '-1'
		,	@UI_CAPIT_ON_BASE_DATE_OPEN sysname = '-1'
		,	@UI_BANK_RECEIVABLES		sysname = '-1'
		,	@UI_JOINT_TYPE				int = 0
		,	@LIMIT_AVAILABILITY			sysname = '0'
		,	@DEAL_STATUS				int = 0
		,	@LIMIT_TAX_UNCOLLECTED		int = 0
		,	@LIMIT_ZAPOR				int = 0
		,	@IS_CORR					int = 0
		,	@IS_UNIQUE_DEAL				int = 0
		,	@GS_PRODUCT_CODE			int = 0
		,	@CODE_GS_PROGRAMME			int = 0
		,	@CODE_GS_CARD				int = 0
	;
	declare @CCY_CODE_CORS				int = -1
		,	@LIMIT_AVAILABILITY_CORS	sysname = '-1'

		/* Conditions [PREV_COMMON_TA]: */
		,	@RUNNING_ORDER				int = -1
		,	@TYPE_ACTION				varchar(256)
		,	@TAX_CODE					int = -1
		,	@PREF_CODE					sysname = '-1'
		,	@DOC_SUM					float = 0.0
		,	@DOC_TAX_SUM				float = 0.0
	;

	/* Conditions for DirPrev from [PREV_COMMON_TA] & [RAZPREG_TA]: */
	declare @UI_INOUT_TRANSFER			varchar(256) = null
		,	@BETWEEN_OWN_ACCOUNTS		int = -1
		,	@CCY_CODE_DEAL_BEN			int = -1
		, 	@UI_STD_DOG_CODE_BEN		int = -1
	;

	drop table if EXISTS dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS]
	;
	create table dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS]
	(
		[ID] INT IDENTITY(1,1)
	,	[SQL_COND] nvarchar(1000)
	,	[DESCR] nvarchar(2000)
	,	[IS_BASE_SELECT] BIT DEFAULT(0)
	,	[IS_SELECT_COUNT] BIT DEFAULT(0)
	)
	;

	/**********************************************************************************************/

	drop table if EXISTS dbo.[#TBL_TA_CONDITIONS]
	;
	select [V].*
	into dbo.[#TBL_TA_CONDITIONS] 
	from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] [V] with(nolock) where [V].[ROW_ID] = IsNull(@TestCaseRowID, -1)
	;

	select top(1) /* Client conditions: */
			@TA_TYPE					= ''''+ [TA_TYPE] + ''''
		,	@SECTOR						= [SECTOR]
		,	@UNIFIED					= [UNIFIED]
		,	@IS_SERVICE					= [IS_SERVICE]
		,	@CODE_EGFN_TYPE				= [CODE_EGFN_TYPE]
		,	@DB_CLIENT_TYPE_DT300		= [DB_CLIENT_TYPE_DT300]
		,	@VALID_ID					= [VALID_ID]
		,	@CUSTOMER_CHARACTERISTIC	= [CODE_CUSTOMER_CHARACTERISTIC]
		,	@CUSTOMER_AGE				= [CUSTOMER_AGE]
		,	@CUSTOMER_BIRTH_DATE_MIN	= CONVERT( char(8), [CUSTOMER_BIRTH_DATE_MIN], 112)
		,	@CUSTOMER_BIRTH_DATE_MAX	= CONVERT( char(8), [CUSTOMER_BIRTH_DATE_MAX], 112)
		,	@IS_PROXY					= [IS_PROXY]
		,	@IS_UNIQUE_CUSTOMER			= [IS_UNIQUE_CUSTOMER]
		,	@HAVE_CREDIT				= [HAVE_CREDIT]
		,	@COLLECT_TAX_FROM_ALL_ACC	= [COLLECT_TAX_FROM_ALL_ACC]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Conditions [PROXY_SPEC_TA]: */
			@UI_RAZPOREDITEL			= [UI_RAZPOREDITEL]
		,	@UI_UNLIMITED				= [UI_UNLIMITED]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Deal conditions: */
			@UI_STD_DOG_CODE			= cast( [UI_STD_DOG_CODE] as int)
		,	@UI_INDIVIDUAL_DEAL			= cast( [UI_INDIVIDUAL_DEAL] as int)
		,	@INT_COND_STDCONTRACT		= cast( [INT_COND_STDCONTRACT] as int )
		,	@CODE_UI_NM342				= cast( [CODE_UI_NM342]  as int)
		,	@CCY_CODE_DEAL				= [CCY_CODE_DEAL]
		,	@UI_OTHER_ACCOUNT_FOR_TAX	= [UI_OTHER_ACCOUNT_FOR_TAX]
		,	@UI_NOAUTOTAX				= [UI_NOAUTOTAX]
		,	@UI_DENY_MANUAL_TAX_ASSIGN	= [UI_DENY_MANUAL_TAX_ASSIGN]
		,	@UI_CAPIT_ON_BASE_DATE_OPEN = [UI_CAPIT_ON_BASE_DATE_OPEN]
		,	@UI_BANK_RECEIVABLES		= [UI_BANK_RECEIVABLES]
		,	@UI_JOINT_TYPE				= [UI_JOINT_TYPE]
		,	@LIMIT_AVAILABILITY			= [LIMIT_AVAILABILITY]
		,	@DEAL_STATUS				= [DEAL_STATUS]
		,	@LIMIT_TAX_UNCOLLECTED		= [LIMIT_TAX_UNCOLLECTED]
		,	@LIMIT_ZAPOR				= cast(FLOOR([LIMIT_ZAPOR]) as int)
		,	@IS_CORR					= [IS_CORR]
		,	@IS_UNIQUE_DEAL				= [IS_UNIQUE_DEAL]
		,	@GS_PRODUCT_CODE			= [GS_PRODUCT_CODE]
		,	@CODE_GS_PROGRAMME			= [CODE_GS_PROGRAMME]
		,	@CODE_GS_CARD				= [CODE_GS_CARD]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Conditions [DEALS_CORR_TA]: */
			@CCY_CODE_CORS				= [CCY_CODE_CORS]
		,	@LIMIT_AVAILABILITY_CORS	= [LIMIT_AVAILABILITY_CORS]
		,	@TAX_CODE					= [TAX_CODE]
		,	@PREF_CODE					= [PREF_CODE]
		,	@DOC_SUM					= [DOC_SUM]
		,	@DOC_TAX_SUM				= [DOC_TAX_SUM]
				/* Conditions [PREV_COMMON_TA]: */
		,	@RUNNING_ORDER				= [RUNNING_ORDER]
		,	@TYPE_ACTION				= [TYPE_ACTION]
				/* Conditions for DirPrev from [PREV_COMMON_TA] & [RAZPREG_TA]: */
		,	@UI_INOUT_TRANSFER			= [UI_INOUT_TRANSFER]
		,	@BETWEEN_OWN_ACCOUNTS		= [BETWEEN_OWN_ACCOUNTS]
		,	@CCY_CODE_DEAL_BEN			= [CCY_CODE_DEAL_BEN]
		,	@UI_STD_DOG_CODE_BEN		= [UI_STD_DOG_CODE_BEN]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;

	/*********************************************************************/
	/* Prepate Base SELECT statement: */
	select @Sql2 = N'select DISTINCT TOP (1) ''ID_'+@TestCaseRowID+'_'+REPLACE(@TA_TYPE,'''','')+ ''''
		+ N' AS [TEST_ID]
		, [DEAL].[DEAL_TYPE], [DEAL].[DEAL_NUM]
		, [CUST].[CUSTOMER_ID], [PROXY].[CUSTOMER_ID] AS [REPRESENTATIVE_CUSTOMER_ID] '
		+ case when IsNull(@TYPE_ACTION,'') IN ( 'CT', 'DD' ) and IsNull(@UI_INOUT_TRANSFER,'-1') = '3' and IsNull(@BETWEEN_OWN_ACCOUNTS,-1) in (0,1)
			then ', [DEAL_BEN].[DEAL_TYPE_BEN], [DEAL_BEN].[DEAL_NUM_BEN] '
			else ', NULL AS [DEAL_TYPE_BEN],  NULL AS [DEAL_NUM_BEN]' end + @CrLf
	insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR], [IS_BASE_select] )
	select	@Sql2,	N'SELECT ...', 1
	;
	select @Sql += @Sql2
	;

	/*********************************************************************/
	/* prepare tables joint statement:  */
	-- @SECTOR and @CCY_CODE_DEAL
	select @Sql2 = N'
	from dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [DEAL] with(nolock)
	inner join dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [CUST] with(nolock)
		on	[CUST].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
		and [DEAL].[CLIENT_SECTOR] = '+str(@SECTOR,len(@SECTOR),0)+N'
		and [DEAL].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+' ';

	-- [DT015_CUSTOMERS_ACTIONS_TA].[SECTOR] and [RAZPREG_TA].[UI_CURRENCY_CODE]
	insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
	select	(@Sql2 + @CrLf), N' BASE join: SECTOR = '+str(@SECTOR,len(@SECTOR),0)+' & [UI_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+' '
	select @Sql += @Sql2

	-- Access Deal throwght with proxy customer
	if @UI_RAZPOREDITEL IS NOT NULL
	begin
		/* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
		declare @CUSTOMER_ROLE_TYPE varchar(32) = N''
		;
		-- 0 - Пълномощник; 1 - Законен представител
		select @CUSTOMER_ROLE_TYPE = case IsNull(@UI_RAZPOREDITEL,-1)	
											when  0 then ' = 2'				/* 2 - Пълномощник*/
											when  1 then ' = 3'				/* 3 - Законен представител */
											when -1 then ' in (2,3) ' end;	/* 2 & 3 */
		select @Sql2 = N'
		inner join dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] [PROXY_ID] with(nolock)
			on	[PROXY_ID].[DEAL_TYPE] = 1
			and [PROXY_ID].[DEAL_NUM]  = [DEAL].[DEAL_NUM]
			and [PROXY_ID].[CUSTOMER_ROLE_TYPE] '+@CUSTOMER_ROLE_TYPE+'
		inner join dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [PROXY] with(nolock)
			on	[PROXY].[CUSTOMER_ID] = [PROXY_ID].[REPRESENTATIVE_CUSTOMER_ID]
		';

		-- [DT015_CUSTOMERS_ACTIONS_TA].[UI_RAZPOREDITEL] -- 0 - Пълномощник; 1 - Законен представител
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N'@UI_RAZPOREDITEL: '+STR(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0)+' '
		select @Sql += @Sql2;
	end
	else 
	begin

		select @Sql2 = N'
		inner join dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [PROXY] with(nolock)
			ON	[PROXY].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
		';

		-- Base join clause: 
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N' WITHOUT PROXY: [PROXY].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]'
		select @Sql += @Sql2;
	end

	/* ВНИМАНИЕ!!! При актуализация на условията тук, може да се наложи и корекция на генерирането на SELECT заявката в секция Prepate Base SELECT statement: */
	-- Add additional joint for document "Credit Transfer": 
	if IsNull(@TYPE_ACTION,'') in ('CT', 'DD') and IsNull(@UI_INOUT_TRANSFER,'-1') = '3' and IsNull(@BETWEEN_OWN_ACCOUNTS,-1) in (0,1)
	begin

		if @BETWEEN_OWN_ACCOUNTS = 1
		begin
			select @Sql2 = N'
			inner join dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] [CD_CNT] with(nolock)
				ON	[CD_CNT].[CUSTOMER_ID]	 = [DEAL].[CUSTOMER_ID]
				AND [CD_CNT].[CURRENCY_CODE] = '+str(@CCY_CODE_DEAL_BEN,len(@CCY_CODE_DEAL_BEN),0)+' 
				AND	[CD_CNT].[DEAL_TYPE]	 = 1
				AND	[CD_CNT].[DEAL_COUNT]	 > 1
			cross apply (
				select top(1)
						[D].[DEAL_TYPE]	AS	[DEAL_TYPE_BEN] 
					,	[D].[DEAL_NUM] 	AS	[DEAL_NUM_BEN] 
				from dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] with(nolock)
				where	[D].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
					and [D].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL_BEN,len(@CCY_CODE_DEAL_BEN),0)+'
					and	[D].[DEAL_NUM] <> [DEAL].[DEAL_NUM]
			) [DEAL_BEN]
			';
		end
		else 
		begin

			/* Условие за стандартен договор на кореспондиращата сделка */
			declare @CND_STD_CONTRACT_BEN nvarchar(256) = N'';
			if IsNull(@UI_STD_DOG_CODE_BEN, -1) > 0
				select @CND_STD_CONTRACT_BEN = N' and [D].[DEAL_STD_DOG_CODE] = '+str(@UI_STD_DOG_CODE_BEN,len(@UI_STD_DOG_CODE_BEN),0);
			;

			select @Sql2 = N'
			cross apply (
				select top(1)
						[D].[DEAL_TYPE]	AS	[DEAL_TYPE_BEN] 
					,	[D].[DEAL_NUM] 	AS	[DEAL_NUM_BEN] 
				from dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] with(nolock)
				where	[D].[CUSTOMER_ID] <> [DEAL].[CUSTOMER_ID]
					and [D].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL_BEN,len(@CCY_CODE_DEAL_BEN),0)
					+ @CND_STD_CONTRACT_BEN + '
			) [DEAL_BEN]
			';
		end

		-- Base join clause: 
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N' Add additiona join for document Credit Transfer; @BETWEEN_OWN_ACCOUNTS :'+str(@BETWEEN_OWN_ACCOUNTS,len(@BETWEEN_OWN_ACCOUNTS),0)
		select @Sql += @Sql2;
	end

	/*********************************************************************/
	/* Prepare WHERE statement: */
	-- [DT015_CUSTOMERS_ACTIONS_TA].[DB_CLIENT_TYPE] => @DB_CLIENT_TYPE_DT300:
	select @Sql2 = N'
	where [CUST].[CLIENT_TYPE_DT300_CODE] = '+str(@DB_CLIENT_TYPE_DT300,len(@DB_CLIENT_TYPE_DT300),0);
	insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
	select	(@Sql2 + @CrLf), ' BASE @DB_CLIENT_TYPE_DT300 : ' + @Sql2
	select @Sql += @Sql2

	-- enum CustomerSubtypes: (-1) - Без значение; 1 - (над 18г.); 2 - (от 14г. до 18г.); 3 - (до 14г.)
	if  IsNull(@CUSTOMER_AGE, '-1') <> '-1'
	Begin 
		select	@Sql2 = N'AND [PROXY].[CLIENT_BIRTH_DATE] BETWEEN '
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0)+' AND ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0)+' ' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[CUSTOMER_AGE] '+@CUSTOMER_AGE+' - between YEAR : ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0) + ' AND '
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0) + @CrLf;

		select @Sql += @Sql2;
	end

	/*****************************************************/
	-- 0 - не е обединяван (клиент с един кл. код); 3 - обединен, без значение дали е бил главен или подчинен (кл.с повече от един кл.код); -1 - без значение
	if @UNIFIED <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_MANY_CLIENT_CODES] = ' + case when @UNIFIED = 0 THEN '0' ELSE '1' END + @CrLf;
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UNIFIED] : ' + str(@UNIFIED,len(@UNIFIED),0 )

		select @Sql += @Sql2
	end

	-- 0 - Не е служебен или свързан със служебен; 1 - Реално ЕГН, има такива служебни; 2 - служебни ЕГН
	if @IS_SERVICE <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_DUBL_CLIENT_IDS] = ' + case when @IS_SERVICE = 0 then '0' else '1' end + @CrLf;
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

		select @Sql += @Sql2

		if @IS_SERVICE <> 0
		begin 
			select @Sql2 = ' AND [CUST].[IS_ORIGINAL_EGFN] = ' + case when @IS_SERVICE = 1 then '1' else '0' end + @CrLf;

			insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

			select @Sql += @Sql2
		end 
	end

	-- enum DetailedTypeOfIdentifier : [DT015_CUSTOMERS].[IDENTIFIER_TYPE]
	if IsNull(@CODE_EGFN_TYPE,-1) <> -1
	begin 
		select @Sql2 = ' AND [CUST].[CLIENT_IDENTIFIER_TYPE] = ' + str(@CODE_EGFN_TYPE,len(@CODE_EGFN_TYPE),0) + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_EGFN_TYPE] : ' + str(@CODE_EGFN_TYPE,len(@CODE_EGFN_TYPE),0 )

		select @Sql += @Sql2
	end 

	-- 1 - валидни документи
	if IsNull(@VALID_ID,-1) = 1
	begin
		select @Sql2 = ' AND [PROXY].[HAS_VALID_DOCUMENT] = 1' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[VALID_ID] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end 

	-- @TODO: @IS_PROXY: 
	-- Ако клиента е маркиран като пълномощник, то той няма да се търси като самостоятелен 
	-- клиент, а данните му ще се актуализират при актуализация на данните за титуляра.
	--if IsNull(@IS_PROXY, -1) <> -1
	--	select @Sql += ' AND [CUST].[CUSTOMER_CHARACTERISTIC] = ' + str(@CUSTOMER_CHARACTERISTIC, len(@CUSTOMER_CHARACTERISTIC), 0);

	-- Указва дали клиента да е уникален за таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA]
	if IsNull(@IS_UNIQUE_CUSTOMER, -1) = 1
	begin 
		select @Sql2 = ' AND NOT EXISTS 
		(
			select * from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [TA_CUST] with(nolock)
			where [TA_CUST].[UI_CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
				/* and [TA_CUST].[TA_TYPE] = '+@TA_TYPE+' */
		)' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[VALID_ID] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end
	;

	-- @HAVE_CREDIT:
	-- Дали клиента има активен кредит: ;Без допълнителни сметки - ;Всички разплащателни и влогове - 
	-- ;Всички разплащателни - несвързани към друг кредит - ; Всички разплащателни, влогове и депозитни сметки -
	if IsNull(@HAVE_CREDIT, -1) in ( 0, 1 )
	begin
		select @Sql2 = ' AND [CUST].[HAS_LOAN] = '+STR(@HAVE_CREDIT,LEN(@HAVE_CREDIT),0) + @CrLf;
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[HAS_LOAN] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end

	-- [COLLECT_TAX_FROM_ALL_ACC] : Клиента има ли непратени такси, който могат да се събират от всички сметки на клиента
	if IsNull(@COLLECT_TAX_FROM_ALL_ACC,-1) in (0,1)
	begin
		select @StrIntVal = STR(@COLLECT_TAX_FROM_ALL_ACC,LEN(@COLLECT_TAX_FROM_ALL_ACC),0);
		select @Sql2 = ' AND [CUST].[HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC] = ' + @StrIntVal + @CrLf;
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[COLLECT_TAX_FROM_ALL_ACC] : ' + @StrIntVal

		select @Sql += @Sql2
	end

	-- 0 - Пълномощник; 1 - Законен представител
	if IsNull(@UI_RAZPOREDITEL,-1) <> -1
	begin 
		if @UI_RAZPOREDITEL = 0
		begin
			select @Sql2 = ' AND [DEAL].[PROXY_COUNT] > 0' + @CrLf;

			insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_RAZPOREDITEL] : ' + str(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0 )

			select @Sql += @Sql2
		end
	end

	-- 1 - безсрочен; 0 - с крайна дата
	-- @TODO: @UI_UNLIMITED:
	--If IsNull(@UI_UNLIMITED, -1) <> -1
	--	select @Sql += ' ''

	-- Код на стандартен договор
	if IsNull(@UI_STD_DOG_CODE,-1) > 0 and IsNull(@UI_INDIVIDUAL_DEAL,-1) NOT IN (1)
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_STD_DOG_CODE] = '+STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_STD_DOG_CODE] : ' + STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0);

		select @Sql += @Sql2
	end 

	--0 - стандартна сделка, 1 - индивидуална сделка
	if IsNull(@UI_INDIVIDUAL_DEAL,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_INDIVIDUAL_DEAL] = '+STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0) + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_INDIVIDUAL_DEAL] : ' + STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0);

		select @Sql += @Sql2

		-- Код на стандартен договор по който е разкрита индивидуалната сделка
		if IsNull(@INT_COND_STDCONTRACT,-1) >= 0
		begin
			select @Sql2 = ' AND [DEAL].[INT_COND_STDCONTRACT] = '+STR(@INT_COND_STDCONTRACT, LEN(@INT_COND_STDCONTRACT),0) + @CrLf;

			insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[INT_COND_STDCONTRACT] : ' + +STR(@INT_COND_STDCONTRACT, LEN(@INT_COND_STDCONTRACT),0);

			select @Sql += @Sql2
		end		

		if IsNull(@UI_STD_DOG_CODE,-1) >= 0
		begin
			select @Sql2 = ' AND [DEAL].[DEAL_STD_DOG_CODE] = '+STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + @CrLf;

			insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_STD_DOG_CODE] : ' + STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + '/* for individual deal: [UI_INDIVIDUAL_DEAL] = 1 */';

			select @Sql += @Sql2
		end

	end 

	-- 0 - не е комбиниран продукт, код > 0 - да принадлежи към този комбиниран продукт
	if IsNull(@CODE_UI_NM342, -1) > 0
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NM342_BUNDLE_PRODUCT_CODE] = '+ STR(@CODE_UI_NM342,LEN(@CODE_UI_NM342),0) + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_UI_NM342] : ' + STR(@CODE_UI_NM342,LEN(@CODE_UI_NM342),0);

		select @Sql += @Sql2
	end

	-- 0 - сметката се таксува от себе си, 1 - има друга таксуваща сметка, 2 - без проверка дали има друга таксуваща сметка или се таксува от себе си
	if IsNull(@UI_OTHER_ACCOUNT_FOR_TAX,-1) in (0, 1)
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_OTHER_TAX_ACCOUNT] = ' + str(@UI_OTHER_ACCOUNT_FOR_TAX,len(@UI_OTHER_ACCOUNT_FOR_TAX),0) + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_OTHER_ACCOUNT_FOR_TAX] : ' + str(@UI_OTHER_ACCOUNT_FOR_TAX,len(@UI_OTHER_ACCOUNT_FOR_TAX),0);

		select @Sql += @Sql2
	end

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_NOAUTOTAX,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NO_AUTO_PAY_TAX] = '+@UI_NOAUTOTAX + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_NOAUTOTAX] : ' + @UI_NOAUTOTAX

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_DENY_MANUAL_TAX_ASSIGN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_DENY_MANUAL_TAX_ASSIGN] = '+@UI_DENY_MANUAL_TAX_ASSIGN + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_DENY_MANUAL_TAX_ASSIGN] : ' + @UI_DENY_MANUAL_TAX_ASSIGN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_CAPIT_ON_BASE_DATE_OPEN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_CAPIT_ON_BASE_DATE_OPEN] = '+@UI_CAPIT_ON_BASE_DATE_OPEN + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_CAPIT_ON_BASE_DATE_OPEN] : ' + @UI_CAPIT_ON_BASE_DATE_OPEN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_BANK_RECEIVABLES,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_EXCLUDE_FROM_BANK_COLLECTIONS] = '+@UI_BANK_RECEIVABLES + @CrLf;
		
		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_BANK_RECEIVABLES] : ' + @UI_BANK_RECEIVABLES

		select @Sql += @Sql2
	end 

	--0 - не е съвместна сделка, 1 - съвместна сделка от тип "по отделно"
	if IsNull(@UI_JOINT_TYPE,-1) in (0, 1)
	begin

		select @Sql2 = ' AND [DEAL].[DEAL_IS_JOINT_DEAL] = ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0) + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_JOINT_TYPE] : ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0);

		select @Sql += @Sql2

		/* enum JointDealsAccessToFundsType: 0 - Separate; 1 - Always Together */	
		if @UI_JOINT_TYPE = 1
		begin 
			select @Sql2 = ' AND [DEAL].[DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] = 0' + @CrLf;

			insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_JOINT_TYPE] (Access type: 0 - Separate; 1 Always Together) : ';

			select @Sql += @Sql2
		end
	end

	-- 0 или долна граница на разполагаемостта ( '<0', '>0' )
	if Left(ltrim(IsNull(@LIMIT_AVAILABILITY,'0')),1) in ('<', '>', '=')
	begin 
		select @Sql2 = ' AND ([DEAL].[ACCOUNT_BEG_DAY_BALANCE] - [DEAL].[BLK_SUMA_MIN] + [DEAL].[DAY_OPERATION_BALANCE]) ' + REPLACE(@LIMIT_AVAILABILITY, ' ','') + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[LIMIT_AVAILABILITY] : ' + @LIMIT_AVAILABILITY;

		select @Sql += @Sql2
	end 

	-- 1 - активна; Безусловно ще се търсят сделки които НЕ СА ЗАМРАЗЕНИ
	if IsNull(@DEAL_STATUS,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[IS_DORMUNT_ACCOUNT] = 0' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[DEAL_STATUS] : ' + str(@DEAL_STATUS,len(@DEAL_STATUS),0);

		select @Sql += @Sql2
	end 

	-- 0 - няма несъбрани такси; 1 - има несъбрани такси, -1 без значение от сумата
	if IsNull(@LIMIT_TAX_UNCOLLECTED,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_TAX_UNCOLECTED] = ' + str(@LIMIT_TAX_UNCOLLECTED,len(@LIMIT_TAX_UNCOLLECTED),0) + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[LIMIT_TAX_UNCOLLECTED] : ' + str(@LIMIT_TAX_UNCOLLECTED,len(@LIMIT_TAX_UNCOLLECTED),0);

		select @Sql += @Sql2
	end 

	-- 0 - няма запор; друга сума - има запор над определена сума; (-1) : няма значение;
	if IsNull(@LIMIT_ZAPOR,-1) >= 0
	begin 

		if @LIMIT_ZAPOR = 0
		begin 
			select @Sql2 = ' AND [DEAL].[HAS_DISTRAINT] = 0' + @CrLf;

			insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 

		if @LIMIT_ZAPOR > 0
		begin
			select @Sql2 = ' AND [DEAL].[HAS_DISTRAINT] = 1 AND [DEAL].[BLK_SUMA_MIN] > 0.0' + @CrLf;

			insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 
	end

	-- Да няма осчетоводено 'Вносни Бележки' по сделката: @RUNNING_ORDER = 1 and @TYPE_ACTION = ''
	if @TYPE_ACTION = 'CashPayment' and IsNull(@RUNNING_ORDER,-1) = 1
	begin
		select @Sql2 = ' AND [DEAL].[HAS_WNOS_BEL] = ' + (case when @RUNNING_ORDER > 1 then '1' else '0' end)  + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[TYPE_ACTION] = ''CashPayment'' and [RUNNING_ORDER] : ' + str(@RUNNING_ORDER,len(@RUNNING_ORDER),0);

		select @Sql += @Sql2
	end

	-- Да няма осчетоводено 'Нареждане Разписка' по сделката: @RUNNING_ORDER = 1 and @TYPE_ACTION = ''
	if @TYPE_ACTION = 'CashW' and IsNull(@RUNNING_ORDER,-1) = 1
	begin
		select @Sql2 = ' AND [DEAL].[HAS_NAR_RAZP] = ' + (case when @RUNNING_ORDER > 1 then '1' else '0' end)  + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[TYPE_ACTION] = ''CashW'' and [RUNNING_ORDER] : ' + str(@RUNNING_ORDER,len(@RUNNING_ORDER),0);

		select @Sql += @Sql2
	end	

	-- Да укаже дали сметката е кореспондираща до други сделки: -1 няма значение; 0 не е; 1 да , кореспондираща е
	if IsNull(@IS_CORR,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND '+CASE WHEN @IS_CORR = 0 THEN 'NOT' ELSE '' END+ ' EXISTS (
			select * from dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] [TAX] with(nolock)
			where  [TAX].[CORR_ACCOUNT] =  [DEAL].[DEAL_ACCOUNT]
		)' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_CORR] : ' + str(@IS_CORR,len(@IS_CORR),0);

		select @Sql += @Sql2
	end 

	-- Указва дали РС да е уникална в таблица [RAZPREG_TA]
	if IsNull(@IS_UNIQUE_DEAL,-1) in ( 1 )
	begin 
		select @Sql2 = ' AND NOT EXISTS (
			select * FROM dbo.[RAZPREG_TA] [TA] with(nolock)
			where	[TA].[UI_DEAL_NUM] = [DEAL].[DEAL_NUM]
				and ( [TA].[IS_BEN] IS NULL OR [TA].[IS_BEN] <> 1 )  
		)' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_UNIQUE_DEAL] : ' + str(@IS_UNIQUE_DEAL,len(@IS_UNIQUE_DEAL),0)

		select @Sql += @Sql2
	end
	;

	-- Код на програма от Group Sales + Продуктов код на карта + Код на GS договор
	if IsNull(@CODE_GS_PROGRAMME,-1) > 0 AND IsNull(@CODE_GS_CARD,-1) > 0 AND IsNull(@GS_PRODUCT_CODE,-1) > 0
	begin 
		select @Sql2 = ' AND EXISTS (
			select * FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [GS] with(nolock)
			where	[GS].[DEAL_NUM]	 = [DEAL].[DEAL_NUM]
				and [GS].[DEAL_TYPE] = 1
				and [GS].[DEAL_GS_INDIVIDUAL_PROGRAM_CODE] = '+STR(@CODE_GS_PROGRAMME,LEN(@CODE_GS_PROGRAMME),0)+'
				and [GS].[DEAL_GS_INDIVIDUAL_CARD_PRODUCT] = '+STR(@CODE_GS_CARD,LEN(@CODE_GS_CARD),0)+'
				and [GS].[DEAL_GS_INDIVIDUAL_PRODUCT_CODE] = '+STR(@GS_PRODUCT_CODE,LEN(@GS_PRODUCT_CODE),0)+'
		)' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_GS_PROGRAMME] : ' + str(@CODE_GS_PROGRAMME,len(@CODE_GS_PROGRAMME),0)
				+', [CODE_GS_CARD] : ' + str(@CODE_GS_CARD,len(@CODE_GS_CARD),0)
				+', [GS_PRODUCT_CODE] : ' + str(@GS_PRODUCT_CODE,len(@GS_PRODUCT_CODE),0)
		select @Sql += @Sql2
	end 

	-- Валута на кореспонденцията
	if IsNull(@CCY_CODE_CORS, -1) > 0
	begin 
		select @Sql2 = ' AND '+CASE WHEN @IS_CORR = 0 THEN 'NOT' ELSE '' END+ ' EXISTS (
			select * FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] [TAX] with(nolock)
			where  [TAX].[CORR_ACCOUNT] = [DEAL].[DEAL_ACCOUNT] ' + @CrLf;

		-- Разполагаемост по сделката 
		if left(ltrim(IsNull(@LIMIT_AVAILABILITY_CORS, '0')),1) in ('<', '>', '=')
				select @Sql2 += ' AND ([TAX].[ACCOUNT_BEG_DAY_BALANCE] - [TAX].[BLK_SUMA_MIN]+ [TAX].[DAY_OPERATION_BALANCE] ) ' + REPLACE(@LIMIT_AVAILABILITY_CORS,' ','');

		select @Sql2 += ')' + @CrLf;

		insert into dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CCY_CODE_CORS] : ' + str(@CCY_CODE_CORS,len(@CCY_CODE_CORS),0) + ', [LIMIT_AVAILABILITY_CORS] : ' + @LIMIT_AVAILABILITY_CORS

		select @Sql += @Sql2
	end 

	/**********************************************************************/
	/* Execute Sql statement: */
	if len(@Sql) > 10
	begin 
		select @Sql as [SQL_QUERY]
		select @Msg = 'TA Row ID: ' + @TestCaseRowID + ', successful generated sql query: "'+@Sql+'"'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, @Sql

		begin try
			insert into dbo.[#TBL_RESULT] 
			exec sp_executeSql  @Sql
		end try 
		begin catch 
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
			return 1
		end catch 
	end

	select @Rows = (select count(*) from dbo.[#TBL_RESULT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: insert into dbo.[#TBL_RESULT], Rows affected : ' + str(@Rows,len(@Rows),0) + ', TA ID :'+ @TestCaseRowID;
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
	end

	if @Rows <= 0 and @SaveTAConditions = 1
	begin
		insert into dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS]
		( [TEST_ID], [SQL_COND], [DESCR], [IS_BASE_SELECT], [IS_SELECT_COUNT] )
		SELECT	@TestCaseRowID	 AS [TEST_ID]
			,	[S].[SQL_COND]
			,	[S].[DESCR]
			,	[S].[IS_BASE_SELECT]
			,	[S].[IS_SELECT_COUNT]
		FROM dbo.[#TEMP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] [S] WITH(NOLOCK)
	end
		
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS]'
	end

	return 0;
end 
go

/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] */
DROP PROCEDURE IF EXISTS dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]
GO

CREATE PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@IS_DEAL_BEN			bit = 0 
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0, @LogResultTable int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql2 nvarchar(4000) = N''
		,	@TA_RowID int = cast ( @TestCaseRowID as int );
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]'
	;

	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(@OnlineSqlServerName,1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(@OnlineSqlDataBaseName,1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)		

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;

	/************************************************************************************************************/
	-- Get TA Deal Row ID:
	declare @TBL_ROW_ID int = 0
	;
	select	@TBL_ROW_ID = case when @IS_DEAL_BEN = 1 then [DEAL_BEN_ROW_ID] else [DEAL_ROW_ID] end
	from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID
			+ '; Deal num: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
			+ '; Is ben deal: ' + str(@IS_DEAL_BEN,len(@IS_DEAL_BEN),0);

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	/************************************************************************************************************/
	-- UPDATE [RAZPREG_TA]: 
	drop table if exists dbo.[#TBL_ONLINE_DEAL_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEAL_INFO]
	(
		[DEAL_NUM]			int
	,	[ACCOUNT]			varchar(64)
	,	[ACCOUNT_CURRENCY]	int
	,	[IBAN]				varchar(64)
	,	[BEG_SAL]			float
	,	[DAY_MOVE]			float
	,	[BLK_SUMA_MIN]		float
	,	[RAZPOL]			float
	,	[TAX_UNCOLLECTED]	float
	,	[DISTRAINT_SUM]		float
	,	[HAS_TAX_UNCOLLECTED] int
	);


	begin try
		insert into dbo.[#TBL_ONLINE_DEAL_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @DEAL_TYPE, @DEAL_NUM
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()

			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
								+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
								+ ', @DEAL_TYPE = 1, @DealNum = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg

			return 2
	end catch

	if @Ret <> 0
		return 3;

	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DEAL_INFO]  with(nolock)
	;

	/************************************************************************************************************/
	-- Load tax uncollected amount from OnlinDB:
	declare @Account varchar(64) = N'', @AccCurrency int = 100, @HasTaxUncollected int = 0
	;
	
	select top (1) @Account = [ACCOUNT], @AccCurrency = [ACCOUNT_CURRENCY], @HasTaxUncollected = [HAS_TAX_UNCOLLECTED]
	from dbo.[#TBL_ONLINE_DEAL_INFO] with(nolock)
	;

	if IsNull(@HasTaxUncollected,0) = 1 and IsNull(@Account,'') <> ''
	begin

		drop table if exists dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		;

		create table dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		(	[ACCOUNT]			varchar(64)
		,	[TAX_UNCOLLECTED]	float
		,	[CNT_ITEMS]			int	
		);

		begin try
			insert into dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
			exec @Ret = dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName, @OnlineSqlDataBaseName, @Account, @AccCurrency
		end try
		begin catch
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
									+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
									+ ', @Account = '+@Account
									+ ', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
				;

				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 4
		end catch

		if exists ( select * from dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] with(nolock))
		begin

			update [D]
			set [TAX_UNCOLLECTED] = [s].[TAX_UNCOLLECTED]
			from dbo.[#TBL_ONLINE_DEAL_INFO] [D]
			inner join dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] [S] with(nolock)
				on	[S].[ACCOUNT] = [D].[ACCOUNT]
				and [d].[ACCOUNT_CURRENCY] = @AccCurrency
		end

	end

	/********************************************************************************************************/
	/* Update data in [RAZPREG_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_DEAL_NUM]			= [S].[DEAL_NUM]				-- RAZPREG_TA	UI_DEAL_NUM	
			,	[DB_ACCOUNT]			= [S].[ACCOUNT]					-- RAZPREG_TA	DB_ACCOUNT	
			,	[UI_ACCOUNT]			= [xa].[ACC_WITH_SPACE]			/* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
			,	[ZAPOR_SUM]				= STR([S].[DISTRAINT_SUM],14,2)	-- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
			,	[IBAN]					= [S].[IBAN]					-- RAZPREG_TA	IBAN	
			,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]			-- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
		FROM dbo.[RAZPREG_TA] [D]
		INNER JOIN  dbo.[#TBL_ONLINE_DEAL_INFO] [S] WITH(NOLOCK)
			ON [S].[DEAL_NUM] = @DEAL_NUM
		cross apply (
			select case when left([S].[ACCOUNT], 2) = '17' 
				then left([S].[ACCOUNT],4)+' '+substring([S].[ACCOUNT],5,9)+' '+substring([S].[ACCOUNT],14,2)+' '+right(rtrim([S].[ACCOUNT]),1)
				else left([S].[ACCOUNT],4)+' '+substring([S].[ACCOUNT],5,3)+' '+substring([S].[ACCOUNT],8,9) +' '+substring([S].[ACCOUNT],17,2)+' '+right(rtrim([S].[ACCOUNT]),1)
				end AS  [ACC_WITH_SPACE]
		) [xa]
		WHERE [D].[ROW_ID] = @TBL_ROW_ID
		;
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[RAZPREG_TA], Rows affected: '+str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0) 
			,	@Sql2 = 'UPDATE dbo.[RAZPREG_TA] [D] SET [UI_DEAL_NUM] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
			 + ', TA Row ID: ' + @TestCaseRowID 
			 + ', Deal num: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
			 + ', Is Ben deal: ' + str(@IS_DEAL_BEN,len(@IS_DEAL_BEN),0)
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]'
	end

	return 0;
end 
GO

/********************************************************************************************************/
/* Процедура за първоначална инициализация */
CREATE OR ALTER PROCEDURE dbo.SP_TA_EXISTING_ONLINE_DATA_INIT
(
	@DB_TYPE SYSNAME = N'AIR'
	, @TestAutomationType SYSNAME = N'%AIR%'
	, @LogTraceInfo INT = 1
)
AS
BEGIN
	DECLARE @Sql VARCHAR(max) = N''
		, @Msg NVARCHAR(max) = N''
		, @LogBegEndProc INT = 1
		, @AccountDateChar VARCHAR(32) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @TimeBeg DATETIME = GetDate()

	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestAutomationType
			, '*** Begin Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_INIT'

	/************************************************************************************************************/
	/* Get Datasources: */
	DECLARE @OnlineSqlServerName SYSNAME = N''
		, @OnlineSqlDataBaseName SYSNAME = N''
		, @DB_ALIAS SYSNAME = N'VCS_OnlineDB'

	EXEC @Ret = dbo.[SP_TA_GET_DATASOURCE] @DB_TYPE
		, @DB_ALIAS
		, @OnlineSqlServerName OUTPUT
		, @OnlineSqlDataBaseName OUTPUT

	IF @Ret <> 0
	BEGIN
		SELECT @Msg = N'Error execute proc, Error code: ' + str(@Ret, len(@Ret), 0) + '  Result: @OnlineSqlServerName = "' + @OnlineSqlServerName + '", @OnlineSqlDataBaseName = "' + @OnlineSqlDataBaseName + '"'
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = ' + @DB_TYPE + N', @DB_ALIAS = ' + @DB_ALIAS + N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 1
	END

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_GET_DATASOURCE], @OnlineSqlServerName: ' + @OnlineSqlServerName + ', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + ' '
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = ' + @DB_TYPE + N', @DB_ALIAS = ' + @DB_ALIAS + N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	DECLARE @SqlFullDBName SYSNAME = @OnlineSqlServerName + '.' + @OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* Get Account Date: */
	DECLARE @CurrAccDate DATETIME = 0

	BEGIN TRY
		EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @CurrAccDate OUTPUT
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()
			, @Sql = N'EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR
		, @AccountDateChar = '''' + convert(CHAR(10), @CurrAccDate, 120) + ''''

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' + @AccountDateChar
			, @Sql = N'EXEC dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Init customers data: */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS] @DB_TYPE
			, @TestAutomationType
			, @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @AccountDateChar
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS], @DB_TYPE = ' + @DB_TYPE + N', @TestAutomationType = ' + @TestAutomationType + N', @OnlineSqlServerName = ' + @OnlineSqlServerName + N', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + N', @AccountDateChar = ' + @AccountDateChar
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @DB_TYPE + ', ' + @TestAutomationType + ', ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Init customers data: */
	BEGIN TRY
		EXEC dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS] @DB_TYPE
			, @TestAutomationType
			, @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @AccountDateChar
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN - 2
	END CATCH

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: exec dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS], @DB_TYPE = ' + @DB_TYPE + N', @TestAutomationType = ' + @TestAutomationType + N', @OnlineSqlServerName = ' + @OnlineSqlServerName + N', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + N', @AccountDateChar = ' + @AccountDateChar
			, @Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] ' + @DB_TYPE + ', ' + @TestAutomationType + ', ' + @OnlineSqlServerName + N', ' + @OnlineSqlDataBaseName + N', @CurrAccDate OUT'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	-- /************************************************************************************************************/
	-- /* Customers - Deals cross tables */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]

	INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] (
		[CUSTOMER_ID]
		, [DEAL_TYPE]
		, [CURRENCY_CODE]
		, [DEAL_COUNT]
		)
	SELECT [s].[CUSTOMER_ID] AS [CUSTOMER_ID]
		, 1 AS [DEAL_TYPE]
		, [s].[DEAL_CURRENCY_CODE] AS [CURRENCY_CODE]
		, COUNT(*) AS [DEAL_COUNT]
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [s] WITH (NOLOCK)
	GROUP BY [s].[CUSTOMER_ID]
		, [s].[DEAL_CURRENCY_CODE]
		/* having count(*) > 1 */

	/**************************************************************/
	/* Log end procedure: */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', AccData: ' + @AccountDateChar + ', Fileter: ' + @TestAutomationType

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_INIT'
	END

	RETURN 0
END
GO

/********************************************************************************************************/
/* Процедура за първоначална инициализация на клиенти */
DROP TABLE IF EXISTS dbo.AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS
GO

CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS]
(
	@DB_TYPE SYSNAME = N'AIR'
	, @TestAutomationType SYSNAME = N'%AIR%'
	, @OnlineSqlServerName SYSNAME = ''
	, @OnlineSqlDataBaseName SYSNAME = ''
	, @AccountDateChar VARCHAR(32)
	, @LogTraceInfo INT = 1
)
AS
BEGIN
	DECLARE @Sql VARCHAR(max) = N''
		, @Msg NVARCHAR(max) = N''
		, @LogBegEndProc INT = 1
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @TimeBeg DATETIME = GetDate()

	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Sql = 'dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS] @DB_TYPE = ' + @DB_TYPE + N' , @@TestAutomationType = ' + @TestAutomationType + N' , @OnlineSqlServerName = ' + @OnlineSqlServerName + N' , @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName
			, @Msg = '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS]'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Format full Online DB name */

	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName), 1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName), 1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	DECLARE @SqlFullDBName SYSNAME = @OnlineSqlServerName + '.' + @OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* Prepare all duplicate customers EGFN */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] 
		SELECT
			CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT) AS [EGFN]
		FROM ' + @SqlFullDBName + '.dbo.[DT015_CUSTOMERS] [C] WITH (NOLOCK)
		WHERE ISNUMERIC( [C].[IDENTIFIER] ) = 1 
		GROUP BY CAST( RIGHT( RTRIM( [C].[IDENTIFIER] ), 13) AS BIGINT) 
		HAVING COUNT(*) > 1
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 3
	END CATCH

	SELECT @Rows = (SELECT count(*) FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] WITH (NOLOCK))
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers data */

	DROP TABLE IF EXISTS #CSTEMP_TA_CLIENT_FILTERS

	SELECT SECTOR
		, DB_CLIENT_TYPE_DT300 AS CLIENT_TYPE
	INTO #CSTEMP_TA_CLIENT_FILTERS
	FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
	WHERE [DB_TYPE] = @DB_TYPE
		AND [TA_TYPE] LIKE @TestAutomationType
	GROUP BY [SECTOR]
		, [DB_CLIENT_TYPE_DT300]

	DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS]
	SET @Sql =
	N'
		WITH [CTE_FILTER] AS 
		(
			SELECT [SECTOR], [CLIENT_TYPE]
			FROM #CSTEMP_TA_CLIENT_FILTERS WITH(NOLOCK)
		)
		SELECT 	IDENTITY(INT, 1, 1) 				AS [ROW_ID]
			, [C].[CUSTOMER_ID]						AS [CUSTOMER_ID]
			, [M].[CL_CODE]							AS [CLIENT_CODE_MAIN]
			, RTRIM([C].[IDENTIFIER])				AS [CLIENT_IDENTIFIER]
			, [C].[IDENTIFIER_TYPE]					AS [CLIENT_IDENTIFIER_TYPE]
			, [C].[ECONOMIC_SECTOR]					AS [CLIENT_SECTOR]		
			, [C].[CLIENT_TYPE]						AS [CLIENT_TYPE_DT300_CODE]
			, [C].[BIRTH_DATE]						AS [CLIENT_BIRTH_DATE]
			, [TYP].[CUSTOMER_CHARACTERISTIC]		AS [CUSTOMER_CHARACTERISTIC]
			, [TYP].[IS_FUNCTIONAL_ID]				AS [IS_FUNCTIONAL_ID]
			, [TYP].[IS_PHISICAL_PERSON]			AS [IS_PHISICAL_PERSON]
			, [EX_BITS].*
		INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS]
		FROM [CTE_FILTER] [F] WITH(NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015_CUSTOMERS] [C] WITH(NOLOCK)
			ON  [F].[SECTOR] = [C].[ECONOMIC_SECTOR]
			AND [F].[CLIENT_TYPE] = [C].[CLIENT_TYPE]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015_MAINCODE_CUSTID] [M] WITH(NOLOCK)
			ON  [M].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
		CROSS APPLY (
			SELECT	CAST( CASE WHEN [C].[IDENTIFIER_TYPE] IN (5,6,7,8) THEN 1 ELSE 0 END AS BIT)
													AS [IS_FUNCTIONAL_ID]
				,	CAST( CASE WHEN [C].[CUSTOMER_TYPE] = 1 THEN 1 ELSE 0 END AS BIT)  
													AS [IS_PHISICAL_PERSON]
				,	CAST( [C].[CUSTOMER_CHARACTERISTIC] as TINYINT )
													AS [CUSTOMER_CHARACTERISTIC]
		) [TYP] 
		CROSS APPLY (
			SELECT CAST ( 0 AS BIT )			AS [HAS_MANY_CLIENT_CODES]
				, CAST ( 0 AS BIT )				AS [HAS_DUBL_CLIENT_IDS]
				, CAST ( 0 AS BIT )				AS [IS_PROXY]
				, CAST ( 0 AS BIT )				AS [HAS_LOAN]
				, CAST ( 0 AS BIT )				AS [HAS_VALID_DOCUMENT]
				, CAST ( 1 AS BIT )				AS [IS_ORIGINAL_EGFN]
				, CAST ( 0 AS BIT )				AS [HAS_ZAPOR]
				, CAST ( 0 AS BIT )				AS [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC]			
		) [EX_BITS]
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Create Indexes ON [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] */

	CREATE INDEX IX_AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_CUSTOMER_ID ON dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] ([CUSTOMER_ID])

	/************************************************************************************************************/
	/* Prepare Customers with multiple client codes */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES]	
		SELECT
			[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] WITH(NOLOCK)
		where EXISTS 
		(
			SELECT [CC].[CUSTOMER_ID] 
			FROM ' + @SqlFullDBName + '.dbo.[DT015] [CC] WITH(NOLOCK)
			WHERE [CC].[CUSTOMER_ID] = [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS].[CUSTOMER_ID]
			GROUP BY [CC].[CUSTOMER_ID] 
			HAVING COUNT(*) > 1
		)
	'
	
	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY
	
	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH
	
	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with duplicated EGFN */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN]	
		SELECT
			[C].[CUSTOMER_ID]
			, [X].[IS_ORIGINAL_EGFN]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
		INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_DUPLICATED_EGFN] [DUBL] WITH(NOLOCK)
			ON [DUBL].[EGFN] = CAST(RIGHT(RTRIM([C].[CLIENT_IDENTIFIER]), 13) AS BIGINT)
		CROSS APPLY
		(
			SELECT CAST( CASE WHEN [DUBL].[EGFN] = CAST( [C].[CLIENT_IDENTIFIER] AS BIGINT )
						THEN 1 ELSE 0 END AS BIT)	AS [IS_ORIGINAL_EGFN]
		) [X]
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers who are proxies */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES]	
		SELECT
			[C].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM ' + @SqlFullDBName + '.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
			WHERE [PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
				AND [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
				AND [PS].[CUSTOMER_ROLE_TYPE] IN (2, 3)  /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник 3 - Законен представител, ... */
		)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with valid IDENTITY DOCUMENTS */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]

	SET @Sql =
	N'
		DECLARE @DateAcc date = ' + @AccountDateChar + '
		
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
		SELECT	[C].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [C] WITH(NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM ' + @SqlFullDBName + '.dbo.[DT015_IDENTITY_DOCUMENTS] [D] WITH(NOLOCK)
			WHERE	[D].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
				AND [D].[NM405_DOCUMENT_TYPE] IN (1, 7, 8)  /* 1 - Лична карта 7 - Паспорт 8 - Шофьорска книжка */
				AND ( [D].[INDEFINITELY] = 1 OR [D].[EXPIRY_DATE] > @DateAcc )
				AND [D].[ISSUER_COUNTRY_CODE] > 0
				AND [D].[ISSUE_DATE] > ''1970-12-31''
				AND len([D].[ISSUER_NAME]) > 0
		)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with Active Loas */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS]

	SELECT @Sql =
	N'
		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS]	
		SELECT [CUST].[CUSTOMER_ID]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [CUST] WITH(NOLOCK)
		WHERE EXISTS 
		(
			SELECT *
			FROM ' + @SqlFullDBName + '.dbo.[KRDREG] [L] WITH(NOLOCK)
			INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015] [CC] WITH(NOLOCK)
				ON [L].[CLIENT_CODE] =  [CC].[CODE]
			WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
				AND [L].[DATE_END_KREDIT] < 2 /* Is active loan */
		)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with Distraint */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT]

	INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] ([CUSTOMER_ID])
	EXEC @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName
		, @OnlineSqlDataBaseName

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Customers with Uncollected tax connected to all customer accounts */

	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]

	INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] ([CUSTOMER_ID])
	EXEC @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName
		, @OnlineSqlDataBaseName

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Update customers */

	UPDATE [D]
	SET [HAS_MANY_CLIENT_CODES] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_MULTIPLE_CLIENT_CODES] [S] WITH (NOLOCK) ON [S].CUSTOMER_ID = [D].CUSTOMER_ID

	UPDATE [D]
	SET [HAS_DUBL_CLIENT_IDS] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN] [S] WITH (NOLOCK) ON [S].CUSTOMER_ID = [D].CUSTOMER_ID

	UPDATE [D]
	SET [IS_ORIGINAL_EGFN] = 0
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DUPLICATED_EGFN] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
		AND [S].[IS_ORIGINAL_EGFN] = 0

	UPDATE [D]
	SET [HAS_LOAN] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_LOANS] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [IS_PROXY] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_PROXIES] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [HAS_VALID_DOCUMENT] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [HAS_ZAPOR] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_DISTRAINT] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	UPDATE [D]
	SET [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC] = 1
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] [S] WITH (NOLOCK) ON [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: update bits in [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS]'
			, @Sql = ' update [AGR_TA_EXISTING_ONLINE_DATA_CUSTOMERS] SET ...'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Log END procedure */

	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', AccData: ' + @AccountDateChar + ', @OnlineSqlServerName = ' + @OnlineSqlServerName + ', @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_CUSTOMERS]'
	END

	RETURN 0
END
GO

/********************************************************************************************************/
/* Процедура за първоначална инициализация на сделки */
DROP TABLE IF EXISTS dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
GO

CREATE OR ALTER PROCEDURE dbo.SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS
(
	@DB_TYPE SYSNAME = N'AIR'
	, @TestAutomationType SYSNAME = N'%AIR%'
	, @OnlineSqlServerName SYSNAME = ''
	, @OnlineSqlDataBaseName SYSNAME = ''
	, @AccountDateChar VARCHAR(32)
	, @LogTraceInfo INT = 1
)
AS
BEGIN
	DECLARE @Sql VARCHAR(max) = N''
		, @Msg NVARCHAR(max) = N''
		, @LogBegEndProc INT = 1
		, @Rows INT = 0
		, @Err INT = 0
		, @Ret INT = 0
		, @TimeBeg DATETIME = GetDate()

	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Sql = 'dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS] @DB_TYPE = ' + @DB_TYPE + N' , @@TestAutomationType = ' + @TestAutomationType + N' , @OnlineSqlServerName = ' + @OnlineSqlServerName + N' , @OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName
			, @Msg = '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS]'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Format full Online DB name */

	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName), 1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName), 1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	DECLARE @SqlFullDBName SYSNAME = @OnlineSqlServerName + '.' + @OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* Prepare BASE conditions */
	
	DROP TABLE IF EXISTS #CSTEMP_TA_DEAL_FILTERS
	
	SELECT
		ROW_ID AS PREV_ROW_ID
		, TA_TYPE AS PREV_TA_TYPE
		, SECTOR AS CUST_CND_SECTOR
		, UI_STD_DOG_CODE AS DEAL_CND_UI_STD_DOG_CODE
		, UI_CURRENCY_CODE AS DEAL_CND_UI_CURRENCY_CODE
		, UI_INDIVIDUAL_DEAL AS UI_INDIVIDUAL_DEAL
	INTO #CSTEMP_TA_DEAL_FILTERS
	FROM VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS WITH(NOLOCK)
	WHERE DB_TYPE = 'AIR'
		AND TA_TYPE LIKE '%AIR%'
	ORDER BY ROW_ID

	SELECT @Rows = @@ROWCOUNT
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: INSERT INTO #CSTEMP_TA_DEAL_FILTERS, Rows Affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestAutomationType
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare deals */

	DROP TABLE IF EXISTS dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
	SET @Sql =
	N'
		DECLARE @DealType int = 1
			,	@DateAcc date = ' + @AccountDateChar + '
		
		DECLARE @StsDeleted						int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
			,	@StsCloased						int	= dbo.SETBIT(cast(0 as binary(4)),  9, 1)
			,	@StsHasIndividualSpecCondPkgs	int = dbo.SETBIT(cast(0 as binary(4)),  5, 1)	/* STS_INDIVIDUAL_SPEC_COND_PKGS (5) */
			,	@StsExcludeFromBankCollection   int = dbo.SETBIT(cast(0 as binary(4)),  8, 1)	/* STS_EXCLUDE_FROM_BANK_COLLECTIONS (8) */
			,	@StsHasOtherTaxAcc				int	= dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* CMN_OTHER_ACCOUNT_FOR_TAX (14) */
			,	@StsIsIndividual				int	= dbo.SETBIT(cast(0 as binary(4)), 16, 1)	/* SD_INDIVIDUAL_DEAL (16) */
			,	@StsNoAutoPayTax				int	= dbo.SETBIT(cast(0 as binary(4)), 29, 1)	/* CMN_NOAUTOTAX (29) */
		
		DECLARE @StsExtJointDeal				int = dbo.SETBIT(cast(0 as binary(4)),  4, 1)	/* STS_EXT_JOINT_DEAL (4) */
			,	@StsExtCapitOnBaseDateOpen		int = dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* STS_EXT_CAPIT_ON_BASE_DATE_OPEN (14) */
			,	@StsExtDenyManualTaxAssign		int = dbo.SETBIT(cast(0 as binary(4)), 20, 1)	/* STS_EXT_DENY_MANUAL_TAX_ASSIGN (20)*/
				/* [BLOCKSUM] */
		
		WITH [X] AS 
		(
			SELECT	[CUST_CND_SECTOR]
				,	[DEAL_CND_UI_CURRENCY_CODE]
				,	count(*) AS CNT
			FROM #CSTEMP_TA_DEAL_FILTERS WITH(NOLOCK)
			GROUP BY [CUST_CND_SECTOR], [DEAL_CND_UI_CURRENCY_CODE]
		)
		SELECT /* Deal info: */
			IDENTITY(INT, 1, 1) AS [ROW_ID]
			, 1 AS [DEAL_TYPE]
			, [REG].[DEAL_NUM] AS [DEAL_NUM]
			, [EXT].[ACCOUNT] AS [DEAL_ACCOUNT]
			, [REG].[CURRENCY_CODE] AS [DEAL_CURRENCY_CODE]
			, [REG].[STD_DOG_CODE] AS [DEAL_STD_DOG_CODE]
			, [REG].[INT_COND_STDCONTRACT] AS [INT_COND_STDCONTRACT]
			, [REG].[NM245_CODE] AS [DEAL_NM245_GROUP_PROGRAM_TYPE_CODE]
			, [REG].[NM342_CODE] AS [DEAL_NM342_BUNDLE_PRODUCT_CODE]
			, [REG].[JOINT_ACCESS_TO_FUNDS_TYPE] AS [DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] /* enum JointDealsAccessToFundsType: 0 - Separate 1 - Always Together */
			, [BAL].[BEG_SALDO] AS [ACCOUNT_BEG_DAY_BALANCE] /* Begin day saldo  */
			, [ACC].[BLK_SUMA_MIN] AS [BLK_SUMA_MIN] /* Block amount for deal */
			, [BAL].[DAY_SALDO] AS [DAY_OPERATION_BALANCE] /* Day operation balance */
			/* Client info: */
			, [REG].[KL_SECTOR] AS [CLIENT_SECTOR]
			, [REG].[CLIENT_CODE] AS [CLIENT_CODE]
			, [CLC].[CUSTOMER_ID] AS [CUSTOMER_ID]
			/* Bits from [STATUS]: */
			, [STS].[IS_ACTIVE_DEAL] AS [DEAL_IS_ACTIVE_DEAL]
			, [STS].[IS_INDIVIDUAL_COND_PKGS] AS [DEAL_IS_INDIVIDUAL_COND_PKGS]
			, [STS].[EXCLUDE_FROM_BANK_COLLECTIONS] AS [DEAL_EXCLUDE_FROM_BANK_COLLECTIONS]
			, [STS].[IS_INDIVIDUAL_DEAL] AS [DEAL_IS_INDIVIDUAL_DEAL]
			, [STS].[HAS_OTHER_TAX_ACC] AS [DEAL_HAS_OTHER_TAX_ACC]
			, [STS].[NO_AUTO_PAY_TAX] AS [DEAL_NO_AUTO_PAY_TAX]
			/* Bits from [STATUS_EXT]: */
			, [STS].[IS_JOINT_DEAL] AS [DEAL_IS_JOINT_DEAL]
			, [STS].[CAPIT_ON_BASE_DATE_OPEN] AS [DEAL_CAPIT_ON_BASE_DATE_OPEN]
			, [STS].[IS_DENY_MANUAL_TAX_ASSIGN] AS [DEAL_IS_DENY_MANUAL_TAX_ASSIGN]
			/* Additional flags */
			, [EXT].[IS_INDIVIDUAL_COMB] AS [DEAL_IS_INDIVIDUAL_COMBINATION]
			, [EX_BITS].*
			, CAST(0 AS SMALLINT) AS [PROXY_COUNT]
		INTO dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS
		FROM ' + @SqlFullDBName + '.dbo.[RAZPREG] [REG] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT015] [CLC] WITH (NOLOCK)
			ON [CLC].[CODE] = [REG].[CLIENT_CODE]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DT008] [CCY] WITH (NOLOCK)
			ON [CCY].[CODE] = [REG].[CURRENCY_CODE]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[PARTS] [ACC] WITH (NOLOCK)
			ON [ACC].[PART_ID] = [REG].[ACCOUNT]
		LEFT JOIN ' + @SqlFullDBName + '.dbo.[DAY_MOVEMENTS] [DM] WITH (NOLOCK)
			ON [DM].[IDENT] = [ACC].[PART_ID]
		LEFT JOIN ' + @SqlFullDBName + '.dbo.[FUTURE_MOVEMENTS] [FM] WITH (NOLOCK)
			ON [FM].[IDENT] = [ACC].[PART_ID]
		INNER JOIN [X]
			ON [X].[CUST_CND_SECTOR] = [REG].[KL_SECTOR]
				AND [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
		CROSS APPLY (
			SELECT CAST(@DealType AS TINYINT) AS [DEAL_TYPE]
				, CAST([REG].[ACCOUNT] AS VARCHAR(33)) AS [ACCOUNT]
				/* Additional flags: */
				, CAST([REG].INDIVIDUAL_COMBINATION_FLAG AS BIT) AS [IS_INDIVIDUAL_COMB]
				, CAST([REG].INDIVIDUAL_PROGRAM_GS_FLAG AS BIT) AS [IS_INDIVIDUAL_PROG]
			) [EXT]
		CROSS APPLY (
			SELECT CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT]
					END AS [BEG_SALDO]
				, CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0) - (IsNull(- [DM].[VNR_DBT], 0) + IsNull(- [FM].[VNR_DBT], 0) + IsNull([DM].[VNB_KRT], 0) + IsNull([FM].[VNB_KRT], 0))
					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0) - (IsNull(- [DM].[VNR_KRT], 0) + IsNull(- [FM].[VNR_KRT], 0) + IsNull([DM].[VNB_DBT], 0) + IsNull([FM].[VNB_DBT], 0))
					END AS [DAY_SALDO]
			) [BAL]
		CROSS APPLY (
			SELECT CAST(0 AS BIT) AS [DEAL_IS_USED]
				, CAST(0 AS BIT) AS [HAS_TAX_UNCOLECTED]
				, CAST(0 AS BIT) AS [HAS_OTHER_TAX_ACCOUNT]
				, CAST(0 AS BIT) AS [HAS_LEGAL_REPRESENTATIVE]
				, CAST(0 AS BIT) AS [HAS_PROXY]
				, CAST(0 AS BIT) AS [HAS_DISTRAINT]
				, CAST(0 AS BIT) AS [HAS_GS_INDIVIDUAL_PROGRAMME]
				, CAST(0 AS BIT) AS [HAS_WNOS_BEL]
				, CAST(0 AS BIT) AS [HAS_NAR_RAZP]
				, CAST(0 AS BIT) AS [IS_DORMUNT_ACCOUNT]
			) [EX_BITS]
		CROSS APPLY (
			SELECT /* Bits from [STATUS]: */
				CAST(CASE 
						WHEN ([REG].[STATUS] & @StsCloased) <> @StsCloased
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_ACTIVE_DEAL]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsHasIndividualSpecCondPkgs) = @StsHasIndividualSpecCondPkgs
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_INDIVIDUAL_COND_PKGS]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsExcludeFromBankCollection) = @StsExcludeFromBankCollection
							THEN 1
						ELSE 0
						END AS BIT) AS [EXCLUDE_FROM_BANK_COLLECTIONS]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsHasOtherTaxAcc) = @StsHasOtherTaxAcc
							THEN 1
						ELSE 0
						END AS BIT) AS [HAS_OTHER_TAX_ACC]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsIsIndividual) = @StsIsIndividual
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_INDIVIDUAL_DEAL]
				, CAST(CASE 
						WHEN ([REG].[STATUS] & @StsNoAutoPayTax) = @StsNoAutoPayTax
							THEN 1
						ELSE 0
						END AS BIT) AS [NO_AUTO_PAY_TAX]
				/* Bits from [STATUS_EXT]: */
				, CAST(CASE 
						WHEN ([REG].[STATUS_EXT] & @StsExtJointDeal) = @StsExtJointDeal
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_JOINT_DEAL]
				, CAST(CASE 
						WHEN ([REG].[STATUS_EXT] & @StsExtCapitOnBaseDateOpen) = @StsExtCapitOnBaseDateOpen
							THEN 1
						ELSE 0
						END AS BIT) AS [CAPIT_ON_BASE_DATE_OPEN]
				, CAST(CASE 
						WHEN ([REG].[STATUS_EXT] & @StsExtDenyManualTaxAssign) = @StsExtDenyManualTaxAssign
							THEN 1
						ELSE 0
						END AS BIT) AS [IS_DENY_MANUAL_TAX_ASSIGN]
			) [STS]
		WHERE ([REG].[STATUS] & @StsDeleted) <> @StsDeleted
			AND ([REG].[STATUS] & @StsCloased) <> @StsCloased
	'
	
	BEGIN TRY
		EXECUTE (@Sql)
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 1
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: SELECT * INTO dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS, Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Add Indexes on dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS */
	ALTER TABLE dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS ADD CONSTRAINT [PK_AGR_TA_EXISTING_ONLINE_DATA_DEALS] PRIMARY KEY CLUSTERED ([ROW_ID])

	CREATE INDEX IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_NUM_DEAL_TYPE ON dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS (
		[DEAL_NUM]
		, [DEAL_TYPE]
		)

	CREATE INDEX IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_ACCOUNT ON dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS ([DEAL_ACCOUNT])

	/************************************************************************************************************/
	/* Prepare TAX UNCOLECTED  */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @TaxActive INT = 0 /* enum eTaxUncollectedStatus: eTaxActive = 1*/

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM DBO.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[TAX_UNCOLLECTED] [T] WITH (NOLOCK)
				WHERE [T].[DEAL_TYPE] = @DealType
					AND [T].[DEAL_NUM] = [REG].[DEAL_NUM]
					AND [T].[TAX_STATUS] = @TaxActive
				)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with Other Tax Account */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @CorreCapitAccount INT = 1 /* eCapitAccount (1) */
			, @CorrTaxServices INT = 3 /* eTaxServices (3) */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
			, [C].[CORR_ACCOUNT]
			, [ACC].[PART_CURRENCY]
			, [BAL].[ACCOUNT_BEG_DAY_BALANCE]
			, [ACC].[BLK_SUMA_MIN]
			, [BAL].[DAY_SALDO] AS [DAY_OPERATION_BALANCE] /* Day operation balance */
		FROM DBO.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[DEALS_CORR] [C] WITH (NOLOCK)
			ON [C].[CORR_TYPE] = @CorrTaxServices
				AND [C].[DEAL_TYPE] = @DealType
				AND [C].[DEAL_NUMBER] = [REG].[DEAL_NUM]
		INNER JOIN ' + @SqlFullDBName + '.dbo.[PARTS] [ACC] WITH (NOLOCK)
			ON [ACC].[PART_ID] = [C].[CORR_ACCOUNT]
		LEFT JOIN ' + @SqlFullDBName + '.dbo.[DAY_MOVEMENTS] [DM] WITH (NOLOCK)
			ON [DM].[IDENT] = [ACC].[PART_ID]
		LEFT JOIN ' + @SqlFullDBName + 
					'.dbo.[FUTURE_MOVEMENTS] [FM] WITH (NOLOCK)
			ON [FM].[IDENT] = [ACC].[PART_ID]
		CROSS APPLY (
			SELECT CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT]
					END AS [ACCOUNT_BEG_DAY_BALANCE]
				, CASE 
					WHEN [ACC].[PART_TYPE] IN (
							1
							, 2
							, 5
							)
						THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0) - (IsNull(- [DM].[VNR_DBT], 0) + IsNull(- [FM].[VNR_DBT], 0) + IsNull([DM].[VNB_KRT], 0) + IsNull([FM].[VNB_KRT], 0))
					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0) - (IsNull(- [DM].[VNR_KRT], 0) + IsNull(- [FM].[VNR_KRT], 0) + IsNull([DM].[VNB_DBT], 0) + IsNull([FM].[VNB_DBT], 0))
					END AS [DAY_SALDO]
			) [BAL]
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with Group Sales INDIVIDUAL PROGRAMME */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @GSActive INT = 1 /* enum eGS_STATUS: GSActive = 1 */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
			, [GSI].[PROGRAMME_CODE] AS [DEAL_GS_INDIVIDUAL_PROGRAM_CODE]
			, [GSI].[PRODUCT_CODE] AS [DEAL_GS_INDIVIDUAL_PRODUCT_CODE]
			, [GSI].[CARD_PRODUCT] AS [DEAL_GS_INDIVIDUAL_CARD_PRODUCT]
		FROM DBO.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + '.dbo.[GS_INDIVIDUAL_PROGRAMME] [GSI] WITH (NOLOCK)
			ON [GSI].[DEAL_TYPE] = @DealType
				AND [GSI].[DEAL_NUMBER] = [REG].[DEAL_NUM]
				AND [GSI].[ACTIVITY_STATUS] = @GSActive
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with WNOS BEL*/
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @CurrDate DATE = GetDate()
			, @StsDeleted INT = dbo.SETBIT(cast(0 AS BINARY (4)), 0, 1)
			, @REG_VNOS_BEL_BIS6 INT = 63 /* #define REG_VNOS_BEL_BIS6 63 */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL] (
			[DEAL_TYPE]
			, [DEAL_NUM]
			)
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[TRAITEMS_DAY] [T] WITH (NOLOCK)
				WHERE [T].[DEAL_NUM] = [REG].[DEAL_NUM]
					AND [T].[DEAL_TYPE] = @DealType
					AND [T].[SUM_OPER] > 0
					AND [T].[SYS_DATE] >= @CurrDate
					AND [T].[REG_CODE_DEF] = @REG_VNOS_BEL_BIS6
					AND ([T].[STATUS] & @StsDeleted) <> @StsDeleted
				)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with Distraint */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT]

	SELECT @Sql =
	N'
		DECLARE @StsDeleted INT = dbo.SETBIT(cast(0 AS BINARY (4)), 0, 1)
			, @StsBlockReasonDistraint INT = dbo.SETBIT(cast(0 AS BINARY (4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/
		DECLARE @Tbl_Distraint_Codes TABLE ([CODE] INT)

		INSERT INTO @Tbl_Distraint_Codes
		SELECT [n].[CODE]
		FROM ' + @SqlFullDBName + '.dbo.[NOMS] [n] WITH (NOLOCK)
		WHERE [n].[NOMID] = 136
			AND ([n].[sTATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT TOP (1) *
				FROM ' + @SqlFullDBName + '.dbo.BLOCKSUM [B] WITH (NOLOCK)
				INNER JOIN @Tbl_Distraint_Codes [N]
					ON [N].[CODE] = [B].[WHYFREEZED]
				WHERE [B].[PARTIDA] = [REG].[DEAL_ACCOUNT]
					AND [B].[SUMA] > 0.01
					AND [B].[CLOSED_FROZEN_SUM] = 0
				)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with DORMUNT ACCOUNT */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @StsPART_IsSleepy INT = dbo.SETBIT(cast(0 AS BINARY (4)), 22, 1) /* #define PART_IsSleepy (22) // Партидата е спяща(замразена) */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT]
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT TOP (1) *
				FROM ' + @SqlFullDBName + '.dbo.[PARTS] [P] WITH (NOLOCK)
				WHERE [P].[PART_ID] = [REG].[DEAL_ACCOUNT]
					AND ([P].[STATUS] & @StsPART_IsSleepy) = @StsPART_IsSleepy
				)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deals Legal representative */
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1 /* Razp deals */
			, @StsDeActivated INT = dbo.SETBIT(cast(0 AS BINARY (4)), 12, 1) /* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE]
		SELECT [D].[DEAL_TYPE]
			, [D].[DEAL_NUM]
			, [CRL].[REPRESENTED_CUSTOMER_ID]
			, [CRL].[REPRESENTATIVE_CUSTOMER_ID]
			, [CRL].[CUSTOMER_ROLE_TYPE]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + 
					'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH (NOLOCK)
			ON [CRL].[DEAL_TYPE] = @DealType
				AND [CRL].[DEAL_NUM] = [D].[DEAL_NUM]
				AND [CRL].[CHANNEL] = 1 /* NM455 (Chanels) : 1 Основна банкова система, ... */
				AND [CRL].[CUSTOMER_ROLE_TYPE] IN (1) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник 3 - Законен представител ... */
				AND [CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
		WHERE ([CRL].[STATUS] & @StsDeActivated) <> @StsDeActivated /* STS_LIMIT_DEACTIVATED 12 (Деактивиран) */
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deals Active Proxy Customers */
	DROP TABLE IF EXISTS dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS]
	SELECT @Sql =
	N' 
		DECLARE @DealType INT = 1 /* Razp deals 1 */
			, @DateAcc DATE = ' + @AccountDateChar + '
			, @StsDeActivated INT = dbo.SETBIT(cast(0 AS BINARY (4)), 12, 1) /* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */

		SELECT [D].[DEAL_TYPE]
			, [D].[DEAL_NUM]
			, [CRL].[REPRESENTATIVE_CUSTOMER_ID]
			, [CRL].[CUSTOMER_ROLE_TYPE]
		INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D] WITH (NOLOCK)
		INNER JOIN ' + @SqlFullDBName + 
						'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] WITH (NOLOCK)
			ON [CRL].[DEAL_TYPE] = @DealType
				AND [CRL].[DEAL_NUM] = [D].[DEAL_NUM]
				AND [CRL].[CHANNEL] = 1 /* NM455 (Chanels) : 1 Основна банкова система, ... */
				AND [CRL].[CUSTOMER_ROLE_TYPE] IN (
					2
					, 3
					) /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник 3 - Законен представител, ... */
				AND [CRL].[CUSTOMER_ACCESS_RIGHT] = 1 /* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
		WHERE ([CRL].[STATUS] & @StsDeActivated) <> @StsDeActivated
			AND EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[PROXY_SPEC] [PS] WITH (NOLOCK)
				INNER JOIN ' + @SqlFullDBName + 
						'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH (NOLOCK)
					ON [D].[PROXY_SPEC_ID] = [PS].[ID]
				WHERE [PS].[REPRESENTED_CUSTOMER_ID] = [CRL].REPRESENTED_CUSTOMER_ID
					AND [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
					AND [PS].[CUSTOMER_ROLE_TYPE] = [CRL].[CUSTOMER_ROLE_TYPE]
					AND (
						[D].[INDEFINITELY] = 1
						OR [D].[VALIDITY_DATE] > @DateAcc
						)
				)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 4
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Prepare Deal with NAR RAZP*/
	TRUNCATE TABLE dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP]

	SELECT @Sql =
	N'
		DECLARE @DealType INT = 1
			, @CurrDate DATE = GetDate()
			, @StsDeleted INT = dbo.SETBIT(cast(0 AS BINARY (4)), 0, 1)
			, @REG_NAR_RAZSP_BIS6 INT = 63 /* #define REG_NAR_RAZSP_BIS6 64 */

		INSERT INTO dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP] (
			[DEAL_TYPE]
			, [DEAL_NUM]
			)
		SELECT [REG].[DEAL_TYPE]
			, [REG].[DEAL_NUM]
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [REG] WITH (NOLOCK)
		WHERE EXISTS (
				SELECT *
				FROM ' + @SqlFullDBName + '.dbo.[TRAITEMS_DAY] [T] WITH (NOLOCK)
				WHERE [T].[DEAL_NUM] = [REG].[DEAL_NUM]
					AND [T].[DEAL_TYPE] = @DealType
					AND [T].[SUM_OPER] > 0
					AND [T].[SYS_DATE] >= @CurrDate
					AND [T].[REG_CODE_DEF] = @REG_NAR_RAZSP_BIS6
					AND ([T].[STATUS] & @StsDeleted) <> @StsDeleted
				)
	'

	BEGIN TRY
		EXEC sp_executesql @Sql
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2
	END CATCH

	SELECT @Rows = (
			SELECT count(*)
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP] WITH (NOLOCK)
			)
		, @Err = @@ERROR

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Rows = IsNull(@Rows, 0)

		SELECT @Msg = N'After: select * into dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP], Rows affected: ' + str(@Rows, len(@Rows), 0)

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* update deals */
	UPDATE [D]
	SET [HAS_TAX_UNCOLECTED] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_TAX_UNCOLECTED] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_OTHER_TAX_ACCOUNT] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_OTHER_TAX_ACCOUNT] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_LEGAL_REPRESENTATIVE] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_LEGAL_REPRESENTATIVE] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_PROXY] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_DISTRAINT] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DISTRAINT] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_GS_INDIVIDUAL_PROGRAMME] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_WNOS_BEL] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_WNOS_BEL] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [HAS_NAR_RAZP] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_NAR_RAZP] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [IS_DORMUNT_ACCOUNT] = 1
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_WITH_DORMUNT_ACCOUNT] [S] WITH (NOLOCK) ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [S].[DEAL_TYPE] = 1

	UPDATE [D]
	SET [PROXY_COUNT] = [S].[CNT]
	FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
	INNER JOIN (
		SELECT [P].[DEAL_NUM]
			, COUNT(*) AS [CNT]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] [P] WITH (NOLOCK)
		WHERE [P].[DEAL_TYPE] = 1
		GROUP BY [P].[DEAL_NUM]
		) [S] ON [S].[DEAL_NUM] = [D].[DEAL_NUM]
		AND [D].[DEAL_TYPE] = 1
		

	/************************************************************************************************************/
	/* Indexes */

	CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_CURRENCY_CODE_DEAL_STD_DOG_CODE_CLIENT_SECTOR_DEAL_IS_JOINT_DEAL]
		ON [dbo].AGR_TA_EXISTING_ONLINE_DATA_DEALS ([DEAL_CURRENCY_CODE] ASC, [DEAL_STD_DOG_CODE] ASC, [CLIENT_SECTOR] ASC, [DEAL_IS_JOINT_DEAL] ASC, [HAS_WNOS_BEL] ASC, [IS_DORMUNT_ACCOUNT] ASC)
		INCLUDE ([DEAL_TYPE], [DEAL_NUM], [DEAL_ACCOUNT], [CUSTOMER_ID])

	CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_DEAL_CURRENCY_CODE_CUSTOMER_ID_DEAL_NUM]
		ON [dbo].AGR_TA_EXISTING_ONLINE_DATA_DEALS ([DEAL_CURRENCY_CODE], [CUSTOMER_ID], [DEAL_NUM])

	CREATE NONCLUSTERED INDEX [IX_AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS_DEAL_TYPE_DEAL_NUM_CUSTOMER_ROLE_TYPE]
		ON [dbo].[AGR_TA_EXISTING_ONLINE_DATA_DEALS_ACTIVE_PROXY_CUSTOMERS] ([DEAL_TYPE], [DEAL_NUM], [CUSTOMER_ROLE_TYPE]) INCLUDE ([REPRESENTATIVE_CUSTOMER_ID])

	IF @LogTraceInfo = 1
	BEGIN
		SELECT @Msg = N'After: update bist in AGR_TA_EXISTING_ONLINE_DATA_DEALS'
			, @Sql = N' update AGR_TA_EXISTING_ONLINE_DATA_DEALS set [HAS_VALID_DOCUMENT] = 1 where ...'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* Log end procedure: */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', AccData: ' + @AccountDateChar + ', Fileter: ' + @TestAutomationType

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_INIT_DEALS'
	END

	RETURN 0
END
GO

/********************************************************************************************************/
/* Процедура за определяне на критериите който ни пречат да намерим подходяща сделка за датен TestCase */
CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_TEST_PROCEDURES_FIND_SUITABLE_DEAL]
(
	@TestCaseRowID NVARCHAR(16)
	, @CurrAccDate DATETIME
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 1
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate()
	DECLARE @Msg NVARCHAR(max) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Sql NVARCHAR(4000) = N''

	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_TEST_PROCEDURES_FIND_SUITABLE_DEAL]'

	/************************************************************************************************************/
	/* @TODO: */
	/**********************************************************************************/
	DROP TABLE IF EXISTS dbo.[#TBL_RESULT]
	CREATE TABLE dbo.[#TBL_RESULT]
	(
		[TEST_ID] NVARCHAR(512)
		, [DEAL_TYPE] SMALLINT
		, [DEAL_NUM] INT
		, [CUSTOMER_ID] INT
		, [REPRESENTATIVE_CUSTOMER_ID] INT
		, [DEAL_TYPE_BEN] SMALLINT
		, [DEAL_NUM_BEN] INT
	)

	DECLARE @CondCount INT = 0
		, @FistCondRowID INT = 0
		, @ScipCondIndex INT = 4
		, @ScipTblRowId INT = 0

	SELECT @CondCount = count(*)
		, @FistCondRowID = min([ID])
	FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
	WHERE [TEST_ID] = @TestCaseRowID

	WHILE @Rows = 0
		AND @ScipCondIndex < @CondCount
	BEGIN
		TRUNCATE TABLE dbo.[#TBL_RESULT]

		SELECT @Sql = N''
			, @Rows = 0
			, @ScipTblRowId = @FistCondRowID + @ScipCondIndex

		-- Prepare Sql to execute: 
		SELECT @Sql += [CND].[COUND]
		FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
		CROSS APPLY (
			SELECT CASE 
					WHEN [ID] = @ScipTblRowId
						THEN ''
					ELSE [SQL_COND]
					END AS [COUND]
			) [CND]
		WHERE [TEST_ID] = @TestCaseRowID
		ORDER BY [ID]

		-- Execute Sql:
		BEGIN TRY
			INSERT INTO dbo.[#TBL_RESULT]
			EXEC sp_executesql @Sql
		END TRY

		BEGIN CATCH
			SELECT @Msg = 'Error execute Sql:' + dbo.FN_GET_EXCEPTION_INFO()
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
			WHERE [ID] = @ScipTblRowId

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg
		END CATCH

		SELECT @Rows = count(*)
		FROM dbo.[#TBL_RESULT] WITH (NOLOCK)

		-- Test Result:
		IF @Rows > 0
		BEGIN
			SELECT @Msg = 'Test Case ID:' + [TEST_ID] + ' Found records: ' + str(@Rows, 3, 0) + ' Skiped condition info: "' + [DESCR] + '" Skiped SQL condition: "' + [SQL_COND] + '"'
			FROM dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS] WITH (NOLOCK)
			WHERE [id] = @ScipTblRowId

			EXEC dbo.SP_SYS_LOG_PROC @@PROCID
				, @Sql
				, @Msg
		END

		SET @ScipCondIndex += 1
	END

	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', TA Row ID: ' + @TestCaseRowID + ' Found Records: ' + str(@Rows, 2, 0) + '.'

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_TEST_PROCEDURES_FIND_SUITABLE_DEAL]'
	END

	RETURN 0
END
GO

/********************************************************************************************************/
/* Процедура за актуализация на дневните салда в TA базата, след обработка на тестови случай */
DROP PROCEDURE IF EXISTS dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE]
GO

CREATE PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE]
(
	@TestCaseRowID  int
,   @UpdateMode     int = 1
)
AS 
begin

	declare @LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Sql nvarchar(4000) = N'', @Ret int = 0
        ,	@RowIdStr nvarchar(8) = STR(@TestCaseRowID,LEN(@TestCaseRowID),0)
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql = 'dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE] @RowIdStr = '+@RowIdStr
					+', @UpdateMode = '+str(@UpdateMode, len(@UpdateMode),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	/************************************************************************************************************/
	/* 2. Find TA Conditions: */
	if not exists (select * from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1))
	begin 
		select  @Msg = N'Error not found condition with [ROW_ID] :' + @RowIdStr
			,	@Sql = N'select * from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock) where [ROW_ID] = IsNull('+@RowIdStr+', -1)'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -1;
	end
	
    declare @DB_TYPE         varchar(256) = N''
        ,   @DEAL_ROW_ID     int = -1 /* Main accoutn row id */
        ,   @CORS_ROW_ID     int = -1 /* Tax accoutn row id */
        ,   @DEAL_BEN_ROW_ID int = -1 /* Ben accoutn row id */
    ;
	select	@DB_TYPE            = [DB_TYPE]
        ,   @DEAL_ROW_ID        = IsNull([DEAL_ROW_ID], -1)
		,	@CORS_ROW_ID        = IsNull([CORS_ROW_ID], -1)
        ,   @DEAL_BEN_ROW_ID    = IsNull([DEAL_BEN_ROW_ID],-1)
	from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1)
	;

	/************************************************************************************************************/
	/* 3. Get Datasources: */
	declare @OnlineSqlServerName sysname = N'',	@OnlineSqlDataBaseName sysname = N'', @DB_ALIAS sysname = N'VCS_OnlineDB'
	;
	exec @Ret = dbo.[SP_TA_GET_DATASOURCE] @DB_TYPE, @DB_ALIAS, @OnlineSqlServerName out, @OnlineSqlDataBaseName out
	if @Ret <> 0
	begin
		select  @Msg = N'Error execute proc, Error code: '+str(@Ret,len(@Ret),0)
					+' ; Result: @OnlineSqlServerName = "'+@OnlineSqlServerName+'", @OnlineSqlDataBaseName = "'+@OnlineSqlDataBaseName+'"'
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -2;
	end

	/************************************************************************************************************/
	/* 4. Load Accounts from test cases and Update day operation balance : */
	create table #TBL_RESULT
	(
		[ACCOUNT]		varchar(64)
	,	[PART_TYPE]		int
	,	[DAY_SALDO]		float
    );

    declare @Row_id     int = -1
        ,   @Deal_Type  int = 1
        ,   @Deal_Num   int = -1
        ,   @Account    varchar(64) = N''
        ,   @Acc_Type   int = 3 /* Pasive */
        ,   @UpdAccont  int = IsNull(@UpdateMode,0);
    ;

    /******************************************************************/
    /* 4.1. Main Account: */
    if IsNull(@DEAL_ROW_ID,-1) > 0 
    begin 
		begin try
			exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @OnlineSqlServerName 
				, @OnlineSqlDataBaseName, @TestCaseRowID, @DEAL_ROW_ID, N'RAZPREG_TA', @UpdAccont
		end try
		begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, 'dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @MainAccount', @Msg
		    return 1;
		end catch
    end

    /******************************************************************/
    /* 4.2. Ben Account: */    
    if IsNull(@DEAL_BEN_ROW_ID,-1) > 0 and (IsNull(@DEAL_ROW_ID,-1) != IsNull(@DEAL_BEN_ROW_ID,-2))
    begin 
		begin try
			exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @OnlineSqlServerName 
				, @OnlineSqlDataBaseName, @TestCaseRowID, @DEAL_BEN_ROW_ID, N'RAZPREG_TA', @UpdAccont
		end try
		begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, 'dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @BenAccount', @Msg
		    return 2;
		end catch
    end

    /******************************************************************/
    /* 4.3. Corespondent Account: */
    if IsNull(@CORS_ROW_ID,-1) > 0
    begin 
		begin try
			exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @OnlineSqlServerName 
				, @OnlineSqlDataBaseName, @TestCaseRowID, @CORS_ROW_ID, N'DEALS_CORR_TA', @UpdAccont
		end try
		begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, 'dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @CorespondentAccount', @Msg
		    return 3;
		end catch
    end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + '; TA Row ID: ' + @RowIdStr;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE]'
	end

    return 0;
end    
GO

/********************************************************************************************************/
/* Процедура за актуализация на дневните салда в TA базата, след обработка на тестови случай */
CREATE OR ALTER PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT]
(
	@OnlineSqlServerName SYSNAME
	, @OnlineSqlDataBaseName SYSNAME
	, @TestCaseRowID INT
	, @DEAL_ROW_ID INT
	, @REG_NAME SYSNAME = N''
	, @UPDATE_MODE INT = 1
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 0
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate();;
	DECLARE @Msg NVARCHAR(max) = N''
		, @Sql NVARCHAR(4000) = N''
		, @Ret INT = 0
		, @RowIdStr NVARCHAR(8) = STR(@TestCaseRowID, LEN(@TestCaseRowID), 0);

	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Sql = 'dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT] @OnlineSqlServerName = ''' + @OnlineSqlServerName + '''' + N', @OnlineSqlDataBaseName = ''' + @OnlineSqlDataBaseName + '''' + N', @TestCaseRowID = ' + @RowIdStr + N', @DEAL_ROW_ID = ' + str(@DEAL_ROW_ID, len(@DEAL_ROW_ID), 0) + N', @REG_NAME = ''' + @REG_NAME + '''' + N', @UPDATE_MODE = ' + str(@UPDATE_MODE, len(@UPDATE_MODE), 0)
			, @Msg = '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT]';

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg
	END

	/************************************************************************************************************/
	/* 2. Load Account from ROW_ID */
	DECLARE @Row_id INT = - 1
		, @Deal_Type INT = 1
		, @Deal_Num INT = - 1
		, @Account VARCHAR(64) = N''
		, @Acc_Type INT = 3 /* Pasive */
		, @UpdAccont INT = @UPDATE_MODE
		, @DayAccBal FLOAT = 0.0;;
	DECLARE @OutputUpdateTbl TABLE (
		[ACCOUNT] VARCHAR(64)
		, [DAY_SALDO] FLOAT
		);

	/* 2.1. Find Account by ROW_ID */
	IF IsNull(@DEAL_ROW_ID, - 1) > 0
	BEGIN
		IF @REG_NAME = N'RAZPREG_TA'
		BEGIN
			SELECT @Row_id = [ROW_ID]
				, @Deal_Type = 1
				, @Deal_Num = [UI_DEAL_NUM]
				, @Account = replace([DB_ACCOUNT], ' ', '')
				, @Acc_Type = 3 /* Pasive */
			FROM dbo.[RAZPREG_TA] [REG] WITH (NOLOCK)
			WHERE [REG].[ROW_ID] IN (@DEAL_ROW_ID);
		END
		ELSE IF @REG_NAME = N'DEALS_CORR_TA'
		BEGIN
			SELECT @Row_id = [ROW_ID]
				, @Deal_Type = [UI_DEAL_TYPE]
				, @Deal_Num = [DEAL_NUM]
				, @Account = replace([UI_CORR_ACCOUNT], ' ', '')
				, @Acc_Type = 3 /* Pasive */
			FROM dbo.[DEALS_CORR_TA] [REG] WITH (NOLOCK)
			WHERE [REG].[ROW_ID] IN (@DEAL_ROW_ID);
		END
	END

	IF IsNull(@Row_id, - 1) <= 0
	BEGIN
		SELECT @Msg = 'Can''t find account by ROW_ID: ' + str(@Row_id, len(@Row_id), 0) + ', Register: ' + @REG_NAME + '.'
			, @Sql = 'select  @Account = .. from ' + @REG_NAME + ' where [ROW_ID] IN (' + str(@Row_id, len(@Row_id), 0) + ') '

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg;

		RETURN 1;
	END

	/* 2.2. Get day operation balance from OnlineDb: */
	BEGIN TRY
		INSERT INTO #TBL_RESULT (
			[ACCOUNT]
			, [PART_TYPE]
			, [DAY_SALDO]
			)
		EXEC @Ret = dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName
			, @OnlineSqlDataBaseName
			, @Account
			, @Acc_Type
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO();

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, 'insert into #TBL_RESULT  ... for Main account'
			, @Msg;

		RETURN 2;
	END CATCH

	IF @Ret <> 0
	BEGIN
		SELECT @Sql = 'exec @Ret = Sql: dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] ' + '@OnlineSqlServerName = ' + @OnlineSqlServerName + '@OnlineSqlDataBaseName = ' + @OnlineSqlDataBaseName + '@Account = ' + @Account + '@AccType = ' + str(@Acc_Type, len(@Acc_Type), 0) + '@LogTrace = 1'
			, @Msg = 'Error ' + str(@Ret, len(@Ret), 0) + ' execute sql for test case ID: ' + @RowIdStr + ', Account: ' + @Account + ', @DEAL_ROW_ID = ' + str(@DEAL_ROW_ID, len(@DEAL_ROW_ID), 0);

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql
			, @Msg

		RETURN 2;
	END

	/* 2.3. Update Account day operation balance in table: */
	IF @UpdAccont = 1
		AND EXISTS (
			SELECT *
			FROM #TBL_RESULT
			WHERE [ACCOUNT] = @Account
			)
		UPDATE [D]
		SET [DAY_OPERATION_BALANCE] = [S].[DAY_SALDO]
		OUTPUT [S].[ACCOUNT]
			, INSERTED.[DAY_OPERATION_BALANCE]
		INTO @OutputUpdateTbl
		FROM dbo.AGR_TA_EXISTING_ONLINE_DATA_DEALS [D]
		INNER JOIN #TBL_RESULT [S]
			ON [S].[ACCOUNT] = [D].[DEAL_ACCOUNT];

	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @DayAccBal = [DAY_SALDO]
		FROM #TBL_RESULT
		WHERE [ACCOUNT] = @Account;

		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + '; TA Row ID: ' + @RowIdStr + '; Account: ' + @Account + '; balance: ' + str(@DayAccBal, 12, 2) + '; Upate mode: ' + str(@UpdAccont, len(@UpdAccont), 0);

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_UPDATE_DAY_OPERATIONS_BALANCE_SINGLE_ACCOUNT]'
	END

	RETURN 0;
END
GO

