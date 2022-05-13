/********************************************************************************************************/
/* Процедура за актуализация на Таблица dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA] */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]
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

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql2 nvarchar(4000) = N''
		,	@TA_RowID int = cast ( @TestCaseRowID as int );
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]'
	;

	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(@OnleneSqlServerName,1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(@OnleneSqlDataBaseName,1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)		

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
	;

	/************************************************************************************************************/
	-- Get TA Deal Row ID:
	declare @TBL_ROW_ID int = 0
	;
	select	@TBL_ROW_ID = [DEAL_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	/************************************************************************************************************/
	-- TODO: UPDATE [RAZPREG_TA]: 
	drop table if exists dbo.[#TBL_ONLINE_DEAL_INFO]
	;

	create table dbo.[#TBL_ONLINE_DEAL_INFO]
	(
		[DEAL_NUM]			int
	,	[ACCOUNT]			varchar(64)
	,	[IBAN]				varchar(64)
	,	[BEG_SAL]			float
	,	[DAY_MOVE]			float
	,	[BLK_SUMA_MIN]		float
	,	[RAZPOL]			float
	,	[TAX_UNCOLLECTED]	float
	,	[DISTRAINT_SUM]		float
	);


	begin try
		insert into dbo.[#TBL_ONLINE_DEAL_INFO]
		exec  @Ret = dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName, @OnleneSqlDataBaseName, @DEAL_TYPE, @DEAL_NUM
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()

			,	@Sql2 = ' exec dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName = '+@OnleneSqlServerName+' '
								+ ', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+' '
								+ ', @DEAL_TYPE = 1, @DealNum = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg

			return 2
	end catch

	if @Ret <> 0
		return 3;

	if @LogTraceInfo = 1 select * from dbo.[#TBL_ONLINE_DEAL_INFO]  with(nolock)
	;

	/* Update data in [RAZPREG_TA] */
	if @WithUpdate = 1
	begin 
		UPDATE [D]
		SET		[UI_DEAL_NUM]			= [S].[DEAL_NUM]				-- RAZPREG_TA	UI_DEAL_NUM	
			,	[DB_ACCOUNT]			= [S].[ACCOUNT]					-- RAZPREG_TA	DB_ACCOUNT	
			,	[UI_ACCOUNT]			= [S].[ACCOUNT]					/* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
			,	[ZAPOR_SUM]				= STR([S].[DISTRAINT_SUM],14,2)	-- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
			,	[IBAN]					= [S].[IBAN]					-- RAZPREG_TA	IBAN	
			,	[TAX_UNCOLLECTED_SUM]	= [S].[TAX_UNCOLLECTED]			-- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
		FROM dbo.[RAZPREG_TA] [D]
		INNER JOIN  dbo.[#TBL_ONLINE_DEAL_INFO] [S] WITH(NOLOCK)
			ON [S].[DEAL_NUM] = @DEAL_NUM
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
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_RAZREG_TA]'
	end

	return 0;
end 
GO
