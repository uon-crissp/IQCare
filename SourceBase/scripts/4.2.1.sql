USE [IQCare]
GO
/****** Object:  StoredProcedure [dbo].[Pr_HIVCE_SaveUpdateManagementxData]    Script Date: 3/25/2019 1:23:16 PM ******/

insert into mst_Feature(FeatureName,ReportFlag,DeleteFlag,AdminFlag,UserID,CreateDate,SystemId,Published,ModuleId,MultiVisit)
values('Morisky Adherence Screening', 0,0,0,1,getdate(), 0,2,203,1)

set 

insert into mst_VisitType(VisitName, DeleteFlag,UserID,CreateDate,SystemId, FeatureId)

select * from mst_Feature

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
	,@VisitTypeId int
AS
BEGIN
	DECLARE @FeatureID INT
	declare @VisitType INT
	declare @visitid int

	SELECT @FeatureID = featureid FROM mst_feature WHERE featurename = 'morisky adherence screening' AND Deleteflag = 0;

	IF @Visit_Pk = 0
	BEGIN
		INSERT INTO ord_Visit (Ptn_Pk,LocationID,VisitDate,VisitType,DataQuality,DeleteFlag,UserID,CreateDate,updatedate,Signature,TypeOfVisit)
		VALUES (@Ptn_pk,@LocationId,@visitdate,@VisitType,0,0,1,getdate(),getdate(),@Signature,@VisitTypeId)

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
			AND visit_id = @Visit_Pk
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
			,@Visit_Pk
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


