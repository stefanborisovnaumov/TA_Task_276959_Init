
/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[DEALS_CORR_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@CUSTOMER_ID			int
,	@PROXY_ID				int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogResultTable int = 0, @LogBegEndProc int = 1, @TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql2 nvarchar(4000) = N'',	@TA_RowID int = cast( @TestCaseRowID as int)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]'
	;

	/************************************************************************************************************/
	/* Find Test Case row and Corr Account */
	declare @TBL_ROW_ID int = 0, @DealRowID int = 0
		,	@CorrAccount varchar(64) = N'', @CorrAccType int = 3
	;

	select	@DealRowID = [DEAL_ROW_ID]
		,	@TBL_ROW_ID = [CORS_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found correspondence from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	select	@CorrAccount = [CORR_ACCOUNT]
	from [dbo].[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [C] with(nolock)
	where [DEAL_TYPE] = 1 AND [DEAL_NUM] = @DEAL_NUM
	;	

	if IsNull(@CorrAccount,'') = ''
	begin  
		select @Msg = 'Not found correspondence account TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 1;
	end 

	/************************************************************************************************************/
	-- Load data from OnlinDB: 
	drop table if exists dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
	(	[DEAL_TYPE]			int
	,	[DEAL_NUM]			int	
	,	[CORR_TYPE]			int	
	,	[CORR_DEAL_TYPE]	int
	,	[CORR_DEAL_NUM]		int
	,	[CORR_ACCOUNT]		varchar(64)
	,	[CORR_ACCOUNT_CCY]	varchar(8)
	,	[CORR_ACC_CCY_CODE]	int
	,	[BLK_SUMA_MIN]		float	
	,	[AVAILABLE_BAL]		float	
	,	[TAX_UNCOLLECTED]	float
	,	[HAS_TAX_UNCOLLECTED] int
	);	

	begin try
		insert into dbo.[#TBL_ONLINE_DEALS_CORR_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @DEAL_NUM, @CorrAccType, @CorrAccount
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnleneSqlServerName = '+@OnleneSqlServerName+' '
								+ ', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+' '
								+ ', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
								+ ', @CORS_ACCOUNT_TYPE = '+str(@CorrAccType,len(@CorrAccType),0)
								+ ', @CORS_ACCOUNT = '''+@CorrAccount+''''
			;

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 2
	end catch

	if @Ret <> 0
		return 3;

	/************************************************************************************************************/
	-- Load tax uncollected amount from OnlinDB:
	declare @Account varchar(64) = N'', @AccCurrency int = 100, @HasTaxUncollected int = 0
	;
	
	select top (1) @Account = [CORR_ACCOUNT], @AccCurrency = [CORR_ACC_CCY_CODE], @HasTaxUncollected = [HAS_TAX_UNCOLLECTED]
	from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] with(nolock)
	;

	if IsNull(@HasTaxUncollected,0) = 1 and IsNull(@Account,'') <> ''
	begin

		drop table if exists dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		;

		create table dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
		(	[ACCOUNT]			varchar(64)
		,	[TAX_UNCOLLECTED]	float
		,	[CNT_ITEMS]			int	
		);

		begin try
			insert into dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED]
			exec @Ret = dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnleneSqlServerName, @OnleneSqlDataBaseName, @Account, @AccCurrency
		end try
		begin catch
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnleneSqlServerName = '+@OnleneSqlServerName+' '
									+ ', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+' '
									+ ', @Account = '+@Account
									+ ', @@AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
				;

				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 4
		end catch

		if exists ( select * from dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] with(nolock))
		begin

			update [D]
			set [TAX_UNCOLLECTED] = [s].[TAX_UNCOLLECTED]
			from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] [D]
			inner join dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] [S] with(nolock)
				on	[S].[CORR_ACCOUNT] = [D].[ACCOUNT]
				and [d].[CORR_ACC_CCY_CODE] = @AccCurrency

		end

	end

	/************************************************************************************************************/
	-- UPDATE [DEALS_CORS_TA] 
	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DEALS_CORR_INFO] with(nolock)
	;

	/* Update data in table [DEALS_CORR_TA] */
	if @WithUpdate = 1
	begin
		UPDATE [D]
		SET [DEAL_NUM]				= [S].[CORR_DEAL_NUM]		-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
		,	[CURRENCY]				= [S].[CORR_ACCOUNT_CCY]	-- DEALS_CORR_TA	CURRENCY	
		,	[UI_CORR_ACCOUNT]		= [S].[CORR_ACCOUNT]		-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
		,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]		-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 

		from dbo.[DEALS_CORR_TA] [D]
		inner join dbo.[#TBL_ONLINE_DEALS_CORR_INFO] [S] with(nolock)
			on	[S].[DEAL_TYPE] 	= 1
			and [S].[DEAL_NUM]		= @DEAL_NUM
			and [S].[CORR_TYPE]		= @CorrAccType
			and [S].[CORR_ACCOUNT]	= @CorrAccount
		where [D].[ROW_ID] = @TBL_ROW_ID
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[DEALS_CORR_TA], Rows affected: '+ str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0) 
			,	@Sql2 = 'UPDATE dbo.[DEALS_CORR_TA] [D] SET [UI_CUSTOMER_ID] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]'
	end

	return 0;
end 
GO
