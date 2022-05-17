--truncate table sys_log_proc
--go

select top (2000) * 
from sys_log_proc with(nolock) 
--where ID > 1140 --50
order by id desc
go

-- *** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_PREPARE_DEALS_BETA]
select top (2000) * 
from sys_log_proc with(nolock)
where [msg] like 'Not found%from TA ROW_ID :%'
order by id
go


--Not found correspondence from TA ROW_ID : 
-- Not found Customer from TA ROW_ID : 400001
select * from dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA]
order by row_id
go
