
/**********************************************************************************************************/
/* Процедура за актуализация данните в на Таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA] за титуляра и Proxy-то*/
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]
(
	@OnlineSqlServerName	sysname
,	@OnlineSqlDataBaseName	sysname
,	@CurrAccountDate		datetime
,	@TestCaseRowID			nvarchar(16)
,	@Customer_ID			int
,	@ProxyCustomer_ID		int
,	@WithUpdate				int = 0
)
AS 
begin

	declare @LogTraceInfo int = 0,	@LogBegEndProc int = 1,	@TimeBeg datetime = GetDate();
	;

	declare @Sql2 nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Ret int = 0, @TA_RowID int = cast(@TestCaseRowID as int)
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]'
	;

	/************************************************************************************************************/
	-- Check customer ID
	if IsNull(@Customer_ID,0) <= 0
	begin  
		select @Msg = N'Incorrect CustomerID : ' + str(@Customer_ID,len(@Customer_ID),0) + N', TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return -1;
	end

	/************************************************************************************************************/
	-- Find customer row id:
	declare @CUSTOMER_ROW_ID int = 0
		,	@CUST_PROXY_ROW_ID int = 0
		,	@CUST_BEN_ROW_ID int = 0
		,	@DEAL_BEN_ROW_ID int = 0
	;

	select	@CUSTOMER_ROW_ID = IsNull([CUST_ROW_ID],-1)
		,	@CUST_PROXY_ROW_ID = IsNull([PROXY_ROW_ID],-1)
		,	@CUST_BEN_ROW_ID = IsNull([CUST_BEN_ROW_ID],-1)
		,	@DEAL_BEN_ROW_ID = IsNull([DEAL_BEN_ROW_ID],-1)
	from dbo.[VIEW_CASH_PAYMENTS_CONDITIONS] with(nolock)
	where [ROW_ID] = @TA_RowID
	;

	if IsNull(@CUSTOMER_ROW_ID,-1) <= 0 
	begin  
		select @Msg = N'Not found TA Customer ROW_ID : ' + str(@CUSTOMER_ROW_ID,len(@CUSTOMER_ROW_ID),0) 
			+ N', CustomerID : ' + str(@Customer_ID,len(@Customer_ID),0)
			+ N', TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return -1;
	end

	/************************************************************************************************************/
	-- Find customer row id:
	declare @Ben_Customer_ID int = 0 /* Customer ID on OnlineDb for Beneficiary */
	;
	if @DEAL_BEN_ROW_ID > 0 
	begin 
		select @Ben_Customer_ID = IsNull([S].[CUSTOMER_ID],-1)
		from dbo.[RAZPREG_TA] [R] with(nolock)
		inner join dbo.[AGR_CASH_PAYMENTS_DEALS] [S] with(nolock)
			on	[S].[DEAL_TYPE] = 1
			and [R].[UI_DEAL_NUM] = [S].[DEAL_NUM] 
	end

	/************************************************************************************************************/
	-- Актуализация на данните за титуляря и Proxy-то...
	-- Първо актуализираме данните на Proxy-то	
	if IsNull(@ProxyCustomer_ID,0) > 0 and IsNull(@CUST_PROXY_ROW_ID,0) > 0
	begin
		begin try 
			select @Sql2 = N'dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName = '+@OnlineSqlServerName
						+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
						+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
						+', @TestCaseRowID = '+@TestCaseRowID
						+', @OnlineDbCustomer_ID = '+str(@ProxyCustomer_ID,len(@ProxyCustomer_ID),0)
						+', @TA_CUST_ROW_ID = ' +str(@CUST_PROXY_ROW_ID,len(@CUST_PROXY_ROW_ID),0)+ '/* for Proxy */'
						+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)

			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName, @OnlineSqlDataBaseName
				, @CurrAccountDate, @TestCaseRowID, @ProxyCustomer_ID, @CUST_PROXY_ROW_ID, @WithUpdate;

			if @Ret <> 0
			begin 
				select @Msg = N'Error exec procedure dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA], error code:'+str(@Ret,len(@Ret),0)
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 1;
			end

		end try
		begin catch
				select @Msg = dbo.FN_GET_EXCEPTION_INFO() 
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 2;
		end catch
	end

	-- Aктуализираме данните на Титуляра
	begin try 
		select @Sql2 = N'dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName = '+@OnlineSqlServerName
					+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
					+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
					+', @TestCaseRowID = '+@TestCaseRowID
					+', @OnlineDbCustomer_ID = '+str(@Customer_ID,len(@Customer_ID),0)
					+', @TA_CUST_ROW_ID = ' +str(@CUSTOMER_ROW_ID,len(@CUSTOMER_ROW_ID),0)+ '/* for Main Customer */'
					+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)

		exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName, @OnlineSqlDataBaseName
			, @CurrAccountDate, @TestCaseRowID, @Customer_ID, @CUSTOMER_ROW_ID, @WithUpdate;

		if @Ret <> 0
		begin 
			select @Msg = N'Error exec procedure dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA], error code:'+str(@Ret,len(@Ret),0)
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 3;
		end
	end try
	begin catch
			select @Msg = dbo.FN_GET_EXCEPTION_INFO() 
			exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
			return 4;
	end catch

	-- Aктуализираме данните на Бенефициента
	if IsNull(@Ben_Customer_ID,0) > 0 and IsNull(@CUST_BEN_ROW_ID,0) > 0
	begin
		begin try 
			select @Sql2 = N'dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName = '+@OnlineSqlServerName
						+', @OnlineSqlDataBaseName = '+@OnlineSqlDataBaseName
						+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
						+', @TestCaseRowID = '+@TestCaseRowID
						+', @OnlineDbCustomer_ID = '+str(@Ben_Customer_ID,len(@Ben_Customer_ID),0)
						+', @TA_CUST_ROW_ID = ' +str(@CUST_BEN_ROW_ID,len(@CUST_BEN_ROW_ID),0)+ '/* for Beneficiary */'
						+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)


			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnlineSqlServerName, @OnlineSqlDataBaseName
				, @CurrAccountDate, @TestCaseRowID, @Ben_Customer_ID, @CUST_BEN_ROW_ID, @WithUpdate;

			if @Ret <> 0
			begin 
				select @Msg = N'Error exec procedure dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA], error code:'+str(@Ret,len(@Ret),0)+ ' /* for Beneficiary */ '
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 5;
			end
		end try
		begin catch
				select @Msg = dbo.FN_GET_EXCEPTION_INFO() + ' /* for Beneficiary */ '
				exec dbo.SP_SYS_LOG_PROC @@PROCID, @Sql2, @Msg
				return 6;
		end catch	
	end

	/************************************************************************************************************/
	/* Log End Of Procedure */
	if @LogBegEndProc = 1
	begin 
		select @Msg = 'Duration: '+ dbo.FN_GET_TIME_DIFF(@TimeBeg, GetDate()) + 
			 + ', TA Row ID: '+@TestCaseRowID
			 + ', @Customer_ID: '+str(@Customer_ID,len(@Customer_ID),0)
			 + ', @ProxyCustomer_ID: '+str(@ProxyCustomer_ID,len(@ProxyCustomer_ID),0);
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @Msg, '*** End Execute Proc ***: dbo.dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]'
	end

	return 0;
end
go
