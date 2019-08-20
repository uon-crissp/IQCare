USE [IQCare]
GO

update AppAdmin set AppVer='4.2.2', DBVer='4.2.2', RelDate='30-Jun-2019'
go

update b set b.RegimenId=a.RegimenId
from dtl_RegimenMap a
inner join ord_PatientPharmacyOrder b on a.Visit_Pk=b.VisitID
where a.RegimenId is not null and b.RegimenId is null
go

alter table mst_patient add ModuleId int
go

update b set b.moduleId = a.ModuleId
from
(
select a.Ptn_Pk
, (select top 1 ModuleId from Lnk_PatientProgramStart x where x.Ptn_pk=a.Ptn_Pk order by StartDate desc) as ModuleId 
from mst_Patient a
) a
inner join mst_Patient b on a.Ptn_Pk=b.Ptn_Pk
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

truncate table dtl_PatientTransfer
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[pr_Clinical_PatientSatelliteDetails_Constella]                                      
@PatientId varchar(15),                                      
@TransferId varchar(10),    
@SystemId varchar(10),      
@password varchar(50),          
@Flag int                                 
as        
Begin                                   
	Declare @SymKey varchar(400)                  
	Set @SymKey = 'Open symmetric key Key_CTC decryption by password='+ @password + ''                      
	exec(@SymKey)      
               
	--0           
	select 
	(select top 1 x.ModuleName from mst_module x where x.ModuleID=a.ModuleId) [CurrentSatName],         
	a.PatientEnrollmentId [PatientID],       
	(convert(varchar(50), decryptbykey(a.firstname))+' '+                              
	ISNULL(convert(varchar(50), decryptbykey(a.MiddleName)),'') + ' '+                               
	convert(varchar(50), decryptbykey(a.lastName)))PatientName,        
	a.PatientClinicID from mst_patient a where a.ptn_pk=@PatientId                                   
          
	--1                                      
	select ModuleID [ID], ModuleName [Name], DeleteFlag from mst_module where deleteflag=0
	and ModuleName not in ('Laboratory', 'Pharmacy Dispense', 'Pharmacy', 'Records') 
                            
	--2                          
	select a.ID
	, (select top 1 x.ModuleName from mst_module x where x.ModuleID=a.TransferredFromID) [TransferfromSatellite]                
	, (select top 1 x.ModuleName from mst_module x where x.ModuleID=a.TransferredToID) [TransfertoSatellite],                  
	CONVERT(varchar(12), a.TransferredDate, 106) [TransferredDate]                               
	from dtl_PatientTransfer a             
	where a.Ptn_pk=@PatientId order by a.ID desc                         
       
	Close symmetric key Key_CTC                             
End
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Procedure [dbo].[pr_Clinical_PatientSatelliteTransferSaveUpdate_Constella]                        
@ID int, @PatientId varchar(15), @TransferfromId varchar(15),                    
@TransfertoId varchar(15), @TransfertoDate varchar(40), @UserId varchar(15),                     
@Createdate varchar(50), @Flag int                    
as                        
Begin                                     
	Insert into dtl_PatientTransfer                     
	(Ptn_pk, TransferredFromID, TransferredtoID, TransferredDate, UserID, CreateDate)                    
	values(@PatientId, @TransferfromId, @TransfertoId, @TransfertoDate, @UserId, getdate()) 
	
	update mst_Patient set ModuleId = @TransfertoId where Ptn_Pk=@PatientId 
End
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_FormBuilder_SaveCustomFormData_Futures]           
       
@Query varchar(5000),  
@PatientId int,  
@CareEndedDate datetime            
          
AS          
BEGIN          
 if exists(select * from Dtl_PatientCareEnded where Ptn_Pk=@PatientId and CareEndedDate=@CareEndedDate)                          
 begin
	delete from dtl_PatientCareEnded where Ptn_Pk=@PatientId and CareEndedDate=@CareEndedDate
 end      
       
Exec (@Query)    
        
END
go
--==

if exists(select * from sysobjects where name='pr_clinical_LoadKNHPMTCTHEI_PrepopulateData' and type='p')
	drop proc pr_clinical_LoadKNHPMTCTHEI_PrepopulateData
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[pr_clinical_LoadKNHPMTCTHEI_PrepopulateData] @ptn_pk int
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

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[pr_Admin_GetCustomFormId]
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
		and a.FeatureID > 1000
		order by a.FeatureID desc
	end
