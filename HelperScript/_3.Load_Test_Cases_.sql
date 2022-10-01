/********************************************************************************************/
/*  Save Current data */
select * 
into cstemp_old_data
from dbo.VIEW_TA_EXISTING_ONLINE_DATA_TEST_CASE_DATA with(nolock)
go

/********************************************************************************************/
/*  Clear All Data */
declare @TA_MaxRowID	 int = 0
		, @TA_RowID		 int= 0
		, @CustomerRowID int = 0
		, @DealRowID	 int = 0
		, @PSpecRowID	 int = 0
		, @CorsRowID	 int = 0
		, @Count		 int = 0
;
select @TA_MaxRowID = MAX([ROW_ID])
from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS]
;
declare @Ret int = 0
	,	@Msg nvarchar(max) = N'', @Sql nvarchar(max) = N''
;


while @TA_RowID < @TA_MaxRowID
begin 
	select top(1)
			@TA_RowID		= [ROW_ID]
		,	@DealRowID		= [DEAL_ROW_ID]
		,	@CorsRowID		= [CORS_ROW_ID]
		,	@CustomerRowID	= [CUST_ROW_ID]
	from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS]
	where [ROW_ID] > @TA_RowID 
	order by [ROW_ID] 
	;

	select @TA_RowID, @DealRowID, @CorsRowID, @CustomerRowID

	EXEC @Ret = DBO.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA @TA_RowID
	select @Ret as [result], @TA_RowID

	select @Msg = 'After Exec DBO.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA @TA_RowID = '+str(@TA_RowID,len(@TA_RowID),0)
		+ '; @DealRowID = '+str(@DealRowID,len(@DealRowID),0)
		+ '; @CorsRowID = '+str(@CorsRowID,len(@CorsRowID),0)
		+ '; @CustomerRowID = '+str(@CustomerRowID,len(@CustomerRowID),0)
	;
	exec dbo.[SP_SYS_LOG_PROC] NULL, 'Exec DBO.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA @TA_RowID', @Msg
	set @Count += 1
end
select @Count as row_count
GO



/********************************************************************************************/
/*  Load One Test Case */
declare @TestCaseID int = 400003, @Ret int = 0
select * from dbo.VIEW_TA_EXISTING_ONLINE_DATA_TEST_CASE_DATA with(nolock)
where row_id = @TestCaseID
;
select * from dbo.VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS with(nolock)
where row_id = @TestCaseID
;

exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES] @TestCaseID
;
select * from dbo.VIEW_TA_EXISTING_ONLINE_DATA_TEST_CASE_DATA with(nolock)
where row_id = @TestCaseID
go

/********************************************************************************************/
/*  Load All */
declare curTestCase cursor for
select [ROW_ID] from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS]
order by [ROW_ID]
;

truncate table dbo.[AGR_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_SQL_CONDITIONS]
;

declare @TestCaseID int, @Ret int = 0 
;
open curTestCase
fetch next from curTestCase into @TestCaseID
;

while @@FETCH_STATUS = 0
begin

	exec @Ret = dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES] @TestCaseID

	if @Ret <> 0 
		print ('Error load test case from '+str(@TestCaseID,len(@TestCaseID),0)+'!');

	fetch next from curTestCase into @TestCaseID
	;	
end

close curTestCase;
deallocate curTestCase
go

/*************************************************************************/
-- Тестови случай за който не са намерени подходящи сделки:
select top (2000) * 
from sys_log_proc with(nolock)
where [msg] like 'Not found suitable deal from Test Case with%'
--	and id > 1057
order by id
go
