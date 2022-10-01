/*********************************************************************************************************/
/* 1.1. Prepare Result table */
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

/* 1.2. Clear Test Case conditions table */
truncate table [AGR_CASH_PAYMENTS_SQL_CONDITIONS]
go

--truncate table SYS_LOG_PROC
--go

/*********************************************************************************************************/
/* 2. Търсим подходящи сделки за вскички Тестови случай: */

declare	@Curr_Acc_Date datetime = Getdate() /* може да използваме текущата счетоводната дата на системата */
;
declare curTestCase cursor for 
select [ROW_ID], [TA_TYPE]
from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS]
order by [ROW_ID]
;
declare @TA_ID int= 0 , @TA_Type varchar(126) = N'', @Ret int = 0
;
open curTestCase
fetch next from curTestCase into @TA_ID, @TA_Type
;
while @@FETCH_STATUS = 0 
begin

	exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_PREPARE_CONDITIONS]	
		@TestCaseRowID = @TA_ID, @CurrAccDate = @Curr_Acc_Date, @SaveTAConditions = 1

	fetch next from curTestCase into @TA_ID, @TA_Type
	;
	truncate table dbo.[#TBL_RESULT]
	;
end
close curTestCase;
deallocate curTestCase;
go

/*********************************************************************************************************/
/* 3. Тестови случай за който по текущите критерии не са намерени сделки: */
select distinct [TEST_ID] 
from [AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
go

/*********************************************************************************************************/
/* 4. Find one unaccepted condition: */
declare	@Curr_Acc_Date datetime = Getdate() /* може да използваме текущата счетоводната дата на системата */
;

declare curTestCase cursor for 
select DISTINCT [TEST_ID]
from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
order by [TEST_ID]
;
declare @TA_ID int= 0 , @TA_Type varchar(126) = N'', @Ret int = 0
;
open curTestCase
fetch next from curTestCase into @TA_ID
;
while @@FETCH_STATUS = 0 
begin

	exec @Ret = dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]
		@TestCaseRowID = @TA_ID, @CurrAccDate = @Curr_Acc_Date

	fetch next from curTestCase into @TA_ID
	;
end
close curTestCase;
deallocate curTestCase;
go

/*********************************************************************************************************/
/* 5. Find one unaccepted condition: */
select distinct [TEST_ID] 
from [AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
order by [TEST_ID] 
go

select * from SYS_LOG_PROC
where msg like '%Skiped SQL condition:%'
order by id desc
go
