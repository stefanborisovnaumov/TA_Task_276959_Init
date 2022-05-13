select 'drop table IF EXISTS ' + name
from sys.tables where name like 'agr_cash_p%'
go

select 'drop proc IF EXISTS ' + name
from sys.procedures where name like 'sp_cash_p%'
go

drop view if exists dbo.VIEW_CASH_PAYMENTS_CONDITIONS
go

select * from dbo.SYS_LOG_PROC
order by id
go

exec sp_db_snapshot_create 'BPB_TA_REGRESSION_NEXT'
go

exec sp_db_snapshot_restore 'BPB_TA_NEXT_SS@2022.05.12_v2'
go
