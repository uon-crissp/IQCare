USE [IQCare]
GO

if not exists(select * from mst_Regimen where RegimenName='OI Medicine')
begin
	insert into mst_RegimenLine(Name,DeleteFlag,SRNO,UserID,CreateDate) values('OI', 0,9,1,getdate())

	insert into mst_Regimen(RegimenID, Purpose,RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(76, 223,9,'OI','OI Medicine',0)
	--Add the other codes here
	--PrEP
	--HEbB
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

update mst_module set ModuleName = 'CCC Clinic' where ModuleName='CCC Patient Card MoH 257'
update mst_module set ModuleName = 'TB Clinic' where ModuleName='TB Clinic Module'
update mst_module set ModuleName = 'Records' where ModuleName='RECORDS'
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

