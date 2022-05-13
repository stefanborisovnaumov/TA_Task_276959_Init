select	TOP (1000)
		[P].[PART_ID] 
	,	[P].DEAL_NUMBER
	,	[P].[BDAY_CURRENCY_DT]
	,	[P].[BDAY_CURRENCY_KT]
	,	[r].[INT_SUM_DAY]
	,	[BAL].ACC_BAL
	,	[SD].SAL_DIFF
	,	[DM].[DAY_PBAL]

	,	[DM].[VP_DBT]
	,	[DM].[VP_KRT]
	,	[DM].[VNR_DBT]
	,	[DM].[VNR_KRT]
	,	[DM].[VNB_DBT]
	,	[DM].[VNB_KRT]

	,	[FM].[VNR_DBT]	AS [F_VNR_DBT]
	,	[FM].[VNR_KRT]	AS [F_VNR_KRT]
	,	[FM].[VNB_DBT]	AS [F_VNB_DBT]
	,	[FM].[VNB_KRT]	AS [F_VNB_KRT]
from dbo.[PARTS] [P] with(nolock)
inner join dbo.[RAZPREG] [R] with(nolock)
	on	[R].[DEAL_NUM]	= [P].[DEAL_NUMBER]
	and [P].[DEAL_TYPE] = 1
	AND [R].[DEAL_NUM]	IN (2437321, 1643836, 1644918, 1647721, 1648156, 1649308, 1649324, 1650913, 1651265, 1657361)
--inner join dbo.[FUTURE_MOVEMENTS] [fmov] with(nolock)
--	on [fmov].IDENT = [P].[PART_ID] 
outer apply (
	select top (1) 
			case when [P].[PART_TYPE] IN ( 1, 2, 5 )
				then [M].[VP_DBT] - [M].[VP_KRT]
				else [M].[VP_KRT] - [M].[VP_DBT]	end [DAY_PBAL]
		,	[M].*
	from dbo.[DAY_MOVEMENTS] [M] with(nolock)
	where [M].[IDENT] = [P].[PART_ID]
) [DM]
outer apply (
	select top (1)
			case when [P].[PART_TYPE] IN ( 1, 2, 5 )
				then [M].[VP_DBT] - [M].[VP_KRT]
				else [M].[VP_KRT] - [M].[VP_DBT]	end [DAY_PBAL]
		,	[M].*
	from dbo.[FUTURE_MOVEMENTS] [M] with(nolock)
	where [M].[IDENT] = [P].[PART_ID]
) [FM]
cross apply (
	select	cast(	case when [P].[PART_TYPE] IN ( 1, 2, 5 )
						then ([P].[BDAY_CURRENCY_DT] - [P].[BDAY_CURRENCY_KT])
						else ([P].[BDAY_CURRENCY_KT] - [P].[BDAY_CURRENCY_DT]) end
					+ IsNull([DM].[DAY_PBAL], 0.0 )
				AS numeric(18,4) )	as [ACC_BAL]

		,	cast(	IsNull([DM].[VNR_DBT], 0.0) + IsNull([FM].[VNR_DBT], 0.0)
				AS numeric(18,4) )	as [DBT_RED_N]

		,	cast(	IsNull([DM].[VNR_KRT], 0.0) + IsNull([FM].[VNR_KRT], 0.0)
				AS numeric(18,4) )	as [KDT_RED_N]

		,	cast(	IsNull([DM].[VNB_DBT], 0.0) + IsNull([FM].[VNB_DBT], 0.0)
				AS numeric(18,4) )	as [DBT_BLACK_N]

		,	cast(	IsNull([DM].[VNB_KRT], 0.0) + IsNull([FM].[VNB_KRT], 0.0)
				AS numeric(18,4) )	as [KDT_BLACK_N]
) [BAL]
cross apply (
	select cast([BAL].[ACC_BAL] - [r].[INT_SUM_DAY] AS NUMERIC(18,2)) as [SAL_DIFF]
) [SD]
--WHERE ABS([SD].[SAL_DIFF]) > 0.02
--	AND ABS([SD].[SAL_DIFF] - [DM].[DAY_PBAL]) > 0.02
go


select * from sys.tables 
where name like 'dt015%'
	and name not like  '%UNIFIED'
order by name
go

select * from DT015_IDENTITY_DOCUMENTS
GO
