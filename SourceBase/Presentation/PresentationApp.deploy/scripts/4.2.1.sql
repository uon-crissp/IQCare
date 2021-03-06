USE [IQCare]
GO

update AppAdmin set AppVer='4.2.1', DBVer='4.2.1', RelDate='15-Apr-2019'
go

if not exists(select * from mst_Regimen where RegimenName='OI Medicine')
begin
	insert into mst_RegimenLine(Name,DeleteFlag,SRNO,UserID,CreateDate) values('OI', 0,9,1,getdate())
	insert into mst_RegimenLine(Name,DeleteFlag,SRNO,UserID,CreateDate) values('HBB', 0,9,1,getdate())
	insert into mst_RegimenLine(Name,DeleteFlag,SRNO,UserID,CreateDate) values('PREP', 0,9,1,getdate())

	insert into mst_Regimen(RegimenID, Purpose,RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(76, 223,9,'OI','OI Medicine',0)
	insert into mst_Regimen(RegimenID, Purpose,RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(76, 223,9,'HPB1A','TDF + 3TC (HIV  -ve HepB patients)',0)
	insert into mst_Regimen(RegimenID, Purpose,RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(76, 223,9,'PRP1A','TDF + FTC (PrEP)',0)
end
go
--==

set identity_insert mst_module on
go
insert into mst_module(ModuleID, ModuleName, DeleteFlag,UserId,CreateDate,Status,UpdateFlag,PharmacyFlag)
values(300, 'Laboratory', 0, 1, getdate(), 2, 0,0)
go
set identity_insert mst_module off
go

if not exists(select * from lnk_PatientModuleIdentifier where ModuleID=300 and FieldID=1)
begin
	insert into lnk_PatientModuleIdentifier(ModuleID, FieldID) values(300,1)
end
go
--==

update mst_module set ModuleName = 'ART Clinic' where ModuleName='CCC Patient Card MoH 257'
update mst_module set ModuleName = 'TB Clinic' where ModuleName='TB Clinic Module'
update mst_module set ModuleName = 'Records' where ModuleName='RECORDS'
go
--==

update mst_Feature set FeatureName='CareEnd_ART Clinic' where FeatureName='CareEnd_CCC Patient Card MoH 257'
update mst_Feature set FeatureName='CareEnd_TB Clinic' where FeatureName='CareEnd_TB Clinic Module'
go
--==

if exists(select * from sysobjects where name='Pr_Laboratory_GetPendingLabOrders' and type='p')
	drop proc Pr_Laboratory_GetPendingLabOrders
go

create proc Pr_Laboratory_GetPendingLabOrders @DBKey varchar(50)
as
begin
	DECLARE @SymKey VARCHAR(400)
	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @DBKey + ''
	EXEC (@SymKey)

	DECLARE @allIDs AS VARCHAR(max)

	SELECT @allIDs = stuff((
				SELECT ',Case When Cast(a.[' + cast(fieldName AS VARCHAR(100)) + '] as varchar(50)) = '''' Then Null Else Cast(a.[' + cast(fieldName AS VARCHAR(100)) + '] as varchar(50)) End '
				FROM mst_patientidentifier
				FOR XML PATH('')
				), 1, 1, '')

	EXEC ('

	SELECT a.ptn_pk
	,Cast(coalesce(' + @allIDs + ') as varchar(50)) as PatientID
	,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname)) + '' '' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + '' '' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName)) AS Name
	,CONVERT(Varchar(17), b.CreateDate, 113) AS TimeOrdered
	,CONVERT(int,ROUND(DATEDIFF(hour,a.DOB,GETDATE())/8766.0,0)) AS Age
	,''New Lab Order'' as Status
	, c.Visit_Id as VisitId
	FROM mst_patient a
	inner join ord_PatientLabOrder b on a.ptn_pk = b.ptn_pk
	inner join ord_Visit c on b.VisitId = c.Visit_Id
	WHERE isnull(b.deleteflag,0) = 0
	and b.labid not in (select x.labid from mst_LabSpecimen x)
	and dbo.Fun_IQTouch_GetIDValue(LabId, ''LAB_ORD_STATUS'')=''Partial''
	AND (b.ReportedByDate IS NULL OR b.ReportedByDate = ''1900-01-01'')
	and CONVERT(VARCHAR(24),b.OrderedByDate,106) = CONVERT(VARCHAR(24),GETDATE(),106)
	order by b.CreateDate asc

	')
end
go
--==

if exists(select * from sysobjects where name='pr_Admin_GetCustomFormId' and type='p')
	drop proc pr_Admin_GetCustomFormId
go
create proc pr_Admin_GetCustomFormId
@Formname varchar(100)
as
begin
	if(@Formname='CareEnd')
	begin
		select top 1 a.FeatureID, a.FeatureName from mst_Feature a
		where a.FeatureName like '%'+@Formname+'%'
		and a.DeleteFlag=0 and a.ModuleId=203
	end
	else
	begin
		select top 1 a.FeatureID, a.FeatureName from mst_Feature a
		inner join lnk_SplFormModule b on a.featureid=b.featureid
		where a.FeatureName like '%'+@Formname+'%'
		and a.DeleteFlag=0 and b.ModuleId=203
	end
end
go
--==

alter PROCEDURE [dbo].[pr_Clinical_GetCustomFormFieldLabel_Constella] @FeatureId INT
	,@PatientId INT
	,@Password VARCHAR(40)
AS
BEGIN
	DECLARE @SymKey VARCHAR(400)
	DECLARE @FormVisitType INT
	DECLARE @VisitTypeId INT
	DECLARE @FeatureName VARCHAR(100)

	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @password + ''

	EXEC (@SymKey)

	--Table 0                                                                                                                                                                                  
	SELECT dbo.fn_PatientIdentificationNumber_Constella(a.ptn_pk, '', 1) [PatientIdentification]
		,(convert(VARCHAR(50), decryptbykey(a.firstname)) + ' ' + ISNULL(convert(VARCHAR(50), decryptbykey(a.MiddleName)), '') + ' ' + convert(VARCHAR(50), decryptbykey(a.lastName))) NAME
		,a.PatientClinicID
		,a.DOB
		,a.LocationID
	FROM mst_patient a
		,ord_visit b
	WHERE a.ptn_pk = b.ptn_pk
		AND b.Visittype = 12
		AND a.ptn_pk = @patientid

	----Table 1                                          
	SELECT *
	FROM (
		SELECT tbl1.FeatureId
			,tbl2.FeatureName
			,tbl1.SectionId
			,tbl3.SectionName
			,CASE tbl1.Predefined
				WHEN 1
					THEN '9999' + convert(VARCHAR, tbl1.FieldId)
				WHEN 0
					THEN '8888' + convert(VARCHAR, Tbl1.FieldId)
				END [FieldId]
			,tbl4.BindField [FieldName]
			,replace(tbl1.FieldLabel, '''', '') [FieldLabel]
			,tbl1.Predefined
			,UPPER(tbl4.PDFTableName) [PDFTableName]
			,tbl4.ControlId
			,tbl4.BindTable [BindSource]
			,tbl4.CategoryId [CodeId]
			,tbl1.Seq
			,tbl3.Seq [SeqSection]
			,tbl3.IsGridView
			,tbl7.TabId
			,tbl8.TabName
			,tbl8.seq [tabSeq]
			,tbl1.AdditionalInformation
		FROM Lnk_forms tbl1
		INNER JOIN mst_feature tbl2 ON tbl1.FeatureId = tbl2.FeatureID
		INNER JOIN mst_section tbl3 ON tbl1.SectionId = tbl3.SectionID
		INNER JOIN Mst_PreDefinedFields tbl4 ON tbl1.FieldId = tbl4.Id
		LEFT OUTER JOIN mst_pmtctcode tbl5 ON (
				tbl4.CategoryId = tbl5.CodeId
				AND tbl4.BindTable = 'Mst_PMTCTDecode'
				)
		LEFT OUTER JOIN mst_code tbl6 ON (
				tbl4.CategoryId = tbl6.CodeId
				AND Tbl4.BindTable = 'Mst_DeCode'
				)
		INNER JOIN dbo.lnk_FormTabSection tbl7 ON tbl1.FeatureId = tbl7.FeatureId
			AND tbl1.SectionId = tbl7.SectionId
		INNER JOIN dbo.Mst_FormBuilderTab tbl8 ON tbl7.TabId = tbl8.TabId
		WHERE tbl1.predefined = 1
			AND tbl1.FeatureId = @FeatureId
			AND tbl1.FieldId <> 71
			AND (
				tbl4.PatientRegistration IS NULL
				OR tbl4.PatientRegistration = 0
				)
			AND (
				tbl2.Deleteflag = 0
				OR tbl2.Deleteflag IS NULL
				)
		
		UNION
		
		SELECT tbl1.FeatureId
			,tbl2.FeatureName
			,tbl1.SectionId
			,tbl3.SectionName
			,tbl1.FieldId
			,'PlaceHolder' + Convert(VARCHAR, tbl1.Seq) + Convert(VARCHAR, tbl1.SectionId) [FieldName]
			,replace(tbl1.FieldLabel, '''', '') [FieldLabel]
			,tbl1.Predefined
			,UPPER(tbl4.PDFTableName) [PDFTableName]
			,tbl4.ControlId
			,tbl4.BindTable [BindSource]
			,tbl4.CategoryId [CodeId]
			,tbl1.Seq
			,tbl3.Seq [SeqSection]
			,tbl3.IsGridView
			,tbl7.TabId
			,tbl8.TabName
			,tbl8.seq [tabSeq]
			,tbl1.AdditionalInformation
		FROM Lnk_forms tbl1
		INNER JOIN mst_feature tbl2 ON tbl1.FeatureId = tbl2.FeatureID
		INNER JOIN mst_section tbl3 ON tbl1.SectionId = tbl3.SectionID
		INNER JOIN Mst_PreDefinedFields tbl4 ON 71 = tbl4.Id
		LEFT OUTER JOIN mst_pmtctcode tbl5 ON (
				tbl4.CategoryId = tbl5.CodeId
				AND tbl4.BindTable = 'Mst_PMTCTDecode'
				)
		LEFT OUTER JOIN mst_code tbl6 ON (
				tbl4.CategoryId = tbl6.CodeId
				AND Tbl4.BindTable = 'Mst_DeCode'
				)
		INNER JOIN dbo.lnk_FormTabSection tbl7 ON tbl1.FeatureId = tbl7.FeatureId
			AND tbl1.SectionId = tbl7.SectionId
		INNER JOIN dbo.Mst_FormBuilderTab tbl8 ON tbl7.TabId = tbl8.TabId
		WHERE tbl1.predefined = 1
			AND tbl1.FeatureId = @FeatureId
			AND tbl1.FieldId = 71
			AND (
				tbl4.PatientRegistration IS NULL
				OR tbl4.PatientRegistration = 0
				) --and substring(convert(varchar,tbl1.fieldid),3,5) = '00000'                                                
			AND (
				tbl2.Deleteflag = 0
				OR tbl2.Deleteflag IS NULL
				)
		
		UNION
		
		SELECT tbl1.FeatureId
			,tbl2.FeatureName
			,tbl1.SectionId
			,tbl3.SectionName
			,CASE tbl1.Predefined
				WHEN 1
					THEN '9999' + convert(VARCHAR, tbl1.FieldId)
				WHEN 0
					THEN '8888' + convert(VARCHAR, Tbl1.FieldId)
				END [FieldId]
			,tbl4.FieldName [FieldName]
			,replace(tbl1.FieldLabel, '''', '') [FieldLabel]
			,tbl1.Predefined
			,'PDFTableName' = Upper(CASE 
					WHEN ControlId = 11
						THEN NULL
					WHEN ControlId = 12
						THEN NULL
					WHEN ControlId = 16
						THEN NULL
					ELSE 'dtl_CustomField'
					END)
			,tbl4.ControlId
			,tbl4.BindTable [BindSource]
			,tbl5.CodeID
			,tbl1.Seq
			,tbl3.Seq [SeqSection]
			,tbl3.IsGridView
			,tbl7.TabId
			,tbl8.TabName
			,tbl8.seq [tabSeq]
			,tbl1.AdditionalInformation
		FROM Lnk_forms tbl1
		INNER JOIN mst_feature tbl2 ON tbl1.FeatureId = tbl2.FeatureID
		INNER JOIN mst_section tbl3 ON tbl1.SectionId = tbl3.SectionID
		INNER JOIN mst_CustomformField tbl4 ON tbl1.FieldId = tbl4.Id
		LEFT OUTER JOIN mst_Modcode tbl5 ON (
				tbl4.CategoryId = tbl5.CodeId
				AND tbl4.BindTable = 'Mst_ModDecode'
				)
		INNER JOIN dbo.lnk_FormTabSection tbl7 ON tbl1.FeatureId = tbl7.FeatureId
			AND tbl1.SectionId = tbl7.SectionId
		INNER JOIN dbo.Mst_FormBuilderTab tbl8 ON tbl7.TabId = tbl8.TabId
		WHERE tbl1.Predefined = 0
			AND tbl1.FeatureId = @FeatureId
			AND (
				tbl3.IsGridView <> 1
				OR tbl3.IsGridView IS NULL
				)
			AND (
				tbl4.PatientRegistration IS NULL
				OR tbl4.PatientRegistration = 0
				)
			AND (
				tbl2.Deleteflag = 0
				OR tbl2.Deleteflag IS NULL
				)
		
		UNION
		
		SELECT tbl1.FeatureId
			,tbl2.FeatureName
			,tbl1.SectionId
			,tbl3.SectionName
			,CASE tbl1.Predefined
				WHEN 1
					THEN '9999' + convert(VARCHAR, tbl1.FieldId)
				WHEN 0
					THEN '8888' + convert(VARCHAR, Tbl1.FieldId)
				END [FieldId]
			,tbl4.FieldName [FieldName]
			,replace(tbl1.FieldLabel, '''', '') [FieldLabel]
			,tbl1.Predefined
			,'PDFTableName' = Upper(CASE 
					WHEN ControlId = 11
						THEN NULL
					WHEN ControlId = 12
						THEN NULL
					WHEN ControlId = 16
						THEN NULL
					ELSE 'DTL_CUSTOMFORM'
					END)
			,tbl4.ControlId
			,tbl4.BindTable [BindSource]
			,tbl5.CodeID
			,tbl1.Seq
			,tbl3.Seq [SeqSection]
			,tbl3.IsGridView
			,tbl7.TabId
			,tbl8.TabName
			,tbl8.seq [tabSeq]
			,tbl1.AdditionalInformation
		FROM Lnk_forms tbl1
		INNER JOIN mst_feature tbl2 ON tbl1.FeatureId = tbl2.FeatureID
		INNER JOIN mst_section tbl3 ON tbl1.SectionId = tbl3.SectionID
		INNER JOIN mst_CustomformField tbl4 ON tbl1.FieldId = tbl4.Id
		LEFT OUTER JOIN mst_Modcode tbl5 ON (
				tbl4.CategoryId = tbl5.CodeId
				AND tbl4.BindTable = 'Mst_ModDecode'
				)
		INNER JOIN dbo.lnk_FormTabSection tbl7 ON tbl1.FeatureId = tbl7.FeatureId
			AND tbl1.SectionId = tbl7.SectionId
		INNER JOIN dbo.Mst_FormBuilderTab tbl8 ON tbl7.TabId = tbl8.TabId
		WHERE tbl1.Predefined = 0
			AND tbl1.FeatureId = @FeatureId
			AND tbl3.IsGridView = 1
			AND (
				tbl4.PatientRegistration IS NULL
				OR tbl4.PatientRegistration = 0
				)
			AND (
				tbl2.Deleteflag = 0
				OR tbl2.Deleteflag IS NULL
				)
		) Z
	ORDER BY Z.SeqSection
		,Z.Seq
		,Z.tabSeq ASC

	---Table 02 [for Business Rule]                                                                                                                                                       
	SELECT DISTINCT Y.FieldId
		,Y.FieldLabel
		,Y.Predefined
		,Y.BusRuleId
		,Y.FieldName
		,Mst_BusinessRule.NAME
		,Y.ControlId
		,ISNULL(Y.Value, 0) [Value]
		,ISNULL(Y.Value1, 0) [Value1]
		--,Upper(Y.TableName) [TableName]
		,'DTL_CUSTOMFORM' as [TableName]
		,Y.TabId
	FROM (
		SELECT Z.FieldId
			,Z.FieldLabel
			,Z.Predefined
			,Z.FieldName
			,lnk_fieldsBusinessRule.BusRuleId
			,lnk_fieldsBusinessRule.Value
			,lnk_fieldsBusinessRule.Value1
			,Z.ControlId
			,Z.TableName
			,Z.TabId
		FROM (
			SELECT CASE tbl1.Predefined
					WHEN 1
						THEN '9999' + convert(VARCHAR, tbl1.FieldId)
					WHEN 0
						THEN '8888' + convert(VARCHAR, Tbl1.FieldId)
					END [FieldId]
				,tbl1.FieldLabel
				,tbl1.Predefined
				,tbl2.BindField [FieldName]
				,tbl2.PDFTableName [TableName]
				,tbl2.ControlId
				,tbl3.TabId
			FROM lnk_forms tbl1
			INNER JOIN Mst_PreDefinedFields tbl2 ON tbl1.FieldId = tbl2.Id
			INNER JOIN dbo.lnk_FormTabSection tbl3 ON tbl1.FeatureId = tbl3.FeatureID
				AND tbl3.SectionID = tbl1.SectionID
			WHERE tbl1.FeatureId = @FeatureId
				AND tbl1.predefined = 1
			
			UNION
			
			SELECT CASE tbl1.Predefined
					WHEN 1
						THEN '9999' + convert(VARCHAR, tbl1.FieldId)
					WHEN 0
						THEN '8888' + convert(VARCHAR, Tbl1.FieldId)
					END [FieldId]
				,tbl1.FieldLabel
				,tbl1.Predefined
				,tbl2.FieldName [FieldName]
				,'dtl_CustomField' [TableName]
				,tbl2.ControlId
				,tbl3.TabId
			FROM lnk_forms tbl1
			INNER JOIN mst_CustomformField tbl2 ON tbl1.FieldId = tbl2.Id
			INNER JOIN dbo.lnk_FormTabSection tbl3 ON tbl1.FeatureId = tbl3.FeatureID
				AND tbl3.SectionID = tbl1.SectionID
			WHERE tbl1.FeatureId = @FeatureId
				AND tbl1.predefined = 0
			) Z
		INNER JOIN lnk_fieldsBusinessRule ON Z.FieldId = CASE lnk_fieldsBusinessRule.Predefined
				WHEN 1
					THEN '9999' + convert(VARCHAR, lnk_fieldsBusinessRule.FieldId)
				WHEN 0
					THEN '8888' + convert(VARCHAR, lnk_fieldsBusinessRule.FieldId)
				END
			AND Z.Predefined = lnk_fieldsBusinessRule.Predefined
		) Y
		,Mst_BusinessRule
	WHERE Y.BusRuleId = Mst_BusinessRule.ID
	
	UNION
	
	SELECT CASE b.Predefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
			END [FieldId]
		,a.ConditionalFieldLabel [FieldLabel]
		,a.ConditionalFieldPredefined [Predefined]
		,c.Id [BusRuleId]
		,a.ConditionalFieldName [FieldName]
		,c.NAME
		,a.ConditionalFieldControlId [ControlId]
		,b.Value
		,b.Value1
		,Upper(a.ConditionalFieldSavingTable) [TableName]
		,a.TabId
	FROM Vw_FieldConditionalField a
	INNER JOIN lnk_FieldsBusinessRule b ON (
			a.ConditionalFieldId = b.FieldId
			AND a.ConditionalFieldPredefined = b.Predefined
			)
	INNER JOIN Mst_BusinessRule c ON b.BusRuleId = c.id
	WHERE a.FeatureId = @FeatureId
	ORDER BY BusRuleId

	---Table 03 for all Controls Except MultiSelect                                                                                           
	SELECT *
	FROM (
		SELECT tbl1.FeatureId
			,tbl2.FeatureName
			,tbl1.SectionId
			,tbl3.SectionName
			,CASE tbl1.Predefined
				WHEN 1
					THEN '9999' + convert(VARCHAR, tbl1.FieldId)
				WHEN 0
					THEN '8888' + convert(VARCHAR, tbl1.FieldId)
				END [FieldId]
			,tbl4.BindField [FieldName]
			,replace(tbl1.FieldLabel, '''', '') [FieldLabel]
			,tbl1.Predefined
			,UPPER(tbl4.PDFTableName) [PDFTableName]
			,tbl4.ControlId
			,tbl4.BindTable [BindSource]
			,tbl4.CategoryId [CodeId]
			,tbl1.Seq
			,tbl7.TabId
			,tbl8.TabName
		FROM Lnk_forms tbl1
		INNER JOIN mst_feature tbl2 ON tbl1.FeatureId = tbl2.FeatureID
		INNER JOIN mst_section tbl3 ON tbl1.SectionId = tbl3.SectionID
		INNER JOIN Mst_PreDefinedFields tbl4 ON tbl1.FieldId = tbl4.Id
		LEFT OUTER JOIN mst_pmtctcode tbl5 ON (
				tbl4.CategoryId = tbl5.CodeId
				AND tbl4.BindTable = 'Mst_PMTCTDecode'
				)
		LEFT OUTER JOIN mst_code tbl6 ON (
				tbl4.CategoryId = tbl6.CodeId
				AND Tbl4.BindTable = 'Mst_DeCode'
				)
		INNER JOIN dbo.lnk_FormTabSection tbl7 ON tbl1.FeatureId = tbl7.FeatureId
			AND tbl1.SectionId = tbl7.SectionId
		INNER JOIN dbo.Mst_FormBuilderTab tbl8 ON tbl7.TabId = tbl8.TabId
		WHERE tbl1.predefined = 1
			AND tbl1.FeatureId = @FeatureId
			AND tbl4.ControlId NOT IN (
				9
				,16
				)
			AND tbl1.FieldId NOT IN (71)
			AND (
				tbl2.Deleteflag = 0
				OR tbl2.Deleteflag IS NULL
				)
		
		UNION
		
		SELECT tbl1.FeatureId
			,tbl2.FeatureName
			,tbl1.SectionId
			,tbl3.SectionName
			,CASE tbl1.Predefined
				WHEN 1
					THEN '9999' + convert(VARCHAR, tbl1.FieldId)
				WHEN 0
					THEN '8888' + convert(VARCHAR, tbl1.FieldId)
				END [FieldId]
			,tbl4.FieldName [FieldName]
			,replace(tbl1.FieldLabel, '''', '') [FieldLabel]
			,tbl1.Predefined
			,'PDFTableName' = Upper(CASE 
					WHEN ControlId = 11
						THEN NULL
					WHEN ControlId = 12
						THEN NULL
					ELSE 'dtl_CustomField'
					END)
			,tbl4.ControlId
			,tbl4.BindTable [BindSource]
			,tbl5.CodeID
			,tbl1.Seq
			,tbl7.TabId
			,tbl8.TabName
		FROM Lnk_forms tbl1
		INNER JOIN mst_feature tbl2 ON tbl1.FeatureId = tbl2.FeatureID
		INNER JOIN mst_section tbl3 ON tbl1.SectionId = tbl3.SectionID
		INNER JOIN mst_CustomformField tbl4 ON tbl1.FieldId = tbl4.Id
		LEFT OUTER JOIN mst_Modcode tbl5 ON (
				tbl4.CategoryId = tbl5.CodeId
				AND tbl4.BindTable = 'Mst_ModDecode'
				)
		INNER JOIN dbo.lnk_FormTabSection tbl7 ON tbl1.FeatureId = tbl7.FeatureId
			AND tbl1.SectionId = tbl7.SectionId
		INNER JOIN dbo.Mst_FormBuilderTab tbl8 ON tbl7.TabId = tbl8.TabId
		WHERE tbl1.Predefined = 0
			AND tbl1.FeatureId = @FeatureId
			AND tbl4.ControlId NOT IN (
				9
				,16
				)
			AND (
				tbl2.Deleteflag = 0
				OR tbl2.Deleteflag IS NULL
				)
		) Z
	ORDER BY Z.Seq ASC

	--- 04                                                                                                                                    
	SELECT drug_pk [DrugId]
		,DrugName
		,0 [Generic]
		,DrugTypeId
		,[Generic Abbrevation] [Abbr]
	FROM vw_Drug
	
	UNION
	
	SELECT GenericId [DrugId]
		,GenericName [DrugName]
		,GenericId [Generic]
		,drugTypeId
		,GenericAbbrevation [Abbr]
	FROM vw_Generic
	WHERE GenericId IS NOT NULL
	ORDER BY [DrugName]

	------------------------------------Updated on 09-Apr-12---------------------------------------------                 
	-- Select GenericId [DrugId],GenericName [DrugName],GenericId [Generic],drugTypeId,GenericAbbrevation[Abbr]                                                                                                         
	-- from vw_Generic where GenericId is not null order by [DrugName]                                           
	------------------------------------------------------------------------------                                                                                                   
	--- 05                                                                                           
	SELECT a.drug_pk [DrugId]
		,a.DrugName
		,b.genericid
		,b.GenericAbbrevation [Abbr]
	FROM mst_drug a
		,mst_Generic b
		,lnk_drugGeneric c
	WHERE a.deleteflag = 0
		AND dbo.fn_GetDrugTypeId_futures(a.drug_pk) = 37
		AND a.drug_pk = c.drug_pk
		AND b.GenericID = c.GenericID
	GROUP BY a.drug_pk
		,a.DrugName
		,b.GenericAbbrevation
		,b.genericid
	
	UNION
	
	SELECT GenericId [DrugId]
		,GenericName [DrugName]
		,GenericId [GenericId]
		,GenericAbbrevation [Abbr]
	FROM vw_Generic
	WHERE GenericId IS NOT NULL
	ORDER BY [DrugName]

	-- 06                     
	SELECT a.LabTestId
		,a.LabName
		,b.SubTestId
		,b.SubTestName
		,c.LabTypeId
		,c.LabTypeName
		,d.LabDepartmentId
		,d.LabDepartmentName
		,a.DeleteFlag
	FROM Mst_LabTest a
		,Lnk_TestParameter b
		,Mst_LabType c
		,Mst_LabDepartment d
	WHERE a.LabTestId = b.TestId
		AND a.LabTypeId = c.LabTypeId
		AND a.LabDepartmentId = d.LabDepartmentId
	ORDER BY a.LabTestId

	--07                                                                                                                                  
	--select c.DefaultUnit,d.codeid,c.id,c.unitID,d.Name as UnitName,a.LabTestId,a.LabName,b.SubTestId,b.SubTestName,c.MinBoundaryValue,                                                   
	--c.MaxBoundaryValue,c.MinNormalRange,c.MaxNormalRange    from                                                                                                                 
	--mst_labTest a right outer join lnk_testparameter b on a.LabTestId=b.TestId                                                                                                                                        
	--inner join Lnk_LabValue c on b.SubTestId=c.SubTestId                                                     
	--left outer join mst_Decode d on d.Id=c.UnitId                                                                                                                                         
	--where                                                                                                                        
	--(c.DefaultUnit=1 or c.defaultUnit is null) and (d.CodeId=30  or d.CodeId is null)                                                                                                                                        
	--and (c.deleteFlag=0 or c.deleteFlag is null)                                                                                                      
	SELECT Id [UnitId]
		,NAME [UnitName]
	FROM mst_decode
	WHERE codeid = 32
		AND deleteflag = 0

	--08                                                                                              
	SELECT DISTINCT '0' [Drug_pk]
		,d.GenericId
		,b.StrengthId
		,b.StrengthName
	FROM lnk_drugstrength a
		,mst_strength b
		,mst_Generic d
	WHERE a.strengthid = b.strengthid
		AND d.GenericID = a.GenericID
	
	UNION
	
	SELECT DISTINCT d.Drug_pk
		,'0' [GenericId]
		,c.StrengthId
		,c.StrengthName
	FROM lnk_DrugGeneric b
		,lnk_DrugStrength a
		,mst_Strength c
		,mst_Drug d
	WHERE d.Drug_pk = b.Drug_pk
		AND b.GenericID = a.GenericID
		AND a.StrengthId = c.StrengthId
	ORDER BY d.GenericId
		,b.StrengthId
		,b.StrengthName

	--09                                                                                    
	SELECT DISTINCT '0' [Drug_pk]
		,d.GenericId
		,a.FrequencyId
		,b.NAME [FrequencyName]
	FROM lnk_DrugFrequency a
		,mst_frequency b
		,mst_Generic d
	WHERE a.frequencyid = b.id
		AND d.GenericID = a.GenericID
	
	UNION
	
	SELECT DISTINCT d.Drug_pk
		,'0' [GenericId]
		,c.ID [FrequencyId]
		,c.NAME [FrequencyName]
	FROM lnk_DrugGeneric b
		,lnk_Drugfrequency a
		,mst_Frequency c
		,mst_Drug d
	WHERE d.Drug_pk = b.Drug_pk
		AND b.GenericID = a.GenericID
		AND a.FrequencyId = c.ID
	ORDER BY d.GenericId
		,a.FrequencyId

	----11                                 
	--select a.GenericId,a.GenericName,a.GenericAbbrevation,b.DrugTypeId                                             
	--from mst_generic a,lnk_drugtypegeneric b                                                                                                                                                          
	--where a.genericid = b.genericid and a.deleteflag = 0                                                     
	--10                                                                                                                                
	SELECT a.Drug_Pk
		,a.DrugName
		,0 [Generic]
		,dbo.fn_GetDrugTypeId_futures(a.Drug_Pk) [DrugTypeId]
		,dbo.fn_GetFixedDoseDrugAbbrevation(a.Drug_Pk) [Abbr]
	FROM mst_drug a
	WHERE a.deleteflag = 0

	--select * from mst_DrugType                                              
	--select * from mst_Drug                                              
	--select * from dbo.Lnk_DrugTypeGeneric                                              
	--11                                                                                                                                
	SELECT a.GenericId
		,a.GenericName [DrugName]
		,a.GenericId [Generic]
		,b.drugTypeId
		,a.GenericAbbrevation [Abbr]
	FROM mst_generic a
		,lnk_drugtypegeneric b
	WHERE a.genericid = b.genericid
		AND a.deleteflag = 0

	--12                                   
	--for OI Treatment Other Medications  - Frq to be displayed from custorm list                                                                                                                                                              
	SELECT Id [FrequencyId]
		,NAME [FrequencyName]
	FROM mst_FrequencyUnits
	WHERE deleteflag = 0

	--13                                                                                     
	SELECT DrugTypeID
		,DrugTypeName
	FROM mst_drugtype
	WHERE deleteflag = 0

	--14                                                                                                                  
	SELECT *
	FROM mst_feature
	WHERE FeatureId = @FeatureId

	--15                                                                                                            
	SELECT @FormVisitType = MultiVisit
		,@FeatureName = FeatureName
	FROM mst_feature
	WHERE FeatureId = @FeatureId

	SELECT @VisitTypeId = VisitTypeId
	FROM mst_Visittype
	WHERE (
			deleteflag = 0
			OR deleteflag IS NULL
			)
		AND visitname = @FeatureName

	IF (@FormVisitType = 1)
	BEGIN
		SELECT '0' [Visit_Id]
	END
	ELSE
	BEGIN
		SELECT Visit_Id
			,VisitDate
		FROM Ord_Visit
		WHERE Ptn_pk = @PatientId
			AND VisitType = @VisitTypeId
			AND (
				DeleteFlag IS NULL
				OR DeleteFlag = 0
				)

		PRINT 'sanjay'
	END

	--16                                                                                                        
	SELECT a.drug_pk
		,a.drugname
		,d.drugtypeid
		,b.GenericAbbrevation
		,b.genericid
		,b.genericname
	FROM mst_drug a
		,mst_generic b
		,lnk_druggeneric c
		,lnk_DrugTypeGeneric d
	WHERE c.genericid = b.genericid
		AND c.drug_pk = a.drug_pk
		AND a.deleteflag = 0
		AND a.Drug_pk = c.Drug_pk
		AND c.GenericID = d.GenericID
	ORDER BY a.drugname

	---17 Conditional Fields                                                                                                    
	----select a.FeatureId,b.FeatureName,a.FieldSectionId,a.FieldSectionName,                                                                                                    
	----a.ConditionalFieldId [FieldId],a.ConditionalFieldBindField [FieldName],                                                             
	----a.ConditionalFieldLabel [FieldLabel], a.ConditionalFieldPredefined [Predefined],                                                                 
	----a.ConditionalFieldSavingTable [PDFTableName],a.ConditionalFieldControlId [ControlId],                                                                                                    
	----a.ConditionalFieldBindTable [BindSource],a.ConditionalFieldCategoryId [CodeId],                                                                                                    
	----a.ConditionalFieldSequence [Seq],a.FieldSectionSequence [SeqSection],ConditionalFieldSectionId,a.FieldId [ConFieldId],                                                                                      
	----a.FieldPredefined [ConFieldPredefined]                                                                                                    
	----from Vw_FieldConditionalField a inner join Mst_Feature b on a.FeatureId = b.FeatureId                                                                                           
	----and a.ConditionalFieldPredefined = 1 and b.FeatureId = @FeatureId and a.ConditionalFieldId is not null                                                       
	----and a.ConditionalFieldName is not null                                                                                      
	----union                                                                                          
	----select a.FeatureId,b.FeatureName,a.FieldSectionId,a.FieldSectionName,                                         
	----a.ConditionalFieldId [FieldId],a.ConditionalFieldName [FieldName],                                                                 
	----a.ConditionalFieldLabel [FieldLabel], a.ConditionalFieldPredefined [Predefined],                               
	----a.ConditionalFieldSavingTable [PDFTableName],a.ConditionalFieldControlId [ControlId],                                                                                                    
	----a.ConditionalFieldBindTable [BindSource],a.ConditionalFieldCategoryId [CodeId],                                                                                                    
	----a.ConditionalFieldSequence [Seq],a.FieldSectionSequence [SeqSection],ConditionalFieldSectionId,a.FieldId [ConFieldId],                                                                                                  
	----a.FieldPredefined [ConFieldPredefined]                                                                                                    
	----from Vw_FieldConditionalField a inner join Mst_Feature b on a.FeatureId = b.FeatureId         
	----and a.ConditionalFieldPredefined = 0 and b.FeatureId = @FeatureId and a.ConditionalFieldId is not null                                                                                           
	----and a.ConditionalFieldName is not null                                                                               
	----union                                                                              
	----select a.FeatureId,b.FeatureName,a.FieldSectionId,a.FieldSectionName,                                                                                                    
	----a.ConditionalFieldId [FieldId],'PlaceHolder' [FieldName],                                                                                                    
	----a.ConditionalFieldLabel [FieldLabel], a.ConditionalFieldPredefined [Predefined],                                                   
	----a.ConditionalFieldSavingTable [PDFTableName],'13' [ControlId],                                                          
	----a.ConditionalFieldBindTable [BindSource],a.ConditionalFieldCategoryId [CodeId],                     
	----a.ConditionalFieldSequence [Seq],a.FieldSectionSequence [SeqSection],ConditionalFieldSectionId,a.FieldId [ConFieldId],                                                                                          
	----a.FieldPredefined [ConFieldPredefined]                                     
	----from Vw_FieldConditionalField a inner join Mst_Feature b on a.FeatureId = b.FeatureId                           
	----and a.ConditionalFieldPredefined = 1 and b.FeatureId = @FeatureId and a.ConditionalFieldId is not null                                                                      
	----and a.ConditionalFieldId like '710000%' 
	SELECT a.FeatureId
		,b.FeatureName
		,a.FieldSectionId
		,a.FieldSectionName
		,CASE a.ConditionalFieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
			END [FieldId]
		,a.ConditionalFieldBindField [FieldName]
		,a.ConditionalFieldLabel [FieldLabel]
		,a.AdditionalInformation [AdditionalInformation]
		,a.ConditionalFieldPredefined [Predefined]
		,Upper(a.ConditionalFieldSavingTable) [PDFTableName]
		,a.ConditionalFieldControlId [ControlId]
		,a.ConditionalFieldBindTable [BindSource]
		,a.ConditionalFieldCategoryId [CodeId]
		,a.ConditionalFieldSequence [Seq]
		,a.FieldSectionSequence [SeqSection]
		,ConditionalFieldSectionId
		,CASE a.FieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.FieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.FieldId)
			END [ConFieldId]
		,a.FieldPredefined [ConFieldPredefined]
		,a.TabId
		,CASE a.ConditionalFieldControlId
			WHEN 6
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'RADIO1-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			END [ConControlId]
		,a.TabName
	FROM Vw_FieldConditionalField a
	INNER JOIN Mst_Feature b ON a.FeatureId = b.FeatureId
		AND a.ConditionalFieldPredefined = 1
		AND b.FeatureId = @FeatureId
		AND a.ConditionalFieldId IS NOT NULL
		AND a.ConditionalFieldName IS NOT NULL
		AND a.ConditionalFieldControlId = 6
	
	UNION
	
	SELECT a.FeatureId
		,b.FeatureName
		,a.FieldSectionId
		,a.FieldSectionName
		,CASE a.ConditionalFieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
			END [FieldId]
		,a.ConditionalFieldName [FieldName]
		,a.ConditionalFieldLabel [FieldLabel]
		,a.AdditionalInformation [AdditionalInformation]
		,a.ConditionalFieldPredefined [Predefined]
		,Upper(a.ConditionalFieldSavingTable) [PDFTableName]
		,a.ConditionalFieldControlId [ControlId]
		,a.ConditionalFieldBindTable [BindSource]
		,a.ConditionalFieldCategoryId [CodeId]
		,a.ConditionalFieldSequence [Seq]
		,a.FieldSectionSequence [SeqSection]
		,ConditionalFieldSectionId
		,CASE a.FieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.FieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.FieldId)
			END [ConFieldId]
		,a.FieldPredefined [ConFieldPredefined]
		,a.TabId
		,CASE a.ConditionalFieldControlId
			WHEN 6
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'RADIO1-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(varchar, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			END [ConControlId]
		,a.TabName
	FROM Vw_FieldConditionalField a
	INNER JOIN Mst_Feature b ON a.FeatureId = b.FeatureId
		AND a.ConditionalFieldPredefined = 0
		AND b.FeatureId = @FeatureId
		AND a.ConditionalFieldId IS NOT NULL
		AND a.ConditionalFieldName IS NOT NULL
		AND a.ConditionalFieldControlId = 6
	
	UNION
	
	SELECT a.FeatureId
		,b.FeatureName
		,a.FieldSectionId
		,a.FieldSectionName
		,CASE a.ConditionalFieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
			END [FieldId]
		,a.ConditionalFieldBindField [FieldName]
		,a.ConditionalFieldLabel [FieldLabel]
		,a.AdditionalInformation [AdditionalInformation]
		,a.ConditionalFieldPredefined [Predefined]
		,Upper(a.ConditionalFieldSavingTable) [PDFTableName]
		,a.ConditionalFieldControlId [ControlId]
		,a.ConditionalFieldBindTable [BindSource]
		,a.ConditionalFieldCategoryId [CodeId]
		,a.ConditionalFieldSequence [Seq]
		,a.FieldSectionSequence [SeqSection]
		,ConditionalFieldSectionId
		,CASE a.FieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.FieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.FieldId)
			END [ConFieldId]
		,a.FieldPredefined [ConFieldPredefined]
		,a.TabId
		,CASE a.ConditionalFieldControlId
			WHEN 1
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXT-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(varchar, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 2
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXT-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 3
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXTNUM-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 4
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'SELECTLIST-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 5
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXTDT-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 6
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'RADIO2-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 7
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'Chk-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 8
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXTMulti-' + a.ConditionalFieldBindField + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 9
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'Pnl_-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END
			END [ConControlId]
		,a.TabName
	FROM Vw_FieldConditionalField a
	INNER JOIN Mst_Feature b ON a.FeatureId = b.FeatureId
		AND a.ConditionalFieldPredefined = 1
		AND b.FeatureId = @FeatureId
		AND a.ConditionalFieldId IS NOT NULL
		AND a.ConditionalFieldName IS NOT NULL
	
	UNION
	
	SELECT a.FeatureId
		,b.FeatureName
		,a.FieldSectionId
		,a.FieldSectionName
		,CASE a.ConditionalFieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
			END [FieldId]
		,a.ConditionalFieldName [FieldName]
		,a.ConditionalFieldLabel [FieldLabel]
		,a.AdditionalInformation [AdditionalInformation]
		,a.ConditionalFieldPredefined [Predefined]
		,Upper(a.ConditionalFieldSavingTable) [PDFTableName]
		,a.ConditionalFieldControlId [ControlId]
		,a.ConditionalFieldBindTable [BindSource]
		,a.ConditionalFieldCategoryId [CodeId]
		,a.ConditionalFieldSequence [Seq]
		,a.FieldSectionSequence [SeqSection]
		,ConditionalFieldSectionId
		,CASE a.FieldPredefined
			WHEN 1
				THEN '9999' + convert(VARCHAR, a.FieldId)
			WHEN 0
				THEN '8888' + convert(VARCHAR, a.FieldId)
			END [ConFieldId]
		,a.FieldPredefined [ConFieldPredefined]
		,a.TabId
		,CASE a.ConditionalFieldControlId
			WHEN 1
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXT-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 2
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXT-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 3
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXTNUM-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 4
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'SELECTLIST-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 5
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXTDT-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 6
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'RADIO2-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 7
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'Chk-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 8
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'TXTMulti-' + a.ConditionalFieldName + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			WHEN 9
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'Pnl_-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END
			END [ConControlId]
		,a.TabName
	FROM Vw_FieldConditionalField a
	INNER JOIN Mst_Feature b ON a.FeatureId = b.FeatureId
		AND a.ConditionalFieldPredefined = 0
		AND b.FeatureId = @FeatureId
		AND a.ConditionalFieldId IS NOT NULL
		AND a.ConditionalFieldName IS NOT NULL
	
	UNION
	
	SELECT a.FeatureId
		,b.FeatureName
		,a.FieldSectionId
		,a.FieldSectionName
		,a.ConditionalFieldId [FieldId]
		,'PlaceHolder' [FieldName]
		,a.ConditionalFieldLabel [FieldLabel]
		,a.AdditionalInformation [AdditionalInformation]
		,a.ConditionalFieldPredefined [Predefined]
		,Upper(a.ConditionalFieldSavingTable) [PDFTableName]
		,'13' [ControlId]
		,a.ConditionalFieldBindTable [BindSource]
		,a.ConditionalFieldCategoryId [CodeId]
		,a.ConditionalFieldSequence [Seq]
		,a.FieldSectionSequence [SeqSection]
		,ConditionalFieldSectionId
		,a.FieldId [ConFieldId]
		,a.FieldPredefined [ConFieldPredefined]
		,a.TabId
		,CASE a.ConditionalFieldControlId
			WHEN 4
				THEN 'ctl00_IQCareContentPlaceHolder_TAB_' + convert(VARCHAR, a.TabId) + '_' + 'SELECTLIST-' + 'PlaceHolder' + '-' + Upper(a.ConditionalFieldSavingTable) + '-' + CASE a.ConditionalFieldPredefined
						WHEN 1
							THEN '9999' + convert(VARCHAR, a.ConditionalFieldId)
						WHEN 0
							THEN '8888' + convert(VARCHAR, a.ConditionalFieldId)
						END + '-' + convert(VARCHAR, a.TabId)
			END [ConControlId]
		,a.TabName
	FROM Vw_FieldConditionalField a
	INNER JOIN Mst_Feature b ON a.FeatureId = b.FeatureId
		AND a.ConditionalFieldPredefined = 1
		AND b.FeatureId = @FeatureId
		AND a.ConditionalFieldId IS NOT NULL
		AND a.ConditionalFieldId LIKE '710000%'

	--18                                                                                   
	SELECT a.StartDate
	FROM dbo.lnk_PatientProgramStart a
	INNER JOIN Mst_Feature b ON a.ModuleId = b.ModuleId
	WHERE b.FeatureId = @FeatureId
		AND a.Ptn_Pk = @PatientId

	--19                                                                     
	--19                                                                     
	DECLARE @sql NVARCHAR(max)

	IF EXISTS (
			SELECT *
			FROM sys.columns
			WHERE NAME = 'visit_pk'
				AND OBJECT_ID = OBJECT_ID('DTL_FBCUSTOMFIELD_' + REPLACE(@FeatureName, ' ', '_') + '')
			)
	BEGIN
		SET @sql = '



Begin 



 if exists(select * from sysobjects where name=''DTL_FBCUSTOMFIELD_' + REPLACE(@FeatureName, ' ', '_') + ''')



 Begin                                                       



	select  * from [DTL_FBCUSTOMFIELD_' + REPLACE(@FeatureName, ' ', '_') + '] a inner join ord_visit b on a.visit_pk=b.Visit_Id where b.ptn_pk=' + convert(VARCHAR, @PatientId) + ' order by 

	b.visitdate desc



 End



 else



 Begin



	Select 0



 End 



End'
	END
	ELSE
	BEGIN
		SET @sql = '



Begin



	if exists(select * from sysobjects where name=''DTL_FBCUSTOMFIELD_' + REPLACE(@FeatureName, ' ', '_') + ''')



	Begin



	select  * from [DTL_FBCUSTOMFIELD_' + REPLACE(@FeatureName, ' ', '_') + '] a inner join dtl_patientCareended b on a.CareEndedId=b.CareEndedID where b.ptn_pk=' + convert(VARCHAR, @PatientId) + ' 

	order by b.CareEndedDate desc



	End



	else



	Begin



	Select 0



	End



End'
	END

	EXECUTE sp_executesql @sql

	--print  @sql                              
	--20    
	SELECT Z.Visit_ID [VisitID]
		,z.VisitDate
	FROM (
		SELECT visit_id
			,VisitDate
		FROM ord_Visit
		WHERE Visittype = (
				SELECT VisitTypeID
				FROM mst_visittype
				WHERE (
						deleteflag = 0
						OR deleteflag IS NULL
						)
					AND VisitTypeID <> 0
					AND convert(BINARY (50), VisitName) = convert(BINARY (50), (
							SELECT FeatureName
							FROM mst_feature
							WHERE FeatureID = @FeatureId
							))
					AND FeatureID = @FeatureId
				)
			AND Ptn_Pk = @PatientId
		) Z
	WHERE Z.visitdate = (
			SELECT X.Visitdate
			FROM (
				SELECT DISTINCT max(visitdate) [visitdate]
				FROM ord_Visit
				WHERE (
						deleteflag = 0
						OR deleteflag IS NULL
						)
					AND Visittype = (
						SELECT VisitTypeID
						FROM mst_visittype
						WHERE (
								deleteflag = 0
								OR deleteflag IS NULL
								)
							AND VisitTypeID <> 0
							AND VisitTypeID <> 0
							AND convert(BINARY (50), VisitName) = convert(BINARY (50), (
									SELECT FeatureName
									FROM mst_feature
									WHERE FeatureID = @FeatureId
									))
							AND FeatureID = @FeatureId
						)
					AND Ptn_Pk = @PatientId
				) X
			)

	--21                                          
	SELECT '0' [Drug_pk]
		,'0' [GenericId]
		,c.ID [FrequencyId]
		,c.NAME [FrequencyName]
	FROM mst_Frequency c
	WHERE (
			c.deleteflag = 0
			OR c.deleteflag IS NULL
			)
	ORDER BY c.Id

	--22                              
	SELECT A.Ptn_pk
		,A.Visit_pk
		,A.LocationId
		,CASE 
			WHEN A.Predefined = 0
				THEN Convert(INT, '8888' + Convert(VARCHAR, A.FieldId))
			WHEN A.Predefined = 1
				THEN Convert(INT, '9999' + Convert(VARCHAR, A.FieldId))
			END [FieldId]
		,A.BlockId
		,A.SubBlockId
		,A.ICDCodeId [Id]
		,+ '%' + Convert(VARCHAR, ISNULL(A.BlockId, 0)) + '%' + Convert(VARCHAR, ISNULL(A.SubBlockId, 0)) + '%' + Convert(VARCHAR, ISNULL(A.ICDCodeId, 0)) + '%' + Convert(VARCHAR, A.Predefined) [CodeId]
		,CASE 
			WHEN A.BlockId > 0
				THEN B.Code + ' ' + B.NAME
			WHEN A.SubBlockId > 0
				THEN C.Code + ' ' + C.NAME
			WHEN A.ICDCodeId > 0
				THEN D.Code + ' ' + D.NAME
			END [Name]
	FROM dtl_ICD10Field A
	LEFT OUTER JOIN dbo.Mst_ICDCodeBlocks B ON A.BlockId = B.BlockId
	LEFT OUTER JOIN dbo.Mst_ICDCodeSubBlock C ON A.SubBlockId = C.SubBlockId
	LEFT OUTER JOIN dbo.mst_ICDCodes D ON A.ICDCodeId = D.Id
	WHERE A.Ptn_pk = @PatientId

	--23            
	SELECT tbl1.TabId
		,tbl2.TabName
		,tbl2.seq
		,ISNULL(tbl2.signature, 0) [signature]
	FROM dbo.lnk_FormTabSection tbl1
	INNER JOIN dbo.Mst_FormBuilderTab tbl2 ON tbl1.TabId = tbl2.TabId
		AND tbl1.FeatureID = @FeatureId
	GROUP BY tbl1.TabId
		,tbl2.TabName
		,tbl2.seq
		,tbl2.signature
	ORDER BY seq

	----24            
	--Select tbl1.TabId, tbl2.TabName, tbl1.SectionId, tbl3.SectionName from dbo.lnk_FormTabSection tbl1 inner join dbo.Mst_FormBuilderTab tbl2            
	--on tbl1.TabId=tbl2.TabId inner join mst_section tbl3  on tbl1.SectionID=tbl3.SectionId and tbl1.FeatureID=@FeatureId            
	SELECT FeatureID
		,FeatureName
		,Published
		,SystemId
		,ModuleId
		,DeleteFlag
	FROM mst_Feature
	WHERE FeatureID > 1000
		AND DeleteFlag = 0

	CLOSE symmetric KEY Key_CTC
END
go
--==

if not exists(select * from mst_Feature where FeatureName='Morisky Adherence Screening')
begin
	set identity_insert mst_Feature on
	insert into mst_Feature(FeatureID, FeatureName,ReportFlag,DeleteFlag,AdminFlag,UserID,CreateDate,SystemId,Published,ModuleId,MultiVisit)
	values(301, 'Morisky Adherence Screening', 0,0,0,1,getdate(), 0,2,203,1)
	set identity_insert mst_Feature on

	insert into mst_VisitType(VisitName,DeleteFlag,UserID,CreateDate,SystemId,FeatureId)
	values('Morisky Adherence Screening',0,1,getdate(),0,301)

	insert into lnk_GroupFeatures(FacilityID, ModuleID,GroupID,FeatureID,FeatureName,TabID,FunctionID,CreateDate)
	values((select top 1 FacilityID from mst_Facility where DeleteFlag=0),203,1,301,'',0,1,getdate())
	insert into lnk_GroupFeatures(FacilityID, ModuleID,GroupID,FeatureID,FeatureName,TabID,FunctionID,CreateDate)
	values((select top 1 FacilityID from mst_Facility where DeleteFlag=0),203,1,301,'',0,2,getdate())
	insert into lnk_GroupFeatures(FacilityID, ModuleID,GroupID,FeatureID,FeatureName,TabID,FunctionID,CreateDate)
	values((select top 1 FacilityID from mst_Facility where DeleteFlag=0),203,1,301,'',0,3,getdate())
	insert into lnk_GroupFeatures(FacilityID, ModuleID,GroupID,FeatureID,FeatureName,TabID,FunctionID,CreateDate)
	values((select top 1 FacilityID from mst_Facility where DeleteFlag=0),203,1,301,'',0,4,getdate())
	insert into lnk_GroupFeatures(FacilityID, ModuleID,GroupID,FeatureID,FeatureName,TabID,FunctionID,CreateDate)
	values((select top 1 FacilityID from mst_Facility where DeleteFlag=0),203,1,301,'',0,5,getdate())
end
go
--==

if exists(select * from sysobjects where name='Pr_HIVCE_SaveUpdateMoriskyData' and type='p')
	drop proc Pr_HIVCE_SaveUpdateMoriskyData
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[Pr_HIVCE_SaveUpdateMoriskyData] 
     @Ptn_pk INT
	,@Visit_Pk INT
	,@visitdate datetime
	,@LocationId INT
	,@UserID INT
	,@ForgetMedicineSinceLastVisit INT = 0
	,@CarelessAboutTakingMedicine INT = 0
	,@FeelWorseStopTakingMedicine INT = 0
	,@FeelBetterStopTakingMedicine INT = 0
	,@TakeMedicineYesterday INT = 0
	,@SymptomsUnderControl_StopTakingMedicine INT = 0
	,@UnderPresureStickingYourTreatmentPlan INT = 0
	,@RememberingMedications INT = 0
	,@MMAS4_Score VARCHAR(50) = NULL
	,@MMAS8_Score VARCHAR(50) = NULL
	,@MMAS4_AdherenceRating VARCHAR(50)
	,@MMAS8_AdherenceRating VARCHAR(50)
	,@ReferToCounselor VARCHAR(50)
	,@signature int

AS
BEGIN
	DECLARE @FeatureID INT
	declare @VisitType INT
	declare @visitid int

	set @FeatureID = (select top 1 featureid FROM mst_feature WHERE featurename = 'morisky adherence screening' AND Deleteflag = 0)
	set @VisitType = (select top 1 VisitTypeID from mst_VisitType where VisitName='morisky adherence screening' and DeleteFlag = 0)

	IF @Visit_Pk = 0
	BEGIN
		INSERT INTO ord_Visit (Ptn_Pk,LocationID,VisitDate,VisitType,DataQuality,DeleteFlag,UserID,CreateDate,updatedate,Signature,TypeOfVisit)
		VALUES (@Ptn_pk,@LocationId,@visitdate,@VisitType,1,0,1,getdate(),getdate(),@Signature,0)

		SET @visitid = IDENT_CURRENT('ord_Visit');
	end
	else
	begin
		set @visitid = @Visit_Pk
	end

	IF EXISTS (SELECT 1 FROM dtl_HIVCE_PatientAdherenceManagement
			WHERE ptn_pk = @Ptn_pk AND visit_id = @visitid AND Location_Id = @LocationId)
	BEGIN
		UPDATE [dbo].[dtl_HIVCE_PatientAdherenceManagement]
		SET [ForgetMedicineSinceLastVisit] = @ForgetMedicineSinceLastVisit
			,[CarelessAboutTakingMedicine] = @CarelessAboutTakingMedicine
			,[FeelWorseStopTakingMedicine] = @FeelWorseStopTakingMedicine
			,[FeelBetterStopTakingMedicine] = @FeelBetterStopTakingMedicine
			,[TakeMedicineYesterday] = @TakeMedicineYesterday
			,[SymptomsUnderControl_StopTakingMedicine] = @SymptomsUnderControl_StopTakingMedicine
			,[UnderPresureStickingYourTreatmentPlan] = @UnderPresureStickingYourTreatmentPlan
			,[RememberingMedications] = @RememberingMedications
			,[MMAS4_Score] = @MMAS4_Score
			,[MMAS8_Score] = @MMAS8_Score
			,[MMAS4_AdherenceRating] = @MMAS4_AdherenceRating
			,[MMAS8_AdherenceRating] = @MMAS8_AdherenceRating
			,[ReferToCounselor] = @ReferToCounselor
			,[Signature] = @Signature
			,[UpdateDate] = getdate()
			,[UpdateBy] = @UserID
			,[DeleteFlag] = 0
		WHERE ptn_pk = @Ptn_pk
			AND visit_id = @visitid
			AND Location_Id = @LocationId;
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[dtl_HIVCE_PatientAdherenceManagement] (
			[Ptn_pk]
			,[Visit_Id]
			,[Location_Id]
			,[ForgetMedicineSinceLastVisit]
			,[CarelessAboutTakingMedicine]
			,[FeelWorseStopTakingMedicine]
			,[FeelBetterStopTakingMedicine]
			,[TakeMedicineYesterday]
			,[SymptomsUnderControl_StopTakingMedicine]
			,[UnderPresureStickingYourTreatmentPlan]
			,[RememberingMedications]
			,[MMAS4_Score]
			,[MMAS8_Score]
			,[MMAS4_AdherenceRating]
			,[MMAS8_AdherenceRating]
			,[ReferToCounselor]
			,[Signature]
			,[CreateDate]
			,[CreateBy]
			)
		VALUES (
			@Ptn_pk
			,@visitid
			,@LocationId
			,@ForgetMedicineSinceLastVisit
			,@CarelessAboutTakingMedicine
			,@FeelWorseStopTakingMedicine
			,@FeelBetterStopTakingMedicine
			,@TakeMedicineYesterday
			,@SymptomsUnderControl_StopTakingMedicine
			,@UnderPresureStickingYourTreatmentPlan
			,@RememberingMedications
			,@MMAS4_Score
			,@MMAS8_Score
			,@MMAS4_AdherenceRating
			,@MMAS8_AdherenceRating
			,@ReferToCounselor
			,@Signature
			,getdate()
			,@UserID
			);
	END
END
go
--==

if exists(select * from sysobjects where name='Pr_HIVCE_GetMoriskyData' and type='p')
	drop proc Pr_HIVCE_GetMoriskyData
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE [dbo].[Pr_HIVCE_GetMoriskyData] 
  @ptn_pk int
, @visit_pk int

as

begin
	SELECT [PAM_ID]
		,[ForgetMedicineSinceLastVisit]
		,[CarelessAboutTakingMedicine]
		,[FeelWorseStopTakingMedicine]
		,[FeelBetterStopTakingMedicine]
		,[TakeMedicineYesterday]
		,[SymptomsUnderControl_StopTakingMedicine]
		,[UnderPresureStickingYourTreatmentPlan]
		,[MMAS4_Score]
		,[MMAS8_Score]
		,[MMAS4_AdherenceRating]
		,[MMAS8_AdherenceRating]
		,[ReferToCounselor]
		,[RememberingMedications]
		,[Signature]
	FROM [dbo].[dtl_HIVCE_PatientAdherenceManagement] PAM
	WHERE PAM.ptn_pk = @Ptn_pk
		AND PAM.visit_Id = @visit_pk
end
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Pr_HIVCE_UpdateAlcoholDepressionScreening] @w_Id INT
	,@w_Ptn_pk INT
	,@w_Visit_Id INT
	,@p_IsFeelingDown INT
	,@p_IsLittleInterest INT
	,@p_PHQLittleInterest INT
	,@p_PHQFeelingDown INT
	,@p_PHQTroubleSleep INT
	,@p_PHQTiredLittleEnergy INT
	,@p_PHQAppetite INT
	,@p_PHQYourselfDown INT
	,@p_PHQTroubleConcentrating INT
	,@p_PHQMovingSlowly INT
	,@p_PHQFidgetyRestless INT
	,@p_PHQHurtingYourself INT
	,@p_PHQTotal INT
	,@p_PHQDepressionSeverity VARCHAR(100)
	,@p_PHQRecommended VARCHAR(100)
	,@p_SGBQ1 INT
	,@p_SGBQ2 INT
	,@p_SGBQ3 INT
	,@p_SGBQ4 INT
	,@p_SGBQ5 INT
	,@p_DisclosureHIVStatus INT
	,@p_DisclosureStatus INT
	,@p_DisclosureTo INT
	,@p_CrafftAlcohol INT
	,@p_CrafftSmoke INT
	,@p_CrafftAnythingHigh INT
	,@p_CrafftC INT
	,@p_CrafftR INT
	,@p_CrafftA INT
	,@p_CrafftF1 INT
	,@p_CrafftF2 INT
	,@p_CrafftT INT
	,@p_CrafftScore INT
	,@p_CrafftRisk VARCHAR(100)
	,@p_CageAIDAlcohol INT
	,@p_CageAIDDrugs INT
	,@p_CageAIDSmoke INT
	,@p_CageAIDQ1 INT
	,@p_CageAIDQ2 INT
	,@p_CageAIDQ3 INT
	,@p_CageAIDQ4 INT
	,@p_CageAIDScore INT
	,@p_CageAIDRisk VARCHAR(100)
	,@p_CageAIDStopSmoking INT
	,@Notes VARCHAR(500)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @visitID INT
		,@locId INT;

	IF NOT EXISTS (
			SELECT *
			FROM dtl_PatientAlcoholDepressionScreening
			WHERE [Ptn_pk] = @w_Ptn_pk
				AND [Visit_Id] = @w_Visit_Id
			)
	BEGIN
		SELECT TOP 1 @locId = locationid
		FROM ord_visit
		ORDER BY visit_id DESC;

		IF (@w_Visit_Id = 0)
		BEGIN
			INSERT INTO ord_visit (
				Ptn_Pk
				,LocationID
				,VisitDate
				,VisitType
				,DataQuality
				,CreateDate
				,UserID
				)
			VALUES (
				@w_Ptn_pk
				,@locId
				,getdate()
				,63
				,1
				,getdate()
				,1
				);

			SELECT @visitID = Cast(scope_identity() AS INT)
		END
		ELSE
		BEGIN
			SELECT @visitID = @w_Visit_Id;
		END

		INSERT INTO dtl_PatientAlcoholDepressionScreening (
			Ptn_pk
			,Visit_Id
			,IsFeelingDown
			,IsLittleInterest
			,PHQLittleInterest
			,PHQFeelingDown
			,PHQTroubleSleep
			,PHQTiredLittleEnergy
			,PHQAppetite
			,PHQYourselfDown
			,PHQTroubleConcentrating
			,PHQMovingSlowly
			,PHQFidgetyRestless
			,PHQHurtingYourself
			,PHQTotal
			,PHQDepressionSeverity
			,PHQRecommended
			,SGBQ1
			,SGBQ2
			,SGBQ3
			,SGBQ4
			,SGBQ5
			,DisclosureHIVStatus
			,DisclosureStatus
			,DisclosureTo
			,CrafftAlcohol
			,CrafftSmoke
			,CrafftAnythingHigh
			,CrafftC
			,CrafftR
			,CrafftA
			,CrafftF1
			,CrafftF2
			,CrafftT
			,CrafftScore
			,CrafftRisk
			,CageAIDAlcohol
			,CageAIDDrugs
			,CageAIDSmoke
			,CageAIDQ1
			,CageAIDQ2
			,CageAIDQ3
			,CageAIDQ4
			,CageAIDScore
			,CageAIDRisk
			,CageAIDStopSmoking
			,CreatedDate
			,UpdatedDate
			,Notes
			)
		VALUES (
			@w_Ptn_pk
			,@visitID
			,@p_IsFeelingDown
			,@p_IsLittleInterest
			,@p_PHQLittleInterest
			,@p_PHQFeelingDown
			,@p_PHQTroubleSleep
			,@p_PHQTiredLittleEnergy
			,@p_PHQAppetite
			,@p_PHQYourselfDown
			,@p_PHQTroubleConcentrating
			,@p_PHQMovingSlowly
			,@p_PHQFidgetyRestless
			,@p_PHQHurtingYourself
			,@p_PHQTotal
			,@p_PHQDepressionSeverity
			,@p_PHQRecommended
			,@p_SGBQ1
			,@p_SGBQ2
			,@p_SGBQ3
			,@p_SGBQ4
			,@p_SGBQ5
			,@p_DisclosureHIVStatus
			,@p_DisclosureStatus
			,@p_DisclosureTo
			,@p_CrafftAlcohol
			,@p_CrafftSmoke
			,@p_CrafftAnythingHigh
			,@p_CrafftC
			,@p_CrafftR
			,@p_CrafftA
			,@p_CrafftF1
			,@p_CrafftF2
			,@p_CrafftT
			,@p_CrafftScore
			,@p_CrafftRisk
			,@p_CageAIDAlcohol
			,@p_CageAIDDrugs
			,@p_CageAIDSmoke
			,@p_CageAIDQ1
			,@p_CageAIDQ2
			,@p_CageAIDQ3
			,@p_CageAIDQ4
			,@p_CageAIDScore
			,@p_CageAIDRisk
			,@p_CageAIDStopSmoking
			,GETDATE()
			,GETDATE()
			,@Notes
			);

		SELECT SCOPE_IDENTITY() AS InsertedID;
	END
	ELSE
	BEGIN
		UPDATE [dbo].dtl_PatientAlcoholDepressionScreening
		SET IsFeelingDown = @p_IsFeelingDown
			,IsLittleInterest = @p_IsLittleInterest
			,PHQLittleInterest = @p_PHQLittleInterest
			,PHQFeelingDown = @p_PHQFeelingDown
			,PHQTroubleSleep = @p_PHQTroubleSleep
			,PHQTiredLittleEnergy = @p_PHQTiredLittleEnergy
			,PHQAppetite = @p_PHQAppetite
			,PHQYourselfDown = @p_PHQYourselfDown
			,PHQTroubleConcentrating = @p_PHQTroubleConcentrating
			,PHQMovingSlowly = @p_PHQMovingSlowly
			,PHQFidgetyRestless = @p_PHQFidgetyRestless
			,PHQHurtingYourself = @p_PHQHurtingYourself
			,PHQTotal = @p_PHQTotal
			,PHQDepressionSeverity = @p_PHQDepressionSeverity
			,PHQRecommended = @p_PHQRecommended
			,SGBQ1 = @p_SGBQ1
			,SGBQ2 = @p_SGBQ2
			,SGBQ3 = @p_SGBQ3
			,SGBQ4 = @p_SGBQ4
			,SGBQ5 = @p_SGBQ5
			,DisclosureHIVStatus = @p_DisclosureHIVStatus
			,DisclosureStatus = @p_DisclosureStatus
			,DisclosureTo = @p_DisclosureTo
			,CrafftAlcohol = @p_CrafftAlcohol
			,CrafftSmoke = @p_CrafftSmoke
			,CrafftAnythingHigh = @p_CrafftAnythingHigh
			,CrafftC = @p_CrafftC
			,CrafftR = @p_CrafftR
			,CrafftA = @p_CrafftA
			,CrafftF1 = @p_CrafftF1
			,CrafftF2 = @p_CrafftF2
			,CrafftT = @p_CrafftT
			,CrafftScore = @p_CrafftScore
			,CrafftRisk = @p_CrafftRisk
			,CageAIDAlcohol = @p_CageAIDAlcohol
			,CageAIDDrugs = @p_CageAIDDrugs
			,CageAIDSmoke = @p_CageAIDSmoke
			,CageAIDQ1 = @p_CageAIDQ1
			,CageAIDQ2 = @p_CageAIDQ2
			,CageAIDQ3 = @p_CageAIDQ3
			,CageAIDQ4 = @p_CageAIDQ4
			,CageAIDScore = @p_CageAIDScore
			,CageAIDRisk = @p_CageAIDRisk
			,CageAIDStopSmoking = @p_CageAIDStopSmoking
			,CreatedDate = GETDATE()
			,UpdatedDate = GETDATE()
			,Notes = @Notes
		WHERE Ptn_pk = @w_Ptn_pk
			AND Visit_Id = @w_Visit_Id;
	END

	SET NOCOUNT OFF
END;
go
--==

update mst_Feature set FeatureName='Treatment Preparation' where FeatureName='HIVCE - Treatment Preparation'
update mst_Feature set FeatureName='ART Readiness Assessment' where FeatureName='HIVCE - ART Readiness Assessment'
update mst_Feature set FeatureName='Transition from Paediatric to Adolescent Services' where FeatureName='HIVCE - Transition'
update mst_Feature set FeatureName='Alcohol, GBV and Depression Screening' where FeatureName='HIVCE - Alcohol Depression Screening'
go

update mst_VisitType set VisitName='Treatment Preparation' where VisitName='HIVCE - Treatment Preparation'
update mst_VisitType set VisitName='ART Readiness Assessment' where VisitName='HIVCE - ART Readiness Assessment'
update mst_VisitType set VisitName='Transition from Paediatric to Adolescent Services' where VisitName='HIVCE - Transition'
update mst_VisitType set VisitName='Alcohol, GBV and Depression Screening' where VisitName='HIVCE - Alcohol Depression Screening'
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[pr_Clinical_GetPatientHistory_Constella] 3072, "'ttwbvXWpqb5WOLfLrBgisw=='"
ALTER PROCEDURE [dbo].[pr_Clinical_GetPatientHistory_Constella] @PatientId INT
	,@Password VARCHAR(40)
AS
BEGIN
	DECLARE @SymKey VARCHAR(400);

	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @password + '';

	EXEC (@SymKey);

	SELECT DISTINCT dbo.fn_PatientIdentificationNumber_Constella(a.ptn_pk, '', 1) AS PatientId
		,CountryId + '-' + PosId + '-' + SatelliteId + '-' + PatientEnrollmentId AS PatientID
		,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname)) + ' ' + ISNULL(CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)), '') + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName)) AS NAME
		,b.LocationID
		,a.Sex
		,a.PatientClinicID
	FROM mst_patient AS a
		,ord_visit AS b
	WHERE a.ptn_pk = b.ptn_pk
		AND a.ptn_pk = @patientid
		AND b.visittype = 12;

	SELECT forms.*
	FROM (
		SELECT 'HIV-Enrollment' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'1' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 0
			AND a.Ptn_Pk = @PatientId
			AND a.PatientEnrollmentID <> ''
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Initial Evaluation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 1
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Prior ART/HIV Care' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'202' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 16
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ART Care' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'202' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 14
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				) ---john start
		
		UNION
		
		SELECT 'ART Therapy' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 19
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				) --john end
		
		UNION
		
		SELECT 'ART History' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 18
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Pharmacy' AS FormName
			,dbo.mst_Patient.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.firstname)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.lastName)) AS NAME
			,TranDate = CASE 
				WHEN dbo.ord_PatientPharmacyOrder.DispensedByDate IS NULL
					THEN dbo.ord_PatientPharmacyOrder.OrderedByDate
				ELSE dbo.ord_PatientPharmacyOrder.DispensedByDate
				END
			,ord_Visit.DataQuality AS DataQuality
			--,dbo.ord_PatientPharmacyOrder.Ptn_Pharmacy_Pk [OrderNo]
			,dbo.ord_Visit.visit_id AS OrderNo
			,dbo.ord_Visit.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'5' AS Priority
			,'0' AS Module
			,mst_decode.ID AS ID
			,mst_decode.NAME AS ART
			--,CAUTION = CASE 
			--	WHEN dbo.ord_PatientPharmacyOrder.DispensedByDate IS NULL
			--		THEN '1'
			--	ELSE '0'
			--	END
			,CAUTION = CASE 
				WHEN dbo.ord_PatientPharmacyOrder.orderstatus IS NULL
					OR dbo.ord_PatientPharmacyOrder.orderstatus = 1
					THEN '1'
				WHEN dbo.ord_PatientPharmacyOrder.orderstatus = 2
					THEN '3'
				WHEN dbo.ord_PatientPharmacyOrder.orderstatus = 3
					THEN '2'
				ELSE '0'
				END
			,'0' AS FeatureID
			,'' AS UserName
		FROM dbo.mst_Patient
		INNER JOIN dbo.ord_PatientPharmacyOrder ON dbo.mst_Patient.Ptn_Pk = dbo.ord_PatientPharmacyOrder.Ptn_pk
		INNER JOIN dbo.ord_Visit ON dbo.mst_Patient.Ptn_Pk = dbo.ord_Visit.Ptn_Pk
			AND dbo.ord_PatientPharmacyOrder.VisitID = dbo.ord_Visit.Visit_Id
		LEFT OUTER JOIN mst_decode ON mst_decode.ID = ord_PatientPharmacyOrder.ProgID
		WHERE dbo.ord_visit.visittype = 4
			AND dbo.mst_Patient.Ptn_Pk = @PatientId
			AND (
				ord_visit.DeleteFlag IS NULL
				OR ord_visit.DeleteFlag = 0
				)
			AND ord_visit.VisitDate IS NOT NULL
			AND ord_PatientPharmacyOrder.ordertype IN (
				116
				,117
				)
		
		UNION
		
		SELECT 'Order Labs' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName)) AS NAME
			,ISNULL(b.OrderedbyDate, '1900-01-01') AS TranDate
			,c.DataQuality AS DataQuality
			,LabId AS OrderNo
			,c.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'0' AS Module
			,ISNULL(b.ResultVisitId, '0') AS ID
			,'0' AS ART
			,CAUTION = CASE 
				WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Completed'
					THEN '0'
				WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
					AND (
						b.ReportedByDate IS NULL
						OR b.ReportedByDate = '1900-01-01'
						)
					THEN '1'
				WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
					AND (
						b.ReportedByDate IS NOT NULL
						OR b.ReportedByDate <> '1900-01-01'
						)
					THEN '2'
				ELSE '1'
				END
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_PatientLabOrder AS b
			,ord_Visit AS c
		WHERE a.ptn_pk = b.ptn_pk
			AND b.VisitId = c.Visit_Id
			AND a.ptn_pk = @PatientId
			AND c.visittype = 6
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ART Follow-Up' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'3' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 2
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'HIV Care/ART Encounter' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'3' AS Priority
			,'202' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 15
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Initial and Follow up Visits' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'3' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 17
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT DISTINCT 'Non-ART Follow-Up' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_Visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.VisitType = 3
			AND b.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Patient Record - Initial Visit' AS FormName
			,mst_Patient.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.firstname, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.MiddleName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.lastName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) AS NAME
			,ISNULL(ord_Visit.VisitDate, '1900-01-01') AS TranDate
			,ord_Visit.DataQuality AS DataQuality
			,ord_Visit.Visit_Id AS OrderNo
			,ord_Visit.LocationID AS LocationID
			,'0' AS PatientRecordNo
			,'0' AS Priority
			,'' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_Patient
		INNER JOIN ord_Visit ON mst_Patient.Ptn_Pk = ord_Visit.Ptn_pk
		WHERE ord_visit.visittype = 7
			AND mst_Patient.ptn_pk = @PatientId
		
		UNION
		
		SELECT 'Patient Record - Follow Up' AS FormName
			,mst_Patient.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.firstname, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.MiddleName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.lastName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) AS NAME
			,ISNULL(ord_Visit.VisitDate, '1900-01-01') AS TranDate
			,ord_Visit.DataQuality AS DataQuality
			,ord_Visit.Visit_Id AS OrderNo
			,ord_Visit.LocationID AS LocationID
			,'0' AS PatientRecordNo
			,'0' AS Priority
			,'' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_Patient
		INNER JOIN ord_Visit ON mst_Patient.Ptn_Pk = ord_Visit.Ptn_pk
		WHERE ord_visit.visittype = 8
			AND mst_Patient.ptn_pk = @PatientId
			AND ord_visit.DeleteFlag IS NULL
		
		UNION
		
		SELECT 'Care Tracking' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,TranDate = CASE 
				WHEN c.Careended = 1
					THEN ISNULL(c.CareEndedDate, '')
				WHEN c.ARTended = 1
					THEN ISNULL(c.ARTenddate, '')
				ELSE ISNULL(b.DateLastContact, '')
				END
			,b.DataQuality AS DataQuality
			,b.TrackingID AS OrderNo
			,c.LocationID AS LocationID
			,c.CareEndedID AS PharmacyNo
			,'9' AS Priority
			,
			--Module=CASE WHEN (b.ModuleId = 1) THEN 'PMTCT' When (b.ModuleId = 2) Then 'ART' END
			b.ModuleId AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,dtl_patienttrackingcare AS b
			,dtl_patientcareended AS c
		WHERE a.Ptn_pk = b.Ptn_pk
			AND a.ptn_pk = c.ptn_pk
			AND b.trackingID = c.trackingID
			AND (
				c.ARTended IS NULL
				OR c.ARTended = 0
				)
			AND a.Ptn_pk = @PatientId
		
		UNION
		
		SELECT 'Home Visit' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.hvBeginDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.HomeVisitID AS OrderNo
			,b.LocationId AS LocationID
			,'0' AS PharmacyNo
			,'8' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,dtl_patienthomevisit AS b
		WHERE a.Ptn_pk = b.Ptn_pk
			AND a.Ptn_pk = @PatientId
			AND (
				b.DeleteFlag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'PEP' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'6' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 21
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Paediatric Initial Evaluation Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 22
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Express' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 31
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Patient Registration' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'1' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 12
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Paediatric Follow up Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 24
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Adult Initial Evaluation Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 25
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Adult Follow up Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 23
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria Adult Initial Evaluation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 32
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria Paediatric Initial Evaluation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 33
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria ART Care Visitation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 34
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria ART Care Summary' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 35
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria Initial Visit' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'8' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 36
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'HEI' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'9' AS Priority
			,'1' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 37
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ANC' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'9' AS Priority
			,'1' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 40
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'DCC Adult Initial Evaluation Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'1' AS Priority
			,'210' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 38
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'DCC Revised Adult Follow up Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'210' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 39
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Green Card Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 50
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		/**** HVICE ******/
		
		UNION
		
		SELECT 'Treatment Preparation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'203' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 60
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ART Readiness Assessment' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'203' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 61
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Transition from Paediatric to Adolescent Services' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'293' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 62
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Alcohol, GBV and Depression Screening' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'292' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 63
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Clinical Encounter' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Clinical Encounter'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Refill Encounter' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Refill Encounter'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Adherence Barriers' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Adherence Barriers'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Enhance Adherence Counselling' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Enhance Adherence Counselling'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT DISTINCT c.VisitName AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,c.VisitTypeID AS Priority
			,d.ModuleId AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,d.featureid AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
			,mst_visitType AS c
			,mst_Feature AS d
		LEFT OUTER JOIN mst_Module AS e ON d.ModuleId = e.ModuleId
		WHERE a.ptn_pk = b.ptn_pk
			AND e.deleteflag = 0
			AND b.visittype = c.VisitTypeID
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
			AND c.systemId = d.systemId
			AND c.VisitName = d.FeatureName

			AND c.visitName NOT IN (
				'Enrollment'
				,'Initial Evaluation'
				,'ART Follow-Up'
				,'Non-ART Follow-Up'
				,'Pharmacy Order'
				,'Scheduler'
				,'Order Labs'
				,'Patient Record - Initial Visit'
				,'Patient Record - Follow Up'
				,'PMTCT Enrollment'
				,'Patient Registration'
				,'KNH PEP Form'
				,'Paediatric Initial Evaluation Form'
				,'Adult Follow up Form'
				,'Paediatric Follow up Form'
				,'Adult Initial Evaluation Form'
				,'Express'
				,'Adult Initial Evaluation'
				,'Paediatric Initial Evaluation'
				,'ART Care Visitation'
				,'Initial Visit'
				,'HEI Form'
				,'DCC Adult Initial Evaluation Form'
				,'DCC Revised Adult Follow up Form'
				,'ANC Form'
				,'Green Card Form'
				,'ART Readiness Assessment'
				,'Transition from Paediatric to Adolescent Services'
				,'Alcohol, GBV and Depression Screening'
				,'Refill Encounter'
				,'Enhance Adherence Counselling'
				,'Adherence Barriers'
				)
				
			AND d.ModuleId NOT IN (0)
			AND d.published = 2
			AND (
				d.deleteflag IS NULL
				OR d.deleteflag = 0
				)
		) forms
	ORDER BY TranDate DESC
		,FormName DESC;--02

	SELECT Visit_Id
		,LocationID
	FROM ord_visit
	WHERE ptn_pk = @patientid
		AND visittype = 0;--03

	SELECT FeatureID
		,FeatureName
	FROM mst_feature AS a
	LEFT OUTER JOIN mst_module AS b ON a.ModuleID = b.ModuleId
	WHERE Published IN (2)
		AND b.deleteflag = 0
		AND a.deleteflag = 0;--04

	SELECT 'Order Labs' AS FormName
		,a.ptn_pk
		,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName)) AS NAME
		,ISNULL(b.OrderedbyDate, '1900-01-01') AS TranDate
		,c.DataQuality AS DataQuality
		,LabId AS OrderNo
		,c.LocationID AS LocationID
		,'0' AS PharmacyNo
		,'7' AS Priority
		,'0' AS Module
		,'0' AS ID
		,'0' AS ART
		,CAUTION = CASE 
			WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Completed'
				THEN '0'
			WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
				AND (
					b.ReportedByDate IS NULL
					OR b.ReportedByDate = '1900-01-01'
					)
				THEN '1'
			WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
				AND (
					b.ReportedByDate IS NOT NULL
					OR b.ReportedByDate <> '1900-01-01'
					)
				THEN '2'
			ELSE '1'
			END
		,'0' AS FeatureID
		,'' AS UserName
		,b.LabNumber
		,dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_URGENT_STATUS') [URGENT]
	FROM mst_patient AS a
		,ord_PatientLabOrder AS b
		,ord_Visit AS c
	WHERE a.ptn_pk = b.ptn_pk
		AND b.VisitId = c.Visit_Id
		AND a.ptn_pk = @PatientId
		AND c.visittype = 6
		AND (
			b.deleteflag IS NULL
			OR b.deleteflag = 0
			)
	ORDER BY TranDate DESC
		,FormName DESC;

	CLOSE SYMMETRIC KEY Key_CTC;
