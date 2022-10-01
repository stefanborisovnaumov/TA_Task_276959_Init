drop proc if exists dbo.[SP_TA_FIND_BREAK_CONDITION]
go

create proc dbo.[SP_TA_FIND_BREAK_CONDITION]
(
	@TA_Type_Filter varchar(128)
,	@Test_Case_ID int = null
,	@Add_Date datetime = null
)
as 
begin

	/* може да използваме текущата счетоводната дата на системата */
	declare	@Curr_Acc_Date datetime = IsNull(@Add_Date,Getdate())
	;

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
	,	[DEAL_TYPE_BEN]	SMALLINT
	,	[DEAL_NUM_BEN]	INT 	
	)
	;

	/* 1.2. Clear Test Case conditions table */
	declare @LastLogId int =  IsNull( (select max(id) from dbo.[SYS_LOG_PROC] with(nolock)), 0)
		,	@LastCndTblId int = IsNull( (select max(id) from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)), 0)
	;

	/******************************************************************/
	-- 1.3 Create table with TA cases for process
	drop table if EXISTS dbo.[#TBL_WITH_TEST_CASES]
	;
	select [ROW_ID], [TA_TYPE]
	into dbo.[#TBL_WITH_TEST_CASES]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] 
	WHERE TA_TYPE LIKE @TA_Type_Filter
		and [ROW_ID] = IsNull(@Test_Case_ID,[ROW_ID])
	order by [ROW_ID]
	;

	/*********************************************************************************************************/
	/* 2. Търсим подходящи сделки за вскички Тестови случай: */
	declare curTestCase cursor for 
	select [ROW_ID], [TA_TYPE]
	from dbo.[#TBL_WITH_TEST_CASES] with(nolock)
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
	deallocate curTestCase
	;

	/*********************************************************************************************************/
	/* 4. Find one unaccepted condition: */
	declare curTestCase cursor for 
	select DISTINCT [c].[TEST_ID]
	from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] [c] with(nolock)
	inner join dbo.[#TBL_WITH_TEST_CASES] [F]
		on [F].ROW_ID = [c].[TEST_ID]
		and [c].[ID] > @LastCndTblId
	order by [c].[TEST_ID]
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

	/*********************************************************************************************************/
	/* 5. Find one unaccepted condition: */
	select distinct [TEST_ID] 
	from [AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
	where [id] > @LastCndTblId
	order by [TEST_ID] 
	;

	select * from SYS_LOG_PROC
	where msg like '%Skiped SQL condition:%'
		and  id > @LastLogId
	order by id desc
	;

	select *
	from [AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
	where id > @LastCndTblId
	order by [TEST_ID]
	;

end
go