-- select top (2000) * from sys_log_proc with(nolock) where [msg] like 'Not found suitable deal from Test Case with%' order by id
/**************************************************************************************************/
-- Prepare temp table:
drop table if exists #TEST_CASE_ID
go

select top (2000) cast( [SQL] as varchar(32) ) as [TEST_CASE_ID]
into #TEST_CASE_ID
from sys_log_proc with(nolock)
where [msg] like 'Not found suitable deal from Test Case with%'
order by id
go

--select * from #TEST_CASE_ID

/**************************************************************************************************/
-- Find unaccepted condition:
declare curId cursor for 
select [TEST_CASE_ID] from #TEST_CASE_ID with(nolock)

open curId;

declare @TestCaseId varchar(23), @AccDate datetime = GetDate()
fetch next from curId into @TestCaseId

while @@FETCH_STATUS = 0
begin
	exec dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL] @TestCaseId , @AccDate

	fetch next from curId into @TestCaseId
end 
close curId
deallocate curId
go