end
go
--==

update mst_module set DeleteFlag=1 where ModuleName in
(
'HIVCARE-STATICFORM',
'SMART ART FORM',
'TB Module',
'PM/SCM',
'HIV Care/ART Card (UG)',
'KNH SMART ART FORMS',
'Paediatric ART',
'Family Planning module',
'Records',
'NIGERIA ART CARE',
'Discordant Couples Clinic',
'Laboratory'
)
go
--==

update b set b.ARTStartDate=a.StartARTDate
from iqtools.dbo.tmp_ARTPatients a
inner join mst_patient b on a.PatientPK=b.Ptn_Pk
where a.StartARTDate<>b.ARTStartDate
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Clinical_SaveUpdate_IPTDetails] (
	@Ptn_pk INT = NULL
	,@Visit_Pk INT = NULL
	,@INHStartDate VARCHAR(30) = NULL
	,@INHEndDate VARCHAR(30) = NULL
	)
AS
BEGIN
	IF EXISTS (
			SELECT 1
			FROM dtl_TBScreening
			WHERE ptn_pk = @Ptn_pk
				AND Visit_Pk = @Visit_Pk
			)
	BEGIN
		print('A') --This update has been done to avoid overwiting of IPT dates

		--UPDATE dtl_TBScreening
		--SET INHStartDate = CONVERT(DATETIME, @INHStartDate, 103)
		--	,INHEndDate = CONVERT(DATETIME, @INHEndDate, 103)
		--WHERE ptn_pk = @Ptn_pk
			--AND visit_pk = @Visit_Pk
	END
END
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Pr_HIVCE_GetClinicalEncounter] @Ptn_pk INT
	,@Visit_Id INT
	,@LocationId INT
