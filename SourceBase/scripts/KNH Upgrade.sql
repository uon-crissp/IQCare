Use IQCare
go

Update mst_module set ModuleName='KNH TB Clinic' where ModuleName='T B'
go

delete from mst_module where ModuleName='TB Module'
go

if not exists(select * from lnk_SplFormModule where ModuleId=203 and FeatureId>1000)
begin
	insert into lnk_SplFormModule(FeatureId, ModuleId,UserId,CreateDate)
	select FeatureId, 203, 1, getdate() from lnk_SplFormModule where ModuleId=204 and FeatureId>1000
end
go
--==

update mst_Feature set Published=2, CountryId=161 where FeatureName ='Clinical Encounter'
go

delete from Mst_FormBuilderTab where TabID < 1000 and FeatureID=295
go

if not exists(select * from Mst_FormBuilderTab where TabName='HIVCETriage')
begin
	set identity_insert Mst_FormBuilderTab on
	insert into Mst_FormBuilderTab(TabID,TabName,FeatureID,DeleteFlag,UserID,CreateDate,seq,Signature) values(1242, 'HIVCETriage', 295,0,1,getdate(),1,1)
	insert into Mst_FormBuilderTab(TabID,TabName,FeatureID,DeleteFlag,UserID,CreateDate,seq,Signature) values(1243, 'PresentingComplaints', 295,0,1,getdate(),2,1)
	insert into Mst_FormBuilderTab(TabID,TabName,FeatureID,DeleteFlag,UserID,CreateDate,seq,Signature) values(1244, 'AddtionalHx', 295,0,1,getdate(),3,1)
	insert into Mst_FormBuilderTab(TabID,TabName,FeatureID,DeleteFlag,UserID,CreateDate,seq,Signature) values(1245, 'Screening', 295,0,1,getdate(),4,1)
	insert into Mst_FormBuilderTab(TabID,TabName,FeatureID,DeleteFlag,UserID,CreateDate,seq,Signature) values(1246, 'SystemicReview', 295,0,1,getdate(),5,1)
	insert into Mst_FormBuilderTab(TabID,TabName,FeatureID,DeleteFlag,UserID,CreateDate,seq,Signature) values(1247, 'Management', 295,0,1,getdate(),6,1)
	set identity_insert Mst_FormBuilderTab off
end
go

if not exists(select * from lnk_GroupFeatures where FeatureID=295 and TabID=1242)
begin
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1242,1,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1243,1,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1244,1,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1245,1,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1246,1,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1247,1,getdate())

	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1242,2,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1243,2,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1244,2,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1245,2,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1246,2,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1247,2,getdate())

	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1242,3,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1243,3,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1244,3,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1245,3,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1246,3,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1247,3,getdate())

	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1242,4,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1243,4,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1244,4,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1245,4,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1246,4,getdate())

	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1242,5,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1243,5,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1244,5,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1245,5,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1246,5,getdate())
	insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)values (0,0,1,295,'',1247,5,getdate())
end
go

insert into lnk_GroupFeatures(facilityid,moduleid,groupid,featureID,featureName,TabId,FunctionID,createdate)
select 754, 203, GroupID, 295, '', 1242, 1, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1243, 1, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1244, 1, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1245, 1, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1246, 1, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1247, 1, getdate() from mst_Groups

union
select 754, 203, GroupID, 295, '', 1242, 2, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1243, 2, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1244, 2, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1245, 2, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1246, 2, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1247, 2, getdate() from mst_Groups

union
select 754, 203, GroupID, 295, '', 1242, 3, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1243, 3, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1244, 3, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1245, 3, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1246, 3, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1247, 3, getdate() from mst_Groups

union
select 754, 203, GroupID, 295, '', 1242, 4, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1243, 4, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1244, 4, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1245, 4, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1246, 4, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1247, 4, getdate() from mst_Groups

union
select 754, 203, GroupID, 295, '', 1242, 5, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1243, 5, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1244, 5, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1245, 5, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1246, 5, getdate() from mst_Groups
union
select 754, 203, GroupID, 295, '', 1247, 5, getdate() from mst_Groups
go
--==

insert into lnk_FormTabSection(TabID, SectionID, FeatureID, UserID, CreateDate) values(1242, 1, 295, 1, getdate())
insert into lnk_FormTabSection(TabID, SectionID, FeatureID, UserID, CreateDate) values(1243, 1, 295, 1, getdate())
insert into lnk_FormTabSection(TabID, SectionID, FeatureID, UserID, CreateDate) values(1244, 1, 295, 1, getdate())
insert into lnk_FormTabSection(TabID, SectionID, FeatureID, UserID, CreateDate) values(1245, 1, 295, 1, getdate())
insert into lnk_FormTabSection(TabID, SectionID, FeatureID, UserID, CreateDate) values(1246, 1, 295, 1, getdate())
insert into lnk_FormTabSection(TabID, SectionID, FeatureID, UserID, CreateDate) values(1247, 1, 295, 1, getdate())
go
--==

update mst_Facility set FacilityName='Kenyatta National Hospital' where FacilityID=754
go

update mst_Facility set DeleteFlag=1 where FacilityID <> 754
go
--==

exec sp_msforeachtable 'ALTER TABLE ? DISABLE TRIGGER all'
go
exec sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'
go

declare @colname varchar(200)
declare @tablename varchar(200)
declare @sql varchar(2000)

Declare @c as cursor
Set @c = cursor for
select distinct a.name, b.name from syscolumns a 
inner join sysobjects b on a.id=b.id where b.type='U' and a.name='LocationId'
order by b.name
open @c
fetch next from @c into @colname, @tablename
while @@FETCH_STATUS = 0
Begin
	print('updating table ['+@tablename+'] ...')
	set @sql = 'update ['+@tablename+'] set locationId=754'
	exec(@sql)

	fetch next from @c into @colname, @tablename
