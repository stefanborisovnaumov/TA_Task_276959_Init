/***************************************************************************************************************/
-- Име          : Стоян Серафимов
-- Дата и час   : 04.05.2022
-- Задача       : 
-- Класификация : TestAutomation
-- Описание     : TestAutomation
-- Параметри    : Няма
/***************************************************************************************************************/
IF EXISTS (SELECT * FROM SYS.TABLES WHERE NAME = 'CURRENCIES_TA')
DROP TABLE [dbo].[CURRENCIES_TA]
GO

CREATE TABLE [dbo].[CURRENCIES_TA](
	[ROW_ID] [int] IDENTITY(1, 1),
	[CODE] [char](3) NULL,
	[FIXING] [FLOAT] NULL,
	[BASE] [int] NULL,
	CONSTRAINT [PK_CURRENCIES_TA] PRIMARY KEY CLUSTERED ([ROW_ID])
) 
GO

INSERT INTO CURRENCIES_TA(CODE, FIXING, BASE) VALUES
('BGN', 1.00000, 1),
('USD', 1.75348, 1),
('EUR', 1.95583, 1),
('GBP', 2.47768, 1)
GO


IF EXISTS (SELECT * FROM SYS.TABLES WHERE NAME = 'TAXES_INFO_COMMISSION_TA')
BEGIN
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'TAX_OVER_SUM'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'UNTIL_SUM'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'CURRENCY'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'IS_DEFAULT_CURRENCY'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'COMMISSION_ORDER'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'TYPE'
	EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'TAX_CODE'
	DROP TABLE [dbo].[TAXES_INFO_COMMISSION_TA]
END
GO


CREATE TABLE [dbo].[TAXES_INFO_COMMISSION_TA](
	[ROW_ID] [int] IDENTITY(1,1),  
	[TAX_CODE] [int] NULL,
	[COMMISSION_CODE] [int] NULL,
	[TYPE] [varchar](50) NULL,
	[COMMISSION_ORDER] [int] NULL,
	[CONSTANT_SUM] [float] NULL,
	[PERCENTAGE] [float] NULL,
	[IS_DEFAULT_CURRENCY] [int] NULL,
	[CURRENCY] [varchar](20) NULL,
	[FROM_SUM] [float] NULL,
	[UNTIL_SUM] [float] NULL,
	[MIN_SUM] [float] NULL,
	[MAX_SUM] [float] NULL,
	[TAX_OVER_SUM] [int] NULL,
	[INCLUDE_TAX_IN_MIN_MAX] [int] NULL,
	[PREF_WITHOUT_DAILY_TURNOVER] [int] NULL,

	CONSTRAINT PK_TAXES_INFO_COMMISSION_TA PRIMARY KEY (ROW_ID)
) 
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Кода на такса' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'TAX_CODE'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Тип на такса: Tax - стандартна; Pref - преференциална' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'TYPE'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Поредност на комисионна' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'COMMISSION_ORDER'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Валута по подразбиране' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'IS_DEFAULT_CURRENCY'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Валута' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'CURRENCY'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'От сума' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'FROM_SUM'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'До сума' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'UNTIL_SUM'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Сума над таксата' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'TAX_OVER_SUM'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Таксата да се включва в min/max' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TAXES_INFO_COMMISSION_TA', @level2type=N'COLUMN',@level2name=N'INCLUDE_TAX_IN_MIN_MAX'
GO

/***************************************************************************************************************/
-- Име          : 
-- Дата и час   : 
-- Задача       : 
-- Класификация : 
-- Описание     : 
-- Параметри    : 
/***************************************************************************************************************/