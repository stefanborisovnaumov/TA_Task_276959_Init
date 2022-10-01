/********************************************************************************************************/
/* Процедура за зареждане на Данни за Кореспонденция от OnLineDB по сделка по номер и кореспондираща партида */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@DEAL_NUM				int
,	@CORS_ACCOUNT_TYPE		int
,	@CORS_ACCOUNT			varchar(33)
)
AS 
BEGIN

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0, @Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1.Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
					+', @CORS_ACCOUNT_TYPE = '+str(@CORS_ACCOUNT_TYPE,len(@CORS_ACCOUNT_TYPE),0)
					+', @CORS_ACCOUNT = '''+@CORS_ACCOUNT+''''
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA]'
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
	;
	/************************************************************************************************************/
	/* 3. Load Deal Corrs data from OlineDB */
	;
	select @Sql1 = N'
	DECLARE @DealType int = 1 
		,	@CorrAccType int = '+str(@CORS_ACCOUNT_TYPE, len(@CORS_ACCOUNT_TYPE),0)+'
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	select	[CORR].[DEAL_TYPE]			AS [DEAL_TYPE]
		,	[CORR].[DEAL_NUMBER]		AS [DEAL_NUMBER]
		,	[CORR].[CORR_TYPE]			AS [CORR_TYPE]		
		,	[ACC].[DEAL_TYPE]			AS [CORR_DEAL_TYPE]
		,	[ACC].[DEAL_NUMBER]			AS [CORR_DEAL_NUMBER]
		,	[CORR].[CORR_ACCOUNT]		AS [CORR_ACCOUNT]
		,	[CCY].[INI]					AS [CORR_ACCOUNT_CCY]
		,	[ACC].[PART_CURRENCY]		AS [CORR_ACC_CCY_CODE]
		,	[ACC].[BLK_SUMA_MIN]		AS [BLK_SUMA_MIN]
		,	[BAL].[AVAILABLE_BAL]		AS [AVAILABLE_BAL]
		,	[BAL].[TAX_UNCOLLECTED_SUM]	AS [TAX_UNCOLLECTED_SUM]
		,	[BAL].[HAS_TAX_UNCOLLECTED]	AS [HAS_TAX_UNCOLLECTED]

	from '+@SqlFullDBName+'.dbo.[DEALS_CORR] [CORR] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC]
		on [ACC].[PART_ID] = [CORR].[CORR_ACCOUNT]
	inner join '+@SqlFullDBName+'.dbo.[DT008] [CCY] with(nolock)
		on	[CCY].[CODE] = [ACC].[PART_CURRENCY]
	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		on [DM].[IDENT] = [CORR].[CORR_ACCOUNT]
	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
		on [FM].[IDENT] = [CORR].[CORR_ACCOUNT]
	cross apply (
		select	CASE WHEN [ACC].[PART_TYPE] IN (1,2,5)
					THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [BEG_SAL]

			,	CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
					THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
							-	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
								+ IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
							-	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
								+ IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
				END AS [DAY_MOVE]
	) [XBAL]
	outer apply 
	(
		select top (1) cast(1 as bit) as [HAS_TAX_UNCOLLECTED]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		where	[T].[ACCOUNT_DT] = [CORR].[CORR_ACCOUNT]
			and [T].[TAX_STATUS] =  0
	) [TAX]
	outer apply (
		select SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
		from '+@SqlFullDBName+'.dbo.[BLOCKSUM] [B] with(nolock)
		inner join '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock)
			on	[N].[NOMID] = 136 
			and [N].[CODE]	= [B].[WHYFREEZED] 
			and([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
		where [B].[PARTIDA] = [CORR].[CORR_ACCOUNT] AND [B].[CLOSED_FROZEN_SUM] = 0
	) [DST]
	cross apply (
		select	ROUND([XBAL].[BEG_SAL], 4)					as [BEG_SAL]
			,	ROUND([XBAL].[DAY_MOVE], 4)					as [DAY_MOVE]
			,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [AVAILABLE_BAL]
			,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4)	as [DISTRAINT_SUM]
			,	ROUND(cast(0 as float), 4)					as [TAX_UNCOLLECTED_SUM]
			,	IsNull([TAX].[HAS_TAX_UNCOLLECTED], 0)		as [HAS_TAX_UNCOLLECTED]
	) [BAL]
	where [CORR].[DEAL_TYPE]		= @DealType
		and [CORR].[DEAL_NUMBER]	= '+str(@DEAL_NUM,len(@DEAL_NUM), 0)+'
		and [CORR].[CORR_TYPE]		= @CorrAccType
		and [CORR].[CORR_ACCOUNT]	= '''+@CORS_ACCOUNT+'''
	';

	if @LogTraceInfo = 1 select @Sql1 as [LOAD_ONLINE_CORS_INFO];

	begin try
		exec @Ret = sp_executeSql @Sql1
	end try
	begin CATCH 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Cors Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA] @OnlineSqlServerName ='+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @DEAL_NUM = '+str(@DEAL_NUM,len(@DEAL_NUM),0)
					+', @CORS_ACCOUNT_TYPE = '+str(@CORS_ACCOUNT_TYPE,len(@CORS_ACCOUNT_TYPE),0)
					+', @CORS_ACCOUNT = '''+@CORS_ACCOUNT+''''
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_CORS_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	return 0;
end 
go

