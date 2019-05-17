Use IQCare
go

Update mst_module set ModuleName='TB Clinic' where ModuleName='T B'
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

if exists(select * from Lnk_PatientProgramStart where ModuleId=204)
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

if exists(select * from sysobjects where name='pr_Clinical_GetClinicalEncounterVisitID' and type='p')
	drop proc pr_Clinical_GetClinicalEncounterVisitID
go

create proc pr_Clinical_GetClinicalEncounterVisitID @ptn_pk int
as
begin
	select top 1 Visit_Id from ord_Visit where Ptn_Pk=1861 and cast(convert(varchar, VisitDate, 106) as datetime) = cast(convert(varchar, getdate(), 106) as datetime)
	and VisitType=(select top 1 x.VisitTypeID from mst_VisitType x where VisitName ='clinical encounter')
	and isnull(DeleteFlag, 0)= 0
end
go
--==

if not exists(select * from mst_Decode where name='None' and CodeID=1027)
begin
	insert into mst_Decode(Name, CodeID, SRNo,UpdateFlag,DeleteFlag,SystemId)values('None',1027,1,0,0,1)
end
go
--==

if not exists(select * from lnk_GroupFeatures where FeatureID=11 and GroupID=1)
begin
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,11,1)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,11,2)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,11,3)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,11,4)
end
go

if not exists(select * from lnk_GroupFeatures where FeatureID=12 and GroupID=1)
begin
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,12,1)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,12,2)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,12,3)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,12,4)
end
go

if not exists(select * from lnk_GroupFeatures where FeatureID=10 and GroupID=1)
begin
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,10,1)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,10,2)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,10,3)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,10,4)
end
go
if not exists(select * from lnk_GroupFeatures where FeatureID=49 and GroupID=1)
begin
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,49,1)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,49,2)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,49,3)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,49,4)
end
go
if not exists(select * from lnk_GroupFeatures where FeatureID=47 and GroupID=1)
begin
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,47,1)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,47,2)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,47,3)
	insert into lnk_GroupFeatures(FacilityID, ModuleID, TabID, FeatureName, GroupID, FeatureID, FunctionID) values(754,0,0,'',1,47,4)
end
go
--==

update mst_Feature set MultiVisit=1 where FeatureName like '%careend_%'
go
--==

update mst_module set modulename='ART Clinic' where moduleId = 203
update mst_module set modulename='HTS' where moduleId = 5
update mst_module set modulename='ANC, Maternity and Postnatal Clinic' where moduleId = 1
update mst_module set modulename='DCC and PrEP' where moduleId = 8
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Function [dbo].[fn_GetPatientProgramStatus_Constella]                                      
(                                      
@Ptn_Pk int                                      
)                                      
Returns varchar(50)                                      
                                      
begin                                      
--declare @RegistrationDatePMTCT datetime                                       
declare @DispenseDate datetime                                      
declare @LongestDate datetime                                      
--declare @ARTEndDate datetime                               
--declare @RecCount int                                       
--declare @ARTStart int                                
declare @CurrentArvRegimen int                                
declare @CareEnded int         
declare @HIVCarePt int            
--declare @ARTStartDate int       
                               
--declare @ARTReStartDate datetime --Added Naveen 23-Sept-2010                               

declare @PtnMstStatus varchar(100)      
                                       
 --------------------------------Check HIVCare Patient---------------------------------------------------------        
 select @HIVCarePt = Count(Ptn_Pk), @PtnMstStatus = ARTStatus from VW_PatientDetail where ModuleId = 2 and ptn_pk = @Ptn_Pk 
 group by ARTStatus        
 --------------------------------------------------------------------------------------------------------------                                 
 ------------------------------ ARV Dispense + Longest Duration + 90 Days -------------------------------------          
 select @DispenseDate = max(b.dispensedbydate),@LongestDate = dateadd(dd,Max(Duration)+90,b.DispensedByDate)        
 from vw_patientdetail a,vw_patientpharmacy b where a.ptn_pk = b.ptn_pk and a.moduleid = 2 and a.ptn_pk = @Ptn_Pk        
 group by b.dispensedbydate                              
 -------------------------------------------------------------------------------------------------------------                                 
                                
