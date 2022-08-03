/*******************************************************************************************************************************/
-- Скрипт за актуализация (попълване) на некоректни и/или не попълнените данни на чуждестранните граждани, както следва:
--	- Дата на раждане - на 19011111
--	- Страна на раждане - на Италия (12)
--	- Град на раждане - за Италия на 'MY MILANO', а за останалите на 'MY HOMETOWN'
--	- TIN - Записваме като префикс '19011111' и допълваме с 0-ли според указаната дължината за TIN-а в NM177
/*******************************************************************************************************************************/

/* 1. Актуализация датата на раждане за чуждестранните физически лица, на който датата е некоректно на 19011111: */
update [CUST]
set [BIRTH_DATE] = 19011111
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
where [CUST].ECONOMIC_SECTOR in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in ( 1, 4, 5, 6 ) /*  1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [CUST].[BIRTH_DATE] < 18010101
go

/* 2.1. Попълване на мястото на раждане за чуждестранните физически лица (страна и град): */
update [NAP]
set	[BIRTH_CNTR] = 12
,	[BIRTH_TWN]  = 'MY MILANO'
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
INNER JOIN dbo.[DT015NAP] [NAP]
	on [NAP].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
where [CUST].[ECONOMIC_SECTOR] in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in ( 1, 4, 5, 6 ) /* 1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [BIRTH_CNTR] = 0 and [BIRTH_TWN] = ''
go

/* 2.2. Попълване на мястото на раждане за чуждестранните физически лица (град): */
update [NAP]
set	[BIRTH_TWN]  = 'MY HOMETOWN'
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
INNER JOIN dbo.[DT015NAP] [NAP]
	on [NAP].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
where [CUST].[ECONOMIC_SECTOR] in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in ( 1, 4, 5, 6 ) /* 1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [BIRTH_CNTR] > 0 and [BIRTH_TWN] = ''
go

/* 3. Попълваме TIN за чуждестранните физически лица с некоректни данни: */
update [NAP]
set	[NO_TIN_AVAILABLE] = 2
,	[CODE_TIN] = [NEW_TIN].[TIN]
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
INNER JOIN dbo.[DT015NAP] [NAP]
	on [NAP].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
inner join dbo.[nm177] [CNTR] WITH(NOLOCK)
	on [CNTR].[CODE] = [NAP].[RESIDENCE_CNTR]
cross apply (
	SELECT CASE WHEN [CNTR].[TIN_LENGTH_FL] < 8 THEN '1901111100'
				WHEN [CNTR].[TIN_LENGTH_FL] = 8 THEN '19011111'
				WHEN [CNTR].[TIN_LENGTH_FL] > 8 THEN '19011111' + REPLACE(STR(0,([CNTR].[TIN_LENGTH_FL]-8), 0), ' ','0')
				ELSE 'No TIN available'	END AS [TIN]
) [NEW_TIN]
where [CUST].[ECONOMIC_SECTOR] in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in (1, 4, 5, 6) /* 1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [CNTR].[IS_TIN_SUPPORTED_FL] in ( 1 ) /* Само за страната поддържащи TIN за физическите лица */
	and [NAP].[CODE_TIN] = '' 
go

/* 4.1. Ако страната за TIN не съвпада с някоя от страните на адресите, и кода на страната за кореспонденция не е попълнен, ще го попълним с този от TIN-a */
UPDATE [CUST]
SET [CORRESPONDENCE_ADDRESS_COUNTRY] = [NAP].[RESIDENCE_CNTR]
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
INNER JOIN dbo.[DT015NAP] [NAP]
	on [NAP].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
inner join dbo.[nm177] [CNTR] WITH(NOLOCK)
	on [CNTR].[CODE] = [NAP].[RESIDENCE_CNTR]
where [CUST].[ECONOMIC_SECTOR] in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in (1, 4, 5, 6) /* 1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [CNTR].[IS_TIN_SUPPORTED_FL] in ( 1 ) /* Само за страната поддържащи TIN за физическите лица */
	and [NAP].[RESIDENCE_CNTR] > 0
	and [NAP].[RESIDENCE_CNTR] not in ([CUST].[CORRESPONDENCE_ADDRESS_COUNTRY], [CUST].[REGISTERED_ADDRESS_COUNTRY], [CUST].[CURRENT_ADDRESS_COUNTRY])
	and [CUST].[CORRESPONDENCE_ADDRESS_COUNTRY] <= 0
