	declare @CUSTOMER_ID int = 1500015, @AccountDate datetime = getdate()
	;
	Declare @StsBlockReasonDistraint int = dbo.SETBIT(cast(0 as binary(4)), 11, 1) /* STS_BLOCK_REASON_DISTRAINT (11)*/ 
	;
	select top (1)  
			[CUST].[CUSTOMER_ID]
		,	[CUST].[IDENTIFIER]				AS [UI_EGFN]
		,	[CUST].[CUSTOMER_NAME]			AS [CUSTOMER_NAME]
		,	[CUST].[COMPANY_EFN]			AS [COMPANY_EFN]	
		,	[MCLC].[CL_CODE]				AS [MAIN_CLIENT_CODE]
		,	[NOTE].[UI_NOTES_EXIST]			AS [UI_NOTES_EXIST]
		,	[XF].[IS_ZAPOR]					AS [IS_ZAPOR]			/* [IS_ZAPOR] : (дали има съдебен запор някоя от сделките на клиента) */
		,	[DOC].[ID_NUMBER]				AS [ID_NUMBER]			/* [ID_NUMBER] Номера на: лична карта; паспорт; шофьорска книжка ... */
		,	[XF].[SERVICE_GROUP_EGFN]		AS [SERVICE_GROUP_EGFN]	/* TODO: [SERVICE_GROUP_EGFN]: */
		,	[XF].[IS_ACTUAL]				AS [IS_ACTUAL]			/* TODO: [IS_ACTUAL]: ?!?*/
		,	[PR].[PROXY_COUNT]				AS [PROXY_COUNT]
	from BPB_VCSBank_Online.dbo.[DT015_CUSTOMERS] [CUST] WITH(NOLOCK)
	inner join BPB_VCSBank_Online.dbo.[DT015_MAINCODE_CUSTID] [MCLC] WITH(NOLOCK)
		ON [MCLC].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
	cross apply (
		select	0		as [IS_ZAPOR]
			,	''		AS [SERVICE_GROUP_EGFN]
			,	0		AS [IS_ACTUAL]
	) [XF]
	outer apply (
		select top(1) count(distinct [CRL].[REPRESENTATIVE_CUSTOMER_ID]) AS [PROXY_COUNT]
		from BPB_VCSBank_Online.dbo.CUSTOMERS_RIGHTS_AND_LIMITS [CRL] WITH(NOLOCK)
		inner join BPB_VCSBank_Online.dbo.[PROXY_SPEC] [PS] WITH(NOLOCK)
			on	[PS].[REPRESENTED_CUSTOMER_ID]	  = [CRL].REPRESENTED_CUSTOMER_ID
			and [PS].[REPRESENTATIVE_CUSTOMER_ID] = [CRL].REPRESENTATIVE_CUSTOMER_ID
		inner join BPB_VCSBank_Online.dbo.[REPRESENTATIVE_DOCUMENTS] [D] WITH(NOLOCK)
			on [D].[PROXY_SPEC_ID] = [PS].[ID]
			and ( [D].[INDEFINITELY] = 1 OR [D].[VALIDITY_DATE] >= @AccountDate)
		where [CRL].REPRESENTED_CUSTOMER_ID = [CUST].[CUSTOMER_ID]
			and [CRL].[CHANNEL] = 1	
	) [PR]
	outer apply (
		select top (1) cast( 1 as bit) as [UI_NOTES_EXIST]
		from BPB_VCSBank_Online.dbo.[DT015_NOTES] [n] with(nolock)
		where [n].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [n].[CLIENT_NOTETYPE] = 1 /* enum ClientNoteType : ClientNoteTypeExtraData = 1 */
	) [NOTE]
	outer apply (
		select top(1) [NM405_DOCUMENT_TYPE]	as [DOCUMENT_TYPE]
			,	[DOCUMENT_NUMBER]			as [ID_NUMBER]
			,	[ISSUER_COUNTRY_CODE]		as [ISSUER_COUNTRY_CODE]
		from BPB_VCSBank_Online.dbo.[DT015_IDENTITY_DOCUMENTS] [d] with(nolock)
		where [d].[CUSTOMER_ID] = [CUST].[CUSTOMER_ID]
			and [d].[NM405_DOCUMENT_TYPE] IN ( 1, 7, 8 ) /* 1 - Лична карта; 7 - Паспорт; 8 - Шофьорска книжка */
		order by [d].[NM405_DOCUMENT_TYPE]
	) [DOC]
	where [CUST].[CUSTOMER_ID] = @CUSTOMER_ID -- ' + str(@CUSTOMER_ID,len(@CUSTOMER_ID),0)