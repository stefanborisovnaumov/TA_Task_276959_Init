--truncate table sys_log_proc
--go

select top (2000) * 
from sys_log_proc with(nolock) 
--where ID > 1140 --50
order by id desc
go


-- Not found suitable deal from Test Case with [ROW_ID]: 400063
-- *** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_PREPARE_DEALS_BETA]
select top (2000) * 
from sys_log_proc with(nolock)
where [msg] like 'Not found suitable deal from Test Case with%'
order by id
go

select top (2000) * 
from sys_log_proc with(nolock)
where [msg] like '%After: insert into dbo._#TBL_RESULT_, Rows affected : 0%'
order by id DESC
go

After: insert into dbo.[#TBL_RESULT], Rows affected : 0, TA ID :400063

--Not found correspondence from TA ROW_ID : 
-- Not found Customer from TA ROW_ID : 400001
select * from dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA]
order by row_id
go