AS
BEGIN
	DECLARE @DOB INT;
	SELECT @DOB = DATEDIFF(YEAR, DOB, GETDATE()) - (
			CASE 
				WHEN DATEADD(YY, DATEDIFF(YEAR, DOB, GETDATE()), DOB) > GETDATE()
					THEN 1
				ELSE 0
				END
			)
	FROM [mst_Patient]
	WHERE Ptn_Pk = @Ptn_pk;
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Visit Type 0
	SELECT c.CodeId
		,c.NAME AS VisitType
		,d.id
		,d.NAME
	FROM Mst_PMTCTcode c
	INNER JOIN Mst_PMTCTDecode d ON c.codeid = d.codeid
	WHERE c.NAME = 'FieldVisitType'
		AND d.NAME NOT LIKE '%ANC%'
	-- Contact Relation 1
	SELECT c.codeid
		,c.NAME AS ContactRelation
		,d.id
		,d.NAME
	FROM mst_code c
	INNER JOIN mst_decode d ON c.codeid = d.codeid
	WHERE c.codeid = 8
		AND d.deleteflag = 0
		AND d.systemid = 0
	ORDER BY d.srno;
	-- District 2
	SELECT DISTINCT C.CountryId as Id
		,Countryname as NAME
		,SrNo
	FROM [mst_Countries] C
	Inner join Mst_LPTF L on C.countryId = L.countryId
	WHERE DeleteFlag = 0
	--and Systemid=1 
	ORDER BY SRNO;
	-- Facility 3
	SELECT DISTINCT Id
		,NAME
		,SrNo
		,MFLCode
		,L.CountryId
		,C.CountryName
	FROM Mst_LPTF L
	Inner Join [mst_Countries] C On L.countryid = C.countryid
	WHERE DeleteFlag = 0
	and MFLCode is not null
	and Systemid=1 
	ORDER BY SRNO;
	-- 4
	SELECT Visit_Id
		,Ptn_Pk
		,LocationID
		,visitdate
		,visittype
		,CreateDate
		,updatedate
		,TypeOfVisit
		,Signature
	FROM ord_visit
	WHERE visit_id = @Visit_Id
		AND Ptn_Pk = @Ptn_pk
		AND LocationId = @LocationId;
	-- 5
	IF (@Visit_Id = 0)
	BEGIN
		IF (@DOB < 12)
		BEGIN
			/*Paediatric Visit Details*/
			SELECT TOP 1 Id
				,Ptn_Pk
				,Visit_Pk
				,LocationId
				,CONVERT(VARCHAR(10), HIVSupportgroup) AS HIVSupportgroup
				,CONVERT(VARCHAR(10), HIVSupportGroupMembership) AS HIVSupportGroupMembership
				,CONVERT(VARCHAR(10), Menarche) AS Menarche
				,CONVERT(VARCHAR(10), AccompaniedByCaregiver) AS AccompaniedByCaregiver
				,CONVERT(VARCHAR(10), ChildAccompaniedBy) AS CaregiverRelationship
			FROM DTL_Paediatric_Initial_Evaluation_Form
			WHERE Ptn_Pk = @Ptn_pk
				AND LocationId = @LocationId
			ORDER BY ID DESC;
		END
		ELSE
		BEGIN
			/*Adult Visit Details*/
			SELECT TOP 1 Id
				,Ptn_Pk
				,Visit_Pk
				,LocationId
				,CONVERT(VARCHAR(10), HIVSupportgroup) AS HIVSupportgroup
				,CONVERT(VARCHAR(10), HIVSupportGroupMembership) AS HIVSupportGroupMembership
				,CONVERT(VARCHAR(10), Menarche) AS Menarche
				,CONVERT(VARCHAR(10), ChildAccompaniedByCaregiver) AS AccompaniedByCaregiver
				,CONVERT(VARCHAR(10), TreatmentSupporterRelationship) AS CaregiverRelationship
			FROM DTL_Adult_Initial_Evaluation_Form
			WHERE Ptn_Pk = @Ptn_pk
				AND LocationId = @LocationId
			ORDER BY ID DESC;
		END
	END
	ELSE
	BEGIN
		IF (@DOB < 12)
		BEGIN
			/*Paediatric Visit Details*/
			SELECT Id
				,Ptn_Pk
				,Visit_Pk
				,LocationId
				,CONVERT(VARCHAR(10), HIVSupportgroup) AS HIVSupportgroup
				,CONVERT(VARCHAR(10), HIVSupportGroupMembership) AS HIVSupportGroupMembership
				,CONVERT(VARCHAR(10), Menarche) AS Menarche
				,CONVERT(VARCHAR(10), AccompaniedByCaregiver) AS AccompaniedByCaregiver
				,CONVERT(VARCHAR(10), ChildAccompaniedBy) AS CaregiverRelationship
			FROM DTL_Paediatric_Initial_Evaluation_Form
			WHERE visit_pk = @Visit_Id
				AND Ptn_Pk = @Ptn_pk
				AND LocationId = @LocationId;
		END
		ELSE
		BEGIN
			/*Adult Visit Details*/
			SELECT Id
				,Ptn_Pk
				,Visit_Pk
				,LocationId
				,CONVERT(VARCHAR(10), HIVSupportgroup) AS HIVSupportgroup
				,CONVERT(VARCHAR(10), HIVSupportGroupMembership) AS HIVSupportGroupMembership
				,CONVERT(VARCHAR(10), Menarche) AS Menarche
				,CONVERT(VARCHAR(10), ChildAccompaniedByCaregiver) AS AccompaniedByCaregiver
				,CONVERT(VARCHAR(10), TreatmentSupporterRelationship) AS CaregiverRelationship
			FROM DTL_Adult_Initial_Evaluation_Form
			WHERE visit_pk = @Visit_Id
				AND Ptn_Pk = @Ptn_pk
				AND LocationId = @LocationId;
		END
	END
	-- 6
	IF (@Visit_Id = 0)
	BEGIN
		SELECT TOP 1 visit_pk
			,'' AS BPDiastolic
			,'' AS BPSystolic
			,'' AS TEMP
			,'' AS RR
			,'' AS HR
			,'' AS Headcircumference
			,CONVERT(VARCHAR(10), height) AS height
			,CONVERT(VARCHAR(10), weight) AS weight
			,'' AS MUAC
			,'' AS weightforage
			,'' AS weightforheight
			,'' AS BMIz
			,'' as NurseComments
		FROM dtl_PatientVitals
		WHERE ptn_pk = @Ptn_pk
			AND LocationId = @LocationId
		ORDER BY visit_pk;
	END
	ELSE
	BEGIN
		SELECT visit_pk
			,CONVERT(VARCHAR(10), BPDiastolic) AS BPDiastolic
			,CONVERT(VARCHAR(10), BPSystolic) AS BPSystolic
			,CONVERT(VARCHAR(10), TEMP) AS TEMP
			,CONVERT(VARCHAR(10), RR) AS RR
			,CONVERT(VARCHAR(10), HR) AS HR
			,CONVERT(VARCHAR(10), Headcircumference) AS Headcircumference
			,CONVERT(VARCHAR(10), height) AS height
			,CONVERT(VARCHAR(10), weight) AS weight
			,CONVERT(VARCHAR(10), MUAC) AS MUAC
			,CONVERT(VARCHAR(10), weightforage) AS weightforage
			,CONVERT(VARCHAR(10), weightforheight) AS weightforheight
			,CONVERT(VARCHAR(10), BMIz) AS BMIz
			,NurseComments
		FROM dtl_PatientVitals
		WHERE ptn_pk = @Ptn_pk
			AND visit_pk = @Visit_Id
			AND LocationId = @LocationId;
	END
	/* HIV Care 7 */
	IF (@Visit_Id = 0)
	BEGIN
		SELECT TOP 1 OV.Ptn_pk
			,OV.LocationID
			,OV.Visit_Id AS Visit_Id
			,OV.VisitDate AS HIVCareEnrollmentDate
			,CASE 
				WHEN CONVERT(DATETIME, PCS.DateHIVDiagnosis) = '1900-01-01'
					THEN NULL
				ELSE PCS.DateHIVDiagnosis
				END AS DateHIVDiagnosis
			,PCS.HIVDiagnosisVerified
			,PAHC.HIVCareWhere
			,CASE 
				WHEN CONVERT(DATETIME, PCIE.ARTTransferInDate) = '1900-01-01'
					THEN NULL
				ELSE PCIE.ARTTransferInDate
				END AS ARTTransferInDate
			,PCIE.ARTTransferInFrom
			,PCIE.FromDistrict
			,CASE 
				WHEN CONVERT(DATETIME, PCE.ARTStartDate) = '1900-01-01'
					THEN NULL
				ELSE PCE.ARTStartDate
				END AS ARTStartDate
			,OV.UserID
			,P.TransferIn
			,PCE.ConfirmHIVPosDate
			,p.ReferredFrom 
			,p.ReferredFromSpecify
		FROM ord_visit OV
		LEFT OUTER JOIN mst_patient P ON OV.ptn_pk = P.Ptn_pk
		LEFT OUTER JOIN dtl_PatientHivPrevCareIE PCIE ON OV.Visit_Id = PCIE.Visit_pk
		LEFT OUTER JOIN dtl_PatientClinicalStatus PCS ON OV.visit_id = PCS.visit_pk
		LEFT OUTER JOIN dtl_PriorArvAndHivCare PAHC ON OV.Visit_Id = PAHC.Visit_pk
		LEFT OUTER JOIN dtl_PatientHivPrevCareEnrollment PCE ON OV.Visit_Id = PCE.Visit_pk
		WHERE OV.ptn_pk = @Ptn_pk
			AND OV.LocationId = @LocationId
		ORDER BY PCE.ARTStartDate desc;
	END
	ELSE
	BEGIN
		SELECT TOP 1 OV.Ptn_pk
			,OV.LocationID
			,OV.Visit_Id AS Visit_Id
			,OV.VisitDate AS HIVCareEnrollmentDate
			,CASE 
				WHEN CONVERT(DATETIME, PCS.DateHIVDiagnosis) = '1900-01-01'
					THEN NULL
				ELSE PCS.DateHIVDiagnosis
				END AS DateHIVDiagnosis
			,PCS.HIVDiagnosisVerified
			,PAHC.HIVCareWhere
			,CASE 
				WHEN CONVERT(DATETIME, PCIE.ARTTransferInDate) = '1900-01-01'
					THEN NULL
				ELSE PCIE.ARTTransferInDate
				END AS ARTTransferInDate
			,PCIE.ARTTransferInFrom
			,PCIE.FromDistrict
			,CASE 
				WHEN CONVERT(DATETIME, PCE.ARTStartDate) = '1900-01-01'
					THEN NULL
				ELSE PCE.ARTStartDate
				END AS ARTStartDate
			,OV.UserID
			,P.TransferIn
			,PCE.ConfirmHIVPosDate
			,p.ReferredFrom 
			,p.ReferredFromSpecify
		FROM ord_visit OV
		LEFT OUTER JOIN mst_patient P ON OV.ptn_pk = P.Ptn_pk
		LEFT OUTER JOIN dtl_PatientHivPrevCareIE PCIE ON OV.Visit_Id = PCIE.Visit_pk
		LEFT OUTER JOIN dtl_PatientClinicalStatus PCS ON OV.visit_id = PCS.visit_pk
		LEFT OUTER JOIN dtl_PriorArvAndHivCare PAHC ON OV.Visit_Id = PAHC.Visit_pk
		LEFT OUTER JOIN dtl_PatientHivPrevCareEnrollment PCE ON OV.Visit_Id = PCE.Visit_pk
		WHERE OV.ptn_pk = @Ptn_pk
			AND OV.Visit_Id = @Visit_Id
			AND OV.LocationId = @LocationId
		ORDER BY OV.Visit_Id asc;
	END
	-- 8
	SELECT ptn_pk
		,locationid
		,visit_pk
		,LMP
		,Pregnant
		,EDD
		,DateofDelivery
		,DateofInducedAbortion
		,DateofMiscarriage
		,Amenorrhoea
	FROM dtl_PatientClinicalStatus
	WHERE ptn_pk = @Ptn_pk
		AND visit_pk = @Visit_Id
		AND LocationId = @LocationId;
	-- 9
	SELECT ptn_pk
		,locationid
		,visit_pk
		,BreastStatus
	FROM dtl_PatientOtherTreatment
	WHERE ptn_pk = @Ptn_pk
		AND visit_pk = @Visit_Id
		AND LocationId = @LocationId;
	-- 10
	SELECT Ptn_pk
		,LocationID
		,Visit_pk
		,FamilyPlanningStatus
		,NoFamilyPlanning
	FROM dtl_patientCounseling PC
	WHERE ptn_pk = @Ptn_pk
		AND visit_pk = @Visit_Id
		AND LocationId = @LocationId;
	-- 11
	SELECT UserID
		,UserName
		--,Email
		,Designation
		,DeleteFlag
	FROM [dbo].[VW_UserDesignationTransaction]
	ORDER BY UserName;
	--12 (SPO2%)
	SELECT LO.TestResults SPO2
	FROM dtl_PatientLabResults LO
	INNER JOIN ord_PatientLabOrder LR ON LO.LabID = LR.LabID
		AND LO.LocationID = LR.LocationID
	INNER JOIN mst_LabTest ml ON LO.LabTestID = ml.LabTestID
	WHERE LR.VisitId = @Visit_Id
		AND LR.Ptn_Pk = @Ptn_pk
		AND LO.LocationId = @LocationId
		AND LR.LocationID = @LocationId
		AND ml.LabName = N'SPO2(%)';
	/*** Existing Initial visit data***/
	-- 13
	DECLARE @vtId INT
	DECLARE @FeatureID INT
		,@VisitType INT;
	SELECT @FeatureID = featureid
	FROM mst_feature
	WHERE featurename = 'Clinical Encounter'
		AND Deleteflag = 0;
	SELECT @VisitType = VisitTypeID
	FROM mst_VisitType
	WHERE VisitName = 'Clinical Encounter'
		AND FeatureID = @FeatureID
		AND Deleteflag = 0;
	SELECT @vtId = d.id
	FROM Mst_PMTCTcode c
	INNER JOIN Mst_PMTCTDecode d ON c.codeid = d.codeid
	WHERE c.NAME = 'FieldVisitType'
		AND ltrim(rtrim(d.NAME)) = 'Initial only'
		AND d.NAME NOT LIKE '%ANC%'
	SELECT visit_id
		,VisitDate
	FROM Ord_Visit
	WHERE ptn_Pk = @Ptn_pk
		AND LocationId = @LocationId
		AND VisitType = @VisitType
		AND TypeOfVisit = @vtId
		AND (
			deleteflag IS NULL
			OR deleteflag = 0
			)
	ORDER BY visit_id DESC;
	SELECT m_FBT.TabName TabName
		,m_FBT.FeatureID FeatureID
		,m_F.FeatureName FeatureName
		,m_FBT.TabID TabID
	FROM Mst_FormBuilderTab m_FBT
	JOIN lnk_FormTabOrdVisit l_FTOV ON l_FTOV.TabID = m_FBT.TabID
		AND l_FTOV.Visit_pk = @Visit_Id and l_FTOV.Visit_pk <> 0
	JOIN mst_Feature m_F ON m_F.FeatureID = m_FBT.FeatureID
		AND ISNULL(m_FBT.DeleteFlag, 0) = 0
		AND ISNULL(m_F.DeleteFlag, 0) = 0;
	-- Transfer In 14 
	SELECT TOP 1 art.ptn_pk AS Ptn_Pk
		,art.Visit_Id AS Visit_pk
		,art.LocationId
		,art.FirstLineRegStDate
		,art.Firstlinereg
		,art.cd4
		,art.cd4percent
		,art.pregnant
		,FLOOR(art.weight) AS weight
		,FLOOR(art.Height) AS Height
		,stg.whostage
		,art.CurrentRegimen
		,art.BaselineViralLoad
		,art.BaselineViralLoadDate
		,art.MUAC
	FROM dtl_patientArtCare art
	LEFT OUTER JOIN dtl_patientvitals vit ON art.visit_id = vit.Visit_pk
	LEFT OUTER JOIN dtl_PatientARVEligibility stg ON art.visit_id = stg.visit_id
	WHERE art.Ptn_pk = @Ptn_pk
		AND art.locationId = @LocationId
	--AND ISNULL(DeleteFlag, 0) = 0
	ORDER BY art.Visit_Id DESC;
	-- Regimen 15
	SELECT RegimenID AS RegimenId
		,RegimenCode + ' - ' + RegimenName AS Regimen
	FROM mst_Regimen
	WHERE DeleteFlag = 0;
	-- WHO Stage 16
	SELECT d.id
		,d.NAME
		,LTRIM(RTRIM(c.NAME)) AS CName
	FROM MST_CODE c
	INNER JOIN Mst_Decode d ON c.codeid = d.codeid
	WHERE c.NAME IN ('WHO Stage')
		OR d.Codeid IN (
			10
			,4
			)
		AND (
			d.DeleteFlag = 0
			OR d.DeleteFlag IS NULL
			)
		AND d.SystemId IN (
			0
			,1
			)
	ORDER BY d.codeid
		,d.id
		,d.srno;
	-- Refered From 17
	SELECT d.id
		,d.NAME
		,LTRIM(RTRIM(c.NAME)) AS CName
	FROM MST_CODE c
	INNER JOIN Mst_Decode d ON c.codeid = d.codeid
	WHERE c.NAME IN ('PatientReferred')
		And d.Name in (
		'VCT'
		,'HBTC'
		,'OPD'
		,'MCH'
		,'TB Clinic'
		,'IPD'
		,'CCC'
		,'Self referral'
		,'Other Specify'
		,'Peer'
		,'Outreach'
		,'Community'
		)
		AND (
			d.DeleteFlag = 0
			OR d.DeleteFlag IS NULL
			)
		AND d.SystemId IN (
			0
			,1
			)
	ORDER BY d.codeid
		,d.id
		,d.srno;
	-- Appointment From 18
	SELECT CASE 
			WHEN CONVERT(DATETIME, AppDate) = '1900-01-01'
				THEN NULL
			ELSE AppDate
			END AS AppDate
		,AppReason
	FROM dtl_patientappointment
	WHERE ptn_pk = @Ptn_pk
		AND visit_PK = @Visit_Id
		AND LocationId = @LocationId;
	-- Adherence [19]
	SELECT [PAM_ID]
		,[Signature]
	FROM [dbo].[dtl_HIVCE_PatientAdherenceManagement] PAM
	WHERE PAM.ptn_pk = @Ptn_pk
		AND PAM.visit_Id = @Visit_Id
		AND Pam.Location_Id = @LocationId;
	--20  Purpose:        
	SELECT ID
		,NAME
	FROM mst_Decode
	WHERE codeid = 26
		AND (
			DeleteFlag = 0
			OR DeleteFlag IS NULL
			);
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
			--AND DATEADD(mm, 6, a.INHStartDate) >= GETDATE()
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

