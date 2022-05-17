
/********************************************************************************************************/
/* Процедура за зареждане на Данни за сделка от OnLineDB по номер */
DROP PROCEDURE IF EXISTS dbo.[SP_LOAD_ONLINE_DEAL_DATA]
GO

CREATE PROCEDURE dbo.[SP_LOAD_ONLINE_DEAL_DATA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
,	@DEAL_TYPE INT
,	@DEAL_NUM INT
)
as 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0,	@Sql1 nvarchar(4000) = N''
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 
	begin	
		select @Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,  @Msg =  '*** Begin Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA]'
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
	;
	/************************************************************************************************************/
	/* 3. Load Deals data from OlineDB */

	select @Sql1 = N'
	DECLARE @DealType int = 1 
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;

	select	[REG].[DEAL_NUM]
		,	[REG].[ACCOUNT]
		,	[II].[IBAN]
		,	[BAL].[BEG_SAL]
		,	[BAL].[DAY_MOVE]
		,	[ACC].[BLK_SUMA_MIN]
		,	[BAL].[RAZPOL]
		,	[BAL].[TAX_UNCOLLECTED_SUM]
		,	[BAL].[DISTRAINT_SUM]
	from '+@SqlFullDBName+'.dbo.[RAZPREG] [REG] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[IBAN_IDENT] [II] with(nolock)
		ON	[II].[ID] = [REG].[ACCOUNT]
		AND [II].[IBAN_TYPE] = 0 /* 0 - eIban_Real*/
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		ON [REG].[ACCOUNT] = [ACC].[PART_ID]
	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		ON [DM].[IDENT] = [REG].[ACCOUNT]
	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
		ON [FM].[IDENT] = [REG].[ACCOUNT]
	cross apply (
		SELECT	CASE WHEN [ACC].[PART_TYPE] IN (1,2,5)
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
		select SUM( [T].[AMOUNT] - [T].[COLLECTED_AMOUNT] ) AS [TAX_UNCOLLECTED_SUM]
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		WHERE	[T].[ACCOUNT_DT] = [REG].[ACCOUNT]
			/* AND [T].[DEAL_TYPE]	= @DealType */
			/* AND [T].[DEAL_NUM]	= [REG].[DEAL_NUM] */
			AND [T].[TAX_STATUS] =  0
	) [TAX]
	outer apply (
		SELECT SUM( [B].[SUMA] ) as [DISTRAINT_SUM]
		FROM '+@SqlFullDBName+'.dbo.[BLOCKSUM] [B] with(nolock)
		INNER JOIN '+@SqlFullDBName+'.dbo.[NOMS] [N] with(nolock)
			ON	[N].[NOMID] = 136 
			AND [N].[CODE]	= [B].[WHYFREEZED] 
			AND ([N].[STATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint 
		WHERE [B].[PARTIDA] = [REG].[ACCOUNT] 
	) [DST]
	cross apply (
		SELECT	ROUND([XBAL].[BEG_SAL], 4) AS [BEG_SAL]
			,	ROUND([XBAL].[DAY_MOVE], 4)  AS [DAY_MOVE]
			,	ROUND([XBAL].[BEG_SAL] + [XBAL].[DAY_MOVE] - [ACC].[BLK_SUMA_MIN], 4) AS [RAZPOL]
			,	ROUND(IsNull([DST].[DISTRAINT_SUM],0), 4) as [DISTRAINT_SUM]
			,	ROUND(IsNull([TAX].[TAX_UNCOLLECTED_SUM],0), 4) as [TAX_UNCOLLECTED_SUM]
	) [BAL]
	where [REG].[DEAL_NUM] = '+str(@DEAL_NUM,len(@DEAL_NUM),0);

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch 
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 1;
	end catch

	if @LogTraceInfo = 1 
	begin
		select  @Msg = N'After: Load Deals Data From OnLineDB'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select	@Sql1 = 'dbo.[SP_LOAD_ONLINE_DEAL_DATA] @OnleneSqlServerName ='+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName+', @DEAL_TYPE = 1'+', @DEAL_NUM = '+STR(@DEAL_NUM,LEN( @DEAL_NUM),0)
			,	@Msg = '*** End Execute Proc ***: dbo.[SP_LOAD_ONLINE_DEAL_DATA], Duration: '
					+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + ', DEAL_NUM: ' + str(@DEAL_NUM,len(@DEAL_NUM),0)
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end
	;

	return 0;
end 
GO
