
/********************************************************************************************************/
/* Процедура за определяне на критериите който ни пречат да намерим подходяща сделка за датен TestCase */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]
(
	@TestCaseRowID nvarchar(16)
,	@CurrAccDate datetime
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0,	@Sql nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	;

	/************************************************************************************************************/
	/* @TODO: */
	/**********************************************************************************/
	drop table if EXISTS dbo.[#TBL_RESULT]
	;
	create table dbo.[#TBL_RESULT]
	(
		[TEST_ID]		nvarchar(512) 
	,	[DEAL_TYPE]		smallint
	,	[DEAL_NUM]		INT 	
	,	[CUSTOMER_ID]	INT
	,	[REPRESENTATIVE_CUSTOMER_ID] INT
	,	[DEAL_TYPE_BEN]	SMALLINT
	,	[DEAL_NUM_BEN]	INT
	)
	;

	declare @CondCount int = 0, @FistCondRowID int = 0, @ScipCondIndex int = 4, @ScipTblRowId int = 0
	;

	select @CondCount = count(*), @FistCondRowID = min([ID])
	from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with (nolock)
	where [TEST_ID] = @TestCaseRowID
	;

	while @Rows = 0 AND @ScipCondIndex < @CondCount
	begin

		truncate table dbo.[#TBL_RESULT]
		;

		select  @Sql = N'', @Rows = 0, @ScipTblRowId = @FistCondRowID + @ScipCondIndex
		;

		-- Prepare Sql to execute: 
		select @Sql += [CND].[COUND] 
		from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] WITH(NOLOCK)
		cross apply (
			select case when [ID] = @ScipTblRowId 
					then '' else [SQL_COND] end	as [COUND] 
		) [CND]
		where [TEST_ID] = @TestCaseRowID 
		order by [ID]

		-- Execute Sql:
		begin try
			insert into dbo.[#TBL_RESULT]
			exec sp_executesql @Sql
		end try

		begin catch
			select @Msg = 'Error execute Sql:' + dbo.FN_GET_EXCEPTION_INFO()
			from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
			where [ID] = @ScipTblRowId

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		end catch

		select @Rows = count(*)
		from dbo.[#TBL_RESULT] with(nolock)

		-- Test Result:
		if @Rows > 0
		begin
			select @Msg = 'Test Case ID:'+[TEST_ID]+'; Found records: '+str(@Rows,3,0)+'; Skiped condition info: "'+[DESCR]+'"; Skiped SQL condition: "'+[SQL_COND]+'";'
			from dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS] with(nolock)
			where [id] = @ScipTblRowId
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		end

		set @ScipCondIndex += 1;
	end
	
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())+', TA Row ID: '+@TestCaseRowID+'; Found Records: '+str(@Rows,2,0)+'.';
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	end

	return 0;
end 
go

