
/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
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
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @Account = '''+@Account+''''
					+', @AccCurrency = '+str(@AccCurrency,len(@AccCurrency),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC]'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 2. Prepare Sql Server full database name */
	IF LEN(@OnlineSqlServerName) > 1 AND LEFT(RTRIM(@OnlineSqlServerName),1) <> N'['
		SELECT @OnlineSqlServerName = QUOTENAME(@OnlineSqlServerName)

	IF LEN(@OnlineSqlDataBaseName) > 1 AND LEFT(RTRIM(@OnlineSqlDataBaseName),1) <> N'['
		SELECT @OnlineSqlDataBaseName = QUOTENAME(@OnlineSqlDataBaseName)	

	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName

	/************************************************************************************************************/
	/* 3. Load Tax Uncolected amount by Account from OlineDB */

	select @Sql1 = N'
	declare @Account varchar(64) = '''+@Account+'''
		,	@Account_CCY int = '+str(@AccCurrency,len(@AccCurrency),0)+'
	;
	with TAX_BY_CCY AS 
	(
		select	[T].[ORIGINAL_CURRENCY]									as [CURRENCY_TOT]
			,	SUM ( [T].[AMOUNT] - [T].[COLLECTED_AMOUNT] )			as [TAX_UNCOLLECTED_TOT]
			,	SUM ( [T].[DDS_AMOUNT] - [T].[DDS_COLLECTED_AMOUNT] )	as [DDS_UNCOLLECTED_TOT]
			,	COUNT(*)												as [CNT_ITEMS]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = @Account
			and [T].[TAX_STATUS] = 0
		GROUP BY [T].[ORIGINAL_CURRENCY]
	) 
	, [TAX_BY_ACC] AS 
	(
		SELECT	SUM( dbo.TRANS_CCY_TO_CCY_TA( [T].[TAX_UNCOLLECTED_TOT], [T].[CURRENCY_TOT], @Account_CCY)
				   + dbo.TRANS_CCY_TO_CCY_TA( [T].[DDS_UNCOLLECTED_TOT], 100,  @Account_CCY ) )
									AS [TAX_UNCOLLECTED]
			,	SUM( [CNT_ITEMS] )	AS [CNT_ITEMS]
		FROM TAX_BY_CCY [T]
	)
	SELECT	@Account						as [ACCOUNT]
		,	round([R].[TAX_UNCOLLECTED], 4)	as [TAX_UNCOLLECTED]
		,	[R].[CNT_ITEMS]					as [CNT_ITEMS]
	FROM [TAX_BY_ACC] [R]
	';

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin catch
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
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_TAX_UNCOLECTED_BY_ACC] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
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
