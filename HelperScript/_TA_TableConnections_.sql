--вносна бележка--
select 'PREV' AS [REG], * 
from PREV_COMMON_TA
where ROW_ID = '400003'--сделка--
go

select 'DEAL' AS [REG], * 
from RAZPREG_TA
	where ROW_ID = '200010'--титуляр
go

select 'CUST' AS [REG], * 
from DT015_CUSTOMERS_ACTIONS_TA
	where ROW_ID = '100025'
go

--има ли титуляра пълномощник:
select 'SPEC' AS [REG], * 
from PROXY_SPEC_TA
	where REF_ID = '100025'--кой е пълномощника пълномощник:
go

--select PROXY_CLIENT_ID from PROXY_SPEC_TA
--	where REF_ID = '100025'--Kъде трябва да се актуализират данните за пълномощника
--go

select 'PROXY' AS [REG], * 
from DT015_CUSTOMERS_ACTIONS_TA
	where ROW_ID = '100400'
go

--Има и връзка между Prev_common_ta и DT015_CUSTOMERS_ACTIONS_TA, която изповаме за да знаем с кое ЕГН да влезем в сесия, когато влизаме с пълномощник.
select PROXY_ROW_ID from PREV_COMMON_TA
	where ROW_ID = '400003'--така пак се стига до тук:
go

--Пълномощник--
select * from DT015_CUSTOMERS_ACTIONS_TA
where ROW_ID in
(select PROXY_ROW_ID from PREV_COMMON_TA

	where ROW_ID = '400003'
)
go

--Титуляр--
select * from DT015_CUSTOMERS_ACTIONS_TA
where ROW_ID in (select REF_ID from RAZPREG_TA where ROW_ID in (select REF_ID from PREV_COMMON_TA where ROW_ID = '400003') )
go

/******************************************************************/
declare @TestCaseID int = '400002'
;
-- View което показва само данните подлежащи на актуализация
select * from dbo.[VIEW_TA_EXISTING_ONLINE_DATA_TEST_CASE_DATA]
where [ROW_ID] = @TestCaseID
;

-- Преглед на всички данни:
select * 
--вносна бележка--
from dbo.[PREV_COMMON_TA] [PREV] WITH(NOLOCK)
/* Сделка */
INNER JOIN dbo.[RAZPREG_TA] [DEAL] WITH(NOLOCK)
	ON [PREV].[REF_ID] = [DEAL].[ROW_ID]
/* Титуляр */
INNER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [CUST] WITH(NOLOCK)
	ON [CUST].[ROW_ID] = [DEAL].[REF_ID]
/* Връзка към пълномощник */
LEFT OUTER JOIN dbo.[PROXY_SPEC_TA] [PSPEC] WITH(NOLOCK)
	ON [PSPEC].[REF_ID] = [DEAL].[REF_ID]
/* Даннни за пълномощник */
LEFT OUTER JOIN dbo.[DT015_CUSTOMERS_ACTIONS_TA] [PROXY] WITH(NOLOCK)
	ON [PROXY].[ROW_ID] = [PSPEC].[PROXY_CLIENT_ID]
where [PREV].[ROW_ID] = @TestCaseID 
go

