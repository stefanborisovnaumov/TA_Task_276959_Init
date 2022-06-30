
/********************************************************************************************************/
/* Процедура за първоначална инициализация */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
GO

drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS]
GO
drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_INIT_DEALS]
(
	@DB_TYPE				sysname = N'BETA'
,	@TestAutomationType		sysname = N'%BETA%'
,	@LogTraceInfo			int = 0
)
as 
begin
	select @LogTraceInfo = 1
	;

	declare @Sql varchar(max) = N'', @Msg nvarchar(max) = N'', @LogBegEndProc int = 1
		,	@AccountDate varchar(32) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql1 nvarchar(4000) = N'', @Sql2 nvarchar(4000) = N'', @Sql3 nvarchar(4000) = N'', @TimeBeg datetime = GetDate()
	;

	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestAutomationType, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_INIT_DEALS]'
	;


	/************************************************************************************************************/
	/* 0.1. Get Datasources: */
	declare @OnlineSqlServerName sysname = N'',	@OnlineSqlDataBaseName sysname = N'', @DB_ALIAS sysname = N'VCS_OnlineDB'
	;

	exec @Ret = dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE] @DB_TYPE, @DB_ALIAS, @OnlineSqlServerName out, @OnlineSqlDataBaseName out
	if @Ret <> 0
	begin
		select  @Msg = N'Error execute proc, Error code: '+str(@Ret,len(@Ret),0)
					+' ; Result: @OnlineSqlServerName = "'+@OnlineSqlServerName+'", @OnlineSqlDataBaseName = "'+@OnlineSqlDataBaseName+'"'
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return -1;
	end

	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_CASH_PAYMENTS_GET_DATASOURCE], @OnlineSqlServerName: ' +@OnlineSqlServerName+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName+' '
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @DB_TYPE = '
					+ @DB_TYPE  +N', @DB_ALIAS = '+ @DB_ALIAS +N', @OnlineSqlServerName OUT, @OnlineSqlDataBaseName OUT'
		;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end
	
	declare @SqlFullDBName sysname = @OnlineSqlServerName +'.'+@OnlineSqlDataBaseName;

	/************************************************************************************************************/
	/* 0.2. Get Account Date: */
	declare @CurrAccDate datetime = 0
	;

	begin try
		exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] @OnlineSqlServerName, @OnlineSqlDataBaseName, @CurrAccDate OUT
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnlineSqlServerName+N', '+@OnlineSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return -2
	end catch 

	select @Rows = @@ROWCOUNT, @Err = @@ERROR, @AccountDate = ''''+convert( char(10), @CurrAccDate, 120)+'''';
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB], Online Accoun Date: ' +@AccountDate
			,	@Sql1 = N'exec dbo.[SP_SYS_GET_ACCOUNT_DATE_FROM_DB] '+@OnlineSqlServerName+N', '+@OnlineSqlDataBaseName+N', @CurrAccDate OUT'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/************************************************************************************************************/
	/* 1.1. Prepare BASE conditions */
	drop table if exists #TBL_WITH_FILTERS
	;

	select	[PREV].ROW_ID							AS [PREV_ROW_ID]
		,	[PREV].PROXY_ROW_ID						AS [PREV_PROXY_ROW_ID]
		,	[PREV].TA_TYPE							AS [PREV_TA_TYPE]

		,	[CUST].[SECTOR]							AS [CUST_CND_SECTOR]
		,	[DREG].[UI_STD_DOG_CODE]				AS [DEAL_CND_UI_STD_DOG_CODE]
		,	[DREG].[UI_CURRENCY_CODE]				AS [DEAL_CND_UI_CURRENCY_CODE]
		,	[DREG].[UI_INDIVIDUAL_DEAL]				AS [UI_INDIVIDUAL_DEAL]

	into #TBL_WITH_FILTERS
	from dbo.[PREV_COMMON_TA] [PREV] with(nolock)
	inner join dbo.[RAZPREG_TA] [DREG] with(nolock)
		on [PREV].REF_ID = [DREG].ROW_ID
	left join dbo.[DEALS_CORR_TA] [CORS] with(nolock)
		on [CORS].REF_ID = [DREG].ROW_ID
	inner join dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] with(nolock)
		on [DREG].REF_ID = [CUST].ROW_ID
	left join dbo.[PROXY_SPEC_TA] as [PSPEC] with(nolock)
		on [CUST].ROW_ID = [PSPEC].REF_ID
	where [PREV].[TA_TYPE] LIKE @TestAutomationType
		and [PREV].[DB_TYPE] = 'BETA'
	order by [PREV].[ROW_ID]
	;

	select @Rows = @@ROWCOUNT, @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin
		select @Msg = N'After: INSERT into [#TBL_WITH_FILTERS], Rows Affected: '+ str(@Rows,len(@Rows),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestAutomationType, @Msg
	end
	;

	/* 1.2. Prepare deals  */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS]
	;

	set @Sql1 = N'
	declare @DealType int = 1
		,	@DateAcc date = '+@AccountDate+'
	;

	declare @StsDeleted						int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@StsCloased						int	= dbo.SETBIT(cast(0 as binary(4)),  9, 1)
		,	@StsHasIndividualSpecCondPkgs	int = dbo.SETBIT(cast(0 as binary(4)),  5, 1)	/* STS_INDIVIDUAL_SPEC_COND_PKGS (5) */
		,	@StsExcludeFromBankCollection   int = dbo.SETBIT(cast(0 as binary(4)),  8, 1)	/* STS_EXCLUDE_FROM_BANK_COLLECTIONS (8) */
		,	@StsHasOtherTaxAcc				int	= dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* CMN_OTHER_ACCOUNT_FOR_TAX (14) */
		,	@StsIsIndividual				int	= dbo.SETBIT(cast(0 as binary(4)), 16, 1)	/* SD_INDIVIDUAL_DEAL (16) */
		,	@StsNoAutoPayTax				int	= dbo.SETBIT(cast(0 as binary(4)), 29, 1)	/* CMN_NOAUTOTAX (29) */
	;

	declare @StsExtJointDeal				int = dbo.SETBIT(cast(0 as binary(4)),  4, 1)	/* STS_EXT_JOINT_DEAL (4) */
		,	@StsExtCapitOnBaseDateOpen		int = dbo.SETBIT(cast(0 as binary(4)), 14, 1)	/* STS_EXT_CAPIT_ON_BASE_DATE_OPEN (14) */
		,	@StsExtDenyManualTaxAssign		int = dbo.SETBIT(cast(0 as binary(4)), 20, 1)	/* STS_EXT_DENY_MANUAL_TAX_ASSIGN (20)*/
			/* [BLOCKSUM] */
	;
	WITH [X] AS 
	(
		select	[CUST_CND_SECTOR]
			,	[DEAL_CND_UI_CURRENCY_CODE]
			,	count(*) AS CNT
		from #TBL_WITH_FILTERS with(nolock)
		group by [CUST_CND_SECTOR], [DEAL_CND_UI_CURRENCY_CODE]
	)';
	set @Sql2 = N'
	select	/* Deal info: */
			IDENTITY( INT, 1, 1)					AS [ROW_ID]
		,	1										AS [DEAL_TYPE]
		,	[REG].[DEAL_NUM]						AS [DEAL_NUM]
		,	[EXT].[ACCOUNT]							AS [DEAL_ACCOUNT]
		,	[REG].[CURRENCY_CODE]					AS [DEAL_CURRENCY_CODE]
		,	[REG].[STD_DOG_CODE]					AS [DEAL_STD_DOG_CODE]
		,	[REG].[INT_COND_STDCONTRACT]			AS [INT_COND_STDCONTRACT]

		,	[REG].[NM245_CODE]						AS [DEAL_NM245_GROUP_PROGRAM_TYPE_CODE]
		,	[REG].[NM342_CODE]						AS [DEAL_NM342_BUNDLE_PRODUCT_CODE] 
		,	[REG].[JOINT_ACCESS_TO_FUNDS_TYPE]		AS [DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] /* enum JointDealsAccessToFundsType: 0 - Separate; 1 - Always Together */		

		,	[BAL].[BEG_SALDO] 						AS [ACCOUNT_BEG_DAY_BALANCE] /* Begin day saldo  */
		,	[ACC].[BLK_SUMA_MIN]					AS [BLK_SUMA_MIN] /* Block amount for deal */
		,	[BAL].[DAY_SALDO] 						AS [DAY_OPERATION_BALANCE] /* Day operation balance */

			/* Client info: */
		,	[REG].[KL_SECTOR]						AS [CLIENT_SECTOR]
		,	[REG].[CLIENT_CODE]						AS [CLIENT_CODE]
		,	[CLC].[CUSTOMER_ID]						AS [CUSTOMER_ID]

			/* Bits from [STATUS]: */
		,	[STS].[IS_ACTIVE_DEAL]					AS [DEAL_IS_ACTIVE_DEAL]
		,	[STS].[IS_INDIVIDUAL_COND_PKGS]			AS [DEAL_IS_INDIVIDUAL_COND_PKGS]
		,	[STS].[EXCLUDE_FROM_BANK_COLLECTIONS]	AS [DEAL_EXCLUDE_FROM_BANK_COLLECTIONS]
		,	[STS].[IS_INDIVIDUAL_DEAL]				AS [DEAL_IS_INDIVIDUAL_DEAL]
		,	[STS].[HAS_OTHER_TAX_ACC]				AS [DEAL_HAS_OTHER_TAX_ACC]
		,	[STS].[NO_AUTO_PAY_TAX]					AS [DEAL_NO_AUTO_PAY_TAX]

			/* Bits from [STATUS_EXT]: */
		,	[STS].[IS_JOINT_DEAL]					AS [DEAL_IS_JOINT_DEAL]
		,	[STS].[CAPIT_ON_BASE_DATE_OPEN]			AS [DEAL_CAPIT_ON_BASE_DATE_OPEN]
		,	[STS].[IS_DENY_MANUAL_TAX_ASSIGN]		AS [DEAL_IS_DENY_MANUAL_TAX_ASSIGN]

			/* Additional flags */
		,	[EXT].[IS_INDIVIDUAL_COMB]				AS [DEAL_IS_INDIVIDUAL_COMBINATION]

		,	[EX_BITS].*
		,	CAST( 0 AS SMALLINT )					AS [PROXY_COUNT]

	into dbo.[AGR_CASH_PAYMENTS_DEALS]
	from '+@SqlFullDBName+'.dbo.[RAZPREG] [REG] with(nolock) 

	inner join '+@SqlFullDBName+'.dbo.[DT015] [CLC] with(nolock)	
		on  [CLC].[CODE] = [REG].[CLIENT_CODE] 

	inner join '+@SqlFullDBName+'.dbo.[DT008] [CCY] with(nolock) 
		on  [CCY].[CODE] = [REG].[CURRENCY_CODE]

	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock) 
		on  [ACC].[PART_ID] = [REG].[ACCOUNT]

	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		on [DM].[IDENT] = [ACC].[PART_ID]

	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
		on [FM].[IDENT] = [ACC].[PART_ID]

	inner join [X] 
		on  [X].[CUST_CND_SECTOR]			= [REG].[KL_SECTOR]
		and [X].[DEAL_CND_UI_CURRENCY_CODE] = [CCY].[INI]
	';
	set @Sql3 = N' 
	cross apply (
		select	CAST(@DealType AS TINYINT)				AS [DEAL_TYPE]
			,	CAST([REG].[ACCOUNT] AS VARCHAR(33))	AS [ACCOUNT]
				/* Additional flags: */
			,	CAST( [REG].INDIVIDUAL_COMBINATION_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_COMB]
			,	CAST( [REG].INDIVIDUAL_PROGRAM_GS_FLAG AS bit ) 
														AS [IS_INDIVIDUAL_PROG]
	) [EXT]
	cross apply (
		select	CASE WHEN [ACC].[PART_TYPE] IN (1,2,5)
					THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [BEG_SALDO]

			,	CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
					THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
							-	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
								+ IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
							-	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
								+ IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
				END AS [DAY_SALDO] 	
	) [BAL]
	cross apply (
		select 	CAST( 0 AS bit ) 						AS [DEAL_IS_USED]
			,	CAST( 0 AS bit ) 						AS [HAS_TAX_UNCOLECTED]
			,	CAST( 0 AS bit ) 						AS [HAS_OTHER_TAX_ACCOUNT]
			,	CAST( 0 AS bit ) 						AS [HAS_LEGAL_REPRESENTATIVE]
			,	CAST( 0 AS bit ) 						AS [HAS_PROXY]
			,	CAST( 0 AS bit ) 						AS [HAS_DISTRAINT]
			,	CAST( 0 AS bit ) 						AS [HAS_GS_INDIVIDUAL_PROGRAMME]
			,	CAST( 0 AS bit ) 						AS [HAS_WNOS_BEL]
			,	CAST( 0 AS bit ) 						AS [HAS_NAR_RAZP]
			,	CAST( 0 AS bit ) 						AS [IS_DORMUNT_ACCOUNT]
	) [EX_BITS]
	cross apply (
		select	/* Bits from [STATUS]: */
				CAST(CASE WHEN ([REG].[STATUS] & @StsCloased) <> @StsCloased THEN 1 ELSE 0 END AS BIT)
										AS [IS_ACTIVE_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasIndividualSpecCondPkgs) = @StsHasIndividualSpecCondPkgs THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_COND_PKGS]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsExcludeFromBankCollection) = @StsExcludeFromBankCollection THEN 1 ELSE 0 END AS BIT)
										AS [EXCLUDE_FROM_BANK_COLLECTIONS]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsHasOtherTaxAcc) = @StsHasOtherTaxAcc THEN 1 ELSE 0 END AS BIT)
										AS [HAS_OTHER_TAX_ACC]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsIsIndividual) = @StsIsIndividual THEN 1 ELSE 0 END AS BIT)
										AS [IS_INDIVIDUAL_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS] & @StsNoAutoPayTax) = @StsNoAutoPayTax THEN 1 ELSE 0 END AS BIT)
										AS [NO_AUTO_PAY_TAX]

				/* Bits from [STATUS_EXT]: */
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtJointDeal) = @StsExtJointDeal THEN 1 ELSE 0 END AS BIT)
										AS [IS_JOINT_DEAL]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtCapitOnBaseDateOpen) = @StsExtCapitOnBaseDateOpen THEN 1 ELSE 0 END AS BIT)
										AS [CAPIT_ON_BASE_DATE_OPEN]
			,	CAST(CASE WHEN ([REG].[STATUS_EXT] & @StsExtDenyManualTaxAssign) = @StsExtDenyManualTaxAssign THEN 1 ELSE 0 END AS BIT)
										AS [IS_DENY_MANUAL_TAX_ASSIGN]
	) [STS]
	WHERE	([REG].[STATUS] & @StsDeleted) <> @StsDeleted
		and ([REG].[STATUS] & @StsCloased) <> @StsCloased'
	;

	begin try
		execute( @Sql1 + @Sql2 + @Sql3 );
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO(), @Sql = @Sql1 + @Sql2 + @Sql3;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
		return 1
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1 
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS], Rows affected: ' + str(@Rows,len(@Rows),0), @Sql = @Sql1 + @Sql2 + @Sql3
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
	end
	;

	/* 1.2.1 Add Indexes on dbo.[AGR_CASH_PAYMENTS_DEALS] */
	alter table dbo.[AGR_CASH_PAYMENTS_DEALS]
		add constraint [PK_AGR_CASH_PAYMENTS_DEALS] 
			primary key clustered ( [ROW_ID] )
	;

	create index IX_AGR_CASH_PAYMENTS_DEALS_DEAL_NUM_DEAL_TYPE
		on dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_NUM], [DEAL_TYPE] )
	;

	create index IX_AGR_CASH_PAYMENTS_DEALS_DEAL_ACCOUNT
		on dbo.[AGR_CASH_PAYMENTS_DEALS] ( [DEAL_ACCOUNT] )
	;	

	/* 1.3. Prepare TAX UNCOLECTED  */
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	;

	select @Sql1 = N';
	declare @DealType int = 1
		,	@TaxActive int = 0 /* enum eTaxUncollectedStatus: eTaxActive = 1*/
	;

	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED]
	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	from DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	where EXISTS (
		select	*
		from '+@SqlFullDBName+'.dbo.[TAX_UNCOLLECTED] [T] with(nolock)
		WHERE	[T].[DEAL_TYPE]		= @DealType
			and [T].[DEAL_NUM]		= [REG].[DEAL_NUM]
			and [T].[TAX_STATUS]	= @TaxActive 
	)'
	;
	
	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.4. Prepare Deal with Other Tax Account */
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	;

	select @Sql1 = N';
	declare @DealType int = 1
		,	@CorreCapitAccount int = 1 /* eCapitAccount (1) */
		,	@CorrTaxServices int = 3 /* eTaxServices (3) */
	;

	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT]
	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]
		,	[C].[CORR_ACCOUNT]
		,	[ACC].[PART_CURRENCY]
		,	[BAL].[ACCOUNT_BEG_DAY_BALANCE]
		,	[ACC].[BLK_SUMA_MIN]
		,	[BAL].[DAY_SALDO] 				AS [DAY_OPERATION_BALANCE] /* Day operation balance */

	from DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[DEALS_CORR] [C] with(nolock)
		on  [C].[CORR_TYPE]		= @CorrTaxServices
		and	[C].[DEAL_TYPE]		= @DealType
		and [C].[DEAL_NUMBER]	= [REG].[DEAL_NUM]
	inner join '+@SqlFullDBName+'.dbo.[PARTS] [ACC] with(nolock)
		on  [ACC].[PART_ID]	= [C].[CORR_ACCOUNT]
	left outer join '+@SqlFullDBName+'.dbo.[DAY_MOVEMENTS] [DM] with(nolock)
		on [DM].[IDENT] = [ACC].[PART_ID]
	left outer join '+@SqlFullDBName+'.dbo.[FUTURE_MOVEMENTS] [FM] with(nolock)
		on [FM].[IDENT] = [ACC].[PART_ID]	
	cross apply (
		select CASE WHEN [ACC].[PART_TYPE] IN ( 1, 2, 5 )
					THEN [ACC].[BDAY_CURRENCY_DT] - [ACC].[BDAY_CURRENCY_KT]
					ELSE [ACC].[BDAY_CURRENCY_KT] - [ACC].[BDAY_CURRENCY_DT] 
				END AS [ACCOUNT_BEG_DAY_BALANCE]

			,	CASE WHEN [ACC].[PART_TYPE] IN (1,2, 5)
					THEN IsNull([DM].[VP_DBT], 0) - IsNull([DM].[VP_KRT], 0)
							-	( IsNull(-[DM].[VNR_DBT], 0) + IsNull(-[FM].[VNR_DBT], 0) 
								+ IsNull( [DM].[VNB_KRT], 0) + IsNull( [FM].[VNB_KRT], 0) )

					ELSE IsNull([DM].[VP_KRT], 0) - IsNull([DM].[VP_DBT], 0)
							-	( IsNull(-[DM].[VNR_KRT], 0) + IsNull(-[FM].[VNR_KRT], 0) 
								+ IsNull( [DM].[VNB_DBT], 0) + IsNull( [FM].[VNB_DBT], 0) )
				END AS [DAY_SALDO]
	) [BAL]
	';

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.5. Prepare Deal with Group Sales INDIVIDUAL PROGRAMME */
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]
	;

	select @Sql1 = N';
	declare @DealType int = 1
		,	@GSActive int = 1 /* enum eGS_STATUS: GSActive = 1 */
	;
	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME]	
	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]	
		,	[GSI].[PROGRAMME_CODE]					AS [DEAL_GS_INDIVIDUAL_PROGRAM_CODE]
		,	[GSI].[PRODUCT_CODE]					AS [DEAL_GS_INDIVIDUAL_PRODUCT_CODE]
		,	[GSI].[CARD_PRODUCT]					AS [DEAL_GS_INDIVIDUAL_CARD_PRODUCT]

	from DBO.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[GS_INDIVIDUAL_PROGRAMME] [GSI] with(nolock)
		on  [GSI].[DEAL_TYPE]		= @DealType
		and [GSI].[DEAL_NUMBER]		= [REG].[DEAL_NUM]
		and [GSI].[ACTIVITY_STATUS] = @GSActive
	';

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.6. Prepare Deal with WNOS BEL*/
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL]
	;

	select @Sql1 = N';
	declare @DealType 	int = 1
		,	@CurrDate	date = GetDate()
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@REG_VNOS_BEL_BIS6 int = 63 /* #define REG_VNOS_BEL_BIS6 63 */
	;

	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] ( [DEAL_TYPE], [DEAL_NUM] )
	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	where EXISTS (
		select	*
		from '+@SqlFullDBName+'.dbo.[TRAITEMS_DAY] [T] with(nolock)
		WHERE	[T].[DEAL_NUM]	= [REG].[DEAL_NUM]
			and [T].[DEAL_TYPE] = @DealType
			and	[T].[SUM_OPER] > 0
			and [T].[SYS_DATE] >= @CurrDate
			and [T].[REG_CODE_DEF] = @REG_VNOS_BEL_BIS6
			and ([T].[STATUS] & @StsDeleted) <> @StsDeleted
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.7. Prepare Deal with Distraint */
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT]
	;

	select @Sql1 = N';
	declare @StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)), 0, 1) 
		,	@StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1)	/* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	declare @Tbl_Distraint_Codes TABLE ( [CODE] INT )
	;

	insert into @Tbl_Distraint_Codes
	SELECT [n].[CODE]
	from '+@SqlFullDBName+'.dbo.[NOMS] [n] with(nolock)
	where	[n].[NOMID] = 136
		and ([n].[sTATUS] & @StsBlockReasonDistraint) = @StsBlockReasonDistraint
	;

	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] 
	select	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 

	from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock) 
	where EXISTS ( 
		select TOP (1) *  
		from '+@SqlFullDBName+'.dbo.BLOCKSUM [B] with(nolock) 
		inner join @Tbl_Distraint_Codes [N]
			on	[N].[CODE]	= [B].[WHYFREEZED] 
		WHERE	[B].[PARTIDA] = [REG].[DEAL_ACCOUNT]
			and [B].[SUMA] > 0.0
			and [B].[CLOSED_FROZEN_SUM] = 0
	)'
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 1.8. Prepare Deal with DORMUNT ACCOUNT */
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT]
	;

	select @Sql1 = N';
	declare @DealType 	int = 1
		,	@StsPART_IsSleepy int = dbo.SETBIT(cast(0 as binary(4)), 22, 1)	/* #define PART_IsSleepy (22) // Партидата е спяща(замразена) */
	;

	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] 
	select	[REG].[DEAL_TYPE] 
		,	[REG].[DEAL_NUM] 
	
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock) 
	where EXISTS ( 
		select TOP (1) * 
		from '+@SqlFullDBName+'.dbo.[PARTS] [P] with(nolock) 
		WHERE	[P].[PART_ID] = [REG].[DEAL_ACCOUNT] 
			and ([P].[STATUS] & @StsPART_IsSleepy) = @StsPART_IsSleepy 		
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end	

	/* 1.9. Prepare Deals Legal representative */
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]
	;

	select @Sql1 = N';
	declare @DealType int = 1 /* Razp deals */
		,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;

	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE]	
	select	[D].[DEAL_TYPE]
		,	[D].[DEAL_NUM]
		,	[CRL].[REPRESENTED_CUSTOMER_ID] 
		,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
		,	[CRL].[CUSTOMER_ROLE_TYPE] 

	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] with(nolock) 
		on  [CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1									/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] in ( 1 )						/* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1 						/* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	where ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated	/* STS_LIMIT_DEACTIVATED 12 (Деактивиран) */
	';

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 1.10. Prepare Deals Active Proxy Customers */
	drop table if exists dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	;

	select @Sql1 = N'; 
	declare @DealType int = 1 /* Razp deals 1 */
	,	@DateAcc date = '+@AccountDate+'
	,	@StsDeActivated int	= dbo.SETBIT(cast(0 as binary(4)), 12, 1)	/* #define STS_LIMIT_DEACTIVATED 12 (DeActivated) */
	;
	select	[D].[DEAL_TYPE]
		,	[D].[DEAL_NUM]
		,	[CRL].[REPRESENTATIVE_CUSTOMER_ID] 
		,	[CRL].[CUSTOMER_ROLE_TYPE]

	into dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS]
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[CUSTOMERS_RIGHTS_AND_LIMITS] [CRL] with(nolock) 
		on  [CRL].[DEAL_TYPE]	= @DealType 
		AND	[CRL].[DEAL_NUM]	= [D].[DEAL_NUM] 
		AND	[CRL].[CHANNEL]		= 1					/* NM455 (Chanels) : 1 Основна банкова система, ... */
		AND	[CRL].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 )	/* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
		AND	[CRL].[CUSTOMER_ACCESS_RIGHT] = 1		/* NM620 (Type Rights): 1 - Вноска, 2 - Теглене, ... */
	where  ( [CRL].[STATUS] & @StsDeActivated ) <> @StsDeActivated 
	and exists
	(
		select * 
		from '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] with(nolock)
		inner join '+@SqlFullDBName+'.dbo.[REPRESENTATIVE_DOCUMENTS] [D] with(nolock)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
		where	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
			and [PS].[CUSTOMER_ROLE_TYPE]		  = [CRL].[CUSTOMER_ROLE_TYPE] 
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] > @DateAcc )
	)'
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 1.11. Prepare Deal with NAR RAZP*/
	truncate table dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP]
	;

	select @Sql1 = N';
	declare @DealType 	int = 1
		,	@CurrDate	date = GetDate()
		,	@StsDeleted	int = dbo.SETBIT(cast(0 as binary(4)),  0, 1)
		,	@REG_NAR_RAZSP_BIS6 int = 63 /* #define REG_NAR_RAZSP_BIS6 64 */		
	;

	insert into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP] ( [DEAL_TYPE], [DEAL_NUM] )
	select	[REG].[DEAL_TYPE]
		,	[REG].[DEAL_NUM]

	from dbo.[AGR_CASH_PAYMENTS_DEALS] [REG] with(nolock)
	where EXISTS (
		select	*
		from '+@SqlFullDBName+'.dbo.[TRAITEMS_DAY] [T] with(nolock)
		WHERE	[T].[DEAL_NUM]	= [REG].[DEAL_NUM]
			and [T].[DEAL_TYPE] = @DealType
			and	[T].[SUM_OPER] > 0
			and [T].[SYS_DATE] >= @CurrDate
			and [T].[REG_CODE_DEF] = @REG_NAR_RAZSP_BIS6
			and ([T].[STATUS] & @StsDeleted) <> @StsDeleted
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 2
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/**************************************************************/
	/* 2. Prepare Customers data */

	/* 2.1 Prepare all duplicate customers EGFN */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]
	;	

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] 
	select  CAST(RIGHT(RTRIM([C].[IDENTIFIER]), 13) AS BIGINT) AS [EGFN]

	from '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] WITH (NOLOCK)
	where ISNUMERIC( [C].[IDENTIFIER] ) = 1 
	group by CAST( RIGHT( RTRIM( [C].[IDENTIFIER] ), 13) AS BIGINT) 
	HAVING COUNT(*) > 1 '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 3
	end catch 

	select @Rows = (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN]  Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg;
	end

	/* 2.2 Prepare Customers data */	
	drop table if exists dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	;

	set @Sql1 = N'
	;
	WITH [CTE_CUST_ID] AS 
	(
		select [A].[CUSTOMER_ID]
		from 
		(
			select DISTINCT [CUSTOMER_ID]
			from dbo.[AGR_CASH_PAYMENTS_DEALS] with(nolock)	
			UNION ALL 
			select DISTINCT ]REPRESENTATIVE_CUSTOMER_ID]
			from dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] with(nolock)
		) [A]
		group by [CUSTOMER_ID]
	)
	select 	IDENTITY( INT, 1, 1) 					AS [ROW_ID] 
		,	[C].[CUSTOMER_ID]						AS [CUSTOMER_ID]
		,	[M].[CL_CODE]							AS [CLIENT_CODE_MAIN]
		,	RTRIM([C].[IDENTIFIER])					AS [CLIENT_IDENTIFIER]
		,	[C].[IDENTIFIER_TYPE]					AS [CLIENT_IDENTIFIER_TYPE]
		,	[C].[ECONOMIC_SECTOR]					AS [CLIENT_SECTOR]		
		,	[C].[CLIENT_TYPE]						AS [CLIENT_TYPE_DT300_CODE]
		,	[C].[BIRTH_DATE]						AS [CLIENT_BIRTH_DATE]
		,	[TYP].[CUSTOMER_CHARACTERISTIC]			AS [CUSTOMER_CHARACTERISTIC]
		,	[TYP].[IS_FUNCTIONAL_ID]				AS [IS_FUNCTIONAL_ID]
		,	[TYP].[IS_PHISICAL_PERSON]				AS [IS_PHISICAL_PERSON]
		,	[EX_BITS].*
	into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS]
	from [CTE_CUST_ID] [F] with(nolock)
	inner join '+@SqlFullDBName+'.dbo.[DT015_CUSTOMERS] [C] with(nolock)
		on  [F].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	inner join '+@SqlFullDBName+'.dbo.[DT015_MAINCODE_CUSTID] [M] with(nolock)
		on  [M].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
	cross apply (
		select	CAST( CASE WHEN [C].[IDENTIFIER_TYPE] IN (5,6,7,8) THEN 1 ELSE 0 END AS BIT)
												AS [IS_FUNCTIONAL_ID]
			,	CAST( CASE WHEN [C].[CUSTOMER_TYPE] = 1 THEN 1 ELSE 0 END AS BIT)  
												AS [IS_PHISICAL_PERSON]
			,	CAST( [C].[CUSTOMER_CHARACTERISTIC] as TINYINT )
												AS [CUSTOMER_CHARACTERISTIC]
	) [TYP] 
	cross apply (
		select	CAST ( 0 AS BIT )				AS [HAS_MANY_CLIENT_CODES]
			,	CAST ( 0 AS BIT )				AS [HAS_DUBL_CLIENT_IDS]
			,	CAST ( 0 AS BIT )				AS [IS_PROXY]
			,	CAST ( 0 AS BIT )				AS [HAS_LOAN]
			,	CAST ( 0 AS BIT )				AS [HAS_VALID_DOCUMENT]
			,	CAST ( 1 AS BIT )				AS [IS_ORIGINAL_EGFN]
			,	CAST ( 0 AS BIT )				AS [HAS_ZAPOR]
			,	CAST ( 0 AS BIT )				AS [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC]			
	) [EX_BITS]
	'
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.2.1 Create Indexes on [AGR_CASH_PAYMENTS_CUSTOMERS] */
	create index IX_AGR_CASH_PAYMENTS_CUSTOMERS_CUSTOMER_ID
		on dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] ( [CUSTOMER_ID] )
	;	

	/* 2.3 Prepare Customers with many client codes  */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES]	
	select	[CUST].[CUSTOMER_ID]

	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] with(nolock)
	where EXISTS 
	(
		select [CC].[CUSTOMER_ID] 
		from '+@SqlFullDBName+'.dbo.[DT015] [CC] with(nolock)
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
		group by [CC].[CUSTOMER_ID] 
		HAVING COUNT(*) > 1
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.4 Prepare Customers with Dubl EGFN  */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN]	
	select	[C].[CUSTOMER_ID]
		,	[X].[IS_ORIGINAL_EGFN]

	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] with(nolock)
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_DUBL_EGFN] [DUBL] with(nolock)
		on [DUBL].[EGFN] = CAST(RIGHT(RTRIM([C].[CLIENT_IDENTIFIER]), 13) AS BIGINT)
	cross apply (
		select CAST( CASE WHEN [DUBL].[EGFN] = CAST( [C].[CLIENT_IDENTIFIER] AS BIGINT )
					THEN 1 ELSE 0 END AS BIT)	AS [IS_ORIGINAL_EGFN]
	) [X]'
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.5 Prepare Customers are proxies */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES]	
	select	[C].[CUSTOMER_ID]

	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] with(nolock)
	where EXISTS 
	(
		select *
		from '+@SqlFullDBName+'.dbo.[PROXY_SPEC] [PS] with(nolock)
		WHERE	[PS].[REPRESENTATIVE_CUSTOMER_ID] = [C].[CUSTOMER_ID]
			and [PS].[REPRESENTED_CUSTOMER_ID] <> [C].[CUSTOMER_ID]
			and [PS].[CUSTOMER_ROLE_TYPE] IN ( 2, 3 )  /* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/* 2.6 Prepare Customers with valid IDENTITY DOCUMENTS */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	;

	set @Sql1 = N'
	declare @DateAcc date = '+@AccountDate+'
	;

	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS]
	select	[C].[CUSTOMER_ID]

	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [C] with(nolock)
	where EXISTS 
	(
		select *
		from '+@SqlFullDBName+'.dbo.[DT015_IDENTITY_DOCUMENTS] [D] with(nolock)
		WHERE	[D].[CUSTOMER_ID] = [C].[CUSTOMER_ID]
			and [D].[NM405_DOCUMENT_TYPE] IN ( 1, 7, 8  )  /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
			and ( [D].[INDEFINITELY] = 1 OR [D].[EXPIRY_DATE] > @DateAcc )
			and [D].[ISSUER_COUNTRY_CODE] > 0
			and [D].[ISSUE_DATE] > ''1970-12-31''
			and len([D].[ISSUER_NAME]) > 0
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end	

	/* 2.7 Prepare Customers with Active Loas */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]
	;

	select @Sql1 = N';
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS]	
	select	[CUST].[CUSTOMER_ID]

	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] with(nolock)
	where EXISTS 
	(
		select *
		from '+@SqlFullDBName+'.dbo.[KRDREG] [L] with(nolock)
		inner join '+@SqlFullDBName+'.dbo.[DT015] [CC] with(nolock)
			on [L].[CLIENT_CODE] =  [CC].[CODE]
		WHERE	[CC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [L].[DATE_END_KREDIT] < 2 /* Is active loan */
	) '
	;

	begin try
		exec sp_executeSql @Sql1
	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 4
	end catch 

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: select * into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 2.8 Prepare Customers with Distraint */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT]
	;
	
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] ( [CUSTOMER_ID] )
	exec @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_DISTRAINT] @OnlineSqlServerName, @OnlineSqlDataBaseName

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 2.9 Prepare Customers with Uncollected tax connected to all customer accounts */
	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS]
	;
	
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] ( [CUSTOMER_ID] )
	exec @Ret = dbo.[SP_LOAD_ONLINE_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] @OnlineSqlServerName, @OnlineSqlDataBaseName

	select @Rows =  (select count(*) from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS], Rows affected: ' + str(@Rows,len(@Rows),0);
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 3. update customers: */
	update [D]
	set [HAS_MANY_CLIENT_CODES] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D] 
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_MANY_CLIENT_CODES] [S] with(nolock)
		on [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	update [D]
	set [HAS_DUBL_CLIENT_IDS] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		on [S].CUSTOMER_ID = [D].CUSTOMER_ID
	;

	update [D]
	set [HAS_LOAN] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_LOANS] [S] with(nolock)
		on [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [IS_PROXY] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_ARE_PROXIES] [S] with(nolock)
		on [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [HAS_VALID_DOCUMENT] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_VALID_IDENTITY_DOCUMENTS] [S] with(nolock)
		on [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [IS_ORIGINAL_EGFN] = 0
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DUBL_EGFN] [S] with(nolock)
		on  [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
		and [S].[IS_ORIGINAL_EGFN] = 0
	;

	update [D]
	set [HAS_ZAPOR] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_DISTRAINT] [S] with(nolock)
		on  [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	update [D]
	set [HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC] = 1
	from dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_WITH_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACCOUNTS] [S] with(nolock)
		on  [S].[CUSTOMER_ID] = [D].[CUSTOMER_ID]
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: update bist in [AGR_CASH_PAYMENTS_CUSTOMERS]', @Sql1 = ' update [AGR_CASH_PAYMENTS_CUSTOMERS] set ...' 
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 5. update deals: */
	update [D]
	set [HAS_TAX_UNCOLECTED] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_TAX_UNCOLECTED] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_OTHER_TAX_ACCOUNT] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_LEGAL_REPRESENTATIVE] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_LEGAL_REPRESENTATIVE] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_PROXY] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_DISTRAINT] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DISTRAINT] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_GS_INDIVIDUAL_PROGRAMME] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_WNOS_BEL] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_WNOS_BEL] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [HAS_NAR_RAZP] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_NAR_RAZP] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [IS_DORMUNT_ACCOUNT] = 1
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_DORMUNT_ACCOUNT] [S] with(nolock)
		on [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [S].[DEAL_TYPE] = 1
	;

	update [D]
	set [PROXY_COUNT] = [S].[CNT]
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [D]
	inner join 
	(
		select [P].[DEAL_NUM], COUNT(*) AS [CNT]
		from dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [P] with(nolock)
		where [P].[DEAL_TYPE] = 1
		group by [P].[DEAL_NUM]
	) [S]
		on  [S].[DEAL_NUM] = [D].[DEAL_NUM]
		and [D].[DEAL_TYPE] = 1
	;

	truncate table dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
	;
	insert into dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY]
	( [CUSTOMER_ID], [DEAL_TYPE], [CURRENCY_CODE], [DEAL_COUNT] )
	select  [s].[CUSTOMER_ID]			AS [CUSTOMER_ID]
		,	1 							AS [DEAL_TYPE]	
		,	[s].[DEAL_CURRENCY_CODE]	AS [CURRENCY_CODE] 
		,	COUNT(*) 					AS [DEAL_COUNT]
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [s] with(nolock)
	group by [s].[CUSTOMER_ID], [s].[DEAL_CURRENCY_CODE]
	/* having count(*) > 1 */
	;

	/****** Object:  Index [IX_AGR_CASH_PAYMENTS_DEALS_DEAL_CURRENCY_CODE_DEAL_STD_DOG_CODE_CLIENT_SECTOR_DEAL_IS_JOINT_DEAL]    Script Date: 29.06.2022 г. 15:07:23 ******/
	CREATE NONCLUSTERED INDEX [IX_AGR_CASH_PAYMENTS_DEALS_DEAL_CURRENCY_CODE_DEAL_STD_DOG_CODE_CLIENT_SECTOR_DEAL_IS_JOINT_DEAL] 
	ON [dbo].[AGR_CASH_PAYMENTS_DEALS]
	(
		[DEAL_CURRENCY_CODE] ASC
	,	[DEAL_STD_DOG_CODE] ASC
	,	[CLIENT_SECTOR] ASC
	,	[DEAL_IS_JOINT_DEAL] ASC
	,	[HAS_WNOS_BEL] ASC
	,	[IS_DORMUNT_ACCOUNT] ASC
	)
	INCLUDE([DEAL_TYPE],[DEAL_NUM],[DEAL_ACCOUNT],[CUSTOMER_ID]) 
	;

	CREATE NONCLUSTERED INDEX [IX_AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS_DEAL_TYPE_DEAL_NUM_CUSTOMER_ROLE_TYPE]
		ON [dbo].[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] ( [DEAL_TYPE], [DEAL_NUM], [CUSTOMER_ROLE_TYPE] )
	INCLUDE ( [REPRESENTATIVE_CUSTOMER_ID] )
	;

	if @LogTraceInfo = 1
	begin 
		select  @Msg = N'After: update bist in [AGR_CASH_PAYMENTS_DEALS]', @Sql1 = N' update [AGR_CASH_PAYMENTS_DEALS] set [HAS_VALID_DOCUMENT] = 1 where ...'
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
	end

	/**************************************************************/
	/* 6. Log end procedure: */
	if @LogBegEndProc = 1
	begin
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', AccData: ' + @AccountDate + ', Fileter: ' + @TestAutomationType;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_INIT_DEALS]'
	end

	return 0;
end
go

