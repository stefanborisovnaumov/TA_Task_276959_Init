
/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от OnlineDb с неплатени такси към всички кл. сметки */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
(
	@OnlineSqlServerName	sysname 
,	@OnlineSqlDataBaseName	sysname 
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
        ,   @Sql1 nvarchar(2000) = N'', @Msg nvarchar(2000) = N''
    ;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end   

    /************************************************************************************************************/
	/* 2.1. Prepare Online Database FullName */
	if LEN(@OnlineSqlServerName) > 1 and LEFT(@OnlineSqlServerName,1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	if LEN(@OnlineSqlDataBaseName) > 1 and LEFT(@OnlineSqlDataBaseName,1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)

	declare @Sql nvarchar(4000) = N'', @Ret int = 0
		,	@SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;
	;

	/************************************************************************************************************/
	/* 2.2. Prepare SQL statement */
	select @Sql = '
    select distinct [C].[CUSTOMER_ID] 
    from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
    inner join '+@SqlFullDBName+'.dbo.[PARTS] [A] with(nolock)
        on [a].[PART_ID] = [T].[ACCOUNT_DT]
    inner join '+@SqlFullDBName+'.dbo.[DT015] [C] with(nolock)
        on [C].[CODE] = [A].[CLIENT_ID]
    where	[T].[TAX_STATUS] =  0 /* eTaxActive = 0 // Действаща такса */
        and [T].[COLLECT_FROM_ALL_CUSTOMER_ACCOUNTS] = 1
    ';

	/************************************************************************************************************/
	/* 3. Execute SQL statement */
	begin try
        exec @Ret = sp_executesql @Sql
    end try
	begin catch
		select @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch    

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go