go

/* 4.2. Ако страната за TIN не съвпада с някоя от страните на адресите, и кода на страната за регистрация не е попълнен, ще го попълним с този от TIN-a */
UPDATE [CUST]
SET [REGISTERED_ADDRESS_COUNTRY] = [NAP].[RESIDENCE_CNTR]
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
INNER JOIN dbo.[DT015NAP] [NAP]
	on [NAP].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
inner join dbo.[nm177] [CNTR] WITH(NOLOCK)
	on [CNTR].[CODE] = [NAP].[RESIDENCE_CNTR]
where [CUST].[ECONOMIC_SECTOR] in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in (1, 4, 5, 6) /* 1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [CNTR].[IS_TIN_SUPPORTED_FL] in ( 1 ) /* Само за страната поддържащи TIN за физическите лица */
	and [NAP].[RESIDENCE_CNTR] > 0
	and [NAP].[RESIDENCE_CNTR] not in ([CUST].[CORRESPONDENCE_ADDRESS_COUNTRY], [CUST].[REGISTERED_ADDRESS_COUNTRY], [CUST].[CURRENT_ADDRESS_COUNTRY])
	and [CUST].[REGISTERED_ADDRESS_COUNTRY] <= 0
go

/* 4.3. Ако страната за TIN не съвпада с някоя от страните на адресите, и кода на страната за текущ адрес не е попълнен, ще го попълним с този от TIN-a */
UPDATE [CUST]
SET [CURRENT_ADDRESS_COUNTRY] = [NAP].[RESIDENCE_CNTR]
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
INNER JOIN dbo.[DT015NAP] [NAP]
	on [NAP].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
inner join dbo.[nm177] [CNTR] WITH(NOLOCK)
	on [CNTR].[CODE] = [NAP].[RESIDENCE_CNTR]
where [CUST].[ECONOMIC_SECTOR] in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in (1, 4, 5, 6) /* 1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [CNTR].[IS_TIN_SUPPORTED_FL] in ( 1 ) /* Само за страната поддържащи TIN за физическите лица */
	and [NAP].[RESIDENCE_CNTR] > 0
	and [NAP].[RESIDENCE_CNTR] not in ([CUST].[CORRESPONDENCE_ADDRESS_COUNTRY], [CUST].[REGISTERED_ADDRESS_COUNTRY], [CUST].[CURRENT_ADDRESS_COUNTRY])
	and [CUST].[CURRENT_ADDRESS_COUNTRY] <= 0
go

/* 4.4. Ако страната за TIN (все още) не съвпада с някоя от страните на адресите, кода на страната за текущ адрес ще го попълним с този от TIN-a */
update  [CUST]
set [CORRESPONDENCE_ADDRESS_COUNTRY] = [NAP].[RESIDENCE_CNTR]
from dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
INNER JOIN dbo.[DT015NAP] [NAP]
	on [NAP].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
inner join dbo.[nm177] [CNTR] WITH(NOLOCK)
	on [CNTR].[CODE] = [NAP].[RESIDENCE_CNTR]
where [CUST].[ECONOMIC_SECTOR] in (9400, 9999)
	and [CUST].[IDENTIFIER_TYPE] in (1, 4, 5, 6) /* 1 - 'ЕГН'; 4 - 'ЛНЧ'; 5 - 'Функционално ЕГН'; 6 - 'Функционално ЛНЧ (ЧФЛ) */
	and [CNTR].[IS_TIN_SUPPORTED_FL] in ( 1 ) /* Само за страната поддържащи TIN за физическите лица */
	and [NAP].[RESIDENCE_CNTR] not in ([CUST].[CORRESPONDENCE_ADDRESS_COUNTRY], [CUST].[REGISTERED_ADDRESS_COUNTRY], [CUST].[CURRENT_ADDRESS_COUNTRY])
go