-- ------------------------------ARV End Date------------------------------------------------------------------                                          
-- select top 1 @ARTEndDate = ARTenddate from (select 1 [ExistFlag], ARTended,                                                                         
-- ARTenddate, createdate, CareEndedId from  dtl_PatientCareEnded where ptn_pk=@Ptn_Pk)Z                               
-- order by CareEndedId desc                    
-- ------------------------------------------------------------------------------------------------------------        
--------------------------------ARV Restart Date------------------------------------------------------------------                                          
-- select top 1 @ARTReStartDate = Restartdate from (select 1 [ExistFlag], DeleteFlag,                                                                         
-- Restartdate, createdate, ARTRestart_Id from  dtl_PatientARTRestart where ptn_pk=@Ptn_Pk and (DeleteFlag=0 or DeleteFlag is null))Z                               
-- order by ARTRestart_Id desc                    
-- ------------------------------------------------------------------------------------------------------------                                
                                
-- -----------------------------NONART------------------------------------------------------------------------- 
--
--                               
-- select @ARTStart = count(a.ptn_pk) from VW_PatientDetail a  where (a.artstartdate = '1900-01-01' or a.artstartdate is null) and                                 
-- a.ptn_pk = @ptn_pk and a.moduleid = 2 and a.ptn_pk in ( select b.ptn_pk from VW_PatientCareEnd b   
-- where b.artended in (select  top 1 ARTEnded from VW_PatientCareEnd where artended = 1  and ptn_pk = @Ptn_Pk  order by artenddate desc) and b.ptn_pk = a.ptn_Pk)  
-- and @ARTReStartDate is null                
-- ------------------------------------------------------------------------------------------------------------                                
 -----------------------------CareEnd-------------------------------------------------------------------------                                
 select top 1 @CareEnded = CareEnded from VW_PatientCareEnd where (CareEnded is not null or CareEnded <> 0)        
 and  ptn_pk = @ptn_pk order by CareEndedId desc                
 ------------------------------------------------------------------------------------------------------------                                
 ---------------------------------------------Prior Exposure-Transfer in----------------------------------------------------------------                                
 select @CurrentArvRegimen=Count(ptn_pk) from dtl_PatientHivPrevCareEnrollment where PrevHivCare=265 and ptn_pk=@ptn_pk                                
 ----------------------------------------------------------------------------------------------------------------------                                
        
if(@HIVCarePt<1)        
  begin        
    Return ''        
  end                      
if (@CareEnded>0)                                
  begin                                
    Return 'Care Ended'                                
  end                                       
                                
if(@PtnMstStatus = 'Non ART' )                                    
  begin                                
       Return 'Non-ART'                                      
  end                                 
                                   
if (@PtnMstStatus = 'ART' and @LongestDate >= getdate())                                 
   begin                                
        Return 'ART'                                      
   end                                      
                                
if(((@LongestDate < getdate()) or (@LongestDate= '' or @LongestDate is null))or @CurrentArvRegimen >0 )                                
   begin                                
        Return 'Due for Termination'                                 
   end                                
                                
if (@PtnMstStatus = 'ART Stopped')                                     
  begin                                      
    Return 'Stopped ART'                                       
  end       
                             
Return ''                                      
end
go
--==

truncate table mst_regimenline
go
truncate table mst_regimen
go

INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (1, N'222', 1, N'AF4B', N'ABC + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (2, N'222', 1, N'AF4A', N'ABC + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (3, N'222', 1, N'AF1B', N'AZT + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (4, N'222', 1, N'AF1A', N'AZT + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (5, N'222', 1, N'AF3B', N'd4T + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (6, N'222', 1, N'AF3A', N'd4T + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (7, N'222', 1, N'AF2B', N'TDF + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (8, N'222', 1, N'AF2A', N'TDF + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (9, N'222', 1, N'AF5X', N'other Adult 1st line', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (10, N'222', 3, N'AS5B', N'ABC + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (11, N'222', 3, N'AS5A', N'ABC + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (12, N'222', 3, N'AS1B', N'AZT + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (13, N'222', 3, N'AS1A', N'AZT + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (14, N'222', 3, N'AS2C', N'TDF + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (15, N'222', 3, N'AS2A', N'TDF + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (16, N'222', 3, N'AS6X', N'other Adult 2nd line', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (17, N'222', 5, N'AT2A', N'ETV + 3TC + DRV + RTV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (18, N'222', 5, N'AT1A', N'RAL + 3TC + DRV + RTV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (19, N'222', 5, N'AT1B', N'RAL + 3TC + DRV + RTV + AZT', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (20, N'222', 5, N'AT1C', N'RAL + 3TC + DRV + RTV + TDF', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (21, N'222', 5, N'AT2X', N'other Adult 3rd line', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (22, N'222', 1, N'CF2E', N'ABC + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (23, N'222', 1, N'CF2B', N'ABC + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (24, N'222', 1, N'CF2D', N'ABC + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (25, N'222', 1, N'CF2A', N'ABC + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (26, N'222', 1, N'CF1D', N'AZT + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (27, N'222', 1, N'CF1B', N'AZT + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (28, N'222', 1, N'CF1C', N'AZT + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (29, N'222', 1, N'CF1A', N'AZT + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (30, N'222', 1, N'CF3B', N'd4T + 3TC + EFV for children weighing >=  25kg', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (31, N'222', 1, N'CF3A', N'd4T + 3TC + NVP for children weighing >=  25kg', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (32, N'222', 1, N'CF4D', N'TDF + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (33, N'222', 1, N'CF4B', N'TDF + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (34, N'222', 1, N'CF4C', N'TDF + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (35, N'222', 1, N'CF4A', N'TDF + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (36, N'222', 1, N'CF5X', N'other Paediatric 1st line', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (37, N'222', 3, N'CS2C', N'ABC + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (38, N'222', 3, N'CS2A', N'ABC + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (39, N'222', 3, N'CS1B', N'AZT + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (40, N'222', 3, N'CS1A', N'AZT + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (41, N'222', 3, N'CS4X', N'other Paediatric 2nd line', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (42, N'222', 5, N'CT2A', N'ETV + 3TC + DRV + RTV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (43, N'222', 5, N'CT1A', N'RAL + 3TC + DRV + RTV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (44, N'222', 5, N'CT1C', N'RAL + 3TC + DRV + RTV + ABC', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (45, N'222', 5, N'CT1B', N'RAL + 3TC + DRV + RTV + AZT', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (46, N'222', 5, N'CT3X', N'other Paediatric 3rd line', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (47, N'224', 6, N'PA4X', N'other PEP regimens - Adults', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (48, N'224', 6, N'PA1C', N'AZT + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (49, N'224', 6, N'PA1B', N'AZT + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (50, N'224', 6, N'PA3C', N'TDF + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (51, N'224', 6, N'PA3B', N'TDF + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (52, N'224', 6, N'PC3A', N'ABC + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (53, N'224', 6, N'PC4X', N'other PEP regimens - Children', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (54, N'224', 6, N'PC1A', N'AZT + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (55, N'223', 7, N'PM1X', N'other PMTCT regimens - Women', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (56, N'223', 7, N'PM10', N'AZT + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (57, N'223', 7, N'PM4', N'AZT + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (58, N'223', 7, N'PM5', N'AZT + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (59, N'223', 7, N'PM3', N'AZT + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (60, N'223', 7, N'PM1', N'AZT from 14Wks to Delivery + NVP stat + AZT stat + 3TC BD during labour; then AZT/3TC 1 Wk post-partum', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (61, N'223', 7, N'PM2', N'NVP stat + AZT stat + 3TC BD during labour; then AZT/3TC 1wk post-partum', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (62, N'223', 7, N'PM11', N'TDF + 3TC + ATV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (63, N'223', 7, N'PM9', N'TDF + 3TC + EFV', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (64, N'223', 7, N'PM7', N'TDF + 3TC + LPV/r', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (65, N'223', 7, N'PM6', N'TDF + 3TC + NVP', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (66, N'223', 7, N'PC5', N'3TC Liquid BD', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (67, N'223', 7, N'PC1X', N'other PMTCT regimens - Infants', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (68, N'223', 7, N'PC4', N'AZT Liquid BD for 6 weeks ', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (69, N'223', 7, N'PC6', N'NVP Liquid OD for 12 weeks ', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (70, N'223', 7, N'PC2', N'NVP OD for Breastfeeding Infants until 1 week after complete cessation of Breastfeeding ', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (71, N'223', 7, N'PC1', N'NVP OD up to 6 weeks of age ', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (72, N'222', 1, N'AF2E', N'TDF + 3TC + DTG', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (73, N'222', 1, N'AF1D', N'AZT + 3TC + DTG', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (74, N'222', 1, N'AF4C', N'ABC + 3TC + DTG', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (75, N'222', 3, N'AS6X', N'TDF + 3TC + DTG', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (76, N'223', 9, N'OI', N'OI Medicine', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (76, N'223', 9, N'HPB1A', N'TDF + 3TC (HIV  -ve HepB patients)', 0)
GO
INSERT [dbo].[mst_Regimen] ([RegimenID], [Purpose], [RegimenLineID], [RegimenCode], [RegimenName], [DeleteFlag]) VALUES (76, N'223', 9, N'PRP1A', N'TDF + FTC (PrEP)', 0)
GO
SET IDENTITY_INSERT [dbo].[mst_RegimenLine] ON 

GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (1, N'First line', 0, 1, NULL, 1, CAST(N'2011-08-19 12:00:10.000' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (2, N'First line substitute', 1, 2, NULL, 1, CAST(N'2011-08-19 12:00:10.000' AS DateTime), CAST(N'2017-09-18 16:26:09.677' AS DateTime))
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (3, N'Second line', 0, 3, NULL, 1, CAST(N'2011-08-19 12:00:10.000' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (4, N'Second line substitute', 1, 4, NULL, 1, CAST(N'2011-08-19 12:00:10.000' AS DateTime), CAST(N'2017-09-18 16:26:09.677' AS DateTime))
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (5, N'Third line', 0, 5, NULL, 1, CAST(N'2011-08-19 12:00:10.000' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (6, N'PEP', 0, 6, NULL, 1, CAST(N'2016-01-31 09:16:33.987' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (7, N'PMTCT', 0, 7, NULL, 1, CAST(N'2016-01-31 09:16:33.987' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (8, N'PrEP', 0, 8, NULL, 1, CAST(N'2017-09-18 16:26:09.687' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (9, N'OI', 0, 9, NULL, 1, CAST(N'2019-05-02 05:51:48.260' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (10, N'HBB', 0, 9, NULL, 1, CAST(N'2019-05-02 05:51:48.260' AS DateTime), NULL)
GO
INSERT [dbo].[mst_RegimenLine] ([ID], [Name], [DeleteFlag], [SRNO], [UpdateFlag], [UserID], [CreateDate], [UpdateDate]) VALUES (11, N'PREP', 0, 9, NULL, 1, CAST(N'2019-05-02 05:51:48.260' AS DateTime), NULL)
GO
SET IDENTITY_INSERT [dbo].[mst_RegimenLine] OFF
GO
--==

if not exists(select * from mst_BlueDecode where name='N/A or None' and CodeID=11)
	insert into mst_BlueDecode(name, CodeID, SRNo, UpdateFlag, DeleteFlag, SystemId) values('N/A or None', 11, 10,0,0,1)
go
--==

if not exists(select * from mst_Decode where name='Hypertension' and CodeID=1096)
	insert into mst_Decode(name, CodeID, SRNo, UpdateFlag, DeleteFlag, SystemId) values('Hypertension', 1096, 10,0,0,1)
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Clinical_SaveKNHMEIPregPregnancies_Futures]
	-- Add the parameters for the stored procedure here                                                                  
	@patientid INT = NULL
	,@Visit_ID INT = NULL
	,@YearofBaby INT = NULL
	,@PlaceOfDelivery VARCHAR(300) = NULL
	,@Maturity INT = NULL
	,@LabourHour DECIMAL(18, 2) = NULL
	,@ModeOfDelivery INT = NULL
	,@Gender INT = NULL
	,@Fate INT = NULL
	,@UserId INT = NULL
	,@BirthWeight decimal(5,3) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.                                              
	SET NOCOUNT ON;

	IF EXISTS (
			SELECT TOP 1 *
			FROM dtl_PatientKNHPMTCTMEIPrevPregnancies
			WHERE [ptn_pk] = @patientid
				AND [visit_Pk] = @Visit_ID
				AND [YearofBaby] = @YearofBaby
				AND [PlaceOfDelivery] = @PlaceOfDelivery
				AND [Maturity] = @Maturity
				AND [ModeOfDelivery] = @ModeOfDelivery
				AND [LabourHour] = @LabourHour
				AND [Gender] = @Gender
				AND [Fate] = @Fate
				AND BirthWeight= @BirthWeight
			)
	BEGIN
		DELETE
		FROM dtl_PatientKNHPMTCTMEIPrevPregnancies
		WHERE [ptn_pk] = @patientid
			AND [visit_Pk] = @Visit_ID
			AND [YearofBaby] = @YearofBaby
			AND [PlaceOfDelivery] = @PlaceOfDelivery
			AND [Maturity] = @Maturity
			AND [ModeOfDelivery] = @ModeOfDelivery
			AND [LabourHour] = @LabourHour
			AND [Gender] = @Gender
			AND [Fate] = @Fate
			AND BirthWeight= @BirthWeight
	END

	INSERT INTO [dbo].[dtl_PatientKNHPMTCTMEIPrevPregnancies] (
		[ptn_pk]
		,[visit_Pk]
		,[YearofBaby]
		,[PlaceOfDelivery]
		,[Maturity]
		,[UserId]
		,[CreateDate]
		,[UpdateDate]
		,[ModeOfDelivery]
		,[LabourHour]
		,[Gender]
		,[Fate]
		,BirthWeight
		)
	VALUES (
		@patientid
		,@Visit_ID
		,@YearofBaby
		,@PlaceOfDelivery
		,@Maturity
		,@UserId
		,GETDATE()
		,GetDate()
		,@ModeOfDelivery
		,@LabourHour
		,@Gender
		,@Fate
		,@BirthWeight
		)
END
go
--==

if not exists(select * from mst_Code where name='KeyPopulation')
	insert into mst_Code(Name, DeleteFlag, UserID, CreateDate,UpdateDate) values('KeyPopulation',0,1,getdate(),getdate())
go

if not exists(select * from mst_Decode where name='Men Who have Sex with Men (MSM)')
begin
	insert into mst_Decode(name, CodeID, SRNo, UpdateFlag, DeleteFlag, SystemId) values('Men Who have Sex with Men (MSM)',(select top 1 CodeID from mst_Code where Name='KeyPopulation'), 10,0,0,1)
	insert into mst_Decode(name, CodeID, SRNo, UpdateFlag, DeleteFlag, SystemId) values('Female Sex Worker (FSW)',(select top 1 CodeID from mst_Code where Name='KeyPopulation'), 10,0,0,1)
	insert into mst_Decode(name, CodeID, SRNo, UpdateFlag, DeleteFlag, SystemId) values('People Who Inject Drugs (PWID)',(select top 1 CodeID from mst_Code where Name='KeyPopulation'), 10,0,0,1)
end
go
--==


select * from mst_Code where name='KeyPopulation'