
/**********************************************************************************************************/
/* Процедура за актуализация данните в на Таблица dbo.[DT015_CUSTOMERS_ACTIONS_TA] за титуляра и Proxy-то*/
DROP PROCEDURE IF EXISTS dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]
GO

CREATE PROCEDURE dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]
(
	@OnleneSqlServerName	sysname
,	@OnleneSqlDataBaseName	sysname
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

	declare @Sql2 nvarchar(4000) = N'', @Msg nvarchar(max) = N'', @Ret int = 0
	;
	/************************************************************************************************************/
	/* Log Begining of Procedure execution */
	if @LogBegEndProc = 1 exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, '*** Begin Execute Proc ***: dbo.[SP_CASH_PAYMENTS_UPDATE_CLIENT_DATA]'
	;

	/************************************************************************************************************/
	-- Check customer ID
	if IsNull(@Customer_ID,0) <= 0
	begin  
		select @Msg = N'Incorrect CustomerID : ' + IsNull(@Customer_ID,0) + N', TA ROW_ID : ' + @TestCaseRowID;
		exec dbo.SP_SYS_LOG_PROC @@PROCID, @TestCaseRowID, @Msg
		return -1;
	end 

	/************************************************************************************************************/
	-- Актуализация на данните за титуляря и Proxy-то...
	-- Първо актуализираме данните на Proxy-то	
	if IsNull(@ProxyCustomer_ID,0) > 0
	begin
		begin try 
			select @Sql2 = N'dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnleneSqlServerName = '+@OnleneSqlServerName
						+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName
						+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
						+', @TestCaseRowID = '+@TestCaseRowID
						+', @OnlineDbCustomer_ID = '+str(@ProxyCustomer_ID,len(@ProxyCustomer_ID),0)
						+', @IsProxy = 1,'
						+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)


			exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnleneSqlServerName, @OnleneSqlDataBaseName
				, @CurrAccountDate, @TestCaseRowID, @ProxyCustomer_ID, 1, @WithUpdate;

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
		select @Sql2 = N'dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnleneSqlServerName = '+@OnleneSqlServerName
					+', @OnleneSqlDataBaseName = '+@OnleneSqlDataBaseName
					+', @CurrAccountDate = '+convert(varchar(16), @CurrAccountDate,23)
					+', @TestCaseRowID = '+@TestCaseRowID
					+', @OnlineDbCustomer_ID = '+str(@Customer_ID,len(@Customer_ID),0)
					+', @IsProxy = 0,'
					+', @WithUpdate = '+str(@WithUpdate,len(@WithUpdate),0)


		exec @Ret = dbo.[SP_CASH_PAYMENTS_UPDATE_DT015_CUSTOMERS_ACTIONS_TA] @OnleneSqlServerName, @OnleneSqlDataBaseName
			, @CurrAccountDate, @TestCaseRowID, @Customer_ID, 0, @WithUpdate;

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