End
close @c
deallocate @c
go

delete from lnk_GroupFeatures where FacilityID <> 754
delete from lnk_FacilityModule where FacilityID <> 754
go

update Lnk_FacilityStore set FacilityID=754
update mst_LabSpecimen set FacilityID=754
go

sp_msforeachtable 'ALTER TABLE ? ENABLE TRIGGER all'
go
exec sp_msforeachtable 'ALTER TABLE ? CHECK CONSTRAINT all'
go
--==

---insert a location of 754 for each patient who does not have 754. Then delete all the other locations
--update dtl_urbanResidence set LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_ruralResidence where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_ruralResidence x where x.LocationID<>754)
--delete from dtl_PatientVitals where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_patientInterviewer where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_PatientHouseHoldInfo where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_PatientHivPrevCareEnrollment where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_patientGuarantor where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_patientDeposits where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_PatientContacts where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--delete from dtl_PatientClinicalStatus where LocationID=754 and ptn_pk in (select x.ptn_pk from dtl_urbanResidence x where x.LocationID<>754)
--go

delete from Lnk_PatientProgramStart where ModuleId=203
go

delete from lnk_SplFormModule where ModuleId=203 and FeatureId in (select x.FeatureId from lnk_SplFormModule x where x.ModuleId=204)
go

update app_SystemLabels set Moduleid=203 where ModuleId=204
update dtl_Bill set Moduleid=203 where ModuleId=204
update dtl_PatientItemsOrder set Moduleid=203 where ModuleId=204
update dtl_PatientTrackingCare set Moduleid=203 where ModuleId=204
update dtl_WaitingList set Moduleid=203 where ModuleId=204
update lnk_FacilityModule set Moduleid=203 where ModuleId=204
update lnk_GroupFeatures set Moduleid=203 where ModuleId=204
update Lnk_ModuleDeathreason set Moduleid=203 where ModuleId=204
update lnk_PatientModuleIdentifier set Moduleid=203 where ModuleId=204
update Lnk_PatientProgramStart set Moduleid=203 where ModuleId=204
update Lnk_PatientReEnrollment set Moduleid=203 where ModuleId=204
update lnk_ServiceBusinessRule set Moduleid=203 where ModuleId=204
update lnk_SplFormModule set Moduleid=203 where ModuleId=204
update lnk_VisitAuditTrail set Moduleid=203 where ModuleId=204
update lnkModule_DiseaseICDCode set Moduleid=203 where ModuleId=204
update mst_BlueCode set Moduleid=203 where ModuleId=204
update mst_CustomReportsFieldGroup set Moduleid=203 where ModuleId=204
update mst_CustomReportsFields set Moduleid=203 where ModuleId=204
update mst_Decode set Moduleid=203 where ModuleId=204
update mst_Feature set Moduleid=203 where ModuleId=204
update Mst_PreDefinedFields set Moduleid=203 where ModuleId=204
update ord_Visit set Moduleid=203 where ModuleId=204
go

delete from lnk_PatientModuleIdentifier where ModuleID=203 and FieldID=1
go

create nonclustered index ix__lnk_PatientProgramStart__ModuleId on Lnk_PatientProgramStart (ModuleId) include(StartDate)
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
			SELECT @Identifiers = ' AND (' + Replace(@SS, ',', ' like ''%' + @enrollmentid + ''' or ') + ' like ''%' + @enrollmentid + ''' or P.IQNumber like ''%' + @enrollmentid + ''')';
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
					THEN 'And ((DATEDIFF(YYYY,P.DOB,GETDATE()) > 12 and P.Sex <> 16) OR (DATEDIFF(YYYY,P.DOB,GETDATE()) <= 2 ))'
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
		SELECT @StatusStr = ' AND ( @Status IS NULL	OR 	ISNULL(CT.PatientCareEndStatus,0) = CASE @Status  WHEN 0 THEN 0  WHEN 1 THEN 1  END )';
	END
	ELSE
	BEGIN
		SET @PMTCT = '';
	END
	SET @Query = N'
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
    	And Case When @FirstName Is  Null Or Convert(varchar(50), decryptbykey(P.FirstName)) Like  ''''+@Firstname+''%'' Then 1
		Else 0 End = 1
		And Case When @LastName Is  Null Or Convert(varchar(50), decryptbykey(P.LastName)) Like  ''''+@LastName+''%'' Then 1
		Else 0 End = 1
		And Case When @MiddleName Is  Null Or Convert(varchar(50), decryptbykey(P.MiddleName)) Like  ''''+@MiddleName+''%'' Then 1
		Else 0 End = 1
		And (@DOB Is Null Or P.DOB = @DOB)
		And (@RegistrationDate Is Null Or P.RegistrationDate= @RegistrationDate)
		And (@Sex Is Null Or P.Sex = @Sex)' + @StatusStr + @FacilityStr + @Identifiers + ' Order By P.RegistrationDate desc';
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
	SET @SymKey = 'Open symmetric key Key_CTC decryption by password=' + @Password;
	PRINT @Query
	EXEC sp_executesql @SymKey;
	EXEC sp_Executesql @Query
		,@ParamDefinition
		,@Sex
		,@Firstname
		,@LastName
		,@MiddleName
		,@DOB
		,@RegistrationDate
		,@EnrollmentID
		,@FacilityID
		,@status
		,@password
		,@moduleId
		,@top;
	CLOSE symmetric KEY Key_CTC
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
	select * from lnk_SplFormModule where moduleid= @ModuleId and (featureid= @FeatureId or @FeatureId=0)                                                                       
End
go
--==