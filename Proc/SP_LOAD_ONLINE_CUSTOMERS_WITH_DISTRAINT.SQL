
/********************************************************************************************************/
/* Процедура за селектиране на всички клиенти от Online базата с активни запори */
DROP PROC IF EXISTS dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
GO

CREATE PROC dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]
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
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT]'
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
	select @Sql = 
	'declare @Ret int = 0
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	
	declare @Tbl_Distraint_Codes TABLE ( [CODE] INT )
	;

	insert into @Tbl_Distraint_Codes
	SELECT [n].[CODE]
	from '+@SqlFullDBName+'.dbo.[NOMS] [n] with(nolock)
	where	[n].[NOMID] = 136
		and ([n].[sTATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
	;
	WITH [CTE_X] AS
	(
		SELECT [CODE] 
		FROM @Tbl_Distraint_Codes 
	)
	SELECT distinct [CLC].[CUSTOMER_ID]
	FROM '+@SqlFullDBName+'.dbo.[BLOCKSUM] [BLK] with(nolock)
	inner join [CTE_X] [X] with(nolock)
		on	[BLK].[WHYFREEZED] = [X].[CODE]
		and [BLK].[CLOSED_FROZEN_SUM] <> 1
		and [BLK].[SUMA] > 0.0
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		on [ACC].[PART_ID] = [BLK].[PARTIDA]
	inner join '+@SqlFullDBName+'.dbo.[dt015] [CLC] with(nolock)
		on [CLC].[CODE] = [ACC].[CLIENT_ID]
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
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end    

	return 0
end
go
