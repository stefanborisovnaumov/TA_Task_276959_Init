
/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@Account				sysname
,	@AccCurrency			int
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName
					+', @Account = '''+@Account+''''
					+', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnleneSqlServerName) > 1 AND LEFT(RTRIM(@OnleneSqlServerName),1) <> N'['
		SELECT @OnleneSqlServerName = QUOTENAME(@OnleneSqlServerName)

	IF LEN(@OnleneSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnleneSqlDataBaseName),1) <> N'['
		SELECT @OnleneSqlDataBaseName = QUOTENAME(@OnleneSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnleneSqlServerName +'.'+@OnleneSqlDataBaseName

	/************************************************************************************************************/
	/* 3. Load Tax Uncolected amount by Account from OlineDB */

	select @Sql1 = N'
	declare @Account varchar(64) = '''+@Account+'''
		,	@Account_CCY int = '+str(@AccCurrency,len(@AccCurrency),0)+'
	;
	with TAX_BY_CCY AS 
	(
		select	[T].[ACCOUNT_DT]
			,	[T].[ORIGINAL_CURRENCY]				as [ORIGINAL_CURRENCY]
			,	SUM ( [T].[AMOUNT] )				as [AMOUNT_TOT]
			,	SUM ( [T].[COLLECTED_AMOUNT] )		as [COLLECTED_AMOUNT_TOT]
			,	SUM ( [T].[DDS_AMOUNT] - [T].[DDS_COLLECTED_AMOUNT]
										)			as [DDS_UNCOLLECTED]

			,	COUNT(*)							as [CNT_ITEMS]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = @Account
			and [T].[TAX_STATUS] = 0
		GROUP BY [T].[ACCOUNT_DT], [T].[ORIGINAL_CURRENCY]
	) 
	, [TAX_BY_ACC] AS 
	(
		SELECT	[T].[ACCOUNT_DT] 
			,	SUM(	
						(dbo.TRANS_VAL_TO_VAL_TA([T].[AMOUNT_TOT], [T].[ORIGINAL_CURRENCY], @Account_CCY) - [T].[COLLECTED_AMOUNT_TOT]) 
						+  dbo.TRANS_VAL_TO_VAL_TA([T].[DDS_UNCOLLECTED], 100,  @Account_CCY) 
					) as [TAX_UNCOLLECTED]
			,	SUM([CNT_ITEMS]) AS [CNT_ITEMS]
		FROM TAX_BY_CCY [T]
		GROUP BY [T].[ACCOUNT_DT]
	)
	SELECT	[R].[ACCOUNT_DT]		as [ACCOUNT]
		,	round([R].[TAX_UNCOLLECTED], 4)
									as [TAX_UNCOLLECTED]
		,	[R].[CNT_ITEMS]			as [CNT_ITEMS]
	FROM [TAX_BY_ACC] [R]
	';

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2;
	end catch

	if @LogTraceInfo = 1 select @Sql1 as [LOAD_TAX_UNCOLECTED_BY_ACC];

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Cors Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName
					+', @Account = '''+@Account+''''
					+', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', @Account: ' + @Account
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
go
