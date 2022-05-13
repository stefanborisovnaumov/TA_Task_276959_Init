/*********************************************************************************/
/* 1. Връзки м/у записите в TA таблиците: */
--вносна бележка--
select 'PREV_COMMON_TA' AS TABLE_NAME 
	,	'вносна бележка' AS TABLE_DESCRIPTION
	,	* 
from PREV_COMMON_TA
where ROW_ID = '400003'
go

--сделка--
select 'RAZPREG_TA' AS TABLE_NAME 
	,	'сделка' AS TABLE_DESCRIPTION
	,	*
from RAZPREG_TA
where ROW_ID = '200010'
go


--титуляр
select 'DT015_CUSTOMERS_ACTIONS_TA' AS TABLE_NAME 
	,	'титуляр' AS TABLE_DESCRIPTION
	,	*
from DT015_CUSTOMERS_ACTIONS_TA
where ROW_ID = '100025'
go

----има ли титуляра пълномощник:
--select 'PROXY_SPEC_TA' AS TABLE_NAME 
--	,	'има ли титуляра пълномощник' AS TABLE_DESCRIPTION
--	,	[PROXY_CLIENT_ID]
--from [PROXY_SPEC_TA]
--where REF_ID = '100025'
--go

--кой е пълномощника пълномощник:
select 'PROXY_SPEC_TA' AS TABLE_NAME 
	,	'кой е пълномощника пълномощник' AS TABLE_DESCRIPTION
	,	[PROXY_CLIENT_ID] 
	,	*
from PROXY_SPEC_TA
where REF_ID = '100025'
go

-- Данни за пълномощника 
select 'DT015_CUSTOMERS_ACTIONS_TA' AS TABLE_NAME 
	,	'Данни за пълномощника' AS TABLE_DESCRIPTION
	,	*
from DT015_CUSTOMERS_ACTIONS_TA
where REF_ID = '100400'
go

/*********************************************************************************/
-- 2. Актуализация на данните 
--Kъде трябва да се актуализират данните за пълномощника
select * 
from DT015_CUSTOMERS_ACTIONS_TA
where ROW_ID = '100400'
go

--Има и връзка между Prev_common_ta и DT015_CUSTOMERS_ACTIONS_TA, която изповаме за да знаем с кое ЕГН да влезем в сесия, когато влизаме с пълномощник.
select PROXY_ROW_ID 
from PREV_COMMON_TA
where ROW_ID = '400003'
go

--така пак се стига до тук:
--Пълномощник--
select * 
from DT015_CUSTOMERS_ACTIONS_TA
where ROW_ID in
(select PROXY_ROW_ID from PREV_COMMON_TA
where ROW_ID = '400003')
go

--Титуляр--
select * from DT015_CUSTOMERS_ACTIONS_TA
where ROW_ID in
(
	select REF_ID from RAZPREG_TA where ROW_ID in
	( select REF_ID from PREV_COMMON_TA where ROW_ID = '400003') )
go