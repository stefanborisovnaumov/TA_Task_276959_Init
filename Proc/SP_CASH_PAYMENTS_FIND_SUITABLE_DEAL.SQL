
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
	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	;

	/************************************************************************************************************/
	/* @TODO: */
	
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_FIND_SUITABLE_DEAL]'
	end
	;

	return 0;
end 
go

