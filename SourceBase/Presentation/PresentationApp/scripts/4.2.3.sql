USE [IQCare]
GO

update AppAdmin set AppVer='4.2.3', DBVer='4.2.3', RelDate='31-Jul-2019'
go

update b set b.moduleId = a.ModuleId
from
(
select a.Ptn_Pk
, (select top 1 ModuleId from Lnk_PatientProgramStart x where x.Ptn_pk=a.Ptn_Pk order by StartDate desc) as ModuleId 
from mst_Patient a
) a
inner join mst_Patient b on a.Ptn_Pk=b.Ptn_Pk
where b.ModuleId is null
go
--==

use IQCare
go

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
		p.PatientEnrollmentId As IQNumber, NullIf(P.PatientClinicID, '''')PatientClinicID, LocationID,
		(select top 1 x.ModuleName from mst_module x where x.moduleid=p.moduleid) as ModuleName, 
		isnull((select top 1 x.ModuleId from mst_module x where x.moduleid=p.moduleid),0) as ModuleId, 
		Case DOBPrecision
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
		And isnull(Convert(varchar(50), decryptbykey(P.MiddleName)),'''') Like  ''''+@MiddleName+''%''
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

create proc pr_SaveRefillEncounterTBScreen
 @ptn_pk int
,@visit_pk int
,@tbfindings int
,@location int
,@userid int

as

begin
	insert into dtl_TBScreening(Ptn_Pk, Visit_Pk, LocationID, UserID, CreateDate,UpdateDate, TBFindings)
	values(@ptn_pk, @visit_pk,@location, @userid, getdate(), getdate(), @tbfindings)
end
go
--==

create proc pr_GetRefillEncounterTBScreen
@visit_pk int

as

begin
	select max(TBFindings) as TBFindings from dtl_TBScreening where Visit_Pk=@visit_pk
	select * from dtl_Multiselect_line where Visit_Pk=@visit_pk and FieldName='TBAssessmentICF'
end
go
--==