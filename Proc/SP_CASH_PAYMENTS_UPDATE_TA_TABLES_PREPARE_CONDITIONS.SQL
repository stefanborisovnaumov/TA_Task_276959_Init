
/********************************************************************************************************/
/* Процедура формираща SQL заявката за търсене на подходяща сделка по ID на тестови случай */
/* 2022/06/98 - v2.6.3 -> търсена на подходящи сделките за навързаните документи се извършва само за първия тестови случай */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]
(
	@TestCaseRowID nvarchar(16)
,	@CurrAccDate datetime
,	@SaveTAConditions tinyint = 0
)
AS 
begin

	declare @LogTraceInfo int = 1, @LogBegEndProc int = 1, @TimeBeg datetime = GetDate()
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0, @Ret int = 0
		,	@Sql nvarchar(max) = N'', @Sql2 nvarchar(4000) = N'', @CrLf nvarchar(4) = nchar(13) + nchar(10)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]'
	;

	/************************************************************************************************************/
	/* 1.0 Generate Sql for TA Conditions: */
	declare @DateAcc DATE = @CurrAccDate, @StrIntVal varchar(32) = ''
	;

	/* Client conditions [DT015_CUSTOMERS_ACTIONS_TA]: */
	declare @TA_TYPE					sysname = ''	
		,	@SECTOR						int = 0
		,	@UNIFIED					int = -1
		,	@IS_SERVICE					int = -1
		,	@CODE_EGFN_TYPE				int = -1
		,	@DB_CLIENT_TYPE_DT300		int = -1
		,	@VALID_ID					int = -1
		,	@CUSTOMER_CHARACTERISTIC	int = -1
		,	@CUSTOMER_AGE				sysname = '-1'
		,	@CUSTOMER_BIRTH_DATE_MIN	int = 18910101
		,	@CUSTOMER_BIRTH_DATE_MAX	int = 20220101
		,	@IS_PROXY					int = -1
		,	@IS_UNIQUE_CUSTOMER			int = -1
		,	@HAVE_CREDIT				int = -1
		,	@COLLECT_TAX_FROM_ALL_ACC 	int = -1
			/* [PROXY_SPEC_TA]: */
		,	@UI_RAZPOREDITEL			int = -1
		,	@UI_UNLIMITED				int = -1
	;
	/* Deal conditions [RAZPREG_TA]: */
	declare @UI_STD_DOG_CODE			int = 0
		,	@UI_INDIVIDUAL_DEAL			int = 0
		,	@INT_COND_STDCONTRACT		int = 0
		,	@CODE_UI_NM342				int = 0
		,	@CCY_CODE_DEAL				int = 0
		,	@UI_OTHER_ACCOUNT_FOR_TAX	int = 0
		,	@UI_NOAUTOTAX				sysname = '-1'
		,	@UI_DENY_MANUAL_TAX_ASSIGN	sysname = '-1'
		,	@UI_CAPIT_ON_BASE_DATE_OPEN sysname = '-1'
		,	@UI_BANK_RECEIVABLES		sysname = '-1'
		,	@UI_JOINT_TYPE				int = 0
		,	@LIMIT_AVAILABILITY			sysname = '0'
		,	@DEAL_STATUS				int = 0
		,	@LIMIT_TAX_UNCOLLECTED		int = 0
		,	@LIMIT_ZAPOR				int = 0
		,	@IS_CORR					int = 0
		,	@IS_UNIQUE_DEAL				int = 0
		,	@GS_PRODUCT_CODE			int = 0
		,	@CODE_GS_PROGRAMME			int = 0
		,	@CODE_GS_CARD				int = 0
	;
	declare @CCY_CODE_CORS				int = -1
		,	@LIMIT_AVAILABILITY_CORS	sysname = '-1'

		/* Conditions [PREV_COMMON_TA]: */
		,	@RUNNING_ORDER				int = -1
		,	@TYPE_ACTION				varchar(256)
		,	@TAX_CODE					int = -1
		,	@PREF_CODE					sysname = '-1'
		,	@DOC_SUM					float = 0.0
		,	@DOC_TAX_SUM				float = 0.0
	;

	/* Conditions for DirPrev from [PREV_COMMON_TA] & [RAZPREG_TA]: */
	declare @UI_INOUT_TRANSFER			varchar(256) = null
		,	@BETWEEN_OWN_ACCOUNTS		int = -1
		,	@CCY_CODE_DEAL_BEN			int = -1
	;

	drop table if EXISTS dbo.[#TBL_SQL_CONDITIONS]
	;
	create table dbo.[#TBL_SQL_CONDITIONS]
	(
		[ID] INT IDENTITY(1,1)
	,	[SQL_COND] nvarchar(1000)
	,	[DESCR] nvarchar(2000)
	,	[IS_BASE_SELECT] BIT DEFAULT(0)
	,	[IS_SELECT_COUNT] BIT DEFAULT(0)
	)
	;

	/**********************************************************************************************/

	drop table if EXISTS dbo.[#TBL_TA_CONDITIONS]
	;
	select [V].*
	into dbo.[#TBL_TA_CONDITIONS] 
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] [V] with(nolock) where [V].[ROW_ID] = IsNull(@TestCaseRowID, -1)
	;

	select top(1) /* Client conditions: */
			@TA_TYPE					= ''''+ [TA_TYPE] + ''''
		,	@SECTOR						= [SECTOR]
		,	@UNIFIED					= [UNIFIED]
		,	@IS_SERVICE					= [IS_SERVICE]
		,	@CODE_EGFN_TYPE				= [CODE_EGFN_TYPE]
		,	@DB_CLIENT_TYPE_DT300		= [DB_CLIENT_TYPE_DT300]
		,	@VALID_ID					= [VALID_ID]
		,	@CUSTOMER_CHARACTERISTIC	= [CODE_CUSTOMER_CHARACTERISTIC]
		,	@CUSTOMER_AGE				= [CUSTOMER_AGE]
		,	@CUSTOMER_BIRTH_DATE_MIN	= CONVERT( char(8), [CUSTOMER_BIRTH_DATE_MIN], 112)
		,	@CUSTOMER_BIRTH_DATE_MAX	= CONVERT( char(8), [CUSTOMER_BIRTH_DATE_MAX], 112)
		,	@IS_PROXY					= [IS_PROXY]
		,	@IS_UNIQUE_CUSTOMER			= [IS_UNIQUE_CUSTOMER]
		,	@HAVE_CREDIT				= [HAVE_CREDIT]
		,	@COLLECT_TAX_FROM_ALL_ACC	= [COLLECT_TAX_FROM_ALL_ACC]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Conditions [PROXY_SPEC_TA]: */
			@UI_RAZPOREDITEL			= [UI_RAZPOREDITEL]
		,	@UI_UNLIMITED				= [UI_UNLIMITED]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Deal conditions: */
			@UI_STD_DOG_CODE			= cast( [UI_STD_DOG_CODE] as int)
		,	@UI_INDIVIDUAL_DEAL			= cast( [UI_INDIVIDUAL_DEAL] as int)
		,	@INT_COND_STDCONTRACT		= cast( [INT_COND_STDCONTRACT] as int )
		,	@CODE_UI_NM342				= cast( [CODE_UI_NM342]  as int)
		,	@CCY_CODE_DEAL				= [CCY_CODE_DEAL]
		,	@UI_OTHER_ACCOUNT_FOR_TAX	= [UI_OTHER_ACCOUNT_FOR_TAX]
		,	@UI_NOAUTOTAX				= [UI_NOAUTOTAX]
		,	@UI_DENY_MANUAL_TAX_ASSIGN	= [UI_DENY_MANUAL_TAX_ASSIGN]
		,	@UI_CAPIT_ON_BASE_DATE_OPEN = [UI_CAPIT_ON_BASE_DATE_OPEN]
		,	@UI_BANK_RECEIVABLES		= [UI_BANK_RECEIVABLES]
		,	@UI_JOINT_TYPE				= [UI_JOINT_TYPE]
		,	@LIMIT_AVAILABILITY			= [LIMIT_AVAILABILITY]
		,	@DEAL_STATUS				= [DEAL_STATUS]
		,	@LIMIT_TAX_UNCOLLECTED		= [LIMIT_TAX_UNCOLLECTED]
		,	@LIMIT_ZAPOR				= cast(FLOOR([LIMIT_ZAPOR]) as int)
		,	@IS_CORR					= [IS_CORR]
		,	@IS_UNIQUE_DEAL				= [IS_UNIQUE_DEAL]
		,	@GS_PRODUCT_CODE			= [GS_PRODUCT_CODE]
		,	@CODE_GS_PROGRAMME			= [CODE_GS_PROGRAMME]
		,	@CODE_GS_CARD				= [CODE_GS_CARD]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;
	select top(1) /* Conditions [DEALS_CORR_TA]: */
			@CCY_CODE_CORS				= [CCY_CODE_CORS]
		,	@LIMIT_AVAILABILITY_CORS	= [LIMIT_AVAILABILITY_CORS]
		,	@TAX_CODE					= [TAX_CODE]
		,	@PREF_CODE					= [PREF_CODE]
		,	@DOC_SUM					= [DOC_SUM]
		,	@DOC_TAX_SUM				= [DOC_TAX_SUM]
				/* Conditions [PREV_COMMON_TA]: */
		,	@RUNNING_ORDER				= [RUNNING_ORDER]
		,	@TYPE_ACTION				= [TYPE_ACTION]
				/* Conditions for DirPrev from [PREV_COMMON_TA] & [RAZPREG_TA]: */
		,	@UI_INOUT_TRANSFER			= [UI_INOUT_TRANSFER]
		,	@BETWEEN_OWN_ACCOUNTS		= [BETWEEN_OWN_ACCOUNTS]
		,	@CCY_CODE_DEAL_BEN			= [CCY_CODE_DEAL_BEN]
	from dbo.[#TBL_TA_CONDITIONS] [F] with(nolock)
	;

	/*********************************************************************/
	/* Prepate Base SELECT statement: */
	select @Sql2 = N'select DISTINCT TOP (3) ''ID_'+@TestCaseRowID+'_'+REPLACE(@TA_TYPE,'''','')+ ''''
		+ N' AS [TEST_ID]
		, [DEAL].[DEAL_TYPE], [DEAL].[DEAL_NUM]
		, [CUST].[CUSTOMER_ID], [PROXY].[CUSTOMER_ID] AS [REPRESENTATIVE_CUSTOMER_ID] '
		+ case when IsNull(@TYPE_ACTION,'') = 'CT' and IsNull(@UI_INOUT_TRANSFER,'-1') = '3' and IsNull(@BETWEEN_OWN_ACCOUNTS,-1) in (0,1)
			then ', [DEAL_BEN].[DEAL_TYPE_BEN], [DEAL_BEN].[DEAL_NUM_BEN] '
			else ', NULL AS [DEAL_TYPE_BEN],  NULL AS [DEAL_NUM_BEN]' end + @CrLf
	insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR], [IS_BASE_select] )
	select	@Sql2,	N'SELECT ...', 1
	;
	select @Sql += @Sql2
	;

	/*********************************************************************/
	/* prepare tables joint statement:  */
	-- @SECTOR and @CCY_CODE_DEAL
	select @Sql2 = N'
	from dbo.[AGR_CASH_PAYMENTS_DEALS] [DEAL] with(nolock)
	inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [CUST] with(nolock)
		on	[CUST].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
		and [DEAL].[CLIENT_SECTOR] = '+str(@SECTOR,len(@SECTOR),0)+N'
		and [DEAL].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+' ';

	-- [DT015_CUSTOMERS_ACTIONS_TA].[SECTOR] and [RAZPREG_TA].[UI_CURRENCY_CODE]
	insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
	select	(@Sql2 + @CrLf), N' BASE join: SECTOR = '+str(@SECTOR,len(@SECTOR),0)+' & [UI_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL,len(@CCY_CODE_DEAL),0)+' '
	select @Sql += @Sql2

	-- Access Deal throwght with proxy customer
	if @UI_RAZPOREDITEL IS NOT NULL
	begin
		/* NM622 (client roles): 1 - Титуляр, 2- Пълномощник; 3 - Законен представител, ... */
		declare @CUSTOMER_ROLE_TYPE varchar(32) = N''
		;
		-- 0 - Пълномощник; 1 - Законен представител
		select @CUSTOMER_ROLE_TYPE = case IsNull(@UI_RAZPOREDITEL,-1)	
											when  0 then ' = 2'				/* 2 - Пълномощник*/
											when  1 then ' = 3'				/* 3 - Законен представител */
											when -1 then ' in (2,3) ' end;	/* 2 & 3 */
		select @Sql2 = N'
		inner join dbo.[AGR_CASH_PAYMENTS_DEALS_ACTIVE_PROXY_CUSTOMERS] [PROXY_ID] with(nolock)
			on	[PROXY_ID].[DEAL_TYPE] = 1
			and [PROXY_ID].[DEAL_NUM]  = [DEAL].[DEAL_NUM]
			and [PROXY_ID].[CUSTOMER_ROLE_TYPE] '+@CUSTOMER_ROLE_TYPE+'
		inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [PROXY] with(nolock)
			on	[PROXY].[CUSTOMER_ID] = [PROXY_ID].[REPRESENTATIVE_CUSTOMER_ID]
		';

		-- [DT015_CUSTOMERS_ACTIONS_TA].[UI_RAZPOREDITEL] -- 0 - Пълномощник; 1 - Законен представител
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N'@UI_RAZPOREDITEL: '+STR(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0)+' '
		select @Sql += @Sql2;
	end
	else 
	begin

		select @Sql2 = N'
		inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS] [PROXY] with(nolock)
			ON	[PROXY].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
		';

		-- Base join clause: 
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N' WITHOUT PROXY: [PROXY].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]'
		select @Sql += @Sql2;
	end

		-- Add additional joint for document "Credit Transfer":
	if IsNull(@TYPE_ACTION,'') = 'CT' and IsNull(@UI_INOUT_TRANSFER,'-1') = '3' and IsNull(@BETWEEN_OWN_ACCOUNTS,-1) in (0,1)
	begin

		if @BETWEEN_OWN_ACCOUNTS = 1
		begin
			select @Sql2 = N'
			inner join dbo.[AGR_CASH_PAYMENTS_CUSTOMERS_COUNT_DEAL_BY_CURRENCY] [CD_CNT] with(nolock)
				ON	[CD_CNT].[CUSTOMER_ID]	 = [DEAL].[CUSTOMER_ID]
				AND [CD_CNT].[CURRENCY_CODE] = '+str(@CCY_CODE_DEAL_BEN,len(@CCY_CODE_DEAL_BEN),0)+' 
				AND	[CD_CNT].[DEAL_TYPE]	 = 1
				AND	[CD_CNT].[DEAL_COUNT]	 > 1
			cross apply (
				select top(1)
						[D].[DEAL_TYPE]	AS	[DEAL_TYPE_BEN] 
					,	[D].[DEAL_NUM] 	AS	[DEAL_NUM_BEN] 
				from dbo.[AGR_CASH_PAYMENTS_DEALS] [D] with(nolock)
				where	[D].[CUSTOMER_ID] = [DEAL].[CUSTOMER_ID]
					and [D].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL_BEN,len(@CCY_CODE_DEAL_BEN),0)+'
					and	[D].[DEAL_NUM] <> [DEAL].[DEAL_NUM]
			) [DEAL_BEN]
			';
		end
		else 
		begin
			select @Sql2 = N'
			cross apply (
				select top(1)
						[D].[DEAL_TYPE]	AS	[DEAL_TYPE_BEN] 
					,	[D].[DEAL_NUM] 	AS	[DEAL_NUM_BEN] 
				from dbo.[AGR_CASH_PAYMENTS_DEALS] [D] with(nolock)
				where	[D].[CUSTOMER_ID] <> [DEAL].[CUSTOMER_ID]
					and [D].[DEAL_CURRENCY_CODE] = '+str(@CCY_CODE_DEAL_BEN,len(@CCY_CODE_DEAL_BEN),0)+'
			) [DEAL_BEN]
			';
		end

		-- Base join clause: 
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	(@Sql2 + @CrLf), N' Add additiona join for document Credit Transfer; @BETWEEN_OWN_ACCOUNTS :'+str(@BETWEEN_OWN_ACCOUNTS,len(@BETWEEN_OWN_ACCOUNTS),0)
		select @Sql += @Sql2;
	end

	/*********************************************************************/
	/* Prepare WHERE statement: */
	-- [DT015_CUSTOMERS_ACTIONS_TA].[DB_CLIENT_TYPE] => @DB_CLIENT_TYPE_DT300:
	select @Sql2 = N'
	where [CUST].[CLIENT_TYPE_DT300_CODE] = '+str(@DB_CLIENT_TYPE_DT300,len(@DB_CLIENT_TYPE_DT300),0);
	insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
	select	(@Sql2 + @CrLf), ' BASE @DB_CLIENT_TYPE_DT300 : ' + @Sql2
	select @Sql += @Sql2

	-- enum CustomerSubtypes: (-1) - Без значение; 1 - (над 18г.); 2 - (от 14г. до 18г.); 3 - (до 14г.)
	if  IsNull(@CUSTOMER_AGE, '-1') <> '-1'
	Begin 
		select	@Sql2 = N'AND [PROXY].[CLIENT_BIRTH_DATE] BETWEEN '
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0)+' AND ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0)+' ' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[CUSTOMER_AGE] '+@CUSTOMER_AGE+' - between YEAR : ' 
				+ STR(@CUSTOMER_BIRTH_DATE_MIN,LEN(@CUSTOMER_BIRTH_DATE_MIN),0) + ' AND '
				+ STR(@CUSTOMER_BIRTH_DATE_MAX,LEN(@CUSTOMER_BIRTH_DATE_MAX),0) + @CrLf;

		select @Sql += @Sql2;
	end

	/*****************************************************/
	-- 0 - не е обединяван (клиент с един кл. код); 3 - обединен, без значение дали е бил главен или подчинен (кл.с повече от един кл.код); -1 - без значение
	if @UNIFIED <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_MANY_CLIENT_CODES] = ' + case when @UNIFIED = 0 THEN '0' ELSE '1' END + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UNIFIED] : ' + str(@UNIFIED,len(@UNIFIED),0 )

		select @Sql += @Sql2
	end

	-- 0 - Не е служебен или свързан със служебен; 1 - Реално ЕГН, има такива служебни; 2 - служебни ЕГН
	if @IS_SERVICE <> -1
	begin 
		select @Sql2 = ' AND [CUST].[HAS_DUBL_CLIENT_IDS] = ' + case when @IS_SERVICE = 0 then '0' else '1' end + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

		select @Sql += @Sql2

		if @IS_SERVICE <> 0
		begin 
			select @Sql2 = ' AND [CUST].[IS_ORIGINAL_EGFN] = ' + case when @IS_SERVICE = 1 then '1' else '0' end + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[IS_SERVICE] : ' + str(@IS_SERVICE,len(@IS_SERVICE),0 )

			select @Sql += @Sql2
		end 
	end

	-- enum DetailedTypeOfIdentifier : [DT015_CUSTOMERS].[IDENTIFIER_TYPE]
	if IsNull(@CODE_EGFN_TYPE,-1) <> -1
	begin 
		select @Sql2 = ' AND [CUST].[CLIENT_IDENTIFIER_TYPE] = ' + str(@CODE_EGFN_TYPE,len(@CODE_EGFN_TYPE),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_EGFN_TYPE] : ' + str(@CODE_EGFN_TYPE,len(@CODE_EGFN_TYPE),0 )

		select @Sql += @Sql2
	end 

	-- 1 - валидни документи
	if IsNull(@VALID_ID,-1) = 1
	begin
		select @Sql2 = ' AND [PROXY].[HAS_VALID_DOCUMENT] = 1' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[VALID_ID] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end 

	-- @TODO: @IS_PROXY: 
	-- Ако клиента е маркиран като пълномощник, то той няма да се търси като самостоятелен 
	-- клиент, а данните му ще се актуализират при актуализация на данните за титуляра.
	--if IsNull(@IS_PROXY, -1) <> -1
	--	select @Sql += ' AND [CUST].[CUSTOMER_CHARACTERISTIC] = ' + str(@CUSTOMER_CHARACTERISTIC, len(@CUSTOMER_CHARACTERISTIC), 0);

	-- Указва дали клиента да е уникален за таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA]
	if IsNull(@IS_UNIQUE_CUSTOMER, -1) = 1
	begin 
		select @Sql2 = ' AND NOT EXISTS 
		(
			select * from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [TA_CUST] with(nolock)
			where [TA_CUST].[UI_CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
				/* and [TA_CUST].[TA_TYPE] = '+@TA_TYPE+' */
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[VALID_ID] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end
	;

	-- @HAVE_CREDIT:
	-- Дали клиента има активен кредит: ;Без допълнителни сметки - ;Всички разплащателни и влогове - 
	-- ;Всички разплащателни - несвързани към друг кредит - ; Всички разплащателни, влогове и депозитни сметки -
	if IsNull(@HAVE_CREDIT, -1) in ( 0, 1 )
	begin
		select @Sql2 = ' AND [CUST].[HAS_LOAN] = '+STR(@HAVE_CREDIT,LEN(@HAVE_CREDIT),0) + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[HAS_LOAN] : ' + str(@VALID_ID,len(@VALID_ID),0 )

		select @Sql += @Sql2
	end

	-- [COLLECT_TAX_FROM_ALL_ACC] : Клиента има ли непратени такси, който могат да се събират от всички сметки на клиента
	if IsNull(@COLLECT_TAX_FROM_ALL_ACC,-1) in (0,1)
	begin
		select @StrIntVal = STR(@COLLECT_TAX_FROM_ALL_ACC,LEN(@COLLECT_TAX_FROM_ALL_ACC),0);
		select @Sql2 = ' AND [CUST].[HAS_UNCOLLECTED_TAX_CONNECTED_TO_ALL_ACC] = ' + @StrIntVal + @CrLf;
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[COLLECT_TAX_FROM_ALL_ACC] : ' + @StrIntVal

		select @Sql += @Sql2
	end

	-- 0 - Пълномощник; 1 - Законен представител
	if IsNull(@UI_RAZPOREDITEL,-1) <> -1
	begin 
		if @UI_RAZPOREDITEL = 0
		begin
			select @Sql2 = ' AND [DEAL].[PROXY_COUNT] > 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_RAZPOREDITEL] : ' + str(@UI_RAZPOREDITEL,len(@UI_RAZPOREDITEL),0 )

			select @Sql += @Sql2
		end
	end

	-- 1 - безсрочен; 0 - с крайна дата
	-- @TODO: @UI_UNLIMITED:
	--If IsNull(@UI_UNLIMITED, -1) <> -1
	--	select @Sql += ' ''

	-- Код на стандартен договор
	if IsNull(@UI_STD_DOG_CODE,-1) > 0 and IsNull(@UI_INDIVIDUAL_DEAL,-1) NOT IN (1)
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_STD_DOG_CODE] = '+STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_STD_DOG_CODE] : ' + STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0);

		select @Sql += @Sql2
	end 

	--0 - стандартна сделка, 1 - индивидуална сделка
	if IsNull(@UI_INDIVIDUAL_DEAL,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_INDIVIDUAL_DEAL] = '+STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_INDIVIDUAL_DEAL] : ' + STR(@UI_INDIVIDUAL_DEAL, LEN(@UI_INDIVIDUAL_DEAL),0);

		select @Sql += @Sql2

		-- Код на стандартен договор по който е разкрита индивидуалната сделка
		if IsNull(@INT_COND_STDCONTRACT,-1) >= 0
		begin
			select @Sql2 = ' AND [DEAL].[INT_COND_STDCONTRACT] = '+STR(@INT_COND_STDCONTRACT, LEN(@INT_COND_STDCONTRACT),0) + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[INT_COND_STDCONTRACT] : ' + +STR(@INT_COND_STDCONTRACT, LEN(@INT_COND_STDCONTRACT),0);

			select @Sql += @Sql2
		end		

		if IsNull(@UI_STD_DOG_CODE,-1) >= 0
		begin
			select @Sql2 = ' AND [DEAL].[DEAL_STD_DOG_CODE] = '+STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_STD_DOG_CODE] : ' + STR(@UI_STD_DOG_CODE, LEN(@UI_STD_DOG_CODE),0) + '/* for individual deal: [UI_INDIVIDUAL_DEAL] = 1 */';

			select @Sql += @Sql2
		end

	end 

	-- 0 - не е комбиниран продукт, код > 0 - да принадлежи към този комбиниран продукт
	if IsNull(@CODE_UI_NM342, -1) > 0
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NM342_BUNDLE_PRODUCT_CODE] = '+ STR(@CODE_UI_NM342,LEN(@CODE_UI_NM342),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_UI_NM342] : ' + STR(@CODE_UI_NM342,LEN(@CODE_UI_NM342),0);

		select @Sql += @Sql2
	end

	-- 0 - сметката се таксува от себе си, 1 - има друга таксуваща сметка, 2 - без проверка дали има друга таксуваща сметка или се таксува от себе си
	if IsNull(@UI_OTHER_ACCOUNT_FOR_TAX,-1) in (0, 1)
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_OTHER_TAX_ACCOUNT] = 1' + str(@UI_OTHER_ACCOUNT_FOR_TAX,len(@UI_OTHER_ACCOUNT_FOR_TAX),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_OTHER_ACCOUNT_FOR_TAX] : ' + str(@UI_OTHER_ACCOUNT_FOR_TAX,len(@UI_OTHER_ACCOUNT_FOR_TAX),0);

		select @Sql += @Sql2
	end

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_NOAUTOTAX,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_NO_AUTO_PAY_TAX] = '+@UI_NOAUTOTAX + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_NOAUTOTAX] : ' + @UI_NOAUTOTAX

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е
	if IsNull(@UI_DENY_MANUAL_TAX_ASSIGN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_IS_DENY_MANUAL_TAX_ASSIGN] = '+@UI_DENY_MANUAL_TAX_ASSIGN + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_DENY_MANUAL_TAX_ASSIGN] : ' + @UI_DENY_MANUAL_TAX_ASSIGN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_CAPIT_ON_BASE_DATE_OPEN,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_CAPIT_ON_BASE_DATE_OPEN] = '+@UI_CAPIT_ON_BASE_DATE_OPEN + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_CAPIT_ON_BASE_DATE_OPEN] : ' + @UI_CAPIT_ON_BASE_DATE_OPEN

		select @Sql += @Sql2
	end 

	--'-1' няма значение, 0 не е избрано, 1 избрано е 
	if IsNull(@UI_BANK_RECEIVABLES,'-1') in ('0', '1')
	begin 
		select @Sql2 = ' AND [DEAL].[DEAL_EXCLUDE_FROM_BANK_COLLECTIONS] = '+@UI_BANK_RECEIVABLES + @CrLf;
		
		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_BANK_RECEIVABLES] : ' + @UI_BANK_RECEIVABLES

		select @Sql += @Sql2
	end 

	--0 - не е съвместна сделка, 1 - съвместна сделка от тип "по отделно"
	if IsNull(@UI_JOINT_TYPE,-1) in (0, 1)
	begin

		select @Sql2 = ' AND [DEAL].[DEAL_IS_JOINT_DEAL] = ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[UI_JOINT_TYPE] : ' + str(@UI_JOINT_TYPE,len(@UI_JOINT_TYPE),0);

		select @Sql += @Sql2

		/* enum JointDealsAccessToFundsType: 0 - Separate; 1 - Always Together */	
		if @UI_JOINT_TYPE = 1
		begin 
			select @Sql2 = ' AND [DEAL].[DEAL_JOINT_ACCESS_TO_FUNDS_TYPE] = 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[UI_JOINT_TYPE] (Access type: 0 - Separate; 1 Always Together) : ';

			select @Sql += @Sql2
		end
	end

	-- 0 или долна граница на разполагаемостта ( '<0', '>0' )
	if Left(ltrim(IsNull(@LIMIT_AVAILABILITY,'0')),1) in ('<', '>', '=')
	begin 
		select @Sql2 = ' AND ([DEAL].[ACCOUNT_BEG_DAY_BALANCE] - [DEAL].[BLK_SUMA_MIN] + [DEAL].[DAY_OPERATION_BALANCE]) ' + REPLACE(@LIMIT_AVAILABILITY, ' ','') + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[LIMIT_AVAILABILITY] : ' + @LIMIT_AVAILABILITY;

		select @Sql += @Sql2
	end 

	-- 1 - активна; Безусловно ще се търсят сделки които НЕ СА ЗАМРАЗЕНИ
	if IsNull(@DEAL_STATUS,-1) = 1
	begin 
		select @Sql2 = ' AND [DEAL].[IS_DORMUNT_ACCOUNT] = 0' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2, '[DEAL_STATUS] : ' + str(@DEAL_STATUS,len(@DEAL_STATUS),0);

		select @Sql += @Sql2
	end 

	-- 0 - няма несъбрани такси; 1 - има несъбрани такси, -1 без значение от сумата
	if IsNull(@LIMIT_TAX_UNCOLLECTED,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND [DEAL].[HAS_TAX_UNCOLECTED] = ' + str(@LIMIT_TAX_UNCOLLECTED,len(@LIMIT_TAX_UNCOLLECTED),0) + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[LIMIT_TAX_UNCOLLECTED] : ' + str(@LIMIT_TAX_UNCOLLECTED,len(@LIMIT_TAX_UNCOLLECTED),0);

		select @Sql += @Sql2
	end 

	-- 0 - няма запор; друга сума - има запор над определена сума; (-1) : няма значение;
	if IsNull(@LIMIT_ZAPOR,-1) >= 0
	begin 

		if @LIMIT_ZAPOR = 0
		begin 
			select @Sql2 = ' AND [DEAL].[HAS_DISTRAINT] = 0' + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 

		if @LIMIT_ZAPOR > 0
		begin
			select @Sql2 = ' AND [DEAL].[HAS_DISTRAINT] = 1 AND [DEAL].[BLK_SUMA_MIN] > 0.0' + @CrLf;

			insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
			select	@Sql2
				,	'[LIMIT_ZAPOR] : ' + str(@LIMIT_ZAPOR,len(@LIMIT_ZAPOR),0);

			select @Sql += @Sql2
		end 
	end

	-- Да няма осчетоводено 'Вносни Бележки' по сделката: @RUNNING_ORDER = 1 and @TYPE_ACTION = ''
	if @TYPE_ACTION = 'CashPayment' and IsNull(@RUNNING_ORDER,-1) = 1
	begin
		select @Sql2 = ' AND [DEAL].[HAS_WNOS_BEL] = ' + (case when @RUNNING_ORDER > 1 then '1' else '0' end)  + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[TYPE_ACTION] = ''CashPayment'' and [RUNNING_ORDER] : ' + str(@RUNNING_ORDER,len(@RUNNING_ORDER),0);

		select @Sql += @Sql2
	end

	-- Да няма осчетоводено 'Нареждане Разписка' по сделката: @RUNNING_ORDER = 1 and @TYPE_ACTION = ''
	if @TYPE_ACTION = 'CashW' and IsNull(@RUNNING_ORDER,-1) = 1
	begin
		select @Sql2 = ' AND [DEAL].[HAS_NAR_RAZP] = ' + (case when @RUNNING_ORDER > 1 then '1' else '0' end)  + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[TYPE_ACTION] = ''CashW'' and [RUNNING_ORDER] : ' + str(@RUNNING_ORDER,len(@RUNNING_ORDER),0);

		select @Sql += @Sql2
	end	

	-- Да укаже дали сметката е кореспондираща до други сделки: -1 няма значение; 0 не е; 1 да , кореспондираща е
	if IsNull(@IS_CORR,-1) in ( 0, 1 )
	begin 
		select @Sql2 = ' AND '+CASE WHEN @IS_CORR = 0 THEN 'NOT' ELSE '' END+ ' EXISTS (
			select * from dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [TAX] with(nolock)
			where  [TAX].[CORR_ACCOUNT] =  [DEAL].[DEAL_ACCOUNT]
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_CORR] : ' + str(@IS_CORR,len(@IS_CORR),0);

		select @Sql += @Sql2
	end 

	-- Указва дали РС да е уникална в таблица [RAZPREG_TA]
	if IsNull(@IS_UNIQUE_DEAL,-1) in ( 1 )
	begin 
		select @Sql2 = ' AND NOT EXISTS (
			select * FROM dbo.[RAZPREG_TA] [TA] with(nolock)
			where	[TA].[UI_DEAL_NUM] = [DEAL].[DEAL_NUM]
				and ( [TA].[IS_BEN] IS NULL OR [TA].[IS_BEN] <> 1 )  
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[IS_UNIQUE_DEAL] : ' + str(@IS_UNIQUE_DEAL,len(@IS_UNIQUE_DEAL),0)

		select @Sql += @Sql2
	end
	;

	-- Код на програма от Group Sales + Продуктов код на карта + Код на GS договор
	if IsNull(@CODE_GS_PROGRAMME,-1) > 0 AND IsNull(@CODE_GS_CARD,-1) > 0 AND IsNull(@GS_PRODUCT_CODE,-1) > 0
	begin 
		select @Sql2 = ' AND EXISTS (
			select * FROM dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_GS_INDIVIDUAL_PROGRAMME] [GS] with(nolock)
			where	[GS].[DEAL_NUM]	 = [DEAL].[DEAL_NUM]
				and [GS].[DEAL_TYPE] = 1
				and [GS].[DEAL_GS_INDIVIDUAL_PROGRAM_CODE] = '+STR(@CODE_GS_PROGRAMME,LEN(@CODE_GS_PROGRAMME),0)+'
				and [GS].[DEAL_GS_INDIVIDUAL_CARD_PRODUCT] = '+STR(@CODE_GS_CARD,LEN(@CODE_GS_CARD),0)+'
				and [GS].[DEAL_GS_INDIVIDUAL_PRODUCT_CODE] = '+STR(@GS_PRODUCT_CODE,LEN(@GS_PRODUCT_CODE),0)+'
		)' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CODE_GS_PROGRAMME] : ' + str(@CODE_GS_PROGRAMME,len(@CODE_GS_PROGRAMME),0)
				+', [CODE_GS_CARD] : ' + str(@CODE_GS_CARD,len(@CODE_GS_CARD),0)
				+', [GS_PRODUCT_CODE] : ' + str(@GS_PRODUCT_CODE,len(@GS_PRODUCT_CODE),0)
		select @Sql += @Sql2
	end 

	-- Валута на кореспонденцията
	if IsNull(@CCY_CODE_CORS, -1) > 0
	begin 
		select @Sql2 = ' AND '+CASE WHEN @IS_CORR = 0 THEN 'NOT' ELSE '' END+ ' EXISTS (
			select * FROM dbo.[AGR_CASH_PAYMENTS_DEALS_WITH_OTHER_TAX_ACCOUNT] [TAX] with(nolock)
			where  [TAX].[CORR_ACCOUNT] = [DEAL].[DEAL_ACCOUNT] ' + @CrLf;

		-- Разполагаемост по сделката 
		if left(ltrim(IsNull(@LIMIT_AVAILABILITY_CORS, '0')),1) in ('<', '>', '=')
				select @Sql2 += ' AND ([TAX].[ACCOUNT_BEG_DAY_BALANCE] - [TAX].[BLK_SUMA_MIN]+ [TAX].[DAY_OPERATION_BALANCE] ) ' + REPLACE(@LIMIT_AVAILABILITY_CORS,' ','');

		select @Sql2 += ')' + @CrLf;

		insert into dbo.[#TBL_SQL_CONDITIONS] ( [SQL_COND], [DESCR] )
		select	@Sql2
			,	'[CCY_CODE_CORS] : ' + str(@CCY_CODE_CORS,len(@CCY_CODE_CORS),0) + ', [LIMIT_AVAILABILITY_CORS] : ' + @LIMIT_AVAILABILITY_CORS

		select @Sql += @Sql2
	end 

	/**********************************************************************/
	/* Execute Sql statement: */
	if len(@Sql) > 10
	begin 
		select @Sql as [SQL_QUERY]
		select @Msg = 'TA Row ID: ' + @TestCaseRowID + ', successful generated sql query: "'+@Sql+'"'
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, @Sql

		begin try
			insert into dbo.[#TBL_RESULT] 
			exec sp_executeSql  @Sql
		end try 
		begin catch 
			select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg
			return 1
		end catch 
	end

	select @Rows = (select count(*) from dbo.[#TBL_RESULT] with(nolock) ), @Err = @@ERROR;
	if @LogTraceInfo = 1
	begin 
		select @Rows = IsNull(@Rows,0);
		select @Msg = N'After: insert into dbo.[#TBL_RESULT], Rows affected : ' + str(@Rows,len(@Rows),0) + ', TA ID :'+ @TestCaseRowID;
	 	exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql, @Msg;
	end

	if @Rows <= 0 and @SaveTAConditions = 1
	begin
		insert into dbo.[AGR_CASH_PAYMENTS_SQL_CONDITIONS]
		( [TEST_ID], [SQL_COND], [DESCR], [IS_BASE_SELECT], [IS_SELECT_COUNT] )
		SELECT	@TestCaseRowID	 AS [TEST_ID]
			,	[S].[SQL_COND]
			,	[S].[DESCR]
			,	[S].[IS_BASE_SELECT]
			,	[S].[IS_SELECT_COUNT]
		FROM dbo.[#TBL_SQL_CONDITIONS] [S] WITH(NOLOCK)
	end
		
	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_TA_TABLES_PREPARE_CONDITIONS]'
	end

	return 0;
end 
go
