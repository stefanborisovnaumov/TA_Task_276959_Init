
/********************************************************************************************************/
/* Процедура за актуализация на дневните салда в TA базата, след обработка на тестови случай */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE]
(
    @OnlineSqlServerName    sysname
,	@OnlineSqlDataBaseName  sysname    
,	@TestCaseRowID          int
,   @DEAL_ROW_ID            int 
,   @REG_NAME               sysname = N''
,   @UPDATE_MODE            int = 1
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Sql nvarchar(4000) = N'', @Ret int = 0
        ,	@RowIdStr nvarchar(8) = STR(@TestCaseRowID,LEN(@TestCaseRowID),0)
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql = 'dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName = '''+@OnlineSqlServerName+''''
				+ N', @OnlineSqlDataBaseName = '''+@OnlineSqlDataBaseName+''''
				+ N', @TestCaseRowID = '+@RowIdStr
				+ N', @DEAL_ROW_ID = ' + str(@DEAL_ROW_ID,len(@DEAL_ROW_ID), 0)
				+ N', @REG_NAME = ''' + @REG_NAME +''''
				+ N', @UPDATE_MODE = ' + str(@UPDATE_MODE,len(@UPDATE_MODE), 0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	/************************************************************************************************************/
	/* 2. Load Account from ROW_ID */
    declare @Row_id     int = -1
        ,   @Deal_Type  int = 1
        ,   @Deal_Num   int = -1
        ,   @Account    varchar(64) = N''
        ,   @Acc_Type   int = 3 /* Pasive */
        ,   @UpdAccont  int = @UPDATE_MODE
		,	@DayAccBal	float = 0.0;
    ;

    declare @OutputUpdateTbl Table ( [ACCOUNT] varchar(64), [DAY_SALDO] float )
    ;

    /* 2.1. Find Account by ROW_ID */
    if IsNull(@DEAL_ROW_ID,-1) > 0
    begin
        if @REG_NAME = N'RAZPREG_TA'
        begin
            select  @Row_id     = [ROW_ID] 
                ,   @Deal_Type  = 1
                ,   @Deal_Num   = [UI_DEAL_NUM]
                ,   @Account    = replace([DB_ACCOUNT], ' ','')
                ,   @Acc_Type   = 3 /* Pasive */
            from dbo.[RAZPREG_TA] [REG] with(nolock)
            where [REG].[ROW_ID] in ( @DEAL_ROW_ID )
            ;
        end
        else if @REG_NAME = N'DEALS_CORR_TA'
        begin
            select  @Row_id     = [ROW_ID] 
                ,   @Deal_Type  = [UI_DEAL_TYPE]
                ,   @Deal_Num   = [DEAL_NUM]
                ,   @Account    = replace([UI_CORR_ACCOUNT], ' ','')
                ,   @Acc_Type   = 3 /* Pasive */
            from dbo.[DEALS_CORR_TA] [REG] with(nolock)
            where [REG].[ROW_ID] in ( @DEAL_ROW_ID )
            ;
        end
    end

    if IsNull(@Row_id,-1) <= 0
    begin
        select  @Msg = 'Can''t find account by ROW_ID: '+str(@Row_id,len(@Row_id),0)+', Register: '+ @REG_NAME +'.'
            ,   @Sql = 'select  @Account = .. from '+@REG_NAME+' where [ROW_ID] IN ('+str(@Row_id,len(@Row_id),0)+') '
        exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
        return 1;
    end

    /* 2.2. Get day operation balance from OnlineDb: */
    begin try 
        insert into #TBL_RESULT ( [ACCOUNT], [PART_TYPE], [DAY_SALDO] )
        exec @Ret = dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName
            , @OnlineSqlDataBaseName
            , @Account
            , @Acc_Type
    end try 
    begin catch 
        select @Msg = dbo.FN_GET_EXCEPTION_INFO();
        exec dbo.SP_SYS_LOG_PROC @@PROCID, 'insert into #TBL_RESULT  ... for Main account', @Msg;
        return 2;
    end catch 

    if @Ret <> 0
    begin 
        select @Sql = 'exec @Ret = Sql: dbo.[SP_LOAD_ONLINE_ACCOUNT_DAY_OPERATION_BALANCE] '
                + '@OnlineSqlServerName = '+ @OnlineSqlServerName
                + '@OnlineSqlDataBaseName = '+ @OnlineSqlDataBaseName
                + '@Account = '+ @Account
                + '@AccType = '+ str(@Acc_Type,len(@Acc_Type), 0)
                + '@LogTrace = 1'
            , @Msg = 'Error '+str(@Ret,len(@Ret),0)+' execute sql for test case ID: '+@RowIdStr
                + ', Account: '+@Account 
                + ', @DEAL_ROW_ID = '+str(@DEAL_ROW_ID,len(@DEAL_ROW_ID),0)
        ;
        exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
        return 2;
    end

    /* 2.3. Update Account day operation balance in table: */
    if @UpdAccont = 1 and exists (select * from #TBL_RESULT  where [ACCOUNT] = @Account)
        update [D]
            set [DAY_OPERATION_BALANCE] = [S].[DAY_SALDO]
            output [S].[ACCOUNT], INSERTED.[DAY_OPERATION_BALANCE] into @OutputUpdateTbl
        from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
        inner join #TBL_RESULT  [S]
            on [S].[ACCOUNT] = [D].[DEAL_ACCOUNT]
    ;

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin
		select @DayAccBal = [DAY_SALDO] from #TBL_RESULT where [ACCOUNT] = @Account;
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
			+ '; TA Row ID: ' + @RowIdStr
			+ '; Account: '+ @Account
			+ '; balance: '+str(@DayAccBal, 12,2)
			+ '; Upate mode: '+str(@UpdAccont, len(@UpdAccont),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE]'
	end

    return 0;
end    
GO