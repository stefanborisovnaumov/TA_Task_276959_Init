/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG] */
DROP PROCEDURE IF EXISTS dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]
GO

CREATE PROCEDURE dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@TestCaseRowID			nvarchar(16)
,	@DEAL_TYPE				int 
,	@DEAL_NUM				int 
,	@IS_DEAL_BEN			bit = 0 
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0, @LogResultTable int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql2 nvarchar(4000) = N''
		,	@TA_RowID int = cast ( @TestCaseRowID as int );
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]'
	;

	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(@OnlineSqlServerName,1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(@OnlineSqlDataBaseName,1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)		

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName
	;

	/************************************************************************************************************/
	-- Get TA Deal Row ID:
	declare @TBL_ROW_ID int = 0
	;
	select	@TBL_ROW_ID = case when @IS_DEAL_BEN = 1 then [DEAL_BEN_ROW_ID] else [DEAL_ROW_ID] end
	from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID
			+ '; Deal num: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
			+ '; Is ben deal: ' + str(@IS_DEAL_BEN,len(@IS_DEAL_BEN),0);

		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	/************************************************************************************************************/
	-- UPDATE [RAZPREG_TA]: 
	drop table if exists dbo.[#TBL_ONLINE_DEAL_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEAL_INFO]
	(
		[DEAL_NUM]			int
	,	[ACCOUNT]			varchar(64)
	,	[ACCOUNT_CURRENCY]	int
	,	[IBAN]				varchar(64)
	,	[BEG_SAL]			float
	,	[DAY_MOVE]			float
	,	[BLK_SUMA_MIN]		float
	,	[RAZPOL]			float
	,	[TAX_UNCOLLECTED]	float
	,	[DISTRAINT_SUM]		float
	,	[HAS_TAX_UNCOLLECTED] int
	);


	begin try
		insert into dbo.[#TBL_ONLINE_DEAL_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName, @OnlineSqlDataBaseName, @DEAL_TYPE, @DEAL_NUM
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()

			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
								+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
								+ ', @DEAL_TYPE = 1, @DealNum = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg

			return 2
	end catch

	if @Ret <> 0
		return 3;

	if @LogResultTable = 1 select * from dbo.[#TBL_ONLINE_DEAL_INFO]  with(nolock)
	;

	/************************************************************************************************************/
	-- Load tax uncollected amount from OnlinDB:
	declare @Account varchar(64) = N'', @AccCurrency int = 100, @HasTaxUncollected int = 0
	;
	
	select top (1) @Account = [ACCOUNT], @AccCurrency = [ACCOUNT_CURRENCY], @HasTaxUncollected = [HAS_TAX_UNCOLLECTED]
	from dbo.[#TBL_ONLINE_DEAL_INFO] with(nolock)
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
			exec @Ret = dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName, @OnlineSqlDataBaseName, @Account, @AccCurrency
		end try
		begin catch
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
				,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName = '+@OnlineSqlServerName+' '
									+ ', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
									+ ', @Account = '+@Account
									+ ', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
				;

				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 4
		end catch

		if exists ( select * from dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] with(nolock))
		begin

			update [D]
			set [TAX_UNCOLLECTED] = [s].[TAX_UNCOLLECTED]
			from dbo.[#TBL_ONLINE_DEAL_INFO] [D]
			inner join dbo.[#TBL_ONLINE_ACC_TAX_UNCOLECTED] [S] with(nolock)
				on	[S].[ACCOUNT] = [D].[ACCOUNT]
				and [d].[ACCOUNT_CURRENCY] = @AccCurrency
		end

	end

	/********************************************************************************************************/
	/* Update data in [RAZPREG_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_DEAL_NUM]			= [S].[DEAL_NUM]				-- RAZPREG_TA	UI_DEAL_NUM	
			,	[DB_ACCOUNT]			= [S].[ACCOUNT]					-- RAZPREG_TA	DB_ACCOUNT	
			,	[UI_ACCOUNT]			= [xa].[ACC_WITH_SPACE]			/* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
			,	[ZAPOR_SUM]				= STR([S].[DISTRAINT_SUM],14,2)	-- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
			,	[IBAN]					= [S].[IBAN]					-- RAZPREG_TA	IBAN	
			,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]			-- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
		FROM dbo.[RAZPREG_TA] [D]
		INNER JOIN  dbo.[#TBL_ONLINE_DEAL_INFO] [S] WITH(NOLOCK)
			ON [S].[DEAL_NUM] = @DEAL_NUM
		cross apply (
			select case when left([S].[ACCOUNT], 2) = '17' 
				then left([S].[ACCOUNT],4)+' '+substring([S].[ACCOUNT],5,9)+' '+substring([S].[ACCOUNT],14,2)+' '+right(rtrim([S].[ACCOUNT]),1)
				else left([S].[ACCOUNT],4)+' '+substring([S].[ACCOUNT],5,3)+' '+substring([S].[ACCOUNT],8,9) +' '+substring([S].[ACCOUNT],17,2)+' '+right(rtrim([S].[ACCOUNT]),1)
				end AS  [ACC_WITH_SPACE]
		) [xa]
		WHERE [D].[ROW_ID] = @TBL_ROW_ID
		;
	end

	select @Rows = @@ROWCOUNT, @Err = @@ERROR
	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After Update dbo.[RAZPREG_TA], Rows affected: '+str(@Rows,len(@Rows),0)+', [ROW_ID] = '+str(@TBL_ROW_ID,len(@TBL_ROW_ID),0) 
			,	@Sql2 = 'UPDATE dbo.[RAZPREG_TA] [D] SET [UI_DEAL_NUM] = ... WHERE [ROW_ID] = ' + str(@TBL_ROW_ID,len(@TBL_ROW_ID),0);

	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg;
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate())
			 + ', TA Row ID: ' + @TestCaseRowID 
			 + ', Deal num: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
			 + ', Is Ben deal: ' + str(@IS_DEAL_BEN,len(@IS_DEAL_BEN),0)
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_RAZPREG]'
	end

	return 0;
end 
GO

