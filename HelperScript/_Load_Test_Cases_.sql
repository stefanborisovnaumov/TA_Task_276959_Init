/********************************************************************************************/
/*  Load One Test Case */
declare @TestCaseID int = 400003, @Ret int = 0
select * from dbo.VIEW_CASH_PAYMENT_TEST_CASE_DATA with(nolock)
where row_id = @TestCaseID
;
select * from dbo.VIEW_CASH_PAYMENTS_CONDITIONS with(nolock)
where row_id = @TestCaseID
;

exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES] @TestCaseID
;
select * from dbo.VIEW_CASH_PAYMENT_TEST_CASE_DATA with(nolock)
where row_id = @TestCaseID
go

/********************************************************************************************/
/*  Load All */
declare curTestCase cursor for
select [ROW_ID] from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS]
order by [ROW_ID]
;

truncate table dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
;

declare @TestCaseID int, @Ret int = 0 
;
open curTestCase
fetch next from curTestCase into @TestCaseID
;

while @@FETCH_STATUS = 0
begin

	exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES] @TestCaseID

	if @Ret <> 0 
		print ('Error load test case from '+str(@TestCaseID,len(@TestCaseID),0)+'!');

	fetch next from curTestCase into @TestCaseID
	;	
end

close curTestCase;
deallocate curTestCase
go
