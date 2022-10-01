
/********************************************************************************************************/
/* Процедура за актуализация на дневните салда в TA базата, след обработка на тестови случай */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNTS_DAY_OPERATION_BAL]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNTS_DAY_OPERATION_BAL]
(
	@TestCaseRowID  int
,   @UpdateMode     int = 1
)
AS 
begin

	declare @LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;
	declare @Msg nvarchar(max) = N'', @Sql nvarchar(4000) = N'', @Ret int = 0
        ,	@RowIdStr nvarchar(8) = STR(@TestCaseRowID,LEN(@TestCaseRowID),0)
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql = 'dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNTS_DAY_OPERATION_BAL] @RowIdStr = '+@RowIdStr
					+', @UpdateMode = '+str(@UpdateMode, len(@UpdateMode),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNTS_DAY_OPERATION_BAL]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end

	/************************************************************************************************************/
	/* 2. Find TA Conditions: */
	if not exists (select * from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1))
	begin 
		select  @Msg = N'Error not found condition with [ROW_ID] :' + @RowIdStr
			,	@Sql = N'select * from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull('+@RowIdStr+', -1)'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -1;
	end
	
    declare @DB_TYPE         varchar(256) = N''
        ,   @DEAL_ROW_ID     int = -1 /* Main accoutn row id */
        ,   @CORS_ROW_ID     int = -1 /* Tax accoutn row id */
        ,   @DEAL_BEN_ROW_ID int = -1 /* Ben accoutn row id */
    ;
	select	@DB_TYPE            = [DB_TYPE]
        ,   @DEAL_ROW_ID        = IsNull([DEAL_ROW_ID], -1)
		,	@CORS_ROW_ID        = IsNull([CORS_ROW_ID], -1)
        ,   @DEAL_BEN_ROW_ID    = IsNull([DEAL_BEN_ROW_ID],-1)
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock) where [ROW_ID] = IsNull(@TestCaseRowID, -1)
	;

	/************************************************************************************************************/
	/* 3. Get Datasources: */
	declare @OnlineSqlServerName sysname = N'',	@OnlineSqlDataBaseName sysname = N'', @DB_ALIAS sysname = N'VCS_OnlineDB'
	;
	exec @Ret = dbo.[SP_TA_GET_DATASOURCE] @DB_TYPE, @DB_ALIAS, @OnlineSqlServerName out, @OnlineSqlDataBaseName out
	if @Ret <> 0
	begin
		select  @Msg = N'Error execute proc, Error code: '+str(@Ret,len(@Ret),0)
					+' ; Result: @OnlineSqlServerName = "'+@OnlineSqlServerName+'", @OnlineSqlDataBaseName = "'+@OnlineSqlDataBaseName+'"'
			,	@Sql = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return -2;
	end

	/************************************************************************************************************/
	/* 4. Load Accounts from test cases and Update day operation balance : */
	create table #TBL_RESULT
	(
		[ACCOUNT]		varchar(64)
	,	[PART_TYPE]		int
	,	[DAY_SALDO]		float
    );

    declare @Row_id     int = -1
        ,   @Deal_Type  int = 1
        ,   @Deal_Num   int = -1
        ,   @Account    varchar(64) = N''
        ,   @Acc_Type   int = 3 /* Pasive */
        ,   @UpdAccont  int = IsNull(@UpdateMode,0);
    ;

    /******************************************************************/
    /* 4.1. Main Account: */
    if IsNull(@DEAL_ROW_ID,-1) > 0 
    begin 
		begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName 
				, @OnlineSqlDataBaseName, @TestCaseRowID, @DEAL_ROW_ID, N'RAZPREG_TA', @UpdAccont
		end try
		begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, 'dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE] @MainAccount', @Msg
		    return 1;
		end catch
    end

    /******************************************************************/
    /* 4.2. Ben Account: */    
    if IsNull(@DEAL_BEN_ROW_ID,-1) > 0 and (IsNull(@DEAL_ROW_ID,-1) != IsNull(@DEAL_BEN_ROW_ID,-2))
    begin 
		begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName 
				, @OnlineSqlDataBaseName, @TestCaseRowID, @DEAL_BEN_ROW_ID, N'RAZPREG_TA', @UpdAccont
		end try
		begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, 'dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE] @BenAccount', @Msg
		    return 2;
		end catch
    end

    /******************************************************************/
    /* 4.3. Corespondent Account: */
    if IsNull(@CORS_ROW_ID,-1) > 0
    begin 
		begin try
			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE] @OnlineSqlServerName 
				, @OnlineSqlDataBaseName, @TestCaseRowID, @CORS_ROW_ID, N'DEALS_CORR_TA', @UpdAccont
		end try
		begin catch
    		select @Msg = dbo.FN_GET_EXCEPTION_INFO();
	    	exec dbo.SP_SYS_LOG_PROC @@PROCID, 'dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNT_DAY_OPERATION_BALANCE] @CorespondentAccount', @Msg
		    return 3;
		end catch
    end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + '; TA Row ID: ' + @RowIdStr;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_ACCOUNTS_DAY_OPERATION_BAL]'
	end

    return 0;
end    
GO