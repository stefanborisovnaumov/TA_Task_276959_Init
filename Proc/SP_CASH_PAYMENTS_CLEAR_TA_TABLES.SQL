/********************************************************************************************************/
/* Процедура за зачистване наданните от TA Таблиците */
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]
(
	@TestCaseRowID NVARCHAR(16)
)
as 
begin

	declare @LogTraceInfo int = 1,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Msg nvarchar(max) = N'', @Rows int = 0, @Err int = 0
		,	@Sql1 nvarchar(4000) = N'',	@TA_RowID int = cast ( @TestCaseRowID as int )
	;
	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]'


	/************************************************************************************************************/
	-- 2. Get  TA Table Row IDs:
	declare @RAZPREG_TA_RowID int = 0
		,	@DEALS_CORR_TA_RowID int = 0
		,	@DT015_CUSTOMERS_RowID int = 0
		,	@PROXY_CUSTOMERS_RowID int = 0
	;
	select	@RAZPREG_TA_RowID		= [DEAL_ROW_ID]
		,	@DEALS_CORR_TA_RowID	= [CORS_ROW_ID]
		,	@DT015_CUSTOMERS_RowID	= [CUST_ROW_ID]
		,	@PROXY_CUSTOMERS_RowID	= [PROXY_ROW_ID]
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID

	if IsNull(@RAZPREG_TA_RowID,0) <= 0
	begin  
		select @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 1;
	end
	
	if IsNull(@DT015_CUSTOMERS_RowID,0) <= 0
	begin  
		select @Msg = 'Not found customer from TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return 2;
	end 

	begin try

		-- Актуализация данните за кореспондиращата сметка
		if IsNull(@DEALS_CORR_TA_RowID,0) > 0
		begin

			UPDATE [D]
			SET		[DEAL_NUM]				= 0		-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
				,	[CURRENCY]				= '' 	-- DEALS_CORR_TA	CURRENCY	
				,	[UI_CORR_ACCOUNT]		= ''	-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
				,	[TAX_UNCOLLECTED_SUM]	= 0		-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 
			from dbo.[DEALS_CORR_TA] [D]
			where [D].[ROW_ID] = @DEALS_CORR_TA_RowID
			;
		end

		-- Актуализация данните на пълномощника
		if IsNull(@PROXY_CUSTOMERS_RowID,0) > 0
		begin

			UPDATE [D]
			SET		[UI_CUSTOMER_ID]		= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				,	[UI_EGFN]				= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				,	[NAME]					= ''		-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				,	[COMPANY_EFN]			= ''		-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				,	[UI_CLIENT_CODE]		= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				,	[UI_NOTES_EXIST]		= 0			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				,	[IS_ZAPOR]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				,	[ID_NUMBER]				= ''		-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				,	[SERVICE_GROUP_EGFN]	= ''		-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				,	[IS_ACTUAL]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1; 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				,	[PROXY_COUNT]			= 0			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			where [D].[ROW_ID] = @PROXY_CUSTOMERS_RowID
			;
		end

		-- Актуализация данните на сделката
		UPDATE [D]
		SET		[UI_DEAL_NUM]			= 0		-- RAZPREG_TA	UI_DEAL_NUM	
			,	[DB_ACCOUNT]			= ''	-- RAZPREG_TA	DB_ACCOUNT	
			,	[UI_ACCOUNT]			= ''	/* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
			,	[ZAPOR_SUM]				= ''	-- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
			,	[IBAN]					= ''	-- RAZPREG_TA	IBAN	
			,	[TAX_UNCOLLECTED_SUM]	= ''	-- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
		FROM dbo.[RAZPREG_TA] [D]
		WHERE [D].[ROW_ID] = @RAZPREG_TA_RowID
		;

		-- Актуализация данните на клиента
		UPDATE [D]
		SET		[UI_CUSTOMER_ID]		= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
			,	[UI_EGFN]				= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
			,	[NAME]					= ''		-- DT015_CUSTOMERS_ACTIONS_TA	NAME
			,	[COMPANY_EFN]			= ''		-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
			,	[UI_CLIENT_CODE]		= ''		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
			,	[UI_NOTES_EXIST]		= 0			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
			,	[IS_ZAPOR]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
			,	[ID_NUMBER]				= ''		-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
			,	[SERVICE_GROUP_EGFN]	= ''		-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
			,	[IS_ACTUAL]				= 0			-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1; 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
			,	[PROXY_COUNT]			= 0			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
		from dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
		where [D].[ROW_ID] = @DT015_CUSTOMERS_RowID
		;

	end try
	begin catch
		select  @Msg = dbo.FN_GET_EXCEPTION_INFO()
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql1, @Msg
		return 3
	end catch 

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: ' + @TestCaseRowID
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_CLEAR_TA_TABLES]'
	end
	;

	return 0;
end 
go
