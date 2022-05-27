/************************************************************************************************************/
/************************************************************************************************************/
/* Test proc: */
-- EXEC dbo.[SP_CASH_PAYMENTS_INIT_DEALS] 'YYANKOV\SQL2016', 'BPB_VCSBank_Online'
--GO

--EXEC dbo.[SP_CASH_PAYMENTS_INIT_DEALS] 'TESTSERVER18\SQL2016', 'BPB_online_NEXT'
--GO

--EXEC dbo.[SP_CASH_PAYMENTS_INIT_DEALS] 'TESTSERVER50\SQL2016', 'BPB_Next_VCSBank_Online'
--GO

select * 
from dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA] 
where	ROW_ID > 1 
	and PROXY_ROW_ID is not null
order by ROW_ID
go

--exec dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES] 400019
--go

exec dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES] 400019
go

select * 
from dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA] 
where PROXY_ROW_ID is not null
	and ROW_ID = 400002
order by ROW_ID
go

