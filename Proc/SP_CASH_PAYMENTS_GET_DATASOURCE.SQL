/********************************************************************************************************/
/* Процедура за определяне на критериите който ни пречат да намерим подходяща сделка за датен TestCase */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]
(
	@DB_ALIAS	sysname
,	@DB_TYPE	sysname = N'CASH_PAYMENTS_BETA'
)
AS 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Sql1 nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, '', N'*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]'
	;

	/************************************************************************************************************/
	/* @TODO: */
	
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = N'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, N'*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]'
	end
	;

	return 0;
end 
go
