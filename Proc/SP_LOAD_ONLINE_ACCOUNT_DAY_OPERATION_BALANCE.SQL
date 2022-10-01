
/********************************************************************************************************/
/* Процедура за зареждане на дневните обороти от OnLineDB по сметка */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@Account                varchar(64)
,	@PartType               tinyint = 3
)
AS 
begin

	declare @LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Sql1 nvarchar(4000) = N'', @Ret int = 0
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName = '''+@OnlineSqlServerName+''''
					+', @OnlineSqlDataBaseName = '''+@OnlineSqlDataBaseName+''''
                    +', @Account = ''' + @Account+'''' 
                    +', @PartType = ' + str(@PartType,len(@PartType),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		select @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		select @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
    ;
	/************************************************************************************************************/
	/* 3. Prepare Sql statement */
    declare @AccountParam varchar(64) = ''''+ @Account+ '''';

	select @Sql1 = 
    N'DECLARE @Account varchar(32) = '+@AccountParam+'
        ,	@PartType int = '+str(@PartType,len(@PartType),0)+'
    ;
    with [ACC] AS (
        SELECT	[ACC].[ACCOUNT]
            ,	[ACC].[PART_TYPE]
        FROM ( VALUES (@Account, @PartType) ) as [ACC]( [ACCOUNT], [PART_TYPE] )
    ) 
    select	[ACC].[ACCOUNT]
        ,	[ACC].[PART_TYPE]
        ,	cast([BAL].[DAY_SALDO] as float)	as [DAY_OPERATION_BALANCE]
    from [ACC] with(nolock)
    left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
        on	[DM].[IDENT] = [ACC].[ACCOUNT]
    left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
        on	[FM].[IDENT] = [ACC].[ACCOUNT]
    cross apply (
        SELECT CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
                        THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
                                -	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
                                    + IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

                        ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
                                -	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
                                    + IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
                    END AS [DAY_SALDO]	
    ) [BAL]
    ';

	/************************************************************************************************************/
	/* 4. Execute SQL statement */
	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		if @@TRANCOUNT > 1 ROLLBACK;
		return 1;
	end catch

    if @Ret <> 0
    begin 
		select  @Msg = N'Error '+str(@Ret,len(@Ret),0)+' execute Sql';
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg            
		return 2;
    end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())+'; @Account: '+ @Account + '; @PartType = '+str(@PartType,len(@PartType),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE]'
	end

	return 0;
end
GO