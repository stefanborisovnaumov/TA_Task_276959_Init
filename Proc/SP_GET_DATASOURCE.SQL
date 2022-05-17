
/********************************************************************************************************/
/* Процедура за визличане на Sql Online Server name и Onle Database name */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]
(
	@DB_TYPE				sysname = N'BETA'
,	@DB_ALIAS				sysname = N'VCS_OnlineDB'
,	@OnleneSqlServerName	sysname = N'' out
,	@OnleneSqlDataBaseName	sysname = N'' out
)
as
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Sql nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, '', N'*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]'
	;

	/************************************************************************************************************/
	/* @TODO: */
	select	@OnleneSqlServerName	= [SERVER_INSTANCE_NAME]
		,	@OnleneSqlDataBaseName	= [DATABASE_NAME]
	from dbo.[TEST_AUTOMATION_DATASOURCES] [DS] with(nolock)
	where [DB_TYPE] = @DB_TYPE and [UNIQUE_ALIAS] = @DB_ALIAS
	;

	if IsNull(@OnleneSqlServerName,'') = '' or IsNull(@OnleneSqlServerName,'') = ''
	begin
		select	@Msg = N'Can find datasource for [DB_TYPE] ='+@DB_TYPE+' AND [UNIQUE_ALIAS] = '+@DB_ALIAS+' '
			,	@Sql = N' SELECT [SERVER_INSTANCE_NAME], [DATABASE_NAME] from dbo.[TEST_AUTOMATION_DATASOURCES] [DS] with(nolock)'
					+  N'	where [DB_TYPE] = '+@DB_TYPE+' and [UNIQUE_ALIAS] = '+@DB_ALIAS+' '
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
		return 1;
	end

	if LEN(@OnleneSqlServerName) > 1 and LEFT(@OnleneSqlServerName,1) <> N'['
		select @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	if LEN(@OnleneSqlDataBaseName) > 1 and LEFT(@OnleneSqlDataBaseName,1) <> N'['
		select @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = N'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, N'*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE]'
	end

	return 0;
end 
go
