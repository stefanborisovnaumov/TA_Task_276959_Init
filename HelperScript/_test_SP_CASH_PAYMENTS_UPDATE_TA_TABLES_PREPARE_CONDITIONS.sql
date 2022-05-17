--/*********************************************************************************************************/
---- Get Account date
--select [BPB_VCSBank_Online].dbo.get_cur_date()
--go

--/*********************************************************************************************************/
---- View Test Cases 
--select * from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] order by ROW_ID
--go


/*********************************************************************************************************/
/* 4. Prepare Sql Conditions: */
drop table if EXISTS dbo.[#TBL_SQL_CONDITIONS]
;
create table dbo.[#TBL_SQL_CONDITIONS]
(
	[ID] INT IDENTITY(1,1)
,	[SQL_COND] nvarchar(1000)
,	[DESCR] nvarchar(2000)
,	[IS_BASE_SELECT] BIT DEFAULT(0)
,	[IS_SELECT_COUNT] BIT DEFAULT(0)
)
go


drop table if EXISTS dbo.[#TBL_RESULT]
;
create table dbo.[#TBL_RESULT]
(
	[TEST_ID]		NVARCHAR(512) 
,	[DEAL_TYPE]		SMALLINT
,	[DEAL_NUM]		INT 	
,	[CUSTOMER_ID]	INT
,	[REPRESENTATIVE_CUSTOMER_ID] INT
)
go

truncate table [#TBL_SQL_CONDITIONS]
go
truncate table [#TBL_RESULT]
go
/*****************************************************************/
-- Tes proc: 
declare @CurrAccDate datetime = '2021-10-20'
	,	@TestCase int		  = 400004
;
exec dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS] @TestCase, @CurrAccDate
go

/*****************************************************************/
-- View Result: 
select * from [#TBL_RESULT]
go
select * from [#TBL_SQL_CONDITIONS]
go