END
go
--==

alter PROCEDURE [dbo].[pr_Clinical_PatientDetails_Constella] @PatientId INT
	,@SystemId INT
	,@ModuleId INT
	,@DBKey VARCHAR(50)
AS

BEGIN
	DECLARE @SymKey VARCHAR(400)
	DECLARE @ARTEndStatus VARCHAR(50)

	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @DBKey + ''

	EXEC (@SymKey)

	-- Table 0                                                                                                                                                                              
	SELECT convert(VARCHAR(50), decryptbykey(a.firstname)) [firstname]
		,convert(VARCHAR(50), decryptbykey(a.middlename)) [middlename]
		,convert(VARCHAR(50), decryptbykey(a.lastName)) [lastname]
		,convert(VARCHAR(50), decryptbykey(a.Address)) [Address]
		,convert(VARCHAR(50), decryptbykey(a.Phone)) [phone]
		,REPLACE(convert(VARCHAR(50), decryptbykey(a.lastName)) + Coalesce(',' + convert(VARCHAR(50), decryptbykey(a.middlename)), '') + ',' + convert(VARCHAR(50), decryptbykey(a.firstname)), ',,', ',') [FullName]
		,a.PosId + '-' + a.SatelliteId + '-' + a.PatientEnrollmentId [PatientEnrollmentId]
		,a.NearestHealthCentre [NearestHC]
		,a.SubCountry
		,a.Landmark
		,a.SubLocation
		,a.PatientClinicId
		,a.RegistrationDate
		,a.STATUS
		,a.IQNumber [IQNumber]
		,a.dob DOB
		,datediff(yy, a.dob, getdate()) [AGE]
		,datediff(month, a.dob, getdate()) [AgeInMonths]
		,dbo.fn_getpatientage(a.ptn_pk) [AGEINYEARMONTH]
		,b.NAME [SexNM]
		,e.NAME [Program]
		,i.NAME [MaritalStatus]
		,isnull(f.NAME, '') [VillageNM]
		,isnull(g.NAME, '') [District]
		,isnull(h.NAME, '') [ProvinceNM]
		,c.EmergContactName [EmergContactName]
		,c.EmergContactPhone [EmergContactPhone]
		,c.EmergContactAddress [EmergContactAddress]
		,ISNULL(c.EmergContactRelation, '0') [EmergContactRelation]
		,d.HIVStatus_Child
		,convert(VARCHAR(50), decryptbykey(c.TenCellLeader)) [TenCellLeader]
		,convert(VARCHAR(50), decryptbykey(c.TenCellLeaderAddress)) [TenCellLeaderAddress]
		,a.PosId + '-' + a.SatelliteId + '-' + a.PatientEnrollmentId [EnrollmentID]
		,isnull(a.ANCNumber, '') [ANCNumber]
		,isnull(a.PMTCTNumber, '') [PMTCTNumber]
		,isnull(a.AdmissionNumber, '') [AdmissionNumber]
		,isnull(a.OutpatientNumber, '') [OutpatientNumber]
		,a.PatientFacilityID
		,isnull(f.ID, '') [VillageId]
		,isnull(g.ID, '') [DistrictId]
	FROM mst_patient a
	LEFT OUTER JOIN mst_decode b
		ON a.sex = b.id
	LEFT OUTER JOIN dtl_patientcontacts c
		ON a.ptn_pk = c.ptn_pk
	LEFT OUTER JOIN dtl_PatientHivOther d
		ON a.Ptn_Pk = d.Ptn_pk
	LEFT OUTER JOIN mst_decode e
		ON a.ProgramId = e.Id
	LEFT OUTER JOIN mst_village f
		ON a.VillageName = f.Id
	LEFT OUTER JOIN mst_district g
		ON a.DistrictName = g.Id
	LEFT OUTER JOIN mst_province h
		ON a.Province = h.Id
	LEFT OUTER JOIN mst_decode i
		ON a.MaritalStatus = i.id
	WHERE a.Ptn_Pk = @PatientId

	--Table 1 --ART --Last Visit Date            
	SELECT TOP 1 a.VisitDate
	FROM ord_Visit a
		,mst_patient b
	WHERE a.ptn_pk = b.ptn_pk
		AND a.Ptn_Pk = @PatientId
		AND (
			a.DeleteFlag = 0
			OR a.DeleteFlag IS NULL
			)
		AND (
			a.visittype NOT IN (
				5
				,10
				,11
				,12
				)
			OR a.visittype < 100
			)
		AND (
			b.DeleteFlag = 0
			OR b.DeleteFlag IS NULL
			)
		AND nullif(b.PatientEnrollmentId, '') IS NOT NULL
	ORDER BY a.Visitdate DESC

	--Table 2                                                                             
	SELECT TOP 1 AppDate
	FROM dtl_patientappointment
	WHERE ptn_pk = @PatientId
		AND Appstatus IN (12)
		AND AppDate <> '1900-01-01'
		AND (
			DeleteFlag = 0
			OR DeleteFlag IS NULL
			)
	ORDER BY AppDate ASC

	--Table 3                                                                                                                                                                        
	SELECT a.TestResults
		,ISNULL(b.OrderedByDate, b.ReportedbyDate) AS OrderedByDate
		,a.Parameterid
	FROM dtl_PatientLabResults a
		,ord_PatientLabOrder b
	WHERE b.LabId = a.LabId
		AND a.ParameterId IN (
			5
			,6
			,10
			,12
			,106
			,75
			)
		AND (
			b.DeleteFlag = 0
			OR b.DeleteFlag IS NULL
			)
		AND b.Ptn_Pk = @PatientId

	--Table 4                             
	SELECT dbo.fn_GetPatientCurrentARTRegimen_Constella(a.ptn_pk) [Current ARV Regimen]
		,dbo.fn_GetPatientCurrentARTStartDate_Constella(a.ptn_pk) [Current ARV StartDate]
		,a.ARTStartDate [AidsRelief ARV StartDate]
		,b.currentartstartdate [Hist ARV StartDate]
		,c.ARTStartDate [Hist ARV StartDateCTC]
	FROM mst_patient a
	LEFT OUTER JOIN dtl_patienthivprevcareie b
		ON a.ptn_pk = b.ptn_pk
	LEFT OUTER JOIN dtl_PatientHivPrevCareEnrollment c
		ON a.ptn_pk = c.ptn_pk
	WHERE (
			a.deleteflag = 0
			OR a.deleteflag IS NULL
			)
		AND a.ptn_pk = @PatientId

	--Table 5                                                                                                                                                  
	SELECT *
	FROM (
		SELECT a.Height [Height]
			,a.Weight [Weight]
			,b.visit_Id [VisitID]
			,convert(DECIMAL(18, 2), Round((Nullif(a.Weight, 0) / (Nullif(a.height / 100, 0) * Nullif(a.height / 100, 0))), 2)) AS BMI
			,b.visitType [VisitType]
			,b.VisitDate [Visit_OrderbyDate]
		FROM dtl_patientvitals a
			,ord_visit b
		WHERE a.visit_pk = b.visit_Id
			AND (
				b.DeleteFlag = 0
				OR b.DeleteFlag IS NULL
				)
			AND a.ptn_pk = @PatientId
			AND a.Height IS NOT NULL
			AND a.Weight IS NOT NULL
		
		UNION
		
		SELECT a.Height [Height]
			,a.Weight [Weight]
			,b.visit_Id [VisitID]
			,convert(DECIMAL(18, 2), Round((Nullif(a.Weight, 0) / (Nullif(a.height / 100, 0) * Nullif(a.height / 100, 0))), 2)) AS BMI
			,b.visitType [VisitType]
			,a.OrderedByDate [Visit_OrderbyDate]
		FROM ord_PatientPharmacyOrder a
			,ord_visit b
		WHERE a.visitId = b.visit_Id
			AND (
				b.DeleteFlag = 0
				OR b.DeleteFlag IS NULL
				)
			AND a.ptn_pk = @PatientId
			AND a.ordertype = 117
			AND a.Height IS NOT NULL
			AND a.Weight IS NOT NULL
		) AS inLineView
	ORDER BY Visit_OrderbyDate DESC

	--Table 6                                                                                     
	SELECT a.Ptn_PK
		,b.labtestid
		,b.TestResults [TestResult]
		,a.OrderedbyDate [DATE]
	FROM ord_PatientLabOrder a
		,dtl_PatientLabResults b
	WHERE a.LabID = b.LabID
		AND b.labtestid = 1
		AND (
			a.deleteflag IS NULL
			OR a.deleteflag = 0
			)
		AND a.Ptn_PK = @PatientId
	ORDER BY a.OrderedbyDate ASC

	--Table 7                                                                                                           
	SELECT a.Ptn_PK
		,b.labtestid
		,b.TestResults [TestResult]
		,a.OrderedbyDate [DATE]
	FROM ord_PatientLabOrder a
		,dtl_PatientLabResults b
	WHERE a.LabID = b.LabID
		AND b.labtestid = 3
		AND (
			a.deleteflag IS NULL
			OR a.deleteflag = 0
			)
		AND a.Ptn_PK = @PatientId
	ORDER BY a.OrderedbyDate ASC

	--Table 8                                                                                                 
	SELECT *
	FROM (
		SELECT a.OrderedbyDate [DATE]
		FROM ord_PatientLabOrder a
			,dtl_PatientLabResults b
		WHERE a.LabID = b.LabID
			AND b.labtestid = 3
			AND (
				a.deleteflag IS NULL
				OR a.deleteflag = 0
				)
			AND a.Ptn_PK = @PatientId
			AND a.OrderedbyDate NOT IN (
				SELECT a.OrderedbyDate [DATE]
				FROM ord_PatientLabOrder a
					,dtl_PatientLabResults b
				WHERE a.LabID = b.LabID
					AND b.labtestid = 1
					AND (
						a.deleteflag IS NULL
						OR a.deleteflag = 0
						)
					AND a.Ptn_PK = @PatientId
				)
		
		UNION ALL
		
		SELECT a.OrderedbyDate [DATE]
		FROM ord_PatientLabOrder a
			,dtl_PatientLabResults b
		WHERE a.LabID = b.LabID
			AND b.labtestid = 1
			AND (
				a.deleteflag IS NULL
				OR a.deleteflag = 0
				)
			AND a.Ptn_PK = @PatientId
		) AS inLineView
	ORDER BY DATE ASC

	--Table 9                                                                            
	IF (@ModuleId = '203')
	BEGIN
		SELECT TOP 1 a.*
			,b.NAME [PregnantValue]
		FROM dtl_PatientClinicalStatus a
		INNER JOIN VW_AllMasters b
			ON a.Pregnant = b.Id
		JOIN Ord_visit c
			ON a.Visit_pk = c.Visit_Id
		WHERE a.ptn_pk = @PatientId
			AND b.ModuleId = @ModuleId
			AND (
				c.deleteflag = 0
				OR c.deleteflag IS NULL
				)
		ORDER BY a.Visit_pk DESC
	END
	ELSE
	BEGIN
		SELECT TOP 1 *
			,[PregnantValue] = CASE 
				WHEN Pregnant = '0'
					THEN 'Negative'
				WHEN Pregnant = '1'
					THEN 'Positive'
				END
		FROM dtl_PatientClinicalStatus a
		JOIN Ord_visit b
			ON a.Visit_pk = b.Visit_Id
		WHERE a.ptn_pk = @PatientId
			AND (
				b.deleteflag = 0
				OR b.deleteflag IS NULL
				)
		ORDER BY a.Visit_pk DESC
	END

	--Table 10 WHOStage Data                                                                    
	IF EXISTS (
			SELECT TOP 1 a.ptn_pk
				,a.visit_pk
				,c.NAME [WHO Stage]
				,d.NAME [WAB Stage]
			FROM dtl_patientstage a
			INNER JOIN ord_visit b
				ON a.visit_pk = b.Visit_ID
			LEFT OUTER JOIN mst_decode c
				ON a.whostage = c.id
			LEFT OUTER JOIN mst_decode d
				ON a.wabstage = d.id
			WHERE a.ptn_pk = @PatientId
				AND (
					WHOStage IS NOT NULL
					AND WHOStage <> 0
					)
				AND (
					b.DeleteFlag IS NULL
					OR b.DeleteFlag = 0
					)
			ORDER BY a.WABStageID DESC
			)
	BEGIN
		SELECT WHOStageFlag = 1

		--Table 11                                                                                        
		SELECT TOP 1 a.ptn_pk
			,a.visit_pk
			,c.NAME [WHOStage]
			,d.NAME [WAB Stage]
		FROM dtl_patientstage a
		INNER JOIN ord_visit b
			ON a.visit_pk = b.Visit_ID
		LEFT OUTER JOIN mst_decode c
			ON a.whostage = c.id
		LEFT OUTER JOIN mst_decode d
			ON a.wabstage = d.id
		WHERE a.ptn_pk = @PatientId
			AND (
				WHOStage IS NOT NULL
				AND WHOStage <> 0
				)
			AND (
				b.DeleteFlag IS NULL
				OR b.DeleteFlag = 0
				)
		ORDER BY a.WABStageID DESC
	END
	ELSE
	BEGIN
		SELECT WHOStageFlag = 0

		SELECT 19
	END

	--Table 12--- Lowest CD4                                                       
	IF EXISTS (
			SELECT *
			FROM (
				SELECT Convert(NUMERIC, PrevLowestCD4) [TestResults]
					,PrevARVsCD4 [TestResultsCTC]
					,PrevLowestCD4Date [OrderedByDate]
				FROM dtl_PatientHivPrevCareIE a
					,ord_Visit b
				WHERE a.Visit_pk = b.Visit_Id
					AND a.Ptn_pk = @PatientId
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
					AND (
						PrevLowestCD4 IS NOT NULL
						OR PrevARVsCD4 IS NOT NULL
						)
				
				UNION
				
				SELECT Convert(NUMERIC, a.TestResults) [TestResults]
					,Convert(NUMERIC, a.TestResults) [TestResultsCTC]
					,b.OrderedByDate [OrderedByDate]
				FROM dtl_PatientLabResults a
					,ord_PatientLabOrder b
				WHERE b.LabId = a.LabId
					AND a.LabTestId = 1
					AND a.ParameterId = 1
					AND b.Ptn_Pk = @PatientId
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
					AND a.TestResults IS NOT NULL
				) AS InlineView
			)
	BEGIN
		SELECT LowestCD4Flag = 1

		--Table 13                                                                                                                                                              
		SELECT *
		FROM (
			SELECT Convert(NUMERIC, PrevLowestCD4) [TestResults]
				,PrevMostRecentCD4 [TestResultsCTC]
				,isnull(PrevLowestCD4Date, PrevMostRecentCD4Date) [OrderedByDate]
			FROM dtl_PatientHivPrevCareIE a
				,ord_Visit b
			WHERE a.Visit_pk = b.Visit_Id
				AND a.Ptn_pk = @PatientId
				AND (
					b.deleteflag IS NULL
					OR b.deleteflag = 0
					)
				AND (
					PrevLowestCD4 IS NOT NULL
					OR PrevMostRecentCD4 IS NOT NULL
					)
			
			UNION
			
			SELECT Convert(NUMERIC, a.TestResults) [TestResults]
				,Convert(NUMERIC, a.TestResults) [TestResultsCTC]
				,b.OrderedByDate [OrderedByDate]
			FROM dtl_PatientLabResults a
				,ord_PatientLabOrder b
			WHERE b.LabId = a.LabId
				AND a.LabTestId = 1
				AND a.ParameterId = 1
				AND b.Ptn_Pk = @PatientId
				AND (
					b.deleteflag IS NULL
					OR b.deleteflag = 0
					)
				AND a.TestResults IS NOT NULL
			) AS InlineView
	END
	ELSE
	BEGIN
		SELECT LowestCD4Flag = 0

		SELECT 20
	END

	--Table 14 Most Recent CD4                                                            
	IF EXISTS (
			SELECT *
			FROM (
				SELECT Convert(NUMERIC, PrevMostRecentCD4) [TestResults]
					,PrevMostRecentCD4Date [OrderedByDate]
				FROM dtl_PatientHivPrevCareIE a
					,ord_Visit b
				WHERE a.Visit_pk = b.Visit_Id
					AND a.Ptn_pk = @PatientId
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
					AND PrevMostRecentCD4 IS NOT NULL
					AND PrevMostRecentCD4Date IS NOT NULL
				
				UNION
				
				SELECT Convert(NUMERIC, a.TestResults) [TestResults]
					,b.OrderedByDate [OrderedByDate]
				FROM dtl_PatientLabResults a
					,ord_PatientLabOrder b
				WHERE b.LabId = a.LabId
					AND a.LabTestId = 1
					AND a.ParameterId = 1
					AND b.Ptn_Pk = @PatientId
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
					AND TestResults IS NOT NULL
				) AS InlineView
			)
	BEGIN
		SELECT RecentCD4Flag = 1

		-- Table 15                                                                             
		SELECT Max(TestResults) [TestResults]
			,OrderedByDate
		FROM (
			SELECT Convert(NUMERIC, PrevMostRecentCD4) [TestResults]
				,PrevMostRecentCD4Date [OrderedByDate]
			FROM dtl_PatientHivPrevCareIE a
				,ord_Visit b
			WHERE a.Visit_pk = b.Visit_Id
				AND a.Ptn_pk = @PatientId
				AND (
					b.deleteflag IS NULL
					OR b.deleteflag = 0
					)
				AND PrevMostRecentCD4 IS NOT NULL
				AND PrevMostRecentCD4Date IS NOT NULL
			
			UNION
			
			SELECT Convert(NUMERIC, a.TestResults) [TestResults]
				,b.OrderedByDate [OrderedByDate]
			FROM dtl_PatientLabResults a
				,ord_PatientLabOrder b
			WHERE b.LabId = a.LabId
				AND a.LabTestId = 1
				AND a.ParameterId = 1
				AND b.Ptn_Pk = @PatientId
				AND (
					b.deleteflag IS NULL
					OR b.deleteflag = 0
					)
				AND a.TestResults IS NOT NULL
				AND b.OrderedByDate IS NOT NULL
			) AS InlineView
		GROUP BY OrderedByDate
		ORDER BY OrderedByDate DESC
	END
	ELSE
	BEGIN
		SELECT RecentCD4Flag = 0

		SELECT 22
	END

	--Table 16                                                                                                    
	IF EXISTS (
			SELECT *
			FROM (
				SELECT Convert(NUMERIC, PrevMostRecentCD4) [TestResults]
					,PrevMostRecentCD4Date [OrderedByDate]
				FROM dtl_PatientHivPrevCareIE a
					,ord_Visit b
				WHERE a.Visit_pk = b.Visit_Id
					AND a.Ptn_pk = @PatientId
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
					AND PrevMostRecentCD4 IS NOT NULL
					AND PrevMostRecentCD4Date IS NOT NULL
				
				UNION
				
				SELECT Convert(NUMERIC, a.TestResults) [TestResults]
					,b.OrderedByDate [OrderedByDate]
				FROM dtl_PatientLabResults a
					,ord_PatientLabOrder b
				WHERE b.LabId = a.LabId
					AND a.LabTestId = 1
					AND a.ParameterId = 1
					AND b.Ptn_Pk = @PatientId
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
					AND TestResults IS NOT NULL
				) AS InlineView
			)
	BEGIN
		DECLARE @checkdate DATETIME
		DECLARE @finaldate DATETIME

		SELECT RecentCD4Flag = 1

		-- Table 17                                                                                                                       
		SET @checkdate = (
				SELECT TOP 1 OrderedByDate
				FROM (
					SELECT Convert(NUMERIC, PrevMostRecentCD4) [TestResults]
						,PrevMostRecentCD4Date [OrderedByDate]
					FROM dtl_PatientHivPrevCareIE a
						,ord_Visit b
					WHERE a.Visit_pk = b.Visit_Id
						AND a.Ptn_pk = @PatientId
						AND (
							b.deleteflag IS NULL
							OR b.deleteflag = 0
							)
						AND PrevMostRecentCD4 IS NOT NULL
						AND PrevMostRecentCD4Date IS NOT NULL
					
					UNION
					
					SELECT Convert(NUMERIC, a.TestResults) [TestResults]
						,b.OrderedByDate [OrderedByDate]
					FROM dtl_PatientLabResults a
						,ord_PatientLabOrder b
					WHERE b.LabId = a.LabId
						AND a.LabTestId = 1
						AND a.ParameterId = 1
						AND b.Ptn_Pk = @PatientId
						AND (
							b.deleteflag IS NULL
							OR b.deleteflag = 0
							)
						AND a.TestResults IS NOT NULL
						AND b.OrderedByDate IS NOT NULL
					) AS InlineView
				ORDER BY OrderedByDate DESC
				)
		SET @finaldate = dateadd(month, 6, @checkdate)

		SELECT @finaldate
	END
	ELSE
	BEGIN
		SELECT RecentCD4Flag = 0

		SELECT 24
	END

	--Table 18 WAB stage                                                      
	SELECT TOP 1 a.ptn_pk
		,a.Visit_Pk
		,a.WABStageID
		,d.NAME [WABStage]
	FROM dtl_patientstage a
		,ord_visit b
		,mst_decode d
	WHERE a.wabstage = d.id
		AND a.visit_pk = b.visit_Id
		AND a.ptn_pk = @PatientId
		AND (
			WABStage IS NOT NULL
			AND WABStage <> 0
			)
		AND (
			b.DeleteFlag IS NULL
			OR b.DeleteFlag = 0
			)
	ORDER BY a.WABStageID DESC

	---Table 19                                 
	SELECT 
		nullif(dbo.fn_GetPatientStatus(@PatientId, @ModuleId), '') [ART/PalliativeCare]
		,nullif(dbo.fn_GetPatientPMTCTProgramStatus_Futures(@PatientId), '') [PMTCTStatus]

	-- Table 20 for family info 
	SELECT count(*) [FamilyCount]
	FROM dtl_familyInfo
	WHERE Ptn_pk = @PatientId
		AND Referenceid IS NOT NULL
		AND (
			DeleteFlag IS NULL
			OR DeleteFlag = 0
			)

	-- Table 21---for family ART Count                                                                            
	SELECT count(*) [FamilyARTCount]
	FROM dtl_FamilyInfo f
	LEFT OUTER JOIN mst_RelationshipType r
		ON r.ID = f.RelationshipType
	LEFT OUTER JOIN mst_decode s
		ON s.ID = f.Sex
	WHERE f.Ptn_pk = @PatientId
		AND dbo.fn_GetHivCareStatusID(f.ptn_pk, f.ReferenceId, f.Id) = 2
		AND f.Referenceid IS NOT NULL
		AND (
			f.DeleteFlag IS NULL
			OR f.DeleteFlag = 0
			)

	--table 22                                                                                                                                    
	SELECT count(*) [FamilyAllCount]
	FROM dtl_familyInfo
	WHERE Ptn_pk = @PatientId
		AND (
			DeleteFlag IS NULL
			OR DeleteFlag = 0
			)

	--Table 23 -- Dynamic Labels                                                                                                                                
	EXEC dbo.pr_SystemAdmin_GetSystemBasedLabels_Constella @SystemId
		,1000
		,''

	--Table 24                                                                                                                                                 
	SELECT TOP 1 Z.TestResults
		,Z.OrderedByDate
		,dateadd(mm, 6, Z.OrderedByDate) [OrderedByDueDate]
		,Z.Dis_Date
	FROM (
		SELECT Convert(NUMERIC, b.PrevARVsCD4) [TestResults]
			,a.RegistrationDate [OrderedByDate]
			,'0' [Dis_Date]
		FROM mst_patient a
		INNER JOIN dtl_PatientHivPrevCareIE b
			ON a.ptn_pk = b.ptn_pk
		INNER JOIN ord_Visit c
			ON c.Visit_Id = b.Visit_pk
				AND c.Ptn_Pk = a.Ptn_pk
				AND c.visittype = 0
		WHERE (
				a.DeleteFlag = 0
				OR a.DeleteFlag IS NULL
				)
			AND b.ptn_pk = @PatientId
			AND a.RegistrationDate IS NOT NULL
			AND b.PrevARVsCD4 IS NOT NULL
		
		UNION
		
		SELECT Convert(NUMERIC, c.TestResults) [TestResults]
			,b.OrderedByDate [OrderedByDate]
			,'1' [Dis_Date]
		FROM mst_patient a
		INNER JOIN ord_PatientLabOrder b
			ON a.ptn_pk = b.ptn_pk
		INNER JOIN dtl_PatientLabResults c
			ON b.LabId = c.LabId
				AND c.LabTestID = 1
				AND c.ParameterId = 1
				AND (
					b.deleteflag IS NULL
					OR b.deleteflag = 0
					)
		WHERE a.Ptn_Pk = @PatientId
			AND (
				a.deleteflag IS NULL
				OR a.deleteflag = 0
				)
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
			AND c.TestResults IS NOT NULL
			AND b.OrderedByDate IS NOT NULL
		) Z
	ORDER BY Z.OrderedByDate DESC

	--Table 25-- Most Recent Weight                                                                          
	SELECT TOP 1 weight
	FROM dtl_patientvitals
	WHERE ptn_pk = @PatientId
		AND Weight IS NOT NULL
	ORDER BY visit_pk DESC

	--Table 26 ARV runs out                                                                                   
	SELECT TOP 1 max(po.Duration)
		,opo.dispensedbydate
		,datediff(dd, getdate(), (dateadd(dd, max(po.duration), opo.dispensedbydate))) [CurrARTStock]
	FROM ord_PatientPharmacyOrder opo
	INNER JOIN dtl_PatientPharmacyOrder po
		ON opo.Ptn_Pharmacy_Pk = po.Ptn_Pharmacy_Pk
	WHERE opo.ptn_pk = @PatientId
		AND opo.Ptn_Pharmacy_Pk IN (
			SELECT a.ptn_pharmacy_pk
			FROM ord_patientpharmacyorder a
			inner join dtl_patientpharmacyorder b on a.ptn_pharmacy_pk = b.ptn_pharmacy_pk
			inner join mst_Drug c on b.Drug_Pk=c.Drug_pk
			WHERE c.drugtype = 37
				AND (
					a.deleteflag = 0
					OR a.deleteflag IS NULL
					)
				AND a.dispensedbydate IS NOT NULL
			)
	GROUP BY opo.dispensedbydate
	ORDER BY dispensedbydate DESC

	--Table 27                                                                                    
	SELECT dbo.fn_GetAgeConstella(DOB, RegistrationDate) [PatientAge]
	FROM mst_patient
	WHERE ptn_pk = @PatientId

	--Table 28 -- PMTCT -- Current ARV Prophylaxis Regimen and Current ARV Prophylaxis Regimen Start Date                                                                   
	IF EXISTS (
			SELECT *
			FROM mst_patient
			WHERE datediff(dd, dob, getdate()) / 365 >= 15
				AND ptn_pk = @PatientId
			)
	BEGIN
		SELECT dbo.fn_GetPatientCurrentProphylaxisRegimen_Constella(@PatientId) [CurrentARVProphylaxisRegimen]
			,dbo.fn_GetPatientCurrentProphylaxisStartDate_Constella(@PatientId) [CurrentProphylaxisRegimenStartDate]
	END
	ELSE
		SELECT [CurrentARVProphylaxisRegimen] = NULL
			,[CurrentProphylaxisRegimenStartDate] = NULL

	--Table 29 -- PMTCT -- Delivery Date                                                                                                                                   
	SELECT max(DateOfDelivery) [DeliveryDateTime]
	FROM dtl_patientclinicalstatus a
		,mst_patient b
	WHERE a.Ptn_pk = @PatientId
		AND a.ptn_pk = b.ptn_pk
		AND (
			b.deleteflag = 0
			OR b.deleteflag IS NULL
			)

	--Table 30 -- PMTCT -- Feeding Option                                                                                                              
	SELECT TOP 1 (a.NAME) [FeedingOption]
	FROM dtl_InfantInfo b
	INNER JOIN mst_pmtctdecode a
		ON b.FeedingOption = a.Id
	INNER JOIN ord_Visit c
		ON b.visit_pk = c.visit_Id
	WHERE b.Ptn_pk = @PatientId
		AND b.FeedingOption IS NOT NULL
		AND (
			a.deleteflag = 0
			OR a.deleteflag IS NULL
			)
		AND (
			b.deleteflag = 0
			OR b.deleteflag IS NULL
			)
	ORDER BY c.visitDate DESC

	--Table 31 -- PMTCT -- Last Visit Date                                                           
	SELECT TOP 1 a.VisitDate [PMTCTVisitDate]
	FROM ord_Visit a
		,mst_patient b
	WHERE a.ptn_pk = b.ptn_pk
		AND a.Ptn_Pk = @PatientId
		AND (
			a.DeleteFlag = 0
			OR a.DeleteFlag IS NULL
			)
		AND (
			a.visittype IN (
				4
				,6
				,11
				,12
				)
			OR a.visittype > 100
			)
		AND (
			b.DeleteFlag = 0
			OR b.DeleteFlag IS NULL
			)
		AND datediff(dd, b.dob, getdate()) / 365 >= 15
		AND b.sex = 17
		AND (
			ANCNumber IS NOT NULL
			OR PMTCTNumber IS NOT NULL
			OR AdmissionNumber IS NOT NULL
			OR OutPatientNumber IS NOT NULL
			)
	ORDER BY Visitdate DESC

	--Table 32 -- Child HIV Status                                                                              
	SELECT TOP 1 (b.NAME) [ChildHIVStatus]
	FROM dtl_patienthivother a
	INNER JOIN mst_pmtctDecode b
		ON a.HIVStatus_CHILD = b.Id
	INNER JOIN ord_Visit c
		ON a.visit_pk = c.visit_Id
	INNER JOIN mst_patient d
		ON a.ptn_pk = d.ptn_pk
	WHERE a.ptn_pk = @PatientId
		AND (
			d.ANCNumber IS NOT NULL
			OR d.PMTCTNumber IS NOT NULL
			OR d.AdmissionNumber IS NOT NULL
			OR d.OutPatientNumber IS NOT NULL
			)
		AND (
			d.DeleteFlag = 0
			OR d.DeleteFlag IS NULL
			)
	ORDER BY c.visitDate DESC

	---Table 33 ---- LMP from ANC-----                                                                      
	SELECT TOP 1 a.LMP [LMP]
	FROM dtl_PatientClinicalStatus a
		,ord_visit b
		,mst_visittype c
		,mst_patient d
	WHERE a.visit_pk = b.visit_id
		AND b.visittype = c.visittypeid
		AND (
			b.DeleteFlag = 0
			OR b.DeleteFlag IS NULL
			)
		AND datediff(dd, d.dob, getdate()) / 365 >= 15
		AND a.ptn_pk = d.ptn_pk
		AND d.sex = 17
		AND c.visitname LIKE '%ANC%'
		AND a.Ptn_pk = @PatientId
		AND a.LMP IS NOT NULL
	ORDER BY b.visitdate ASC

	--Table 34 ---- EDD from ANC-----                                                  
	SELECT TOP 1 a.EDD [EDD]
	FROM dtl_PatientClinicalStatus a
		,ord_visit b
		,mst_visittype c
		,mst_patient d
	WHERE a.visit_pk = b.visit_id
		AND b.visittype = c.visittypeid
		AND (
			b.DeleteFlag = 0
			OR b.DeleteFlag IS NULL
			)
		AND datediff(dd, d.dob, getdate()) / 365 >= 15
		AND a.ptn_pk = d.ptn_pk
		AND d.sex = 17
		AND c.visitname LIKE '%ANC%'
		AND a.Ptn_pk = @PatientId
		AND a.EDD IS NOT NULL
	ORDER BY b.visitdate ASC

	--Table 35 ---- TBStatus from ANC -----                                                  
	SELECT TOP 1 (d.NAME) [TBStatus]
	FROM dtl_PatientOtherTreatment a
		,ord_visit b
		,mst_visittype c
		,mst_pmtctdecode d
		,mst_patient e
	WHERE a.visit_pk = b.visit_id
		AND b.visittype = c.visittypeid
		AND (
			b.DeleteFlag = 0
			OR b.DeleteFlag IS NULL
			)
		AND (
			a.DeleteFlag = 0
			OR a.DeleteFlag IS NULL
			)
		AND a.TBStatus = d.Id
		AND datediff(dd, e.dob, getdate()) / 365 >= 15
		AND b.ptn_pk = e.ptn_pk
		AND e.sex = 17
		AND c.visitname LIKE '%ANC%'
		AND a.Ptn_pk = @PatientId
		AND a.TBStatus IS NOT NULL
	ORDER BY b.visitdate DESC

	--Table 36 ---- Partner HIV Status -----                                                                      
	SELECT TOP 1 (b.NAME) [Partner HIV Status]
	FROM dtl_PatientCounseling a
		,mst_pmtctdecode b
		,ord_Visit c
		,mst_patient d
	WHERE a.visit_pk = c.visit_Id
		AND datediff(dd, d.dob, getdate()) / 365 >= 15
		AND a.ptn_pk = d.ptn_pk
		AND (
			a.DeleteFlag = 0
			OR a.DeleteFlag IS NULL
			)
		AND (
			c.DeleteFlag = 0
			OR c.DeleteFlag IS NULL
			)
		AND a.PartnerHIVTestResult = b.Id
		AND a.PartnerHIVTestResult IS NOT NULL
		AND d.sex = 17
		AND a.Ptn_pk = @PatientId
	ORDER BY c.visitdate DESC

	--Table 37 ---- Infant Prophylaxis Regimen -----                
	SELECT TOP 1 (z.RegimenType) [Prophylaxis Regimen]
	FROM ord_patientpharmacyorder x
		,dtl_patientpharmacyorder y
		,dtl_RegimenMap z
		,mst_patient c
	WHERE (
			x.DeleteFlag IS NULL
			OR x.DeleteFlag = 0
			)
		AND x.progid = 223
		AND y.prophylaxis = 1
		AND x.ptn_pharmacy_pk = y.ptn_pharmacy_pk
		AND x.ptn_pk = c.ptn_pk
		AND datediff(dd, c.dob, getdate()) / 365 <= 2
		AND x.ptn_pk = @PatientId
		AND y.ptn_pharmacy_pk = z.orderid
	ORDER BY x.dispensedbydate DESC

	--Table 38 ---- Lab Results -----                                                           
	SELECT c.subtestname [Test]
		,Convert(VARCHAR, max(a.OrderedByDate), 103) [Date]
		,max(CAST(DATEDIFF(month, d.dob, a.OrderedByDate) / 12.0 AS DECIMAL(10, 1))) [Age(Mnt)]
		,b.TestResults [Result]
	FROM ord_PatientlabOrder a
		,dtl_PatientLabResults b
		,lnk_testParameter c
		,mst_patient d
	WHERE a.labid = b.labid
		AND a.Ptn_pk = @PatientId
		AND b.testresults IS NOT NULL
		AND a.ptn_pk = d.ptn_pk
		AND b.parameterid IN (
			53
			,114
			,101
			)
		AND (
			a.DeleteFlag = 0
			OR a.DeleteFlag IS NULL
			)
		AND datediff(dd, d.dob, getdate()) / 365 <= 2
		AND (
			d.DeleteFlag = 0
			OR d.DeleteFlag IS NULL
			)
		AND b.parameterid = c.subtestid
	GROUP BY d.ptn_pk
		,c.subtestname
		,b.TestResults
	ORDER BY max(a.OrderedByDate) DESC

	--Table 39 ---- Lab Results -----                                                       
	SELECT TOP 1 a.GestAge [Gestational Age]
	FROM dtl_patientdelivery a
		,mst_patient b
	WHERE a.ptn_pk = @PatientId
		AND a.ptn_pk = b.ptn_pk
		AND datediff(dd, b.dob, getdate()) / 365 >= 15
	ORDER BY a.Visit_pk DESC

	--Table 40 ---- Care Ended Status -----                                            
	SELECT TOP 1 PatientExitReason
		,CareEnded
		,PMTCTCareEnded
		,Ptn_Pk
	FROM VW_PatientCareEnd
	WHERE (
			CareEnded IS NOT NULL
			OR CareEnded <> 0
			)
		AND ptn_pk = @PatientId
		AND ModuleId = @ModuleId
	ORDER BY CareEndedId DESC

	--Table 41 ---- Techenical AreaName according Patient Selection -----                
	SELECT ptn_pk
		,ModuleID
		,StartDate
	FROM lnk_patientprogramstart
	WHERE ptn_pk = @PatientId
	ORDER BY ModuleID

	--Table 42 ---- Techenical AreaName according Patient Selection -----                          
	SELECT PatientExitReason
		,CareEnded
		,PMTCTCareEnded
		,Ptn_Pk
	FROM VW_PatientCareEnd
	WHERE ptn_pk = @PatientId
		AND CareEnded = 1
		AND PatientExitReason = 93

	---Table 43  
	SELECT @ARTEndStatus = dbo.fn_GetPatientARTStatus_Futures(@PatientId)

	IF (
			@ARTEndStatus != ''
			OR @ARTEndStatus IS NOT NULL
			)
	BEGIN
		SELECT @ARTEndStatus [ARTEndStatus]
	END
	ELSE
	BEGIN
		SELECT '' [ARTEndStatus]
	END

	---Table 44 
	SELECT TOP 10 row_number() OVER (
			PARTITION BY Ptn_pk ORDER BY OrderedbyDate DESC
			)
		,Ptn_pk
		,Drugname
		,OrderedbyDate
		,OrderedQuantity
		,'0' [DispensedQuantity]
		,isnull(Pillcount, 0) [Pillcount]
	FROM [VW_PatientPharmacy]
	WHERE ptn_pk = @PatientId
		AND DrugTypeId = 37
		AND OrderedbyDate IS NOT NULL

	---Table 45 
	SELECT TOP 10 row_number() OVER (
			PARTITION BY Ptn_pk ORDER BY OrderedbyDate DESC
			)
		,Ptn_pk
		,Drugname
		,OrderedbyDate
		,DispensedQuantity
		,'0' [OrderedQuantity]
		,isnull(Pillcount, 0) [Pillcount]
	FROM [VW_PatientPharmacy]
	WHERE ptn_pk = @PatientId
		AND DrugTypeId = 37
		AND DispensedQuantity IS NOT NULL

	---Table 46 
	SELECT TOP 10 row_number() OVER (
			PARTITION BY Ptn_pk ORDER BY OrderedbyDate DESC
			)
		,Ptn_pk
		,Drugname
		,OrderedbyDate
		,OrderedQuantity
		,'0' [DispensedQuantity]
		,isnull(Pillcount, 0) [Pillcount]
	FROM [VW_PatientPharmacy]
	WHERE ptn_pk = @PatientId
		AND DrugTypeId IN (
			4
			,5
			,6
			,7
			,8
			,36
			)
		AND OrderedbyDate IS NOT NULL

	---Table 47 
	SELECT TOP 10 row_number() OVER (
			PARTITION BY Ptn_pk ORDER BY OrderedbyDate DESC
			)
		,Ptn_pk
		,Drugname
		,OrderedbyDate
		,DispensedQuantity
		,'0' [OrderedQuantity]
		,isnull(Pillcount, 0) [Pillcount]
	FROM [VW_PatientPharmacy]
	WHERE ptn_pk = @PatientId
		AND DrugTypeId IN (
			4
			,5
			,6
			,7
			,8
			,36
			)
		AND DispensedQuantity IS NOT NULL

	CLOSE symmetric KEY Key_CTC
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Clinical_GetPatientRegistration_Constella]
	@patientid INT
	,@VisitType INT
	,@password VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @VisitID INT
	DECLARE @locationid INT
	DECLARE @RegDate DATETIME
	DECLARE @UserID INT
	DECLARE @SymKey VARCHAR(400)

	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @password + ''

	EXEC (@SymKey)
        
	SELECT convert(VARCHAR(50), decryptbykey(a.FirstName)) AS [FirstName]
		,convert(VARCHAR(50), decryptbykey(a.MiddleName)) AS [MiddleName]
		,convert(VARCHAR(50), decryptbykey(a.LastName)) AS [LastName]
		,a.STATUS [Status]
		,a.RegistrationDate [RegDate]
		,e.NAME [Sex]
		,Convert(VARCHAR, a.DOB, 106) [DOB]
		,a.Sex [RegSex]
		,a.DOB [RegDOB]
		,Convert(VARCHAR, datediff(month, a.DOB, getdate()) / 12) [Age]
		,Convert(VARCHAR, datediff(month, a.DOB, getdate()) % 12) [Age1]
		,convert(VARCHAR(50), decryptbykey(a.Address)) AS [Address]
		,convert(VARCHAR(50), decryptbykey(a.Phone)) AS [Phone]
		,a.*
		,datediff(yy, a.dob, getdate()) [AGE]
		,datediff(month, a.dob, getdate()) [AgeInMonths]
		,Isnull(a.PatientType,0) as PatientTypeId
	FROM mst_patient a
	LEFT OUTER JOIN mst_decode e
		ON a.sex = e.Id
	WHERE a.ptn_pk = @patientid

	--1                                                                                      
	SELECT ptn_pk
		,LocationID
		,convert(VARCHAR(50), EmergContactName) [EmergContactName]
		,EmergContactRelation
		,convert(VARCHAR(50), EmergContactPhone) [EmergContactPhone]
		,convert(VARCHAR(50), EmergContactAddress) [EmergContactAddress]
		,NextofKinName
		,NextofKinRelationship
		,NextofKinTelNo
		,NextofAddress
	FROM dtl_patientContacts
	WHERE ptn_pk = @patientid

	--2                    
	SELECT DataQuality
		,VisitDate
	FROM ord_visit
	WHERE visitType = @VisitType
		AND Ptn_pk = @patientid

	--3                
	SELECT Startdate
	FROM lnk_patientprogramstart
	WHERE ptn_pk = @patientid
		AND moduleID = 2

	--4          
	IF (
			NOT EXISTS (
				SELECT ptn_pk
				FROM ord_visit
				WHERE ptn_pk = @PatientID
					AND Visittype = 12
				)
			)
	BEGIN
		SELECT @locationid = LocationId
			,@RegDate = RegistrationDate
			,@UserID = UserId
		FROM mst_patient
		WHERE Ptn_pk = @patientid

		INSERT INTO dbo.ord_Visit (
			Ptn_Pk
			,LocationID
			,VisitDate
			,VisitType
			,DataQuality
			,UserID
			,CreateDate
			)
		VALUES (
			@PatientID
			,@locationid
			,@RegDate
			,12
			,'0'
			,@UserID
			,getdate()
			)
	END

	SELECT @VisitID = Visit_ID
	FROM ord_Visit a
	WHERE a.ptn_pk = @patientid
		AND Visittype = 12

	SELECT @VisitID [VisitID]

	--Table5-Prev HIV Records                
	SELECT PrevHIVCare
		,PrevMedRecords
		,PrevCareHomeBased
		,PrevCareVCT
		,PrevCarePMTCT
		,PrevCareInPatient
		,PrevCareOther
		,PrevCareOtherSpecify
		,PrevART
		,PrevARTSSelfFinanced
		,PrevARTSGovtSponsored
		,PrevARTSUSGSponsered
		,PrevARTSMissionBased
		,PrevARTSThisFacility
		,PrevARTSOthers
		,PrevARTSOtherSpecs
		,UserID
		,UpdateDate
	FROM dbo.dtl_PatientHivPrevCareEnrollment
	WHERE Ptn_Pk = @PatientID
		AND Visit_pk = @VisitID

	--Table6-PatientHouseHoldInfo                  
	SELECT EmploymentStatus
		,Occupation
		,MonthlyIncome
		,NumChildren
		,NumPeopleHousehold
		,DistanceTravelled
		,TimeTravelled
		,TravelledUnits
	FROM dtl_PatientHouseHoldInfo
	WHERE Ptn_Pk = @PatientID

	--Table-7-PatientHivOther                 
	SELECT HIVStatus
		,HIVStatus_Child
		,HIVDisclosure
		,HIVDisclosureOther
		,NumHouseholdHIVTest
		,NumHouseholdHIVPositive
		,NumHouseholdHIVDied
		,SupportGroup
		,SupportGroupName
		,ReferredFromVCT
		,ReferredFromOutpatient
		,ReferredFromOtherSource
		,ReferredFromPMTCT
		,ReferredFromTBOutpatient
		,ReferredFromInPatientWard
		,ReferredFromOtherFacility
	FROM dtl_PatientHivOther
	WHERE Ptn_Pk = @PatientID
		AND Visit_pk = @VisitID

	--Table-8-PatientDisclosure                
	SELECT DisclosureID
		,DisclosureOther
	FROM dtl_patientdisclosure
	WHERE Ptn_Pk = @PatientID
		AND Visit_pk = @VisitID

	CLOSE symmetric KEY Key_CTC
