/************************************************************************************************************/
/************************************************************************************************************/
/* Test proc: */

-- SELECT * FROM TEST_AUTOMATION_DATASOURCES

-- UPDATE TEST_AUTOMATION_DATASOURCES SET SERVER_INSTANCE_NAME = 'SNAUMOV\SQL2016', DATABASE_NAME = 'BPB_Online_20220228' WHERE UNIQUE_ALIAS = 'VCS_OnlineDB' AND DB_TYPE = 'AIR'
-- UPDATE TEST_AUTOMATION_DATASOURCES SET SERVER_INSTANCE_NAME = 'SNAUMOV\SQL2016', DATABASE_NAME = 'BPB_Archive_20220228' WHERE UNIQUE_ALIAS = 'VCS_ArchDB' AND DB_TYPE = 'AIR'
-- UPDATE TEST_AUTOMATION_DATASOURCES SET SERVER_INSTANCE_NAME = 'SNAUMOV\SQL2016', DATABASE_NAME = 'BPB_TestAutomation_20220921' WHERE UNIQUE_ALIAS = 'BPB_TA' AND DB_TYPE = 'AIR'

-- EXEC dbo.SP_CASH_PAYMENTS_INIT_DEALS 
--GO

select * 
from dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA] 
where	ROW_ID > 1 
	and PROXY_ROW_ID is not null
order by ROW_ID
go

--exec dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA 400019
--go

exec dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES] 400019
go

select * 
from dbo.[VIEW_CASH_PAYMENT_TEST_CASE_DATA] 
where PROXY_ROW_ID is not null
	and ROW_ID = 400002
order by ROW_ID
go

