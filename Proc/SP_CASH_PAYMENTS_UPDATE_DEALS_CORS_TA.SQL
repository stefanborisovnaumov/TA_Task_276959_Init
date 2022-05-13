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

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql2 nvarchar(4000) = N'',	@TA_RowID int = cast( @TestCaseRowID as int)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_DEALS_CORS_TA]'
	;

	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(@OnleneSqlServerName,1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(@OnleneSqlDataBaseName,1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)		

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName
	;
	/************************************************************************************************************/
	-- TODO: UPDATE [DEALS_CORS_TA] 
	declare @TBL_ROW_ID int = 0, @DealRowID int = 0
		,	@CorrAccount varchar(64), @CorrAccCurrency varchar(8) = 'BGL'
	;
	select	@DealRowID = [DEAL_ROW_ID]
		,	 @TBL_ROW_ID = [CORS_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@TBL_ROW_ID,0) <= 0
	begin  
		select @Msg = 'Not found correspondence from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 0;
	end 

	;
	with [CTE_CCY] as 
	(
		select [X].*
		from ( 
			values	( 36,	'AUD' )	,	(100,	'BGN' )	,	(124,	'CAD' )	,	(756,	'CHF' )
				,	(826,	'GBP' )	,	(840,	'USD' )	,	(946,	'RON' )	,	(978,	'EUR' )
		) X([ID], [NAME])		
	)
	select	@CorrAccount = [CORR_ACCOUNT]
		,	@CorrAccCurrency = IsNull([CCY].[NAME], 'BGN')
	from [dbo].[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [C] with(nolock)
	OUTER APPLY( 
		select [NM].*
		from [CTE_CCY] [NM]
		where [NM].[ID] = [C].[PART_CURRENCY]
	) [CCY]
	where [DEAL_TYPE] = 1 AND [DEAL_NUM] = @DEAL_NUM
	;

	select @DEAL_NUM as [DEAL_NUM], 0 as [TAX_UNCOLLECTED], @CorrAccCurrency as [CCY], @CorrAccount as [ACC], @DealRowID as [DEAL_ROW_ID]
	;
	SELECT [DEAL_NUM], [TAX_UNCOLLECTED_SUM], [CURRENCY], [UI_CORR_ACCOUNT], [ROW_ID]
	FROM dbo.[DEALS_CORR_TA] [D]
	WHERE [D].[ROW_ID] = @TBL_ROW_ID
	;

	/* Update data in table [DEALS_CORR_TA] */
	if @WithUpdate = 1
	begin
		UPDATE [D]
		SET [DEAL_NUM]				= @DEAL_NUM			-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
		,	[CURRENCY]				= @CorrAccCurrency	-- DEALS_CORR_TA	CURRENCY	
		,	[UI_CORR_ACCOUNT]		= @CorrAccount		-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
		,	[TAX_UNCOLLECTED_SUM]	= 0					-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 
--		,	[DEAL_ROW_ID] =  @DealRowID					-- /* Това ще ви трябва ли */
		from dbo.[DEALS_CORR_TA] [D]
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