END
go
--==

create nonclustered index ix__lnk_PatientProgramStart__ModuleId on Lnk_PatientProgramStart (ModuleId) include(StartDate)
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Pharmacy_GetLastRegimensDispensed] @Ptn_Pk INT
AS
BEGIN
	DECLARE @LastRegimenDispensed VARCHAR(100) = NULL;
	DECLARE @PrevRegimenDispensed VARCHAR(100) = NULL;
	DECLARE @ChangeRegimenDate VARCHAR(20) = NULL;

	SELECT a.Ptn_Pk
		,b.RegimenName
		,c.NAME
		,convert(varchar, min(a.OrderedByDate), 106) as RegimenDate
		,ROW_NUMBER() over(partition by a.Ptn_Pk order by min(a.OrderedByDate) desc) regNo
	INTO #tableRegimen
	FROM ord_PatientPharmacyOrder a
	INNER JOIN mst_Regimen b ON a.RegimenId = b.RegimenID
	INNER JOIN mst_RegimenLine c ON b.RegimenLineID = c.ID
	WHERE a.Ptn_Pk = @Ptn_Pk and isnull(a.DeleteFlag,0) = 0 
	group by a.Ptn_Pk, b.RegimenName, c.NAME


	--table 0     
	SELECT TOP 1 ptn_pharmacy_pk FROM ord_PatientPharmacyOrder WHERE Ptn_pk = @Ptn_Pk
	AND isnull(DeleteFlag,0) = 0 ORDER BY OrderedByDate DESC

	--table 1
	set @LastRegimenDispensed = (SELECT top 1 RegimenName+' - ' + NAME from #tableRegimen where regNo=1)
	select @LastRegimenDispensed

	--table 2
	set @PrevRegimenDispensed = (SELECT top 1 RegimenName+' - ' + NAME from #tableRegimen where regNo=2)
	select @PrevRegimenDispensed

	--table 3
	if exists(SELECT top 1 * from #tableRegimen where regNo=2)
		set @ChangeRegimenDate = (SELECT top 1 RegimenDate from #tableRegimen where regNo=1)
	select @ChangeRegimenDate

	DROP TABLE #tableRegimen;
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[pr_Pharmacy_GetPatientDrugHistory] @Ptn_Pk INT
AS
BEGIN
	--table 0     
	SELECT DISTINCT mst.DrugName [Drug]
		,cast(CONVERT(VARCHAR(11), ord.DispensedByDate, 106) AS DATETIME) [Date]
	FROM dtl_PatientPharmacyOrder dtl
	INNER JOIN mst_Drug mst ON dtl.Drug_Pk = mst.Drug_pk
	INNER JOIN ord_PatientPharmacyOrder ord ON ord.ptn_pharmacy_pk = dtl.ptn_pharmacy_pk
	WHERE ord.Ptn_pk = @Ptn_Pk
		AND ord.DispensedByDate IS NOT NULL
		AND mst.DrugType = 37
	ORDER BY cast(CONVERT(VARCHAR(11), ord.DispensedByDate, 106) AS DATETIME) DESC
		,mst.DrugName
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
ALTER PROCEDURE [dbo].[pr_Clinical_ExtruderVitals] (
	@Ptn_pk INT
	,@DBKey VARCHAR(50)
	)
AS
BEGIN
	DECLARE @SymKey VARCHAR(400)

	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @DBKey + ''

	EXEC (@SymKey)

	--0
	SELECT d.NAME [sex]
		,CONVERT(VARCHAR(11), m.dob, 106) [dob]
		,md.NAME [districtname]
		,convert(VARCHAR(50), decryptbykey(Phone)) [phone]
		,m.PatientIPNo
		,datediff(yy, m.dob, getdate()) [age]
		,CONVERT(VARCHAR(11), m.ARTStartDate, 106) [ArtStartDate]
	FROM mst_patient m
	LEFT JOIN mst_District md
		ON md.ID = m.DistrictName
	LEFT JOIN mst_decode d
		ON m.sex = d.id
	WHERE ptn_pk = @Ptn_pk

	--1
	SELECT TestResults
		,CONVERT(VARCHAR(11), VisitDate, 106) [Date]
	FROM VW_PatientLaboratory
	WHERE TestName = 'cd4'
		AND ptn_pk = @Ptn_pk
		AND TestResults = (
			SELECT max(TestResults)
			FROM VW_PatientLaboratory
			WHERE TestName = 'cd4'
				AND ptn_pk = @Ptn_pk
			)

	--2
	SELECT TestResults
		,CONVERT(VARCHAR(11), VisitDate, 106) [Date]
	FROM VW_PatientLaboratory
	WHERE TestName = 'cd4'
		AND ptn_pk = @Ptn_pk
		AND TestResults = (
			SELECT min(TestResults)
			FROM VW_PatientLaboratory
			WHERE TestName = 'cd4'
				AND ptn_pk = @Ptn_pk
			)

	--3
	SELECT TOP 3 TestResults [Results]
		,CONVERT(VARCHAR(11), VisitDate, 106) [Date]
	FROM VW_PatientLaboratory
	WHERE TestName = 'cd4'
		AND ptn_pk = @Ptn_pk
	ORDER BY VisitDate DESC

	--4
	SELECT TestResults
		,CONVERT(VARCHAR(11), VisitDate, 106) [Date]
	FROM VW_PatientLaboratory
	WHERE TestName = 'Viral Load'
		AND ptn_pk = @Ptn_pk
		AND TestResults = (
			SELECT max(TestResults)
			FROM VW_PatientLaboratory
			WHERE TestName = 'Viral Load'
				AND ptn_pk = @Ptn_pk
			)

	--5
	SELECT TestResults
		,CONVERT(VARCHAR(11), VisitDate, 106) [Date]
	FROM VW_PatientLaboratory
	WHERE TestName = 'Viral Load'
		AND ptn_pk = @Ptn_pk
		AND TestResults = (
			SELECT min(TestResults)
			FROM VW_PatientLaboratory
			WHERE TestName = 'Viral Load'
				AND ptn_pk = @Ptn_pk
			)

	--6
	SELECT TOP 3 CASE 
			WHEN TESTRESULTID = '9998'
				THEN 'Undetectable'
			ELSE Convert(VARCHAR, TestResults)
			END [Results]
		,CONVERT(VARCHAR(11), VisitDate, 106) [Date]
	FROM VW_PatientLaboratory
	WHERE TestName = 'Viral Load'
		AND ptn_pk = @Ptn_pk
	ORDER BY VisitDate DESC

	--7
	SELECT DISTINCT testname [Name]
		,CASE 
			WHEN testname IN (
					'GeneXpert'
					,'Sputum AFB1'
					,'Sputum AFB2'
					,'Sputum AFB3'
					)
				THEN gene.GeneXpertText
			WHEN testname = 'ARV Mutations'
				THEN mstL.ITEM_NAME + ' - ' + mstLL.ITEM_NAME
			WHEN vw.testresultid > 0
				AND vw.TestResultId < 9997
				THEN convert(VARCHAR(50), lnk.Result)
			WHEN vw.TestResultId = 9998
				THEN 'Undetectable'
			WHEN vw.TestResultId = 9999
				THEN convert(VARCHAR(50), vw.TestResults)
			WHEN vw.TestResults1 IS NOT NULL
				AND vw.TestResults1 <> ''
				THEN vw.TestResults1
			ELSE convert(VARCHAR(50), vw.TestResults)
			END [Results]
		,CONVERT(VARCHAR(11), OrderedbyDate, 106) [Order by date]
		,CONVERT(VARCHAR(11), ReportedbyDate, 106) [Reported by date]
	FROM VW_PatientLaboratory vw
	LEFT JOIN dtl_GenXpert gene
		ON vw.LabID = gene.LabOrderID
			AND vw.TestID = gene.ParameterID
	LEFT JOIN Dtl_ArvMutations arvM
		ON vw.LabID = arvM.LabOrderID
	LEFT JOIN mst_lov mstL
		ON arvM.arvtypeid = mstL.ID
	LEFT JOIN mst_Lov_lines mstLL
		ON arvM.MutationID = mstLL.ID
	LEFT JOIN lnk_parameterresult lnk
		ON vw.TestResultId = lnk.ResultID
	WHERE ptn_pk = @Ptn_pk
		AND (
			ISNULL(vw.TestResults, 0) > 0
			OR len(ISNULL(lnk.Result, '')) > 0
			)
		AND VisitDate = (
			SELECT max(VisitDate)
			FROM VW_PatientLaboratory
			WHERE ptn_pk = @Ptn_pk --2862--
			)

	--8
	SELECT TOP 1 CAST(ROUND(Weight / ((height / 100) * (height / 100)), 2) AS NUMERIC(36, 2)) [BMI]
	FROM dtl_PatientVitals dtl
	INNER JOIN ord_Visit ord
		ON dtl.Visit_pk = ord.Visit_Id
	WHERE dtl.Ptn_pk = @Ptn_pk
		AND dtl.Height <> 0
		AND dtl.Height IS NOT NULL
		AND dtl.Weight <> 0
		AND dtl.Weight IS NOT NULL
	ORDER BY ord.VisitDate DESC

	--9 work plan
	SELECT *
	FROM (
		SELECT [Plan]
			,ord.VisitDate
		FROM dtl_KNH_ExpressForm_details dtl
		INNER JOIN ord_Visit ord
			ON ord.Visit_Id = dtl.Visit_pk
		WHERE dtl.Ptn_pk = @Ptn_pk
			AND dtl.[Plan] IS NOT NULL
			AND dtl.[Plan] <> ''
		
		UNION
		
		SELECT WorkUpPlan [Plan]
			,ord.VisitDate
		FROM DTL_KNH_RevisedAdultFollowup_Form dtl
		INNER JOIN ord_Visit ord
			ON ord.Visit_Id = dtl.Visit_pk
		WHERE dtl.Ptn_pk = @Ptn_pk
			AND dtl.WorkUpPlan IS NOT NULL
			AND dtl.WorkUpPlan <> ''
		
		UNION
		
		SELECT WorkUpPlan [Plan]
			,ord.VisitDate
		FROM DTL_Paediatric_Initial_Evaluation_Form dtl
		INNER JOIN ord_Visit ord
			ON ord.Visit_Id = dtl.Visit_pk
		WHERE dtl.Ptn_pk = @Ptn_pk
			AND dtl.WorkUpPlan IS NOT NULL
			AND dtl.WorkUpPlan <> ''
		
		UNION
		
		SELECT WorkUpPlan [Plan]
			,ord.VisitDate
		FROM DTL_Adult_Initial_Evaluation_Form dtl
		INNER JOIN ord_Visit ord
			ON ord.Visit_Id = dtl.Visit_pk
		WHERE dtl.Ptn_pk = @Ptn_pk
			AND dtl.WorkUpPlan IS NOT NULL
			AND dtl.WorkUpPlan <> ''
		) tblPlan
	ORDER BY tblPlan.VisitDate DESC

	--10
	SELECT TOP 1 sts.LMP
		,sts.EDD
		,del.GestAge
		,deRegiment.NAME PMTCTregimen
		,isnull(deHIVPartner.NAME, '') FinalHIVResultPartner
		,ord.Visit_Id
		,ord.VisitDate
		--,stg.WHOStage
		,deWHOStage.NAME WhoStage
		,deMatBG.NAME MartenalBloodGroup
		,dtl.RhesusFactor
	FROM dtl_KNHPMTCTMEI dtl
	JOIN (
		SELECT TOP 1 max(visit_id) Visit_Id
			,VisitDate
		FROM ord_visit
		WHERE Ptn_Pk = @Ptn_pk
		GROUP BY visitDate
		ORDER BY VisitDate DESC
		) ord
		ON dtl.Visit_pk = ord.Visit_Id
	JOIN dtl_PatientClinicalStatus sts
		ON sts.Visit_pk = ord.Visit_Id
	JOIN dtl_PatientDelivery del
		ON del.Visit_pk = ord.Visit_Id
	JOIN dtl_PatientStage stg
		ON stg.Visit_pk = ord.Visit_Id
	LEFT JOIN mst_Decode deWHOStage
		ON deWHOStage.ID = stg.WHOStage
	LEFT JOIN mst_PMTCTDecode deRegiment
		ON deRegiment.ID = dtl.PMTCTregimen
	LEFT JOIN mst_PMTCTDecode deHIVPartner
		ON deHIVPartner.ID = dtl.FinalHIVResultPartner
	LEFT JOIN mst_pmtctDeCode deMatBG
		ON deMatBG.ID = dtl.MartenalBloodGroup
	WHERE dtl.Ptn_pk = @Ptn_pk
	ORDER BY ord.VisitDate DESC

	--11
	SELECT [ChildReferredFrom]
		,POD.NAME AS DeliveryPlaceHEI
		,MD.[Name] AS ModeofDeliveryHEI
		,CPA.NAME AS ChildPEPARVs
		,ANC.NAME AS ANCFollowup
		,SOM.NAME AS StateOfMother
		,[OnART]
		,BirthWeight
		,FeedingOption
		,[MotherReferredtoARV]
	FROM dtl_KNHPMTCTHEI dtl
	JOIN (
		SELECT TOP 1 max(visit_id) Visit_Id
			,VisitDate
		FROM ord_visit
		WHERE Ptn_Pk = @Ptn_pk
		GROUP BY visitDate
		ORDER BY VisitDate DESC
		) ord
		ON dtl.Visit_pk = ord.Visit_Id
	JOIN dtl_InfantInfo infnt
		ON infnt.Visit_pk = ord.Visit_Id
	LEFT JOIN Mst_ModDecode POD
		ON POD.id = dtl.DeliveryPlaceHEI
	LEFT JOIN Mst_ModDecode MD
		ON MD.id = dtl.ModeofDeliveryHEI
	LEFT JOIN Mst_ModDecode CPA
		ON CPA.id = dtl.[ChildPEPARVs]
	LEFT JOIN Mst_ModDecode ANC
		ON ANC.id = dtl.[ANCFollowup]
	LEFT JOIN Mst_ModDecode SOM
		ON SOM.id = dtl.[StateOfMother]
	WHERE dtl.Ptn_Pk = @Ptn_pk
	ORDER BY ord.VisitDate DESC;

	--12. TB treatment
	SELECT TOP 1 CASE 
			WHEN TBRegimenStartDate IS NOT NULL
				THEN 'Yes'
			END AS OnTBtreatment
		,TBRegimenStartDate
		,TBRegimenEndDate
	FROM mst_Patient p
	LEFT JOIN (
		SELECT ptn_pk
			,TBRegimenStartDate
			,DATEADD(mm, 6, TBRegimenStartDate) AS TBRegimenEndDate
		FROM dtl_TBScreening
		WHERE TBRegimenStartDate > cast('1900-01-01' AS DATETIME)
		
		UNION
		
		SELECT ptn_pk
			,TBRxStartDate
			,TBRxEnddate
		FROM dtl_patientothertreatment
		WHERE TBRxStartDate > cast('1900-01-01' AS DATETIME)
		) a
		ON p.Ptn_Pk = a.Ptn_pk
			AND DATEADD(mm, 6, a.TBRegimenStartDate) >= GETDATE()
	WHERE p.Ptn_pk = @ptn_pk
	ORDER BY TBRegimenStartDate DESC

	--13. INH
	SELECT INHStartDate
		,INHStopDate
		,INHEndDate
		,[IPT]
		,b.NAME [IPTName]
	FROM mst_Patient p
	LEFT JOIN dtl_TBScreening a ON p.Ptn_Pk = a.Ptn_pk
			AND DATEADD(mm, 6, a.INHStartDate) >= GETDATE()
	LEFT JOIN mst_decode b
		ON a.IPT = b.ID
	WHERE p.Ptn_pk = @ptn_pk
	and EligibleForIPT=1
	ORDER BY INHStartDate DESC

	--14
	SELECT SOM.NAME AS StateOfMother
		,[OnART]
		,ANC.NAME AS ANCFollowup
		,BirthWeight
		,FeedingOption
		,CASE 
			WHEN MotherReferredtoARV = 1
				THEN 'YES'
			WHEN MotherReferredtoARV = 0
				THEN 'NO'
			WHEN MotherReferredtoARV = 2
				THEN 'NOT KNOWN'
			ELSE NULL
			END [MotherReferredtoARV]
	FROM dtl_KNHPMTCTHEI dtl
	JOIN (
		SELECT TOP 1 max(visit_id) Visit_Id
			,VisitDate
		FROM ord_visit
		WHERE Ptn_Pk = @Ptn_pk
		GROUP BY visitDate
		ORDER BY VisitDate DESC
		) ord
		ON dtl.Visit_pk = ord.Visit_Id
	JOIN dtl_InfantInfo infnt
		ON infnt.Visit_pk = ord.Visit_Id
	LEFT JOIN Mst_ModDecode ANC
		ON ANC.id = dtl.[ANCFollowup]
	LEFT JOIN Mst_ModDecode SOM
		ON SOM.id = dtl.[StateOfMother]
	WHERE dtl.Ptn_Pk = @Ptn_pk
	ORDER BY ord.VisitDate DESC;

	--15 Add this table for display Milestones data on slider(Rahmat 09-Jan-2017)
	SELECT TypeOftest [Duration]
		,Result [Status]
		,Comments
	FROM dtl_KNHPMTCTHEI_GridData dltgd
	JOIN (
		SELECT TOP 1 max(visit_id) Visit_Id
			,VisitDate
		FROM ord_visit
		WHERE Ptn_Pk = @Ptn_pk
		GROUP BY visitDate
		ORDER BY VisitDate DESC
		) ord
		ON dltgd.Visit_pk = ord.Visit_Id
	WHERE dltgd.Section = 'Milestone'
	ORDER BY 1 DESC;

	--16 Add this table for PatientClassification
	SELECT top 1 
		a.PatientClassification
		,d.Name As PatientClassificationName
		,ISNULL(a.IsEnrolDifferenciatedCare,0) as IsEnrolDifferenciatedCare
		,a.ARTRefillModel
	FROM vw_patientpharmacy a
	Inner join mst_Decode d on a.PatientClassification = d.ID
	WHERE codeid = (
			SELECT CodeId
			FROM mst_code
			WHERE NAME = 'Patient Classification'
			)
		AND (
			DeleteFlag = 0
			OR DeleteFlag IS NULL
			)
	and Ptn_Pk = @Ptn_pk
	and a.PatientClassification IS NOT NULL
			AND a.PatientClassification <> ''
	ORDER BY VisitDate DESC;
END
go
--==

if exists(select * from sysobjects where name='pr_Clinical_GetClinicalEncounterVisitID' and type='p')
	drop proc pr_Clinical_GetClinicalEncounterVisitID
go

create proc pr_Clinical_GetClinicalEncounterVisitID @ptn_pk int
as
begin
	select top 1 Visit_Id from ord_Visit where Ptn_Pk=@ptn_pk and cast(convert(varchar, VisitDate, 106) as datetime) = cast(convert(varchar, getdate(), 106) as datetime)
	and VisitType=(select top 1 x.VisitTypeID from mst_VisitType x where VisitName ='clinical encounter')
	and isnull(DeleteFlag, 0)= 0
end
go
--==

if exists(select * from sysobjects where name='pr_SaveMotherToChildLinkage' and type='P')
	drop proc pr_SaveMotherToChildLinkage
go

create proc [dbo].[pr_SaveMotherToChildLinkage] @ptn_pk int, @MotherId varchar(20)

as 

insert into dtl_familyinfo
select @ptn_pk, b.firstname, b.lastname, b.sex, datediff(yy, b.dob, getdate()), null, getdate(), 10 ,37,1, null, null,b.ptn_pk,1,0,getdate(),null
from mst_patient b where b.PatientIPNo=@MotherId or b.PatientEnrollmentID=@MotherId
go
--==

USE [IQCare]
GO
/****** Object:  StoredProcedure [dbo].[pr_SaveMotherToChildLinkage]    Script Date: 5/30/2019 9:25:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[pr_SaveMotherToChildLinkage] @ptn_pk int, @MotherId varchar(20)

as 

begin
	if not exists(select * from dtl_FamilyInfo a where a.Ptn_pk=@ptn_pk and a.ReferenceId=(select top 1 x.Ptn_pk from mst_Patient x where coalesce(x.PatientIPNo,x.patientenrollmentid)=@MotherId))
	begin
		insert into dtl_familyinfo(Ptn_pk, RFirstName,RLastName,sex,AgeYear,AgeMonth,RelationshipDate,RelationshipType,HivStatus,
		HivCareStatus,RegistrationNo,FileNo,ReferenceId,UserId,DeleteFlag,CreateDate,UpdateDate,LastHIVTestDate)
		select @ptn_pk, b.firstname, b.lastname, b.sex, datediff(yy, b.dob, getdate()), null, getdate(), 10 ,37,1, null, null,b.ptn_pk,1,0,getdate(),null,null
		from mst_patient b where coalesce(b.PatientIPNo,b.patientenrollmentid)=@MotherId
	end
end
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Clinical_SaveUpdateKNHHEI_Futures]
	-- Add the parameters for the stored procedure here                                                                  
	@patientid INT = NULL
	,@locationid INT = NULL
	,@Visit_ID INT = NULL
	,@KNHHEIVisitDate VARCHAR(11) = NULL
	,@KNHHEIVisitType INT = NULL
	--vital sign.....
	,@KNHHEITemp DECIMAL(18, 1) = NULL
	,@KNHHEIRR DECIMAL(18, 1) = NULL
	,@KNHHEIHR DECIMAL(18, 1) = NULL
	,@KNHHEIHeight DECIMAL(18, 1) = NULL
	,@KNHHEIWeight DECIMAL(18, 1) = NULL
	,@KNHHEIBPSystolic DECIMAL(18, 1) = NULL
	,@KNHHEIBPDiastolic DECIMAL(18, 1) = NULL
	,@KNHHEIHeadCircum DECIMAL(18, 1) = NULL
	,@KNHHEIWA DECIMAL(18, 1) = NULL
	,@KNHHEIWH DECIMAL(18, 1) = NULL
	,@KNHHEIBMIz DECIMAL(18, 1) = NULL
	,@KNHHEINurseComments VARCHAR(200) = NULL
	,@KNHHEIReferToSpecialClinic VARCHAR(200) = NULL
	,@KNHHEIReferToOther VARCHAR(200) = NULL
	--neonatl history
	,@KNHHEISrRefral VARCHAR(200) = NULL
	,@KNHHEIPlDelivery INT = NULL
	,@KNHHEIPlDeliveryotherfacility VARCHAR(300) = NULL
	,@KNHHEIPlDeliveryother VARCHAR(300) = NULL
	,@KNHHEIMdDelivery INT = NULL
	,@KNHHEIBWeight DECIMAL(5,2) = NULL
	,@KNHHEIARVProp INT = NULL
	,@KNHHEIARVPropOther VARCHAR(300) = NULL
	,@KNHHEIIFeedoption INT = NULL
	,@KNHHEIIFeedoptionother VARCHAR(300) = NULL
	--maternal history
	,@KNHHEIStateofMother INT = NULL
	,@KNHHEIMRegisthisclinic INT = NULL
	,@KNHHEIPlMFollowup INT = NULL
	,@KNHHEIPlMFollowupother VARCHAR(300) = NULL
	,@KNHHEIMRecievedDrug INT = NULL
	,@KNHHEIOnARTEnrol INT = NULL
	/* Immunization, now saving to grid.....
	,@KNHHEIDateImmunised VARCHAR(200) = NULL
	,@KNHHEIPeriodImmunised INT = NULL
	,@KNHHEIGivenImmunised INT = NULL
	*/
	-- presenting complaints 
	,@KNHHEIAdditionalComplaint VARCHAR(200) = NULL
	
	-- Examination
	,@KNHHEIExamination VARCHAR(200) = NULL
	/*-- Milestone, now saving to grid.....
	,@KNHHEIMilestones INT = NULL
	--,@KNHHEIAssessmmentOutcome INT = NULL
	,@KNHHEIPlan INT = NULL
	,@KNHHEIPlanRegimen INT = NULL
	*/
	-- management plan
	,@KNHHEIVitamgiven INT = NULL
	,@KNHHEIWorkPlan varchar(max) = null
	--Referral, Admission and Appointment
	,@KNHHEIReferredto INT = NULL
	,@KNHHEIReferredtoother VARCHAR(300) = NULL
	,@KNHHEIAdmittoward INT = NULL
	,@KNHHEITCA INT = NULL
	,@dataquality INT = NULL
	,@UserId INT = NULL
	--,@Signature INT = NULL
	,@Scheduled smallint=NULL
	,@DurationARTstart INT=NULL
	,@ReferredFrom INT=NULL
	,@ReferredFromOther nvarchar(100)=NULL
	,@SPO2 INT=NULL
	,@AnyComplaints bit=NULL
	,@GeneralExamination int=NULL
	,@NeonatalHistoryNotes nvarchar(1000)=NULL
	,@TBFindings int=NULL
	,@MUAC int=NULL
	,@ReviewSystemComments nvarchar(1000)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from                                                                    
	-- interfering with SELECT statements.                                              
	SET NOCOUNT ON;

	DECLARE @Visit_Pk INT

	IF (@Visit_ID > 0)
	BEGIN
		UPDATE ord_visit
		SET TypeofVisit = @KNHHEIVisitType
			,DataQuality = 1
			,UpdateDate = getdate()
		WHERE visit_Id = @Visit_ID
			AND ptn_pk = @patientid
			AND locationId = @locationid

		IF EXISTS (
				SELECT *
				FROM dtl_KNHPMTCTHEI
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @patientid
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_KNHPMTCTHEI
			SET
				---[TBAssessment] = @KNHHEIAssessmmentOutcome
				---,[Plan] = @KNHHEIPlan
				---,[PlanRegimen] = @KNHHEIPlanRegimen
				[ChildReferredFrom] = @KNHHEISrRefral
				,[DeliveryPlaceHEI] = @KNHHEIPlDelivery
				,[Deliveryotherfacility] = @KNHHEIPlDeliveryotherfacility
				,[Deliveryother] = @KNHHEIPlDeliveryother
				,[ModeofDeliveryHEI] = @KNHHEIMdDelivery
				,[ChildPEPARVs] = @KNHHEIARVProp
				,[ARVPropOther] = @KNHHEIARVPropOther
				,[MotherRegisteredClinic] = @KNHHEIMRegisthisclinic
				,[ANCFollowup] = @KNHHEIPlMFollowup
				,[PlMFollowupother] = @KNHHEIPlMFollowupother
				,[MotherReferredtoARV] = @KNHHEIMRecievedDrug
				,[StateOfMother] = @KNHHEIStateofMother
				,[OnART] = @KNHHEIOnARTEnrol
				---,[ImmunisationDate] = @KNHHEIDateImmunised
				---,[ImmunisationPeriod] = @KNHHEIPeriodImmunised
				--,[ImmunisationGiven] = @KNHHEIGivenImmunised
				,[AdditionalComplaint] = @KNHHEIAdditionalComplaint
				,[Examinations] = @KNHHEIExamination
				---,[MilestonesPeads] = @KNHHEIMilestones
				,[VitaminA] = @KNHHEIVitamgiven
				,[WorkPlan]= @KNHHEIWorkPlan
				,[ReferralPeads] = @KNHHEIReferredto
				,[Referredtoother] = @KNHHEIReferredtoother
				,[WardAdmissionPead] = @KNHHEIAdmittoward
				,[TCA] = @KNHHEITCA
				,[DeleteFlag] = 0
				,[UserID] = @UserId
				,[UpdateDate] = getdate()
				,[Scheduled]=@Scheduled
				,[DurationARTstart]=@DurationARTstart
				,[ReferredFrom]=@ReferredFrom
				,[ReferredFromOther]=@ReferredFromOther
				,[SPO2]=@SPO2
				,[AnyComplaints]=@AnyComplaints
				,[GeneralExamination]=@GeneralExamination
				,[NeonatalHistoryNotes]=@NeonatalHistoryNotes
				,[TBFindings]=@TBFindings
				,[MUAC]=@MUAC
				,[ReviewSystemComments]=@ReviewSystemComments
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @patientid
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[dtl_KNHPMTCTHEI] (
				[Ptn_pk]
				,[LocationID]
				,[Visit_pk]
				--,[TBAssessment]
				--,[Plan]
				--,[PlanRegimen]
				,[ChildReferredFrom]
				,[DeliveryPlaceHEI]
				,[Deliveryotherfacility]
				,[Deliveryother]
				,[ModeofDeliveryHEI]
				,[ChildPEPARVs]
				,[ARVPropOther]
				,[MotherRegisteredClinic]
				,[ANCFollowup]
				,[PlMFollowupother]
				,[MotherReferredtoARV]
				,[StateOfMother]
				,[OnART]
				--,[ImmunisationDate]
				--,[ImmunisationPeriod]
				--,[ImmunisationGiven]
				,[AdditionalComplaint]
				,[Examinations]
				--,[MilestonesPeads]
				,[VitaminA]
				,[WorkPlan]
				,[ReferralPeads]
				,[Referredtoother]
				,[WardAdmissionPead]
				,[TCA]
				,[DeleteFlag]
				,[UserID]
				,[CreateDate]
				,[Scheduled]
				,[DurationARTstart]
				,[ReferredFrom]
				,[ReferredFromOther]
				,[SPO2]
				,[AnyComplaints]
				,[GeneralExamination]
				,[NeonatalHistoryNotes]
				,[TBFindings]
				,[MUAC]
				,[ReviewSystemComments]
				)
			VALUES (
				@patientid
				,@locationid
				,@Visit_ID
				--,@KNHHEIAssessmmentOutcome
				--,@KNHHEIPlan
				--,@KNHHEIPlanRegimen
				,@KNHHEISrRefral
				,@KNHHEIPlDelivery
				,@KNHHEIPlDeliveryotherfacility
				,@KNHHEIPlDeliveryother
				,@KNHHEIMdDelivery
				,@KNHHEIARVProp
				,@KNHHEIARVPropOther
				,@KNHHEIMRegisthisclinic
				,@KNHHEIPlMFollowup
				,@KNHHEIPlMFollowupother
				,@KNHHEIMRecievedDrug
				,@KNHHEIStateofMother
				,@KNHHEIOnARTEnrol
				--,@KNHHEIDateImmunised
				--,@KNHHEIPeriodImmunised
				--,@KNHHEIGivenImmunised
				,@KNHHEIAdditionalComplaint
				,@KNHHEIExamination
				--,@KNHHEIMilestones
				,@KNHHEIVitamgiven
				,@KNHHEIWorkPlan
				,@KNHHEIReferredto
				,@KNHHEIReferredtoother
				,@KNHHEIAdmittoward
				,@KNHHEITCA
				,0
				,@UserId
				,getdate()
				,@Scheduled
				,@DurationARTstart
				,@ReferredFrom
				,@ReferredFromOther
				,@SPO2
				,@AnyComplaints
				,@GeneralExamination
				,@NeonatalHistoryNotes
				,@TBFindings
				,@MUAC
				,@ReviewSystemComments
				)
		END

		IF EXISTS (
				SELECT *
				FROM dtl_PatientVitals
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @patientid
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_PatientVitals
			SET TEMP = Nullif(@KNHHEITemp, '999')
				,RR = Nullif(@KNHHEIRR, '999')
				,HR = Nullif(@KNHHEIHR, '999')
				,Height = Nullif(@KNHHEIHeight, '999')
				,Weight = Nullif(@KNHHEIWeight, '999')
				,BPDiastolic = Nullif(@KNHHEIBPDiastolic, '999')
				,BPSystolic = Nullif(@KNHHEIBPSystolic, '999')
				,Headcircumference = Nullif(@KNHHEIHeadCircum, '999')
				,WeightForAge = Nullif(@KNHHEIWA, '999')
				,WeightForHeight = Nullif(@KNHHEIWH, '999')
				,BMIz = CAST(Nullif(@KNHHEIBMIz, '999') as int)
				,NurseComments = @KNHHEINurseComments
				,UserId = @UserId
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @patientid
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO dtl_PatientVitals (
				ptn_pk
				,Visit_Pk
				,locationId
				,TEMP
				,RR
				,HR
				,Height
				,Weight
				,BPDiastolic
				,BPSystolic
				,Headcircumference
				,WeightForAge
				,WeightForHeight
				,BMIz
				,NurseComments
				,UserId
				,CreateDate
				)
			VALUES (
				@patientid
				,IDENT_CURRENT('ORD_VISIT')
				,@locationid
				,Nullif(@KNHHEITemp, '999')
				,Nullif(@KNHHEIRR, '999')
				,Nullif(@KNHHEIHR, '999')
				,Nullif(@KNHHEIHeight, '999')
				,Nullif(@KNHHEIWeight, '999')
				,Nullif(@KNHHEIBPDiastolic, '999')
				,Nullif(@KNHHEIBPSystolic, '999')
				,Nullif(@KNHHEIHeadCircum, '999')
				,Nullif(@KNHHEIWA, '999')
				,Nullif(@KNHHEIWH, '999')
				,CAST(Nullif(@KNHHEIBMIz, '999') as int)
				,@KNHHEINurseComments
				,@UserId
				,getdate()
				)
		END

		IF EXISTS (
				SELECT *
				FROM dtl_InfantInfo
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @patientid
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_InfantInfo
			SET BirthWeight = Nullif(@KNHHEIBWeight, '999')
				,FeedingOption = @KNHHEIIFeedoption
				,FeedingoptionOther = @KNHHEIIFeedoptionother
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @patientid
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO dtl_InfantInfo (
				ptn_pk
				,Visit_Pk
				,locationId
				,BirthWeight
				,FeedingOption
				,FeedingoptionOther
				,UserId
				,CreateDate
				)
			VALUES (
				@patientid
				,IDENT_CURRENT('ORD_VISIT')
				,@locationid
				,Nullif(@KNHHEIBWeight, '999')
				,@KNHHEIIFeedoption
				,@KNHHEIIFeedoptionother
				,@UserId
				,getdate()
				)
		END

		DELETE
		FROM dtl_Multiselect_line
		WHERE Ptn_pk = @patientid
			AND Visit_Pk = @Visit_ID

		--DELETE
		--FROM dtl_KNHPMTCTNeonatalHistoryHEI
		--WHERE Ptn_pk = @patientid
		--	AND Visit_Pk = @Visit_ID
		--DELETE
		--FROM dtl_KNHPMTCTMaternalHistoryHEI
		--WHERE Ptn_pk = @patientid
		--	AND Visit_Pk = @Visit_ID
		DELETE
		FROM dtl_KNHPMTCTHEI_GridData
		WHERE Ptn_pk = @patientid
			AND Visit_Pk = @Visit_ID

		SELECT @Visit_ID [VisitId]
	END
	ELSE
	BEGIN
		INSERT INTO ord_Visit (
			Ptn_Pk
			,LocationID
			,VisitDate
			,VisitType
			,TypeofVisit
			,DataQuality
			,DeleteFlag
			,UserID
			,CreateDate
			)
		VALUES (
			@patientid
			,@locationid
			,@KNHHEIVisitDate
			,37
			,@KNHHEIVisitType
			,@dataquality
			,0
			,@UserId
			,getdate()
			)

		INSERT INTO [dbo].[dtl_KNHPMTCTHEI] (
			[Ptn_pk]
			,[LocationID]
			,[Visit_pk]
			--,[TBAssessment]
			--,[Plan]
			--,[PlanRegimen]
			,[ChildReferredFrom]
			,[DeliveryPlaceHEI]
			,[Deliveryotherfacility]
			,[Deliveryother]
			,[ModeofDeliveryHEI]
			,[ChildPEPARVs]
			,[ARVPropOther]
			,[MotherRegisteredClinic]
			,[ANCFollowup]
			,[PlMFollowupother]
			,[MotherReferredtoARV]
			,[StateOfMother]
			,[OnART]
			--,[ImmunisationDate]
			--,[ImmunisationPeriod]
			--,[ImmunisationGiven]
			,[AdditionalComplaint]
			,[Examinations]
			--,[MilestonesPeads]
			,[VitaminA]
			,[WorkPlan]
			,[ReferralPeads]
			,[Referredtoother]
			,[WardAdmissionPead]
			,[TCA]
			,[DeleteFlag]
			,[UserID]
			,[CreateDate]
			)
		VALUES (
			@patientid
			,@locationid
			,IDENT_CURRENT('ORD_VISIT')
			--,@KNHHEIAssessmmentOutcome
			--,@KNHHEIPlan
			--,@KNHHEIPlanRegimen
			,@KNHHEISrRefral
			,@KNHHEIPlDelivery
			,@KNHHEIPlDeliveryotherfacility
			,@KNHHEIPlDeliveryother
			,@KNHHEIMdDelivery
			,@KNHHEIARVProp
			,@KNHHEIARVPropOther
			,@KNHHEIMRegisthisclinic
			,@KNHHEIPlMFollowup
			,@KNHHEIPlMFollowupother
			,@KNHHEIMRecievedDrug
			,@KNHHEIStateofMother
			,@KNHHEIOnARTEnrol
			--,@KNHHEIDateImmunised
			--,@KNHHEIPeriodImmunised
			--,@KNHHEIGivenImmunised
			,@KNHHEIAdditionalComplaint
			,@KNHHEIExamination
			--,@KNHHEIMilestones
			,@KNHHEIVitamgiven
			,@KNHHEIWorkPlan
			,@KNHHEIReferredto
			,@KNHHEIReferredtoother
			,@KNHHEIAdmittoward
			,@KNHHEITCA
			,0
			,@UserId
			,getdate()
			)

		INSERT INTO dtl_PatientVitals (
			ptn_pk
			,Visit_Pk
			,locationId
			,TEMP
			,RR
			,HR
			,Height
			,Weight
			,BPDiastolic
			,BPSystolic
			,Headcircumference
			,WeightForAge
			,WeightForHeight
			,BMIz
			,NurseComments
			,UserId
			,CreateDate
			)
		VALUES (
			@patientid
			,IDENT_CURRENT('ORD_VISIT')
			,@locationid
			,Nullif(@KNHHEITemp, '999')
			,Nullif(@KNHHEIRR, '999')
			,Nullif(@KNHHEIHR, '999')
			,Nullif(@KNHHEIHeight, '999')
			,Nullif(@KNHHEIWeight, '999')
			,Nullif(@KNHHEIBPDiastolic, '999')
			,Nullif(@KNHHEIBPSystolic, '999')
			,Nullif(@KNHHEIHeadCircum, '999')
			,Nullif(@KNHHEIWA, '999')
			,Nullif(@KNHHEIWH, '999')
			,CAST(Nullif(@KNHHEIBMIz, '999') as int)
			,@KNHHEINurseComments
			,@UserId
			,getdate()
			)

		INSERT INTO dtl_InfantInfo (
			ptn_pk
			,Visit_Pk
			,locationId
			,BirthWeight
			,FeedingOption
			,FeedingoptionOther
			,UserId
			,CreateDate
			)
		VALUES (
			@patientid
			,IDENT_CURRENT('ORD_VISIT')
			,@locationid
			,Nullif(@KNHHEIBWeight, '999')
			,@KNHHEIIFeedoption
			,@KNHHEIIFeedoptionother
			,@UserId
			,getdate()
			)

		SELECT IDENT_CURRENT('ORD_VISIT') [VisitId]
	END
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_KNH_GetPMTCTHEIPatientData] @patientID INT
	,@VisitId INT
AS
/*
pr_KNH_GetPMTCTHEIPatientData 804,26941
*/
BEGIN
	--0                           
	SELECT Visit_Id
		,Ptn_Pk
		,LocationID
		,VisitDate
		,DataQuality
		,DeleteFlag
		,VisitType
		,Signature
		,TypeofVisit
	FROM ord_visit
	WHERE Ptn_Pk = @patientID
		AND Visit_Id = @VisitId

	--1
	SELECT [Ptn_pk]
		,[LocationID]
		,[Visit_pk]
		--,[TBAssessment]
		,[ChildReferredFrom]
		,[DeliveryPlaceHEI]
		,[Deliveryotherfacility]
		,[Deliveryother]
		,[ModeofDeliveryHEI]
		,[ChildPEPARVs]
		,[ARVPropOther]
		,[MotherRegisteredClinic]
		,isnull((select top 1 coalesce(y.PatientIPNo, y.patientenrollmentid) from dtl_FamilyInfo x 
			inner join mst_Patient y on x.ReferenceId=y.Ptn_Pk where x.Ptn_pk=@patientID and x.RelationshipType=10),'') as motherNo
		,[ANCFollowup]
		,[PlMFollowupother]
		,[MotherReferredtoARV]
		,[StateOfMother]
		,[OnART]
		--,[ImmunisationDate]
		--,[ImmunisationPeriod]
		--,[ImmunisationGiven]
		,[Examinations]
		--,[MilestonesPeads]
		--,[TBAssesment]
		--,[Plan]
		--,[PlanRegimen]
		,[VitaminA]
		,[WorkPlan]
		,[ReferralPeads]
		,[Referredtoother]
		,[WardAdmissionPead]
		,[TCA]
		,[AdditionalComplaint]
		,[DeleteFlag]
		,[UserID]
		,[CreateDate]
		,isnull([Scheduled],0)[Scheduled]
				,isnull([DurationARTstart],0)[DurationARTstart]
				,isnull([ReferredFrom],0)[ReferredFrom]
				,isnull([ReferredFromOther],0)[ReferredFromOther]
				,isnull([SPO2],0)[SPO2]
				,isnull([AnyComplaints],0)[AnyComplaints]
				,isnull([GeneralExamination],0)[GeneralExamination]
				,isnull([NeonatalHistoryNotes],'')[NeonatalHistoryNotes]
				,isnull([TBFindings],0)[TBFindings]
				,isnull([MUAC],0)MUAC
				,isnull([ReviewSystemComments],0)ReviewSystemComments
	FROM dtl_KNHPMTCTHEI
	WHERE Ptn_Pk = @patientID
		AND Visit_Pk = @VisitId

	--2
	SELECT ptn_pk
		,Visit_Pk
		,locationId
		,TEMP
		,RR
		,HR
		,Height
		,Weight
		,BPDiastolic
		,BPSystolic
		,Headcircumference
		,WeightForAge
		,WeightForHeight
		,BMIz
		,NurseComments
		,UserId
		,CreateDate
	FROM dtl_PatientVitals
	WHERE Ptn_Pk = @patientID
		AND Visit_Pk = @VisitId

	--3
	SELECT ptn_pk
		,Visit_Pk
		,locationId
		,BirthWeight
		,FeedingOption
		,FeedingoptionOther
		,UserId
		,CreateDate
	FROM dtl_InfantInfo
	WHERE Ptn_Pk = @patientID
		AND Visit_Pk = @VisitId

	--4
	SELECT *
	FROM dtl_Multiselect_line
	WHERE ptn_pk = @patientID
		AND Visit_Pk = @VisitId

	--5
	SELECT NN.[Ptn_pk]
		,NN.[LocationID]
		,NN.[Visit_pk]
		,NN.[Section]
		,NN.[TypeofTestId] 'TypeofTestId'
		,NN.[TypeofTest] 'TypeofTest'
		,TT.[Name]
		,NN.[ResultId] 'ResultId'
		,NN.[Result] 'Result'
		,NN.[Date] 'Date'
		,NN.[Comments] 'Comments'
		,NN.[DeleteFlag]
		,NN.[UserID]
		,NN.[IsAchieved][Achieved]
	FROM dtl_KNHPMTCTHEI_GridData NN
	LEFT JOIN mst_ModDeCode TT ON NN.TypeofTestId = TT.ID
	WHERE ptn_pk = @patientID
		AND Visit_Pk = @VisitId

		----5
		--SELECT NN.[Ptn_pk]
		--	,NN.[LocationID]
		--	,NN.[Visit_pk]
		--	,NN.[TypeofTest] 'TypeofTestId'
		--	,TT.[Name] 'TypeofTest'
		--	,NN.[Results] 'Results'
		--	,NN.[ResultCollectionDate] 'Date'
		--	,NN.[Comments] 'Comments'
		--	,NN.[DeleteFlag]
		--	,NN.[UserID]
		--FROM dtl_KNHPMTCTNeonatalHistoryHEI NN
		--INNER JOIN mst_ModDeCode TT ON NN.TypeofTest = TT.ID
		--	AND TT.CodeID IN (
		--		SELECT CodeID
		--		FROM mst_ModCode
		--		WHERE NAME = 'TypeOfTest'
		--			AND DeleteFlag = 0
		--			AND SystemId IN (
		--				0
		--				,1
		--				)
		--		)
		--	AND ptn_pk = @patientID
		--	AND Visit_Pk = @VisitId

		----6
		--SELECT MN.[Ptn_pk]
		--	,MN.[LocationID]
		--	,MN.[Visit_pk]
		--	,MN.[TypeofTestMother] 'TypeofMTestId'
		--	,TT.[Name] 'TypeofMTest'
		--	,MN.[ResultsMother] 'MResults'
		--	,MN.[ResultCollectionDateMother] 'MDate'
		--	,MN.[LabCommentsMother] 'MRemarks'
		--	,MN.[DeleteFlag]
		--	,MN.[UserID]
		--FROM dtl_KNHPMTCTMaternalHistoryHEI MN
		--INNER JOIN mst_ModDeCode TT ON MN.TypeofTestMother = TT.ID
		--	AND TT.CodeID IN (
		--		SELECT CodeID
		--		FROM mst_ModCode
		--		WHERE NAME = 'TypeOfTestMother'
		--			AND DeleteFlag = 0
		--			AND SystemId IN (
		--				0
		--				,1
		--				)
		--		)
		--	AND ptn_pk = @patientID
		--	AND Visit_Pk = @VisitId
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[pr_clinical_LoadKNHPMTCTHEI_PrepopulateData] @ptn_pk int
as
begin
	select top 1 *
	,isnull((select top 1 coalesce(y.PatientIPNo, y.patientenrollmentid) from dtl_FamilyInfo x 
			inner join mst_Patient y on x.ReferenceId=y.Ptn_Pk where x.Ptn_pk=@ptn_pk and x.RelationshipType=10),'') as motherNo 
	from dtl_KNHPMTCTHEI where ptn_pk = @ptn_pk order by Visit_pk desc
	select top 1 a.* from dtl_InfantInfo a
	inner join dtl_KNHPMTCTHEI b on a.visit_pk = b.visit_pk
	 where a.Ptn_pk = @ptn_pk order by a.Visit_pk desc
end
go
--==

alter table [dbo].[dtl_PatientDelivery] alter column [Gravidae] varchar(50)
alter table [dbo].[dtl_PatientDelivery] alter column parity varchar(50)
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Pr_ANC_SaveProfileData]
	-- Add the parameters for the stored procedure here                                                                  
		@Ptn_Pk INT
	,@locationid INT
	,@Visit_ID INT = NULL
	,@VisitDate DATETIME
	,@FieldVisitType INT = NULL
	,@LMP DATETIME
	,@EDD DATETIME
	,@Parity varchar(50) = NULL
	,@Gravidae varchar(50) = NULL
	,@Gestation VARCHAR(200) = NULL
	,@UserId INT = NULL
	,@Menarche INT = NULL
	,@SurgicalHistory varchar(1100) = null
	,@HistoryBloodTransfusion INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from                                                                    
	-- interfering with SELECT statements.                                              
	SET NOCOUNT ON;

	DECLARE @Visit_Pk INT
	DECLARE @TabID INT

	SELECT @TabId = TabId
	FROM Mst_FormBuilderTab
	WHERE FeatureID = 277
		AND TabName = 'KNHPMTCTMEIProfile'
		AND DeleteFlag = 0

	IF (@Visit_ID > 0)
	BEGIN
		UPDATE ord_visit
		SET TypeofVisit = @FieldVisitType
			,DataQuality = 0
			,UpdateDate = getdate()
			,SurgicalHistory=@SurgicalHistory
			,HistoryBloodTransfusion = @HistoryBloodTransfusion
		WHERE visit_Id = @Visit_ID
			AND ptn_pk = @ptn_pk
			AND locationId = @locationid

		IF EXISTS (
				SELECT *
				FROM dtl_KNHPMTCTMEI
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @ptn_pk
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_KNHPMTCTMEI
			SET
				[UserID] = @UserId
				,[UpdateDate] = getdate()
				,[Mernarche] = @Menarche
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @ptn_pk
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[dtl_KNHPMTCTMEI] (
				[Ptn_pk]
				,[LocationID]
				,[Visit_pk]
				,[UserID]
				,[CreateDate]
				,[Mernarche]
				)
			VALUES (
				@ptn_pk
				,@locationid
				,@Visit_ID
				,@UserId
				,getdate()
				,@Menarche
				)
		END

		IF EXISTS (
				SELECT *
				FROM dtl_PatientClinicalStatus
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @ptn_pk
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_PatientClinicalStatus
			SET LMP = @LMP
				,EDD = @EDD
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @ptn_pk
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO dtl_PatientClinicalStatus (
				ptn_pk
				,Visit_Pk
				,locationId
				,LMP
				,EDD
				,UserId
				,CreateDate
				)
			VALUES (
				@ptn_pk
				,@Visit_ID
				,@locationid
				,@LMP
				,@EDD
				,@UserId
				,getdate()
				)
		END

		IF EXISTS (
				SELECT *
				FROM dtl_PatientDelivery
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @ptn_pk
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_PatientDelivery
			SET Parity = @Parity
				,Gravidae = Nullif(@Gravidae, '999')
				,GestAge = @Gestation
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @ptn_pk
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO dtl_PatientDelivery (
				ptn_pk
				,Visit_Pk
				,locationId
				,Parity
				,Gravidae
				,GestAge
				,UserId
				,CreateDate
				)
			VALUES (
				@ptn_pk
				,@Visit_ID
				,@locationid
				,@Parity
				,Nullif(@Gravidae, '999')
				,@Gestation
				,@UserId
				,getdate()
				)
		END

		/*DELETE
		FROM dtl_Multiselect_line
		WHERE Ptn_pk = @ptn_pk
			AND Visit_Pk = @Visit_ID*/

		SET @Visit_Pk = @Visit_ID

		Select @Visit_Pk as VisitId

		SELECT TabID
		FROM lnk_FormTabOrdVisit
		WHERE Visit_pk = @Visit_ID
			AND TabId = @TabId
	END
	ELSE
	BEGIN

		INSERT INTO ord_Visit (
			Ptn_Pk
			,LocationID
			,VisitDate
			,VisitType
			,TypeofVisit
			,DataQuality
			,DeleteFlag
			,UserID
			,CreateDate
			,SurgicalHistory
			,HistoryBloodTransfusion
			)
		VALUES (
			@ptn_pk
			,@locationid
			,@VisitDate
			,40
			,@FieldVisitType
			,0
			,0
			,@UserId
			,getdate()
			,@SurgicalHistory
			,@HistoryBloodTransfusion
			)

		INSERT INTO dtl_PatientClinicalStatus (
			ptn_pk
			,Visit_Pk
			,locationId
			,LMP
			,EDD
			,UserId
			,CreateDate
			)
		VALUES (
			@ptn_pk
			,IDENT_CURRENT('ORD_VISIT')
			,@locationid
			,@LMP
			,@EDD
			,@UserId
			,getdate()
			)

		INSERT INTO dtl_PatientDelivery (
			ptn_pk
			,Visit_Pk
			,locationId
			,Parity
			,Gravidae
			,GestAge
			,UserId
			,CreateDate
			)
		VALUES (
			@ptn_pk
			,IDENT_CURRENT('ORD_VISIT')
			,@locationid
			,@Parity
			,Nullif(@Gravidae, '999')
			,@Gestation
			,@UserId
			,getdate()
			)

		SET @Visit_Pk = IDENT_CURRENT('ORD_VISIT')

		IF NOT EXISTS (
				SELECT *
				FROM lnk_FormTabOrdVisit
				WHERE Visit_pk = IDENT_CURRENT('ORD_VISIT')
					AND TabId = @TabId
				)
		BEGIN
			INSERT INTO lnk_FormTabOrdVisit (
				Visit_pk
				,DataQuality
				,TabId
				,UserId
				,CreateDate
				)
			VALUES (
				IDENT_CURRENT('ORD_VISIT')
				,0
				,@TabId
				,@UserId
				,GETDATE()
				)
		END

		Select @Visit_Pk as VisitId

		SELECT TabID
		FROM lnk_FormTabOrdVisit
		WHERE Visit_pk = IDENT_CURRENT('ORD_VISIT')
			AND TabId = @TabId
	END
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Pr_ANC_UpdateVisitDetails] @Ptn_pk INT
	,@Visit_Pk INT
	,@LocationId INT
	,@UserID INT
	,@FirstVisitDate DATETIME = NULL
	,@IPTP INT = NULL
	,@IPTPDateGiven DATETIME = NULL
	,@InsectisideTreatedNet INT = NULL
	,@InsectisideTreatedNetDT DATETIME = NULL
	,@Dewormed INT = NULL
	,@DewormedDateGiven DATETIME = NULL
	,@IronAndFolate INT = NULL
	,@IronAndFolateDateGiven DATETIME = NULL
	,@InfantFeedingCounselling INT = NULL
	,@ExclusiveBreastfeeding INT = NULL
	,@HIVIInfantFeedingOption INT = NULL
	,@MothersDecisionIF INT = NULL
	,@ExclusiveReplacement INT = NULL
	,@PlaceOfDelivery VARCHAR(100) = NULL
	,@PODDate DATETIME = NULL
	,@ModeOfDelivery INT = NULL
	,@BloodLoss INT = NULL
	,@ApgarScore1Min VARCHAR(50) = NULL
	,@ApgarScore5Min VARCHAR(50) = NULL
	,@ApgarScore10Min VARCHAR(50) = NULL
	,@ResusitationDone INT = NULL
	,@TetanusVaccine INT = NULL
	,@TetanusVaccineReason VARCHAR(200) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @DOB INT;
	DECLARE @FeatureID INT
		,@VisitType INT;

	IF (@Visit_Pk > 0)
	BEGIN
		DECLARE @tabId INT

		SELECT @tabId = TabId
		FROM Mst_FormBuilderTab
		WHERE FeatureId = 277
			AND TabName = 'KNHPMTCTMEIVisitDetails'
			AND DeleteFlag = 0;

		IF NOT EXISTS (
				SELECT TabId
				FROM lnk_FormTabOrdVisit
				WHERE Visit_pk = @Visit_Pk
					AND TabId = @tabId
				)
		BEGIN
			INSERT INTO [dbo].[lnk_FormTabOrdVisit] (
				[Visit_pk]
				,[Signature]
				,[DataQuality]
				,[TabId]
				,[UserId]
				,[CreateDate]
				,[StartTime]
				,[EndTime]
				)
			VALUES (
				@Visit_Pk
				,NULL
				,0
				,@tabId
				,@UserId
				,getdate()
				,getdate()
				,getdate()
				)
		END
		ELSE
		BEGIN
			UPDATE [dbo].[lnk_FormTabOrdVisit]
			SET [UserId] = @UserId
				,[UpdateDate] = getdate()
			WHERE Visit_pk = @Visit_Pk
				AND TabId = @tabId
		END

		IF EXISTS (
				SELECT *
				FROM dtl_KNHPMTCTMEI
				WHERE Visit_Pk = @Visit_Pk
					AND ptn_pk = @Ptn_pk
					AND locationId = @LocationId
				)
		BEGIN
			UPDATE dtl_KNHPMTCTMEI
			SET [UserID] = @UserId
				,[UpdateDate] = getdate()
				,[TetanusVaccine] = @TetanusVaccine
				,[TetanusVaccineReason] = @TetanusVaccineReason
			WHERE Visit_Pk = @Visit_Pk
				AND ptn_pk = @Ptn_pk
				AND locationId = @LocationId
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[dtl_KNHPMTCTMEI] (
				[Ptn_pk]
				,[LocationID]
				,[Visit_pk]
				,[UserID]
				,[CreateDate]
				,[TetanusVaccine]
				,[TetanusVaccineReason]
				)
			VALUES (
				@Ptn_pk
				,@LocationId
				,@Visit_Pk
				,@UserId
				,getdate()
				,@TetanusVaccine
				,@TetanusVaccineReason
				)
		END

		IF EXISTS (
				SELECT *
				FROM [dtl_PatientANCVisitDetails]
				WHERE VisitId = @Visit_Pk
					AND ptn_pk = @Ptn_pk
					AND locationId = @LocationId
				)
		BEGIN
			UPDATE [dbo].[dtl_PatientANCVisitDetails]
			SET [FirstVisitDate] = @FirstVisitDate
				,[IPTP] = @IPTP
				,[IPTPDateGiven] = @IPTPDateGiven
				,[InsectisideTreatedNet] = @InsectisideTreatedNet
				,[InsectisideTreatedNetDT] = @InsectisideTreatedNetDT
				,[Dewormed] = @Dewormed
				,[DewormedDateGiven] = @DewormedDateGiven
				,[IronAndFolate] = @IronAndFolate
				,[IronAndFolateDateGiven] = @IronAndFolateDateGiven
				,[InfantFeedingCounselling] = @InfantFeedingCounselling
				,[ExclusiveBreastfeeding] = @ExclusiveBreastfeeding
				,[HIVIInfantFeedingOption] = @HIVIInfantFeedingOption
				,[MothersDecisionIF] = @MothersDecisionIF
				,[ExclusiveReplacement] = @ExclusiveReplacement
				,[PlaceOfDelivery] = @PlaceOfDelivery
				,[PODDate] = @PODDate
				,[ModeOfDelivery] = @ModeOfDelivery
				,[BloodLoss] = @BloodLoss
				,[ApgarScore1Min] = @ApgarScore1Min
				,[ApgarScore5Min] = @ApgarScore5Min
				,[ApgarScore10Min] = @ApgarScore10Min
				,[ResusitationDone] = @ResusitationDone
				,[CreateDate] = getdate()
				,[UserId] = @UserId
				,[UpdatedDate] = getdate()
			WHERE VisitId = @Visit_Pk
				AND ptn_pk = @Ptn_pk
				AND locationId = @LocationId
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[dtl_PatientANCVisitDetails] (
				[Ptn_pk]
				,[VisitId]
				,[Locationid]
				,[FirstVisitDate]
				,[IPTP]
				,[IPTPDateGiven]
				,[InsectisideTreatedNet]
				,[InsectisideTreatedNetDT]
				,[Dewormed]
				,[DewormedDateGiven]
				,[IronAndFolate]
				,[IronAndFolateDateGiven]
				,[InfantFeedingCounselling]
				,[ExclusiveBreastfeeding]
				,[HIVIInfantFeedingOption]
				,[MothersDecisionIF]
				,[ExclusiveReplacement]
				,[PlaceOfDelivery]
				,[PODDate]
				,[ModeOfDelivery]
				,[BloodLoss]
				,[ApgarScore1Min]
				,[ApgarScore5Min]
				,[ApgarScore10Min]
				,[ResusitationDone]
				,[CreateDate]
				,[UserId]
				,[UpdatedDate]
				)
			VALUES (
				@Ptn_pk
				,@Visit_Pk
				,@Locationid
				,@FirstVisitDate
				,@IPTP
				,@IPTPDateGiven
				,@InsectisideTreatedNet
				,@InsectisideTreatedNetDT
				,@Dewormed
				,@DewormedDateGiven
				,@IronAndFolate
				,@IronAndFolateDateGiven
				,@InfantFeedingCounselling
				,@ExclusiveBreastfeeding
				,@HIVIInfantFeedingOption
				,@MothersDecisionIF
				,@ExclusiveReplacement
				,@PlaceOfDelivery
				,@PODDate
				,@ModeOfDelivery
				,@BloodLoss
				,@ApgarScore1Min
				,@ApgarScore5Min
				,@ApgarScore10Min
				,@ResusitationDone
				,getdate()
				,@UserId
				,getdate()
				)
		END

		DELETE
		FROM [dtl_PatientANCPresentPregnancy]
		WHERE VisitId = @Visit_Pk
			AND ptn_pk = @Ptn_pk
			AND locationId = @LocationId;

		DELETE
		FROM [dtl_PatientANCVisitAnthropometric]
		WHERE VisitId = @Visit_Pk
			AND ptn_pk = @Ptn_pk
			AND locationId = @LocationId;

		DELETE
		FROM [dtl_patientappointment]
		WHERE Visit_pk = @Visit_Pk
			AND ptn_pk = @Ptn_pk
			AND locationId = @LocationId;

		update ord_Visit set DataQuality=1 where Visit_Id=@Visit_Pk

		SELECT 1;
	END
	ELSE
	BEGIN
		SELECT 0;
	END

	SET NOCOUNT OFF
END;
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_KNH_GetPMTCTMEIPatientLabResult] @patientID INT
AS
BEGIN
	SELECT LO.Ptn_pk
		,LO.VisitId
		,LR.ParameterID
		,TP.SubTestName
		,LO.OrderedbyDate [TestDate]
		,CASE WHEN LR.TestResultId IS NOT NULL THEN Convert(varchar(20),pr.Result)
			  WHEN LR.TestResults IS NOT NULL THEN Convert(varchar(20),LR.TestResults)
		      else Convert(varchar(20),LR.TestResults1)
		END [Result]
		,CASE  WHEN Convert(DATETIME, LO.ReportedbyDate) = convert(DATE, getdate(), 101) THEN Convert(BIT, '1')
			   ELSE Convert(BIT, '0') END [Order]
		,LR.TestResults
		,LR.TestResults1
	FROM ord_PatientLabOrder LO
	INNER JOIN dtl_PatientLabResults LR ON LO.LabID = LR.LabID
	JOIN lnk_TestParameter TP ON LR.ParameterID = TP.SubTestID
		AND LO.Ptn_pk = @patientID
	LEFT JOIN [lnk_parameterresult] pr ON LR.TestResultId = pr.ResultID
	where LO.LabID in (select top 2 x.LabID from ord_PatientLabOrder x where x.Ptn_pk=@patientID order by LabID desc)
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[pr_Clinical_GetLinkedForms_FormLinking]                                                                                                                  
@ModuleId int,                                                                                                                  
@FeatureId int                                                                                                                  
as                                                                                                                  
                                                                                                                  
begin                                                                                             
	select top 1 * from lnk_SplFormModule where moduleid= @ModuleId and (featureid= @FeatureId or @FeatureId=0)                                                                       
End
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--[pr_Clinical_GetPatientHistory_Constella] 3072, "'ttwbvXWpqb5WOLfLrBgisw=='"
ALTER PROCEDURE [dbo].[pr_Clinical_GetPatientHistory_Constella] @PatientId INT
	,@Password VARCHAR(40)
AS
BEGIN
	DECLARE @SymKey VARCHAR(400);

	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @password + '';

	EXEC (@SymKey);

	SELECT DISTINCT dbo.fn_PatientIdentificationNumber_Constella(a.ptn_pk, '', 1) AS PatientId
		,CountryId + '-' + PosId + '-' + SatelliteId + '-' + PatientEnrollmentId AS PatientID
		,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname)) + ' ' + ISNULL(CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)), '') + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName)) AS NAME
		,b.LocationID
		,a.Sex
		,a.PatientClinicID
	FROM mst_patient AS a
		,ord_visit AS b
	WHERE a.ptn_pk = b.ptn_pk
		AND a.ptn_pk = @patientid
		AND b.visittype = 12;

	SELECT forms.*
	FROM (
		SELECT 'HIV-Enrollment' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'1' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 0
			AND a.Ptn_Pk = @PatientId
			AND a.PatientEnrollmentID <> ''
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Initial Evaluation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 1
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Prior ART/HIV Care' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'202' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 16
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ART Care' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'202' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 14
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				) ---john start
		
		UNION
		
		SELECT 'ART Therapy' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 19
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				) --john end
		
		UNION
		
		SELECT 'ART History' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 18
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Pharmacy' AS FormName
			,dbo.mst_Patient.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.firstname)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.lastName)) AS NAME
			,TranDate = CASE 
				WHEN dbo.ord_PatientPharmacyOrder.DispensedByDate IS NULL
					THEN dbo.ord_PatientPharmacyOrder.OrderedByDate
				ELSE dbo.ord_PatientPharmacyOrder.DispensedByDate
				END
			,ord_Visit.DataQuality AS DataQuality
			--,dbo.ord_PatientPharmacyOrder.Ptn_Pharmacy_Pk [OrderNo]
			,dbo.ord_Visit.visit_id AS OrderNo
			,dbo.ord_Visit.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'5' AS Priority
			,'0' AS Module
			,mst_decode.ID AS ID
			,mst_decode.NAME AS ART
			--,CAUTION = CASE 
			--	WHEN dbo.ord_PatientPharmacyOrder.DispensedByDate IS NULL
			--		THEN '1'
			--	ELSE '0'
			--	END
			,CAUTION = CASE 
				WHEN dbo.ord_PatientPharmacyOrder.orderstatus IS NULL
					OR dbo.ord_PatientPharmacyOrder.orderstatus = 1
					THEN '1'
				WHEN dbo.ord_PatientPharmacyOrder.orderstatus = 2
					THEN '3'
				WHEN dbo.ord_PatientPharmacyOrder.orderstatus = 3
					THEN '2'
				ELSE '0'
				END
			,'0' AS FeatureID
			,'' AS UserName
		FROM dbo.mst_Patient
		INNER JOIN dbo.ord_PatientPharmacyOrder ON dbo.mst_Patient.Ptn_Pk = dbo.ord_PatientPharmacyOrder.Ptn_pk
		INNER JOIN dbo.ord_Visit ON dbo.mst_Patient.Ptn_Pk = dbo.ord_Visit.Ptn_Pk
			AND dbo.ord_PatientPharmacyOrder.VisitID = dbo.ord_Visit.Visit_Id
		LEFT OUTER JOIN mst_decode ON mst_decode.ID = ord_PatientPharmacyOrder.ProgID
		WHERE dbo.ord_visit.visittype = 4
			AND dbo.mst_Patient.Ptn_Pk = @PatientId
			AND (
				ord_visit.DeleteFlag IS NULL
				OR ord_visit.DeleteFlag = 0
				)
			AND ord_visit.VisitDate IS NOT NULL
			AND ord_PatientPharmacyOrder.ordertype IN (
				116
				,117
				)
		
		UNION
		
		SELECT 'Order Labs' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName)) AS NAME
			,ISNULL(b.OrderedbyDate, '1900-01-01') AS TranDate
			,c.DataQuality AS DataQuality
			,LabId AS OrderNo
			,c.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'0' AS Module
			,ISNULL(b.ResultVisitId, '0') AS ID
			,'0' AS ART
			,CAUTION = CASE 
				WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Completed'
					THEN '0'
				WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
					AND (
						b.ReportedByDate IS NULL
						OR b.ReportedByDate = '1900-01-01'
						)
					THEN '1'
				WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
					AND (
						b.ReportedByDate IS NOT NULL
						OR b.ReportedByDate <> '1900-01-01'
						)
					THEN '2'
				ELSE '1'
				END
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_PatientLabOrder AS b
			,ord_Visit AS c
		WHERE a.ptn_pk = b.ptn_pk
			AND b.VisitId = c.Visit_Id
			AND a.ptn_pk = @PatientId
			AND c.visittype = 6
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ART Follow-Up' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'3' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 2
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'HIV Care/ART Encounter' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'3' AS Priority
			,'202' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 15
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Initial and Follow up Visits' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'3' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 17
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT DISTINCT 'Non-ART Follow-Up' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_Visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.VisitType = 3
			AND b.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Patient Record - Initial Visit' AS FormName
			,mst_Patient.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.firstname, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.MiddleName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.lastName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) AS NAME
			,ISNULL(ord_Visit.VisitDate, '1900-01-01') AS TranDate
			,ord_Visit.DataQuality AS DataQuality
			,ord_Visit.Visit_Id AS OrderNo
			,ord_Visit.LocationID AS LocationID
			,'0' AS PatientRecordNo
			,'0' AS Priority
			,'' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_Patient
		INNER JOIN ord_Visit ON mst_Patient.Ptn_Pk = ord_Visit.Ptn_pk
		WHERE ord_visit.visittype = 7
			AND mst_Patient.ptn_pk = @PatientId
		
		UNION
		
		SELECT 'Patient Record - Follow Up' AS FormName
			,mst_Patient.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.firstname, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.MiddleName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(mst_Patient.lastName, mst_Patient.ptn_pk, CONVERT(VARCHAR(50), mst_Patient.ptn_pk))) AS NAME
			,ISNULL(ord_Visit.VisitDate, '1900-01-01') AS TranDate
			,ord_Visit.DataQuality AS DataQuality
			,ord_Visit.Visit_Id AS OrderNo
			,ord_Visit.LocationID AS LocationID
			,'0' AS PatientRecordNo
			,'0' AS Priority
			,'' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_Patient
		INNER JOIN ord_Visit ON mst_Patient.Ptn_Pk = ord_Visit.Ptn_pk
		WHERE ord_visit.visittype = 8
			AND mst_Patient.ptn_pk = @PatientId
			AND ord_visit.DeleteFlag IS NULL
		
		UNION
		
		SELECT 'Care Tracking' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,TranDate = CASE 
				WHEN c.Careended = 1
					THEN ISNULL(c.CareEndedDate, '')
				WHEN c.ARTended = 1
					THEN ISNULL(c.ARTenddate, '')
				ELSE ISNULL(b.DateLastContact, '')
				END
			,b.DataQuality AS DataQuality
			,b.TrackingID AS OrderNo
			,c.LocationID AS LocationID
			,c.CareEndedID AS PharmacyNo
			,'9' AS Priority
			,
			--Module=CASE WHEN (b.ModuleId = 1) THEN 'PMTCT' When (b.ModuleId = 2) Then 'ART' END
			b.ModuleId AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,dtl_patienttrackingcare AS b
			,dtl_patientcareended AS c
		WHERE a.Ptn_pk = b.Ptn_pk
			AND a.ptn_pk = c.ptn_pk
			AND b.trackingID = c.trackingID
			AND (
				c.ARTended IS NULL
				OR c.ARTended = 0
				)
			AND a.Ptn_pk = @PatientId
		
		UNION
		
		SELECT 'Home Visit' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.hvBeginDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.HomeVisitID AS OrderNo
			,b.LocationId AS LocationID
			,'0' AS PharmacyNo
			,'8' AS Priority
			,'2' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,dtl_patienthomevisit AS b
		WHERE a.Ptn_pk = b.Ptn_pk
			AND a.Ptn_pk = @PatientId
			AND (
				b.DeleteFlag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'PEP' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'6' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 21
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Paediatric Initial Evaluation Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 22
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Express' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 31
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Patient Registration' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'1' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 12
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Paediatric Follow up Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 24
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Adult Initial Evaluation Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 25
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Adult Follow up Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'4' AS Priority
			,'204' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 23
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria Adult Initial Evaluation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 32
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria Paediatric Initial Evaluation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 33
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria ART Care Visitation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 34
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria ART Care Summary' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'7' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 35
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Nigeria Initial Visit' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'8' AS Priority
			,'209' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 36
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'HEI' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'9' AS Priority
			,'1' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 37
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ANC' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName, a.ptn_pk, CONVERT(VARCHAR(50), a.ptn_pk))) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'9' AS Priority
			,'1' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 40
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'DCC Adult Initial Evaluation Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'1' AS Priority
			,'210' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 38
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'DCC Revised Adult Follow up Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'210' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 39
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Green Card Form' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 50
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		/**** HVICE ******/
		
		UNION
		
		SELECT 'Treatment Preparation' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'203' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 60
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'ART Readiness Assessment' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'203' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 61
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Transition from Paediatric to Adolescent Services' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'293' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 62
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Alcohol, GBV and Depression Screening' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'203' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'292' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype = 63
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Clinical Encounter' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Clinical Encounter'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Refill Encounter' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Refill Encounter'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Adherence Barriers' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Adherence Barriers'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT 'Enhance Adherence Counselling' AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,'2' AS Priority
			,'0' AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,'0' AS FeatureID
			,'' AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
		WHERE a.ptn_pk = b.ptn_pk
			AND b.visittype IN (
				SELECT TOP 1 visittypeid
				FROM mst_visittype
				WHERE visitname = 'Enhance Adherence Counselling'
					AND (
						b.deleteflag IS NULL
						OR b.deleteflag = 0
						)
				)
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
		
		UNION
		
		SELECT DISTINCT c.VisitName AS FormName
			,a.ptn_pk
			,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.FirstName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.LastName)) AS NAME
			,ISNULL(b.VisitDate, '1900-01-01') AS TranDate
			,b.DataQuality AS DataQuality
			,b.Visit_Id AS OrderNo
			,b.LocationID AS LocationID
			,'0' AS PharmacyNo
			,c.VisitTypeID AS Priority
			,d.ModuleId AS Module
			,'0' AS ID
			,'0' AS ART
			,'0' AS CAUTION
			,d.featureid AS FeatureID
			,dbo.fn_ViewExistingFormUsername(b.Visit_Id) AS UserName
		FROM mst_patient AS a
			,ord_visit AS b
			,mst_visitType AS c
			,mst_Feature AS d
		LEFT OUTER JOIN mst_Module AS e ON d.ModuleId = e.ModuleId
		WHERE a.ptn_pk = b.ptn_pk
			AND e.deleteflag = 0
			AND b.visittype = c.VisitTypeID
			AND a.Ptn_Pk = @PatientId
			AND (
				b.deleteflag IS NULL
				OR b.deleteflag = 0
				)
			AND c.systemId = d.systemId
			AND c.VisitName = d.FeatureName

			AND c.visitName NOT IN (
				'Enrollment'
				,'Initial Evaluation'
				,'ART Follow-Up'
				,'Non-ART Follow-Up'
				,'Pharmacy Order'
				,'Scheduler'
				,'Order Labs'
				,'Patient Record - Initial Visit'
				,'Patient Record - Follow Up'
				,'PMTCT Enrollment'
				,'Patient Registration'
				,'KNH PEP Form'
				,'Paediatric Initial Evaluation Form'
				,'Adult Follow up Form'
				,'Paediatric Follow up Form'
				,'Adult Initial Evaluation Form'
				,'Express'
				,'Adult Initial Evaluation'
				,'Paediatric Initial Evaluation'
				,'ART Care Visitation'
				,'Initial Visit'
				,'HEI Form'
				,'DCC Adult Initial Evaluation Form'
				,'DCC Revised Adult Follow up Form'
				,'ANC Form'
				,'Green Card Form'
				,'ART Readiness Assessment'
				,'Transition from Paediatric to Adolescent Services'
				,'Alcohol, GBV and Depression Screening'
				,'Refill Encounter'
				,'Enhance Adherence Counselling'
				,'Adherence Barriers'
				)
				
			AND d.ModuleId NOT IN (0)
			--AND d.published = 2
			AND (
				d.deleteflag IS NULL
				OR d.deleteflag = 0
				)
		) forms
	ORDER BY TranDate DESC
		,FormName DESC;--02

	SELECT Visit_Id
		,LocationID
	FROM ord_visit
	WHERE ptn_pk = @patientid
		AND visittype = 0;--03

	SELECT FeatureID
		,FeatureName
	FROM mst_feature AS a
	LEFT OUTER JOIN mst_module AS b ON a.ModuleID = b.ModuleId
	WHERE b.deleteflag = 0
		AND a.deleteflag = 0;--04

	SELECT 'Order Labs' AS FormName
		,a.ptn_pk
		,CONVERT(VARCHAR(50), DECRYPTBYKEY(a.firstname)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.MiddleName)) + ' ' + CONVERT(VARCHAR(50), DECRYPTBYKEY(a.lastName)) AS NAME
		,ISNULL(b.OrderedbyDate, '1900-01-01') AS TranDate
		,c.DataQuality AS DataQuality
		,LabId AS OrderNo
		,c.LocationID AS LocationID
		,'0' AS PharmacyNo
		,'7' AS Priority
		,'0' AS Module
		,'0' AS ID
		,'0' AS ART
		,CAUTION = CASE 
			WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Completed'
				THEN '0'
			WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
				AND (
					b.ReportedByDate IS NULL
					OR b.ReportedByDate = '1900-01-01'
					)
				THEN '1'
			WHEN dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_ORD_STATUS') = 'Partial'
				AND (
					b.ReportedByDate IS NOT NULL
					OR b.ReportedByDate <> '1900-01-01'
					)
				THEN '2'
			ELSE '1'
			END
		,'0' AS FeatureID
		,'' AS UserName
		,b.LabNumber
		,dbo.Fun_IQTouch_GetIDValue(LabId, 'LAB_URGENT_STATUS') [URGENT]
	FROM mst_patient AS a
		,ord_PatientLabOrder AS b
		,ord_Visit AS c
	WHERE a.ptn_pk = b.ptn_pk
		AND b.VisitId = c.Visit_Id
		AND a.ptn_pk = @PatientId
		AND c.visittype = 6
		AND (
			b.deleteflag IS NULL
			OR b.deleteflag = 0
			)
	ORDER BY TranDate DESC
		,FormName DESC;

	CLOSE SYMMETRIC KEY Key_CTC;
