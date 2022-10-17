/********************************************************************************************************/
/* Процедура за зачистване наданните от TA Таблиците */
/* 2022/06/98 - v2.6.3 -> актуализацията на сделките с навързаните документи се извършва само за първия тестови случай */

CREATE OR ALTER PROCEDURE dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA
(
	@TestCaseRowID NVARCHAR(16)
	, @REGISTER_TYPE NVARCHAR(256)
)
AS
BEGIN
	DECLARE @LogTraceInfo INT = 1
		, @LogBegEndProc INT = 1
		, @TimeBeg DATETIME = GetDate()
	DECLARE @Msg NVARCHAR(max) = N''
		, @Rows INT = 0
		, @Err INT = 0
		, @Sql1 NVARCHAR(4000) = N''
		, @TA_RowID INT = cast(@TestCaseRowID AS INT)

	/************************************************************************************************************/
	/* 1. Log Begining of Procedure execution */
	IF @LogBegEndProc = 1
		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, '*** Begin Execute Proc ***: dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA'

	/************************************************************************************************************/
	-- 2. Get  TA Table Row IDs:
	DECLARE @RUNNING_ORDER INT = 0
		, @TYPE_ACTION VARCHAR(128) = ''
		, @RAZPREG_TA_RowID INT = 0
		, @DEALS_CORR_TA_RowID INT = 0
		, @DT015_CUSTOMERS_RowID INT = 0
		, @PROXY_CUSTOMERS_RowID INT = 0
		, @CUSTOMER_BEN_ROW_ID INT = 0
		, @RAZPREG_TA_BEN_RowID INT = 0

	SELECT @RAZPREG_TA_RowID = [DEAL_ROW_ID]
		, @DEALS_CORR_TA_RowID = [CORS_ROW_ID]
		, @DT015_CUSTOMERS_RowID = [CUST_ROW_ID]
		, @PROXY_CUSTOMERS_RowID = [PROXY_ROW_ID]
		, @PROXY_CUSTOMERS_RowID = [PROXY_ROW_ID]
		, @RUNNING_ORDER = [RUNNING_ORDER]
		, @CUSTOMER_BEN_ROW_ID = IsNull([CUST_BEN_ROW_ID], - 1)
		, @RAZPREG_TA_BEN_RowID = IsNull([DEAL_BEN_ROW_ID], - 1)
	FROM dbo.[VIEW_TA_EXISTING_ONLINE_DATA_CONDITIONS] WITH (NOLOCK)
	WHERE [ROW_ID] = @TA_RowID
		AND REGISTER_TYPE = @REGISTER_TYPE

	DECLARE @IsNotFirstCashPaymentWithAccumulatedTax BIT = 0

	IF IsNull(@TYPE_ACTION, '') = 'CashPayment' AND IsNull(@RUNNING_ORDER, - 1) > 1
		SELECT @IsNotFirstCashPaymentWithAccumulatedTax = 1

	IF IsNull(@RAZPREG_TA_RowID, 0) <= 0
	BEGIN
		SELECT @Msg = 'Not found deal from TA ROW_ID : ' + @TestCaseRowID

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, @Msg

		RETURN 1
	END

	IF IsNull(@DT015_CUSTOMERS_RowID, 0) <= 0
	BEGIN
		SELECT @Msg = 'Not found customer from TA ROW_ID : ' + @TestCaseRowID

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @TestCaseRowID
			, @Msg

		RETURN 2
	END

	BEGIN TRY
		-- Актуализация данните за кореспондиращата сметка
		IF IsNull(@DEALS_CORR_TA_RowID, 0) > 0
			AND @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [DEAL_NUM] = 0 					-- DEALS_CORR_TA	DEAL_NUM	Номер на кореспондираща сделка
				, [UI_CORR_ACCOUNT] = '' 		-- DEALS_CORR_TA	UI_CORR_ACCOUNT	Партида на кореспондиращата сделка
				, [TAX_UNCOLLECTED_SUM] = 0 	-- DEALS_CORR_TA	TAX_UNCOLLECTED_SUM	 /* @TODO: Трябва да я изчислим !!!... */ 
			FROM dbo.[DEALS_CORR_TA] [D]
			WHERE [D].[ROW_ID] = @DEALS_CORR_TA_RowID
		END

		-- Актуализация данните на пълномощника
		IF IsNull(@PROXY_CUSTOMERS_RowID, 0) > 0
			AND @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_CUSTOMER_ID] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				, [UI_EGFN] = '0' 					-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				, [NAME] = '' 						-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				, [COMPANY_EFN] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				, [UI_CLIENT_CODE] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				, [UI_NOTES_EXIST] = 0				-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				, [IS_ZAPOR] = 0 					-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				, [ID_NUMBER] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				, [SERVICE_GROUP_EGFN] = '0' 		-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				, [IS_ACTUAL] = 0 					-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				, [PROXY_COUNT] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			WHERE [D].[ROW_ID] = @PROXY_CUSTOMERS_RowID
		END

		-- Актуализация данните на сделката
		IF @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_DEAL_NUM] = 0 -- RAZPREG_TA	UI_DEAL_NUM	
				, [DB_ACCOUNT] = '' -- RAZPREG_TA	DB_ACCOUNT	
				, [UI_ACCOUNT] = '' /* TODO: new function + date in TA TABLE */ -- RAZPREG_TA	UI_ACCOUNT 
				, [ZAPOR_SUM] = '' -- RAZPREG_TA	ZAPOR_SUM	Сума на запор по сметката (за целите на плащания по запор)
				, [IBAN] = '' -- RAZPREG_TA	IBAN	
				, [TAX_UNCOLLECTED_SUM] = '' -- RAZPREG_TA	TAX_UNCOLLECTED_SUM	Сума на неплатените такси. Ако няма да се записва 0.00
			FROM dbo.[RAZPREG_TA] [D]
			WHERE [D].[ROW_ID] IN (
					@RAZPREG_TA_RowID
					, @RAZPREG_TA_BEN_RowID
					)
		END

		-- Актуализация данните на клиента
		IF @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_CUSTOMER_ID] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				, [UI_EGFN] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				, [NAME] = '' 					-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				, [COMPANY_EFN] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				, [UI_CLIENT_CODE] = '0' 		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				, [UI_NOTES_EXIST] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				, [IS_ZAPOR] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				, [ID_TYPE] = 0
				, [ID_NUMBER] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				, [SERVICE_GROUP_EGFN] = '0' 	-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				, [IS_ACTUAL] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				, [PROXY_COUNT] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			WHERE [D].[ROW_ID] = @DT015_CUSTOMERS_RowID
		END

		-- Актуализация данните за документа ( за сега само код на такса и преференция )
		IF @IsNotFirstCashPaymentWithAccumulatedTax = 0 AND @REGISTER_TYPE = 'PREV_COMMON_TA'
		BEGIN
			UPDATE [D]
			SET [TAX_CODE] = 0 /* код на такса */
				, [PREF_CODE] = 0 /* код на преференция */
			FROM dbo.[PREV_COMMON_TA] [D]
			WHERE [D].[ROW_ID] = @TA_RowID
		END

		-- Зануляваме данните за бенефициена 
		IF IsNull(@CUSTOMER_BEN_ROW_ID, 0) > 0
			AND @IsNotFirstCashPaymentWithAccumulatedTax = 0
		BEGIN
			UPDATE [D]
			SET [UI_CUSTOMER_ID] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_CUSTOMER_ID
				, [UI_EGFN] = '0' 				-- DT015_CUSTOMERS_ACTIONS_TA	UI_EGFN
				, [NAME] = '' 					-- DT015_CUSTOMERS_ACTIONS_TA	NAME
				, [COMPANY_EFN] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	COMPANY_EFN
				, [UI_CLIENT_CODE] = '0' 		-- DT015_CUSTOMERS_ACTIONS_TA	UI_CLIENT_CODE
				, [UI_NOTES_EXIST] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	UI_NOTES_EXIST
				, [IS_ZAPOR] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ZAPOR (дали има съдебен запор някоя от сделките на клиента) 	Да се разработи обслужване в тестовете
				, [ID_TYPE] = 0
				, [ID_NUMBER] = '0' 			-- DT015_CUSTOMERS_ACTIONS_TA	ID_NUMBER номер на лична карта
				, [SERVICE_GROUP_EGFN] = '0' 	-- DT015_CUSTOMERS_ACTIONS_TA	SERVICE_GROUP_EGFN	EGFN, което се попълва в допълнителния диалог за търсене според IS_SERVICE
				, [IS_ACTUAL] = 0 				-- DT015_CUSTOMERS_ACTIONS_TA	IS_ACTUAL (1 0)	Да се разработи обслужване в тестовете на клиенти с неактуални данни при 1
				, [PROXY_COUNT] = 0 			-- DT015_CUSTOMERS_ACTIONS_TA	PROXY_COUNT	Брой активни пълномощници
			FROM dbo.[DT015_CUSTOMERS_ACTIONS_TA] [D]
			WHERE [D].[ROW_ID] = @CUSTOMER_BEN_ROW_ID
		END
	END TRY

	BEGIN CATCH
		SELECT @Msg = dbo.FN_GET_EXCEPTION_INFO()

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Sql1
			, @Msg

		RETURN 3
	END CATCH

	/************************************************************************************************************/
	/* Log End Of Procedure */
	IF @LogBegEndProc = 1
	BEGIN
		SELECT @Msg = 'Duration: ' + dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + + ', TA Row ID: ' + @TestCaseRowID

		EXEC dbo.SP_SYS_LOG_PROC @@PROCID
			, @Msg
			, '*** End Execute Proc ***: dbo.dbo.SP_TA_EXISTING_ONLINE_DATA_FILL_TA_TABLES_CLEAR_CURRENT_DATA'
	END

	RETURN 0
END
GO