END
go
--==

alter table [dbo].[dtl_PatientDelivery] alter column GestAge varchar(200)
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Pr_Clinical_GetPatientSearchresults]
	 @Sex INT = NULL
	,@Firstname VARCHAR(50) = NULL
	,@LastName VARCHAR(50) = NULL
	,@MiddleName VARCHAR(50) = NULL
	,@DOB DATETIME = NULL
	,@RegistrationDate DATETIME = NULL
	,@EnrollmentType INT = NULL
	,@EnrollmentID VARCHAR(50) = NULL
	,@FacilityID INT = NULL
	,@Status INT = NULL
	,@Password VARCHAR(50) = NULL
	,@ModuleID INT = 999
	,@FilterByModuleID BIT = 0
	,@top INT = 100
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Query NVARCHAR(max)
		,@ParamDefinition NVARCHAR(2000)
		,@Identifiers VARCHAR(4000)
		,@ByModule VARCHAR(2000)
		,@ByStatus VARCHAR(520)
		,@PMTCT VARCHAR(400)
		,@StatusStr VARCHAR(520)
		,@FacilityStr VARCHAR(520);;
	DECLARE @SymKey NVARCHAR(400);
	SELECT @Identifiers = ''
		,@ByModule = ''
		,@FacilityStr = ''
		,@ByStatus = ' Status =  Null ,'
		,@StatusStr = ' And (@Status Is Null Or P.[Status] = @status)';
	IF (@FacilityID <> 9999)
	BEGIN
		SELECT @FacilityStr = 'And (@FacilityID Is Null Or P.LocationID=@FacilityID)'
	END
	IF (@EnrollmentID IS NOT NULL)
	BEGIN
		DECLARE @SS VARCHAR(1000)
		IF (
				@EnrollmentType = 9999
				OR @EnrollmentType = 0
				)
		BEGIN
			SELECT @SS = Substring((
						SELECT ',P.[' + Convert(VARCHAR(Max), FieldName) + ']'
						FROM dbo.mst_patientidentifier
						ORDER BY Id
						FOR XML Path('')
						), 2, 1000);
			--PRINT @SS;
			SELECT @Identifiers = ' AND (' + Replace(@SS, ',', ' like ''%' + @enrollmentid + ''' or ') + ' like ''%' + @enrollmentid + ''' or P.PatientEnrollmentID like ''%' + @enrollmentid + ''')';
		END
		ELSE
		BEGIN
			IF (@EnrollmentType <> 10000)
			BEGIN
				SELECT @SS = Substring((
							SELECT ',P.[' + Convert(VARCHAR(Max), FieldName) + ']'
							FROM dbo.mst_patientidentifier
							WHERE ID = @EnrollmentType
							ORDER BY Id
							FOR XML Path('')
							), 2, 1000);
				--PRINT @SS
				SELECT @Identifiers = ' AND (' + Replace(@SS, ',', ' like ''' + @enrollmentid + '%'' or ') + ' like ''%' + @enrollmentid + ''')';
			END
			ELSE
			BEGIN
				SELECT @Identifiers = ' AND (P.IQNumber like ''%' + @enrollmentid + ''')';
			END
		END
	END
	PRINT @Identifiers
	IF (@ModuleID <> 999)
	BEGIN
		SELECT @PMTCT = CASE @ModuleID
				WHEN 1
					--THEN 'And DATEDIFF(YYYY,P.DOB,GETDATE()) > 14 and P.Sex <> 16'
					--THEN 'And ((DATEDIFF(YYYY,P.DOB,GETDATE()) > 12 and P.Sex <> 16) OR (DATEDIFF(YYYY,P.DOB,GETDATE()) <= 2 ))'
					then ''
				ELSE ''
				END
		SELECT @ByModule = 
			' Left Outer Join (Select	P.Ptn_pk,P.ModuleId,P.StartDate EnrollmentDate,	
							Case CT.CareEnded When 1 Then ''Care Ended'' When 0 Then ''Restarted''  Else ''Active'' End CareStatus,		
							CT.PatientExitReasonName CareEndReason,	isnull(CT.EnrollmentIndex,1) EnrollmentIndex,
							CASE CT.CareEnded WHEN 1 THEN 1 ELSE 0 END PatientCareEndStatus
							From dbo.Lnk_PatientProgramStart As P
							Left Outer Join (Select	CE.Ptn_Pk,	CE.CareEnded,	CE.PatientExitReason,	D.Name As PatientExitReasonName,CE.CareEndedDate,TC.TrackingID,
							TC.ModuleId,Row_number() Over(Partition By TC.Ptn_Pk Order By TC.TrackingId Desc) EnrollmentIndex
							From dbo.dtl_PatientCareEnded As CE
							Inner Join	dbo.dtl_PatientTrackingCare As TC On TC.TrackingID = CE.TrackingId
							Inner Join	dbo.mst_Decode As D On D.ID = CE.PatientExitReason Where TC.ModuleId = @ModuleID) As CT 
							On CT.Ptn_Pk = P.Ptn_pk And CT.ModuleId = P.ModuleId  And CT.EnrollmentIndex = 1  Where P.ModuleID=@ModuleID ) CT 
							On CT.Ptn_Pk=P.Ptn_Pk And CT.ModuleID=@ModuleID '
		SELECT @ByStatus = ' Status = Case When CT.ModuleID Is Null Then ''Not Enrolled'' Else IsNull(CT.CareStatus,CT.CareEndReason) End , 
					 CT.CareEndReason, CT.CareStatus,ISNULL(CT.PatientCareEndStatus,0) PatientCareEndStatus ,'
		SELECT @StatusStr = ' ';
	END
	ELSE
	BEGIN
		SET @PMTCT = '';
	END
	SET @Query = N'
		declare @Sex INT = '''+cast(isnull(@Sex,0) as varchar)+'''
		,@Firstname VARCHAR(50) = '''+cast(isnull(@Firstname,'') as varchar)+'''
		,@LastName VARCHAR(50) = '''+cast(isnull(@LastName,'') as varchar)+'''
		,@MiddleName VARCHAR(50) = '''+cast(isnull(@MiddleName,'') as varchar)+'''
		,@DOB DATETIME = '''+cast(isnull(@DOB,'') as varchar)+'''
		,@RegistrationDate DATETIME = '''+cast(isnull(@RegistrationDate,'') as varchar)+'''
		,@EnrollmentType INT = '''+cast(isnull(@EnrollmentType,'') as varchar)+'''
		,@EnrollmentID VARCHAR(50) = '''+cast(isnull(@EnrollmentID,'') as varchar)+'''
		,@FacilityID INT = '''+cast(isnull(@FacilityID,'') as varchar)+'''
		,@Status INT = '''+cast(isnull(@Status,'') as varchar)+'''
		,@Password VARCHAR(50) = '''''+cast(isnull(@Password,'') as varchar)+'''''
		,@ModuleID INT = '''+cast(isnull(@ModuleID,'') as varchar)+'''
		,@FilterByModuleID BIT = 0
		,@top INT = 100

		Select Top (@top) P.Ptn_Pk PatientID, Convert(varchar(50), Decryptbykey(FirstName)) As FirstName,
		Convert(varchar(50), Decryptbykey(MiddleName)) As Middlename,
		Convert(varchar(50), Decryptbykey(LastName)) As LastName,
		IQNumber As IQNumber, NullIf(P.PatientClinicID, '''')PatientClinicID, LocationID,
		F.FacilityName, Case DOBPrecision
		When 0 Then ''No''
		When 1 Then ''Yes'' End As [Precision],
		Dob,
		P.RegistrationDate,' + @ByStatus + ' 
		P.[Status] AS PatientStatus,
		Sex = Case P.Sex When 16 Then ''Male'' Else ''Female'' End
		From dbo.mst_Patient As P
	 	Inner Join dbo.mst_Facility F On F.FacilityID = P.LocationID' + @ByModule + '
		Where  (P.DeleteFlag = 0 OR P.DeleteFlag Is Null) ' + @PMTCT + 
		'
    	And Convert(varchar(50), decryptbykey(P.FirstName)) Like  ''''+@Firstname+''%''
		And Convert(varchar(50), decryptbykey(P.LastName)) Like  ''''+@LastName+''%''
		And Convert(varchar(50), decryptbykey(P.MiddleName)) Like  ''''+@MiddleName+''%''
		And (@DOB=''01-Jan-1900'' or P.DOB = @DOB)
		And (@DOB=''01-Jan-1900'' or P.RegistrationDate= @RegistrationDate)
		And (@Sex=''0'' Or P.Sex = @Sex)' + @StatusStr + @FacilityStr + @Identifiers + ' Order By P.RegistrationDate desc';
	SET @ParamDefinition = N'@Sex int = Null, 
		@Firstname varchar(50) = Null, 
		@LastName varchar(50) = Null, 
		@MiddleName varchar(50) = Null, 
		@DOB datetime = Null, 
		@RegistrationDate datetime = Null,
		@EnrollmentID varchar(50) = Null,  
		@FacilityID int = Null,  
		@Status int = 0,
		@Password varchar(50) = Null,    
		@ModuleID int = 999,
		@top int=100 ';

	PRINT @Query
	EXEC('Open symmetric key Key_CTC decryption by password=' + @Password)
	EXEC(@Query)
	CLOSE symmetric KEY Key_CTC
END
go
--==

if exists(select * from sysobjects where name='pr_Admin_GetCustomFormId' and type='p')
	drop proc pr_Admin_GetCustomFormId
go

create proc pr_Admin_GetCustomFormId
@Formname varchar(100)
as
begin
	if(@Formname='CareEnd')
	begin
		select top 1 a.FeatureID, a.FeatureName from mst_Feature a
		where a.FeatureName like '%'+@Formname+'%'
		and a.DeleteFlag=0 and a.ModuleId=203 and isnull(a.published, 2)=2
		order by a.FeatureID desc
	end
	else
	begin
		select top 1 a.FeatureID, a.FeatureName from mst_Feature a
		where a.FeatureName like '%'+@Formname+'%'
		and a.DeleteFlag=0 and isnull(a.published, 2)=2
		order by a.FeatureID desc
	end
end
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Clinical_SaveUpdateKNHHEI_Futures]
	-- Add the parameters for the stored procedure here                                                                  
	@patientid INT = NULL
	,@locationid INT = NULL
	,@Visit_ID INT = NULL
	,@KNHHEIVisitDate VARCHAR(11) = NULL
	,@KNHHEIVisitType INT = NULL
	--vital sign.....
	,@KNHHEITemp DECIMAL(18, 1) = NULL
	,@KNHHEIRR DECIMAL(18, 1) = NULL
	,@KNHHEIHR DECIMAL(18, 1) = NULL
	,@KNHHEIHeight DECIMAL(18, 1) = NULL
	,@KNHHEIWeight DECIMAL(18, 1) = NULL
	,@KNHHEIBPSystolic DECIMAL(18, 1) = NULL
	,@KNHHEIBPDiastolic DECIMAL(18, 1) = NULL
	,@KNHHEIHeadCircum DECIMAL(18, 1) = NULL
	,@KNHHEIWA DECIMAL(18, 1) = NULL
	,@KNHHEIWH DECIMAL(18, 1) = NULL
	,@KNHHEIBMIz DECIMAL(18, 1) = NULL
	,@KNHHEINurseComments VARCHAR(200) = NULL
	,@KNHHEIReferToSpecialClinic VARCHAR(200) = NULL
	,@KNHHEIReferToOther VARCHAR(200) = NULL
	--neonatl history
	,@KNHHEISrRefral VARCHAR(200) = NULL
	,@KNHHEIPlDelivery INT = NULL
	,@KNHHEIPlDeliveryotherfacility VARCHAR(300) = NULL
	,@KNHHEIPlDeliveryother VARCHAR(300) = NULL
	,@KNHHEIMdDelivery INT = NULL
	,@KNHHEIBWeight DECIMAL = NULL
	,@KNHHEIARVProp INT = NULL
	,@KNHHEIARVPropOther VARCHAR(300) = NULL
	,@KNHHEIIFeedoption INT = NULL
	,@KNHHEIIFeedoptionother VARCHAR(300) = NULL
	--maternal history
	,@KNHHEIStateofMother INT = NULL
	,@KNHHEIMRegisthisclinic INT = NULL
	,@KNHHEIPlMFollowup INT = NULL
	,@KNHHEIPlMFollowupother VARCHAR(300) = NULL
	,@KNHHEIMRecievedDrug INT = NULL
	,@KNHHEIOnARTEnrol INT = NULL
	/* Immunization, now saving to grid.....
	,@KNHHEIDateImmunised VARCHAR(200) = NULL
	,@KNHHEIPeriodImmunised INT = NULL
	,@KNHHEIGivenImmunised INT = NULL
	*/
	-- presenting complaints 
	,@KNHHEIAdditionalComplaint VARCHAR(200) = NULL
	
	-- Examination
	,@KNHHEIExamination VARCHAR(200) = NULL
	/*-- Milestone, now saving to grid.....
	,@KNHHEIMilestones INT = NULL
	--,@KNHHEIAssessmmentOutcome INT = NULL
	,@KNHHEIPlan INT = NULL
	,@KNHHEIPlanRegimen INT = NULL
	*/
	-- management plan
	,@KNHHEIVitamgiven INT = NULL
	,@KNHHEIWorkPlan varchar(max) = null
	--Referral, Admission and Appointment
	,@KNHHEIReferredto INT = NULL
	,@KNHHEIReferredtoother VARCHAR(300) = NULL
	,@KNHHEIAdmittoward INT = NULL
	,@KNHHEITCA INT = NULL
	,@dataquality INT = NULL
	,@UserId INT = NULL
	--,@Signature INT = NULL
	,@Scheduled smallint=NULL
	,@DurationARTstart INT=NULL
	,@ReferredFrom INT=NULL
	,@ReferredFromOther nvarchar(100)=NULL
	,@SPO2 INT=NULL
	,@AnyComplaints bit=NULL
	,@GeneralExamination int=NULL
	,@NeonatalHistoryNotes nvarchar(1000)=NULL
	,@TBFindings int=NULL
	,@MUAC int=NULL
	,@ReviewSystemComments nvarchar(1000)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from                                                                    
	-- interfering with SELECT statements.                                              
	SET NOCOUNT ON;

	DECLARE @Visit_Pk INT

	IF (@Visit_ID > 0)
	BEGIN
		UPDATE ord_visit
		SET TypeofVisit = @KNHHEIVisitType
			,DataQuality = 1
			,UpdateDate = getdate()
		WHERE visit_Id = @Visit_ID
			AND ptn_pk = @patientid
			AND locationId = @locationid

		IF EXISTS (
				SELECT *
				FROM dtl_KNHPMTCTHEI
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @patientid
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_KNHPMTCTHEI
			SET
				---[TBAssessment] = @KNHHEIAssessmmentOutcome
				---,[Plan] = @KNHHEIPlan
				---,[PlanRegimen] = @KNHHEIPlanRegimen
				[ChildReferredFrom] = @KNHHEISrRefral
				,[DeliveryPlaceHEI] = @KNHHEIPlDelivery
				,[Deliveryotherfacility] = @KNHHEIPlDeliveryotherfacility
				,[Deliveryother] = @KNHHEIPlDeliveryother
				,[ModeofDeliveryHEI] = @KNHHEIMdDelivery
				,[ChildPEPARVs] = @KNHHEIARVProp
				,[ARVPropOther] = @KNHHEIARVPropOther
				,[MotherRegisteredClinic] = @KNHHEIMRegisthisclinic
				,[ANCFollowup] = @KNHHEIPlMFollowup
				,[PlMFollowupother] = @KNHHEIPlMFollowupother
				,[MotherReferredtoARV] = @KNHHEIMRecievedDrug
				,[StateOfMother] = @KNHHEIStateofMother
				,[OnART] = @KNHHEIOnARTEnrol
				---,[ImmunisationDate] = @KNHHEIDateImmunised
				---,[ImmunisationPeriod] = @KNHHEIPeriodImmunised
				--,[ImmunisationGiven] = @KNHHEIGivenImmunised
				,[AdditionalComplaint] = @KNHHEIAdditionalComplaint
				,[Examinations] = @KNHHEIExamination
				---,[MilestonesPeads] = @KNHHEIMilestones
				,[VitaminA] = @KNHHEIVitamgiven
				,[WorkPlan]= @KNHHEIWorkPlan
				,[ReferralPeads] = @KNHHEIReferredto
				,[Referredtoother] = @KNHHEIReferredtoother
				,[WardAdmissionPead] = @KNHHEIAdmittoward
				,[TCA] = @KNHHEITCA
				,[DeleteFlag] = 0
				,[UserID] = @UserId
				,[UpdateDate] = getdate()
				,[Scheduled]=@Scheduled
				,[DurationARTstart]=@DurationARTstart
				,[ReferredFrom]=@ReferredFrom
				,[ReferredFromOther]=@ReferredFromOther
				,[SPO2]=@SPO2
				,[AnyComplaints]=@AnyComplaints
				,[GeneralExamination]=@GeneralExamination
				,[NeonatalHistoryNotes]=@NeonatalHistoryNotes
				,[TBFindings]=@TBFindings
				,[MUAC]=@MUAC
				,[ReviewSystemComments]=@ReviewSystemComments
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @patientid
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[dtl_KNHPMTCTHEI] (
				[Ptn_pk]
				,[LocationID]
				,[Visit_pk]
				--,[TBAssessment]
				--,[Plan]
				--,[PlanRegimen]
				,[ChildReferredFrom]
				,[DeliveryPlaceHEI]
				,[Deliveryotherfacility]
				,[Deliveryother]
				,[ModeofDeliveryHEI]
				,[ChildPEPARVs]
				,[ARVPropOther]
				,[MotherRegisteredClinic]
				,[ANCFollowup]
				,[PlMFollowupother]
				,[MotherReferredtoARV]
				,[StateOfMother]
				,[OnART]
				--,[ImmunisationDate]
				--,[ImmunisationPeriod]
				--,[ImmunisationGiven]
				,[AdditionalComplaint]
				,[Examinations]
				--,[MilestonesPeads]
				,[VitaminA]
				,[WorkPlan]
				,[ReferralPeads]
				,[Referredtoother]
				,[WardAdmissionPead]
				,[TCA]
				,[DeleteFlag]
				,[UserID]
				,[CreateDate]
				,[Scheduled]
				,[DurationARTstart]
				,[ReferredFrom]
				,[ReferredFromOther]
				,[SPO2]
				,[AnyComplaints]
				,[GeneralExamination]
				,[NeonatalHistoryNotes]
				,[TBFindings]
				,[MUAC]
				,[ReviewSystemComments]
				)
			VALUES (
				@patientid
				,@locationid
				,@Visit_ID
				--,@KNHHEIAssessmmentOutcome
				--,@KNHHEIPlan
				--,@KNHHEIPlanRegimen
				,@KNHHEISrRefral
				,@KNHHEIPlDelivery
				,@KNHHEIPlDeliveryotherfacility
				,@KNHHEIPlDeliveryother
				,@KNHHEIMdDelivery
				,@KNHHEIARVProp
				,@KNHHEIARVPropOther
				,@KNHHEIMRegisthisclinic
				,@KNHHEIPlMFollowup
				,@KNHHEIPlMFollowupother
				,@KNHHEIMRecievedDrug
				,@KNHHEIStateofMother
				,@KNHHEIOnARTEnrol
				--,@KNHHEIDateImmunised
				--,@KNHHEIPeriodImmunised
				--,@KNHHEIGivenImmunised
				,@KNHHEIAdditionalComplaint
				,@KNHHEIExamination
				--,@KNHHEIMilestones
				,@KNHHEIVitamgiven
				,@KNHHEIWorkPlan
				,@KNHHEIReferredto
				,@KNHHEIReferredtoother
				,@KNHHEIAdmittoward
				,@KNHHEITCA
				,0
				,@UserId
				,getdate()
				,@Scheduled
				,@DurationARTstart
				,@ReferredFrom
				,@ReferredFromOther
				,@SPO2
				,@AnyComplaints
				,@GeneralExamination
				,@NeonatalHistoryNotes
				,@TBFindings
				,@MUAC
				,@ReviewSystemComments
				)
		END

		IF EXISTS (
				SELECT *
				FROM dtl_PatientVitals
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @patientid
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_PatientVitals
			SET TEMP = Nullif(@KNHHEITemp, '999')
				,RR = Nullif(@KNHHEIRR, '999')
				,HR = Nullif(@KNHHEIHR, '999')
				,Height = Nullif(@KNHHEIHeight, '999')
				,Weight = Nullif(@KNHHEIWeight, '999')
				,BPDiastolic = Nullif(@KNHHEIBPDiastolic, '999')
				,BPSystolic = Nullif(@KNHHEIBPSystolic, '999')
				,Headcircumference = Nullif(@KNHHEIHeadCircum, '999')
				,WeightForAge = Nullif(@KNHHEIWA, '999')
				,WeightForHeight = Nullif(@KNHHEIWH, '999')
				,BMIz = CAST(Nullif(@KNHHEIBMIz, '999') as int)
				,NurseComments = @KNHHEINurseComments
				,UserId = @UserId
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @patientid
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO dtl_PatientVitals (
				ptn_pk
				,Visit_Pk
				,locationId
				,TEMP
				,RR
				,HR
				,Height
				,Weight
				,BPDiastolic
				,BPSystolic
				,Headcircumference
				,WeightForAge
				,WeightForHeight
				,BMIz
				,NurseComments
				,UserId
				,CreateDate
				)
			VALUES (
				@patientid
				,IDENT_CURRENT('ORD_VISIT')
				,@locationid
				,Nullif(@KNHHEITemp, '999')
				,Nullif(@KNHHEIRR, '999')
				,Nullif(@KNHHEIHR, '999')
				,Nullif(@KNHHEIHeight, '999')
				,Nullif(@KNHHEIWeight, '999')
				,Nullif(@KNHHEIBPDiastolic, '999')
				,Nullif(@KNHHEIBPSystolic, '999')
				,Nullif(@KNHHEIHeadCircum, '999')
				,Nullif(@KNHHEIWA, '999')
				,Nullif(@KNHHEIWH, '999')
				,CAST(Nullif(@KNHHEIBMIz, '999') as int)
				,@KNHHEINurseComments
				,@UserId
				,getdate()
				)
		END

		IF EXISTS (
				SELECT *
				FROM dtl_InfantInfo
				WHERE Visit_Pk = @Visit_ID
					AND ptn_pk = @patientid
					AND locationId = @locationid
				)
		BEGIN
			UPDATE dtl_InfantInfo
			SET BirthWeight = Nullif(@KNHHEIBWeight, '999')
				,FeedingOption = @KNHHEIIFeedoption
				,FeedingoptionOther = @KNHHEIIFeedoptionother
			WHERE Visit_Pk = @Visit_ID
				AND ptn_pk = @patientid
				AND locationId = @locationid
		END
		ELSE
		BEGIN
			INSERT INTO dtl_InfantInfo (
				ptn_pk
				,Visit_Pk
				,locationId
				,BirthWeight
				,FeedingOption
				,FeedingoptionOther
				,UserId
				,CreateDate
				)
			VALUES (
				@patientid
				,IDENT_CURRENT('ORD_VISIT')
				,@locationid
				,Nullif(@KNHHEIBWeight, '999')
				,@KNHHEIIFeedoption
				,@KNHHEIIFeedoptionother
				,@UserId
				,getdate()
				)
		END

		DELETE
		FROM dtl_Multiselect_line
		WHERE Ptn_pk = @patientid
			AND Visit_Pk = @Visit_ID

		--DELETE
		--FROM dtl_KNHPMTCTNeonatalHistoryHEI
		--WHERE Ptn_pk = @patientid
		--	AND Visit_Pk = @Visit_ID
		--DELETE
		--FROM dtl_KNHPMTCTMaternalHistoryHEI
		--WHERE Ptn_pk = @patientid
		--	AND Visit_Pk = @Visit_ID
		DELETE
		FROM dtl_KNHPMTCTHEI_GridData
		WHERE Ptn_pk = @patientid
			AND Visit_Pk = @Visit_ID

		SELECT @Visit_ID [VisitId]
	END
	ELSE
	BEGIN
		INSERT INTO ord_Visit (
			Ptn_Pk
			,LocationID
			,VisitDate
			,VisitType
			,TypeofVisit
			,DataQuality
			,DeleteFlag
			,UserID
			,CreateDate
			)
		VALUES (
			@patientid
			,@locationid
			,@KNHHEIVisitDate
			,37
			,@KNHHEIVisitType
			,@dataquality
			,0
			,@UserId
			,getdate()
			)

		INSERT INTO [dbo].[dtl_KNHPMTCTHEI] (
			[Ptn_pk]
			,[LocationID]
			,[Visit_pk]
			--,[TBAssessment]
			--,[Plan]
			--,[PlanRegimen]
			,[ChildReferredFrom]
			,[DeliveryPlaceHEI]
			,[Deliveryotherfacility]
			,[Deliveryother]
			,[ModeofDeliveryHEI]
			,[ChildPEPARVs]
			,[ARVPropOther]
			,[MotherRegisteredClinic]
			,[ANCFollowup]
			,[PlMFollowupother]
			,[MotherReferredtoARV]
			,[StateOfMother]
			,[OnART]
			--,[ImmunisationDate]
			--,[ImmunisationPeriod]
			--,[ImmunisationGiven]
			,[AdditionalComplaint]
			,[Examinations]
			--,[MilestonesPeads]
			,[VitaminA]
			,[WorkPlan]
			,[ReferralPeads]
			,[Referredtoother]
			,[WardAdmissionPead]
			,[TCA]
			,[DeleteFlag]
			,[UserID]
			,[CreateDate]
			)
		VALUES (
			@patientid
			,@locationid
			,IDENT_CURRENT('ORD_VISIT')
			--,@KNHHEIAssessmmentOutcome
			--,@KNHHEIPlan
			--,@KNHHEIPlanRegimen
			,@KNHHEISrRefral
			,@KNHHEIPlDelivery
			,@KNHHEIPlDeliveryotherfacility
			,@KNHHEIPlDeliveryother
			,@KNHHEIMdDelivery
			,@KNHHEIARVProp
			,@KNHHEIARVPropOther
			,@KNHHEIMRegisthisclinic
			,@KNHHEIPlMFollowup
			,@KNHHEIPlMFollowupother
			,@KNHHEIMRecievedDrug
			,@KNHHEIStateofMother
			,@KNHHEIOnARTEnrol
			--,@KNHHEIDateImmunised
			--,@KNHHEIPeriodImmunised
			--,@KNHHEIGivenImmunised
			,@KNHHEIAdditionalComplaint
			,@KNHHEIExamination
			--,@KNHHEIMilestones
			,@KNHHEIVitamgiven
			,@KNHHEIWorkPlan
			,@KNHHEIReferredto
			,@KNHHEIReferredtoother
			,@KNHHEIAdmittoward
			,@KNHHEITCA
			,0
			,@UserId
			,getdate()
			)

		INSERT INTO dtl_PatientVitals (
			ptn_pk
			,Visit_Pk
			,locationId
			,TEMP
			,RR
			,HR
			,Height
			,Weight
			,BPDiastolic
			,BPSystolic
			,Headcircumference
			,WeightForAge
			,WeightForHeight
			,BMIz
			,NurseComments
			,UserId
			,CreateDate
			)
		VALUES (
			@patientid
			,IDENT_CURRENT('ORD_VISIT')
			,@locationid
			,Nullif(@KNHHEITemp, '999')
			,Nullif(@KNHHEIRR, '999')
			,Nullif(@KNHHEIHR, '999')
			,Nullif(@KNHHEIHeight, '999')
			,Nullif(@KNHHEIWeight, '999')
			,Nullif(@KNHHEIBPDiastolic, '999')
			,Nullif(@KNHHEIBPSystolic, '999')
			,Nullif(@KNHHEIHeadCircum, '999')
			,Nullif(@KNHHEIWA, '999')
			,Nullif(@KNHHEIWH, '999')
			,CAST(Nullif(@KNHHEIBMIz, '999') as int)
			,@KNHHEINurseComments
			,@UserId
			,getdate()
			)

		INSERT INTO dtl_InfantInfo (
			ptn_pk
			,Visit_Pk
			,locationId
			,BirthWeight
			,FeedingOption
			,FeedingoptionOther
			,UserId
			,CreateDate
			)
		VALUES (
			@patientid
			,IDENT_CURRENT('ORD_VISIT')
			,@locationid
			,Nullif(@KNHHEIBWeight, '999')
			,@KNHHEIIFeedoption
			,@KNHHEIIFeedoptionother
			,@UserId
			,getdate()
			)

		SELECT IDENT_CURRENT('ORD_VISIT') [VisitId]
	END
END
go
--==

if exists(select * from sysobjects where name='pr_KNHPMTCTHEI_SavecheckedlistItems' and type='p')
	drop proc pr_KNHPMTCTHEI_SavecheckedlistItems
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[pr_KNHPMTCTHEI_SavecheckedlistItems] @patientID INT
	,@ID INT
	,@Visit_ID INT
	,@CodeName VARCHAR(100) = NULL
	,@Numeric INT = NULL
	,@OtherNotes VARCHAR(100) = NULL
	,@UserId INT
AS
SET NOCOUNT ON

BEGIN
	if not exists(select * from dtl_Multiselect_line where Ptn_pk=@patientID and ValueID=@ID and Visit_Pk=@Visit_ID)
	begin
		INSERT INTO dtl_Multiselect_line (
			Ptn_pk
			,ValueID
			,Visit_Pk
			,FieldName
			,NumericField
			,Other_Notes
			,CreateDate
			,UserId
			)
		VALUES (
			@patientID
			,@ID
			,@Visit_ID
			,@CodeName
			,@Numeric
			,@OtherNotes
			,GETDATE()
			,@UserId
			)
	end
END
go
--==