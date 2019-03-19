use IQCare
go

update AppAdmin set AppVer='4.2.0', DBVer='4.2.0', RelDate='15-Mar-2019'
go

alter table mst_drug add DrugAbbreviation varchar(50)
alter table mst_drug add DrugType int
go
--==

alter  procedure [dbo].[pr_SCM_GetDrugType_Futures] 
@ItemTypeId  int = 0                                                                                      
as                                                    
begin 
	declare @CatName varchar(200) 
	set @CatName='' 
	select @CatName = Name from Mst_Decode where Id = @ItemTypeId and codeID=202  
                     
	if (@CatName <> 'Lab Tests')                                                    
	begin  
		select  a.drugTypeID, a.DrugTypeName ,a.DeleteFlag,b.ItemTypeId [MapTypeID]  from  mst_drugtype a  left outer join Lnk_ItemDrugType b on           
		a.DrugTypeID =b.DrugTypeId where (a.deleteflag is null or deleteflag = 0)  order by DrugTypeName asc       
    
		select drugTypeID,DrugTypeName from Mst_DrugType where (deleteflag is null or deleteflag = 0)  order by DrugTypeName asc          
	end   
	else  if (@CatName = 'Lab Tests')
	begin   
		select a.SubTestID[drugTypeID] ,a.SubTestName [DrugTypeName] ,a.DeleteFlag,b.ItemTypeId [MapTypeID] from lnk_testParameter a left outer join Lnk_ItemDrugType b on           
		a.SubTestID =b.DrugTypeId and b.ItemTypeId =@ItemTypeId  where  (a.deleteflag is null or a.deleteflag = 0)  order by SubTestName asc    
  
		select a.SubTestID[drugTypeID] ,a.SubTestName [DrugTypeName],a.DeleteFlag  from lnk_testParameter a  where (a.deleteflag is null or a.deleteflag = 0)   
		order by SubTestName asc    
	end                   
end
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Admin_InsertDrug_Constella] (
 @DrugId INT
,@DrugTypeID int
,@DrugName VARCHAR(150)
,@DrugAbbreviation VARCHAR(50)
,@purchaseUnit int
,@QtyPerpurchaseUnit int
,@dispensingunit int
,@issyrup int
,@UserID INT
,@Status INT
)

AS

BEGIN
	if(@DrugId=0)
	begin
		insert into mst_drug(DrugType, DrugName, drugabbreviation, PurchaseUnit, QtyPerPurchaseUnit, DispensingUnit, syrup, UserID, DeleteFlag,CreateDate)
		values(@DrugTypeID,@DrugName,@DrugAbbreviation,@purchaseUnit,@QtyPerpurchaseUnit,@dispensingunit,@issyrup,@UserID,@Status, getdate())
	end
	else
	begin
		update mst_Drug set DrugType=@DrugTypeID, DrugName=@DrugName, drugabbreviation=@drugabbreviation, 
		PurchaseUnit=@PurchaseUnit, QtyPerPurchaseUnit=@QtyPerPurchaseUnit, DispensingUnit=@DispensingUnit, syrup=@issyrup,
		UserID=@UserID, DeleteFlag=@Status,UpdateDate=getdate()
		where Drug_pk = @DrugId
	end
END
go
--==

update x set x.DrugAbbreviation = a.Abbreviation
from
(
select a.Drug_pk
, STUFF((select distinct '/'+isnull(x.GenericAbbrevation,'') from mst_Generic x 
inner join lnk_DrugGeneric y on x.GenericID=y.GenericID
where y.Drug_pk=a.Drug_pk for xml path('')), 1, 1, '') as Abbreviation
from mst_Drug a
)a
inner join mst_Drug x on a.Drug_pk=x.Drug_pk
go
--==

update c set c.drugtype = a.DrugTypeId 
from lnk_DrugTypeGeneric a
inner join lnk_DrugGeneric b on a.GenericId = b.GenericID
inner join mst_Drug c on b.Drug_pk = c.Drug_pk
go


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_Admin_SelectDrug_Constella] (@drug_pk int)                                         
AS                                          
Begin   
	if(@drug_pk=0)
	begin                                                             
		Select a.Drug_Pk
		,a.DrugName
		,0 as GenericId
		,'' as GenericName
		,a.DrugAbbreviation as GenericAbbrevation
		,c.DrugTypeId
		,c.Drugtypename                                    
		,a.userid
		,Case a.DeleteFlag when 0 then 'Active' when 1 then 'InActive' end as [Status]
		,a.[Sequence]
		,a.PurchaseUnit
		,a.QtyPerPurchaseUnit
		,a.DispensingUnit
		,a.Syrup                                           
		from mst_drug a
		inner join mst_DrugType c on a.DrugType = c.DrugTypeID  
	end
	else
	begin
		Select a.Drug_Pk
		,a.DrugName
		,0 as GenericId
		,'' as GenericName
		,a.DrugAbbreviation as GenericAbbrevation
		,c.DrugTypeId
		,c.Drugtypename                                    
		,a.userid
		,Case a.DeleteFlag when 0 then 'Active' when 1 then 'InActive' end as [Status]
		,a.[Sequence]
		,a.PurchaseUnit
		,a.QtyPerPurchaseUnit
		,a.DispensingUnit
		,a.Syrup                                           
		from mst_drug a
		inner join mst_DrugType c on a.DrugType = c.DrugTypeID  where a.Drug_pk=@drug_pk
	end                                                
End
go
--==

if exists(select * from sysobjects where name='dtl_DrugStockTransactions' and type='u')
	drop table dtl_DrugStockTransactions
go
create table dtl_DrugStockTransactions
(
  id int identity(1,1) 
, drug_pk int
, TransactionDate datetime
, TransactionType int
, StoreId int
, SourceStoreId int
, SupplierId int
, Quantity int
, StoreBal int
, BatchNo varchar(100)
, ExpiryDate datetime
, ptn_pharmacy_pk int
, userid int
, createdate datetime
, updatedate datetime
)
go
--==

if exists(select * from sysobjects where name='pr_Pharmacy_SaveTransaction' and type='p')
	drop proc pr_Pharmacy_SaveTransaction
go

create proc pr_Pharmacy_SaveTransaction(
  @drug_pk int
, @TransactionDate datetime
, @TransactionType int
, @StoreId int
, @SourceStoreId int
, @SupplierId int
, @Quantity int
, @BatchNo varchar(100)
, @ExpiryDate datetime
, @ptn_pharmacy_pk int
, @userid int
)

as
begin
	declare @StoreBal int

	set @StoreBal= @Quantity + isnull((select top 1 StoreBal from dtl_DrugStockTransactions x where x.StoreId=@StoreId and Drug_pk=@drug_pk order by id desc),0)

	insert into dtl_DrugStockTransactions(drug_pk,TransactionDate,TransactionType,StoreId,SourceStoreId,
		SupplierId,Quantity,StoreBal,BatchNo,ExpiryDate,ptn_pharmacy_pk,createdate,userid)
	values(@drug_pk,@TransactionDate,@TransactionType,@StoreId,@SourceStoreId,
		@SupplierId,@Quantity,@StoreBal,@BatchNo,@ExpiryDate,@ptn_pharmacy_pk,getdate(),@userid)

	if(@TransactionType in (3,4)) --deduct stock from source store
	begin
		declare @sourceStoreBal int

		set @sourceStoreBal = isnull((select top 1 StoreBal from dtl_DrugStockTransactions x where x.StoreId=@SourceStoreId and Drug_pk=@drug_pk order by id desc),0) - @Quantity

		insert into dtl_DrugStockTransactions(drug_pk,TransactionDate,TransactionType,StoreId,SourceStoreId,
			SupplierId,Quantity,StoreBal,BatchNo,ExpiryDate,ptn_pharmacy_pk,createdate,userid)
		values(@drug_pk,@TransactionDate,@TransactionType,@SourceStoreId,0,
			@SupplierId,(@Quantity-@Quantity*2),@sourceStoreBal,@BatchNo,@ExpiryDate,@ptn_pharmacy_pk,getdate(),@userid)
	end
end
go
--==

create table mst_StockTransactionType
(
	id int identity(1,1)
	,TransactionId int
	,Name varchar(100)
	,createdate datetime
)

insert into mst_StockTransactionType(TransactionId, name, createdate) values(1, 'Set Opening Stock', getdate())
insert into mst_StockTransactionType(TransactionId, name, createdate) values(2, 'Receive from Supplier', getdate())
insert into mst_StockTransactionType(TransactionId, name, createdate) values(3, 'Receive from Bulk Store', getdate())
insert into mst_StockTransactionType(TransactionId, name, createdate) values(4, 'Inter Dispensing Store Transfer', getdate())
insert into mst_StockTransactionType(TransactionId, name, createdate) values(5, 'Adjust stock', getdate())
insert into mst_StockTransactionType(TransactionId, name, createdate) values(6, 'Dispense to Patient', getdate())
go
--==

create proc pr_SCM_LoadStockTransactions
as
begin
	select * from StockTransactionType where TransactionId <> 6
end
go
--==

alter table ord_patientPharmacyOrder add RegimenId int
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_SCM_SavePharmacyDispenseOrder_Web] @Ptn_Pk INT
	,@LocationId INT
	,@DispensedBy INT = NULL
	,@DispensedByDate VARCHAR(30) = NULL
	,@OrderType INT = NULL
	,@ProgramId INT = NULL
	,@StoreId INT = NULL
	,@Regimen VARCHAR(50) = NULL
	,@UserId INT = NULL
	,@OrderId INT = 0
	,@AppointmentDate DATETIME = NULL
	,@OrderedBy INT = NULL
	,@OrderDate VARCHAR(30) = NULL
	,@deleteScript VARCHAR(1000) = NULL
	,@RegimenLine INT = 0
	,@RegimenCode INT = 0
	,@TherapyPlan INT = NULL
	,@PatientClassification INT = null
	,@IsEnrolDifferenciatedCare int =0
AS
BEGIN
	IF (isnull(@deleteScript, '') <> '')
	BEGIN
		EXEC (@deleteScript)
	END

	DECLARE @EmpID VARCHAR(50), @ARTStartDate DATETIME

	IF @OrderId > 0
	BEGIN
		SET @EmpID = (
				SELECT EmployeeID
				FROM ord_PatientPharmacyOrder
				WHERE ptn_pharmacy_pk = @OrderID
				)

		DECLARE @VisitId INT

		SELECT @VisitId = VisitId FROM dbo.Ord_PatientPharmacyOrder WHERE Ptn_Pharmacy_Pk = @OrderId

		UPDATE dbo.Ord_Visit SET VisitDate = @DispensedByDate,DataQuality = 1,UserId = @UserId,PatientClassification = @PatientClassification,
		IsEnrolDifferenciatedCare = @IsEnrolDifferenciatedCare WHERE Visit_Id = @VisitId

		UPDATE dbo.Ord_PatientPharmacyOrder
		SET DispensedBy = @DispensedBy
			,DispensedByDate = @DispensedByDate
			,TreatmentPlan = @TherapyPlan
			,StoreId = @StoreId
			,UserId = @UserId
			,UpdateDate = getdate()
		WHERE Ptn_Pharmacy_Pk = @OrderId

		IF (@Regimen <> '')
		BEGIN
			UPDATE dbo.Dtl_RegimenMap
			SET RegimenType = @Regimen
				,RegimenId = @RegimenCode
			WHERE ptn_pk = @Ptn_pk
				AND Visit_Pk = @VisitId
				AND OrderId = @OrderId
		END
            
		SELECT @VisitId [VisitId]
			,@OrderId [Ptn_Pharmacy_Pk]

		EXEC pr_SCM_SetPharmacyRefillAppointment @Ptn_Pk
			,@LocationId
			,@VisitId
			,@AppointmentDate
			,@UserId
			,@EmpID
	END
	ELSE
	BEGIN
		INSERT INTO dbo.Ord_Visit (
			Ptn_Pk
			,LocationId
			,VisitDate
			,VisitType
			,DataQuality
			,DeleteFlag
			,UserId
			,CreateDate
			,PatientClassification
			,IsEnrolDifferenciatedCare
			)
		VALUES (
			@Ptn_Pk
			,@LocationId
			,@OrderDate
			,4
			,0
			,0
			,@UserId
			,getdate()
			,@PatientClassification
			,@IsEnrolDifferenciatedCare
			)

		INSERT INTO dbo.Ord_PatientPharmacyOrder (
			Ptn_Pk
			,VisitId
			,LocationId
			,OrderedBy
			,OrderedByDate
			,DispensedBy
			,DispensedByDate
			,OrderType
			,ProgId
			,StoreId
			,DeleteFlag
			,UserId
			,CreateDate
			,RegimenLine
			,orderstatus
			,TreatmentPlan
			,RegimenId
			)
		VALUES (
			@Ptn_Pk
			,ident_current('Ord_Visit')
			,@LocationId
			,@OrderedBy
			,@OrderDate
			,@DispensedBy
			,@DispensedByDate
			,@OrderType
			,@ProgramId
			,@StoreId
			,0
			,@UserId
			,getdate()
			,@RegimenLine
			,1
			,@TherapyPlan
			,@RegimenCode
			)

		UPDATE ord_PatientPharmacyOrder SET ReportingID = (SELECT RIGHT('000000' + CONVERT(VARCHAR, ident_current('dbo.ord_PatientPharmacyOrder')), 6))
		WHERE ptn_pharmacy_pk = ident_current('dbo.ord_PatientPharmacyOrder')

		IF (@Regimen <> '')
		BEGIN
			INSERT INTO dbo.Dtl_RegimenMap (
				Ptn_Pk
				,LocationId
				,Visit_Pk
				,RegimenType
				,OrderId
				,DeleteFlag
				,UserId
				,CreateDate
				,RegimenId
				)
			VALUES (
				@Ptn_Pk
				,@LocationId
				,ident_current('ord_Visit')
				,@Regimen
				,ident_current('Ord_PatientPharmacyOrder')
				,0
				,@UserId
				,getdate()
				,@RegimenCode
				)
		END

		SELECT ident_current('ord_Visit') [VisitId]
			,ident_current('Ord_PatientPharmacyOrder') [Ptn_Pharmacy_Pk]

		DECLARE @NewVisitID INT

		SELECT @NewVisitID = ident_current('ord_Visit')

		SET @EmpID = (
				SELECT EmployeeID
				FROM ord_PatientPharmacyOrder
				WHERE ptn_pharmacy_pk = @OrderID
				)

		EXEC pr_SCM_SetPharmacyRefillAppointment @Ptn_Pk
			,@LocationId
			,@NewVisitID
			,@AppointmentDate
			,@UserId
			,@EmpID
	END

	--vy added art startdate
	SET @ARTStartDate = dbo.fn_GetPatientARTStartDate_constella(@Ptn_pk)

	UPDATE mst_Patient
	SET ARTStartDate = @ARTStartDate
	WHERE ptn_pk = @Ptn_pk
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_SCM_SavePharmacyDispenseOrderDetail_Web] @Ptn_Pk INT
	,@StoreId INT
	,@VisitId INT
	,@Ptn_Pharmacy_Pk INT
	,@Drug_Pk INT
	,
	-----------------------   
	@MorningDose DECIMAL(10, 2)
	,@MiddayDose DECIMAL(10, 2)
	,@EveningDose DECIMAL(10, 2)
	,@NightDose DECIMAL(10, 2)
	,
	-----------------------
	@DispensedQuantity INT
	,@Prophylaxis INT
	,@BatchId INT
	,@BatchNo VARCHAR(50)
	,@ExpiryDate DATETIME
	,@DispensingUnit INT
	,@DispensedByDate VARCHAR(30) = NULL
	,@LocationId INT
	,@UserId INT
	,@DataStatus INT
	,
	-----------------------
	@Duration DECIMAL(18, 2)
	,@PrescribeOrderedQuantity DECIMAL(18, 2)
	,@PillCount DECIMAL(10, 2)
	,
	---------------------------------
	@PrintPrescriptionStatus INT
	,@PatientInstructions VARCHAR(500)
	,@Comments VARCHAR(500)
AS
BEGIN
	DECLARE @EntryStatus INt, @qty int
	SELECT @BatchId = id FROM mst_batch WHERE NAME = @BatchNo AND itemid = @Drug_Pk;
	SET @EntryStatus = 0;
	set @qty = 0;

	IF EXISTS (SELECT Drug_Pk FROM dbo.Dtl_PatientPharmacyOrder WHERE Drug_Pk = @Drug_Pk AND Ptn_Pharmacy_Pk = @Ptn_Pharmacy_Pk)
	BEGIN
		SET @EntryStatus = 1;

		UPDATE dbo.Dtl_PatientPharmacyOrder
		SET DispensedQuantity = @DispensedQuantity
			,BatchNo = @BatchId
			,ExpiryDate = @ExpiryDate
			,--UserId =@UserId,
			UpdateDate = GETDATE()
			,Duration = @Duration
			,OrderedQuantity = @PrescribeOrderedQuantity
			,PrintPrescriptionStatus = @PrintPrescriptionStatus
			,PatientInstructions = @PatientInstructions
			,MorningDose = @MorningDose
			,MiddayDose = @MiddayDose
			,EveningDose = @EveningDose
			,NightDose = @NightDose
			,PillCount = @PillCount
			,comments = @Comments
		WHERE Ptn_Pharmacy_pk = @Ptn_Pharmacy_Pk
			AND Drug_Pk = @Drug_Pk;
	END;

	IF NOT EXISTS (SELECT Drug_Pk FROM dbo.Dtl_PatientPharmacyOrder WHERE Drug_Pk = @Drug_Pk
				AND BatchNo = @BatchId
				AND ExpiryDate = @ExpiryDate
				AND Ptn_Pharmacy_Pk = @Ptn_Pharmacy_Pk)
	BEGIN
		SET @EntryStatus = 1;

		INSERT INTO dbo.Dtl_PatientPharmacyOrder (
			Ptn_Pharmacy_Pk
			,Drug_Pk
			,GenericId
			,StrengthID
			,DispensedQuantity
			,UserId
			,CreateDate
			,Prophylaxis
			,BatchNo
			,ExpiryDate
			,Duration
			,OrderedQuantity
			,PrintPrescriptionStatus
			,PatientInstructions
			,MorningDose
			,MiddayDose
			,EveningDose
			,NightDose
			,PillCount
			,comments
			)
		VALUES (
			@Ptn_Pharmacy_Pk
			,@Drug_Pk
			,0
			,0
			,@DispensedQuantity
			,@UserId
			,GETDATE()
			,@Prophylaxis
			,@BatchId
			,@ExpiryDate
			,@Duration
			,@PrescribeOrderedQuantity
			,@PrintPrescriptionStatus
			,@PatientInstructions
			,@MorningDose
			,@MiddayDose
			,@EveningDose
			,@NightDose
			,@PillCount
			,@Comments
			);
	END;

	IF (@EntryStatus = 0)
	BEGIN
		IF (@DataStatus = 1)
		BEGIN
			INSERT INTO dbo.Dtl_PatientPharmacyOrder (
				Ptn_Pharmacy_Pk
				,Drug_Pk
				,GenericId
				,DispensedQuantity
				,UserId
				,CreateDate
				,Prophylaxis
				,BatchNo
				,ExpiryDate
				,Duration
				,OrderedQuantity
				,PrintPrescriptionStatus
				,PatientInstructions
				,MorningDose
				,MiddayDose
				,EveningDose
				,NightDose
				,PillCount
				)
			VALUES (
				@Ptn_Pharmacy_Pk
				,@Drug_Pk
				,0
				,@DispensedQuantity
				,@UserId
				,GETDATE()
				,@Prophylaxis
				,@BatchId
				,@ExpiryDate
				,@Duration
				,@PrescribeOrderedQuantity
				,@PrintPrescriptionStatus
				,@PatientInstructions
				,@MorningDose
				,@MiddayDose
				,@EveningDose
				,@NightDose
				,@PillCount
				);

			DECLARE @duraction1 DECIMAL(18, 2);
			DECLARE @Qty1 DECIMAL(18, 2);

			SELECT TOP 1 @duraction1 = Duration
				,@Qty1 = OrderedQuantity
			FROM dbo.Dtl_PatientPharmacyOrder
			WHERE Ptn_Pharmacy_Pk = @Ptn_Pharmacy_Pk
				AND Drug_Pk = @Drug_Pk
				AND Duration IS NOT NULL
				AND OrderedQuantity IS NOT NULL;

			UPDATE dbo.Dtl_PatientPharmacyOrder
			SET Duration = @duraction1
				,OrderedQuantity = @Qty1
			WHERE Ptn_Pharmacy_Pk = @Ptn_Pharmacy_Pk
				AND Drug_Pk = @Drug_Pk
				AND Duration IS NULL
				AND OrderedQuantity IS NULL
		END;
	END;


	DECLARE @OrderedQuantityByDrug DECIMAL(18, 2);
	DECLARE @TotalDispensedQuantityByDrug DECIMAL(18, 2);

	SELECT @OrderedQuantityByDrug = orderedquantity
	FROM dtl_patientpharmacyorder
	WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk
		AND Drug_Pk = @Drug_Pk;

	SELECT @TotalDispensedQuantityByDrug = SUM(DispensedQuantity) + SUM(PillCount)
	FROM dtl_patientpharmacyorder
	WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk
		AND Drug_Pk = @Drug_Pk;

	DECLARE @TotalOrderedQuantity DECIMAL(18, 2);
	DECLARE @TotalDispensedQuantity DECIMAL(18, 2);

	SELECT @TotalOrderedQuantity = SUM(z.OrderedQuantity)
	FROM (
		SELECT Drug_Pk
			,ISNULL(OrderedQuantity, 0) AS 'OrderedQuantity'
		FROM dtl_patientpharmacyorder
		WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk
		GROUP BY Drug_Pk
			,OrderedQuantity
		) AS z;

	SELECT @TotalDispensedQuantity = SUM(DispensedQuantity) + SUM(PillCount)
	FROM dtl_patientpharmacyorder WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk;

	IF (@TotalDispensedQuantity = @TotalOrderedQuantity)
	BEGIN
		UPDATE ord_PatientPharmacyOrder SET OrderStatus = 2 WHERE DispensedByDate IS NOT NULL AND ptn_pharmacy_pk = @ptn_pharmacy_pk
	END;

	IF (@TotalDispensedQuantity > 0 AND @TotalDispensedQuantity < @TotalOrderedQuantity)
	BEGIN
		UPDATE ord_PatientPharmacyOrder SET OrderStatus = 3 WHERE DispensedByDate IS NOT NULL AND ptn_pharmacy_pk = @ptn_pharmacy_pk
	END

	IF (@TotalDispensedQuantity < 1)
	BEGIN
		UPDATE ord_PatientPharmacyOrder SET OrderStatus = 1 WHERE DispensedByDate IS NOT NULL AND ptn_pharmacy_pk = @ptn_pharmacy_pk
	END
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_SCM_GetOpeningStock_Web] @StoreId int
AS
BEGIN
	--0           
	SELECT a.Drug_pk
		,a.DrugName
		,@StoreId as StoreId
		,c.NAME [Unit]
		,c.ID
		,'' BatchNo
		,0 batchid
		,NULL expirydate
		,0 availqty
		,0 purchaseunitprice
		,0 qtyperpurchaseunit
		,'' [PurchaseUnit]
	FROM [dbo].[mst_drug] a
	LEFT OUTER JOIN mst_dispensingunit c ON a.DispensingUnit = c.Id
	WHERE (
			a.DeleteFlag = 0
			OR a.deleteflag IS NULL
			)

	--1        
	SELECT Id
		,NAME
		,DeleteFlag
	FROM [dbo].[mst_batch]
	WHERE DeleteFlag = 0

	--2 
	select * from
	(         
	SELECT a.Drug_Pk [ItemId]
		,a.DrugName [ItemName]
		,@StoreId as StoreId
		,(select x.Name from Mst_Store x where x.StoreId=@StoreId) [StoreName]
		,isnull((select top 1 x.StoreBal from dtl_DrugStockTransactions x where x.drug_pk=a.Drug_pk and x.TransactionType=1 and StoreId=@storeid),0) as Quantity
		,0 as BatchId
		,(select top 1 x.BatchNo from dtl_DrugStockTransactions x where x.drug_pk=a.Drug_pk and x.TransactionType=1 and StoreId=@storeid) [BatchNo]
		,d.NAME [DispensingUnit]
		,(select top 1 convert(varchar, x.ExpiryDate, 106) from dtl_DrugStockTransactions x where x.drug_pk=a.Drug_pk and x.TransactionType=1 and StoreId=@storeid) as [ExpiryDate]
		,isnull((select top 1 x.Quantity from dtl_DrugStockTransactions x where x.drug_pk=a.Drug_pk and x.TransactionType=1 and StoreId=@storeid),0) as OpeningStock
		,(select top 1 convert(varchar, x.TransactionDate, 106) from dtl_DrugStockTransactions x where x.drug_pk=a.Drug_pk and x.TransactionType=1 and StoreId=@storeid) as [TransacDate]
	FROM dbo.mst_Drug a
	LEFT OUTER JOIN dbo.mst_dispensingunit d ON a.DispensingUnit = d.Id
	where a.DeleteFlag=0
	) a where a.Quantity > 0 
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[pr_SCM_GetStocksPerStore] @storeid INT
	,@SupplierFlag INT = 0
AS
BEGIN
	SET NOCOUNT ON;

	-- 0
	IF (@SupplierFlag = 1)
	BEGIN
		SELECT mst.Drug_pk [Drug_pk]
			,mst.DrugName [DrugName]
			,'' [BatchNo]
			,'0' [BatchID]
			,'' [ExpiryDate]
			,mstDU.NAME [Unit]
			,1 [AvailQty]
			,ISNULL(mst.PurchaseUnitPrice, 0) [PurchaseUnitPrice]
			,ISNULL(mst.QtyPerPurchaseUnit, 0) [QtyPerPurchaseUnit]
			,mstPurUnit.NAME [PurchaseUnit]
		FROM mst_Drug mst
		LEFT OUTER JOIN Mst_DispensingUnit mstDU ON mst.DispensingUnit = mstDU.Id
		LEFT OUTER JOIN Mst_DispensingUnit mstPurUnit ON mst.PurchaseUnit = mstPurUnit.Id
		WHERE (mst.DeleteFlag = 0 OR mst.DeleteFlag IS NULL)
	END
	ELSE
	BEGIN
		SELECT mstD.Drug_pk
			,mstD.DrugName
			,(select top 1 x.BatchNo from dtl_DrugStockTransactions x where x.drug_pk=mstD.Drug_pk and StoreId=@storeid order by id desc) [BatchNo]
			,0 [BatchID]
			,(select top 1 convert(varchar,x.ExpiryDate,106) from dtl_DrugStockTransactions x where x.drug_pk=mstD.Drug_pk and StoreId=@storeid order by id desc) ExpiryDate
			,mstDU.NAME [Unit]
			,isnull((select top 1 x.StoreBal from dtl_DrugStockTransactions x where x.drug_pk=mstD.Drug_pk and StoreId=@storeid order by id desc),0) AvailQty
			,ISNULL(mstD.PurchaseUnitPrice, 0) [PurchaseUnitPrice]
			,ISNULL(mstD.QtyPerPurchaseUnit, 0) [QtyPerPurchaseUnit]
			,'' [PurchaseUnit]
		FROM mst_Drug mstD
		INNER JOIN Mst_DispensingUnit mstDU ON mstD.DispensingUnit = mstDU.Id
		where mstD.DeleteFlag=0
	END
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[pr_SCM_GetStockSummary_Futures] @StoreId INT
	,@ItemId INT
	,@FromDate DATETIME
	,@ToDate DATETIME
AS
BEGIN
	--0                                                
	SET @Todate = dateadd(dd, 1, @Todate)

	SELECT @StoreId as [StoreId]
	, a.Drug_pk
	, a.DrugName
	FROM mst_Drug a
	where a.Drug_pk in (select x.Drug_pk from dtl_DrugStockTransactions x where x.StoreId=@StoreId)
	and a.DeleteFlag=0
	order by a.DrugName asc

	--1     
	if(@ItemId = 0)
	begin                           
		SELECT a.Drug_Pk [ItemId]
			,a.DrugName [ItemName]
			,b.Name [DispensingUnit]
			,(select top 1 x.StoreBal from dtl_DrugStockTransactions x 
				where x.drug_pk=a.Drug_pk and x.StoreId=@StoreId and x.createdate < @FromDate order by id desc) [OpeningStock]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType in (1,2,3,4) and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.Quantity>0 and x.createdate between @FromDate and @ToDate) [QtyRecieved]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType=6 and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.createdate between @FromDate and @ToDate) [QtyDispensed]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType in (2,3,4) and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.Quantity<0 and x.createdate between @FromDate and @ToDate) [InterStoreIssueQty]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType=5 and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.createdate between @FromDate and @ToDate) [AdjustmentQuantity]
			,(select top 1 x.StoreBal from dtl_DrugStockTransactions x 
				where x.drug_pk=a.Drug_pk and x.StoreId=@StoreId and x.createdate <= @ToDate order by x.id desc) [ClosingQty]
			,@StoreId as [StoreId]
			,(SELECT NAME FROM Mst_Store WHERE Id = @StoreId) [StoreName]
		FROM Mst_Drug a
		inner join Mst_DispensingUnit b on a.DispensingUnit=b.Id
		where a.Drug_pk in (select x.Drug_pk from dtl_DrugStockTransactions x where x.StoreId=@StoreId)
		and a.DeleteFlag=0
		order by a.DrugName asc	
	end
	else
	begin
		SELECT a.Drug_Pk [ItemId]
			,a.DrugName [ItemName]
			,b.Name [DispensingUnit]
			,(select top 1 x.StoreBal from dtl_DrugStockTransactions x 
				where x.drug_pk=a.Drug_pk and x.StoreId=@StoreId and x.createdate < @FromDate order by id desc) [OpeningStock]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType in (1,2,3,4) and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.Quantity>0 and x.createdate between @FromDate and @ToDate) [QtyRecieved]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType=6 and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.createdate between @FromDate and @ToDate) [QtyDispensed]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType in (2,3,4) and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.Quantity<0 and x.createdate between @FromDate and @ToDate) [InterStoreIssueQty]
			,(select sum(x.Quantity) from dtl_DrugStockTransactions x 
				where x.TransactionType=5 and x.drug_pk=a.Drug_pk and StoreId=@StoreId and x.createdate between @FromDate and @ToDate) [AdjustmentQuantity]
			,(select top 1 x.StoreBal from dtl_DrugStockTransactions x 
				where x.drug_pk=a.Drug_pk and x.StoreId=@StoreId and x.createdate <= @ToDate order by x.id desc) [ClosingQty]
			,@StoreId as [StoreId]
			,(SELECT NAME FROM Mst_Store WHERE Id = @StoreId) [StoreName]
		FROM Mst_Drug a
		inner join Mst_DispensingUnit b on a.DispensingUnit=b.Id
		where a.Drug_pk in (select x.Drug_pk from dtl_DrugStockTransactions x where x.StoreId=@StoreId)
		and a.DeleteFlag=0
		and a.Drug_pk=@ItemId
		order by a.DrugName asc	
	end
END
go
--==


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[pr_SCM_SavePharmacyPartialDispense_Web] @Ptn_Pk INT = NULL
	,@StoreId INT = NULL
	,@ptn_pharmacy_pk INT = NULL
	,@drug_pk INT = NULL
	,@batchid INT = NULL
	,@ExpiryDate DATETIME = NULL
	,@DispensedQuantity DECIMAL(18, 2) = NULL
	,@DispensedBy INT = NULL
	,@DispensedByDate DATETIME = NULL
	,@PrintPrescriptionStatus INT
	,@comments VARCHAR(1000) = NULL
	,@deleteScript VARCHAR(1000) = NULL
	,@UserId INT = NULL
AS
BEGIN
	IF (@ptn_pharmacy_pk != 0)
	BEGIN
		IF (ISNULL(@deleteScript, '') <> '')
		BEGIN
			EXEC (@deleteScript);
		END;

		INSERT INTO dtl_PatientPharmacyOrderpartialDispense (
			ptn_pharmacy_pk
			,drug_pk
			,batchid
			,DispensedQuantity
			,DispensedBy
			,DispensedByDate
			,comments
			,createdate
			,deleteflag
			)
		VALUES (
			@ptn_pharmacy_pk
			,@drug_pk
			,@batchid
			,@DispensedQuantity
			,@DispensedBy
			,@DispensedByDate
			,@comments
			,GETDATE()
			,0
			);

		UPDATE dtl_PatientPharmacyOrder
		SET DispensedQuantity = DispensedQuantity + @DispensedQuantity
			,PrintPrescriptionStatus = @PrintPrescriptionStatus
		WHERE ptn_pharmacy_pk = @ptn_pharmacy_pk
			AND Drug_Pk = @drug_pk;

		--Update stocks table
		declare @qty int = 0
		if(@DispensedQuantity>0)
		begin
			set @qty = @DispensedQuantity - @DispensedQuantity*2

			exec pr_Pharmacy_SaveTransaction @drug_pk, @DispensedByDate, 6, @StoreId, null, null
			,@qty , '', @ExpiryDate, @ptn_pharmacy_pk, @userid
		end

		UPDATE ord_PatientPharmacyOrder
		SET DispensedBy = @DispensedBy
			,DispensedByDate = @DispensedByDate
		WHERE ptn_pharmacy_pk = @ptn_pharmacy_pk;

		--Update dispensing status - whether partial or fully dispensed
		----------------------------------------------------------------
		DECLARE @OrderedQuantityByDrug DECIMAL(18, 2);
		DECLARE @TotalDispensedQuantityByDrug DECIMAL(18, 2);

		SELECT @OrderedQuantityByDrug = orderedquantity
		FROM dtl_patientpharmacyorder
		WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk
			AND Drug_Pk = @Drug_Pk;

		SET @TotalDispensedQuantityByDrug = (
				SELECT ISNULL(DispensedQuantity, 0)
				FROM dtl_patientpharmacyorder
				WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk
					AND Drug_Pk = @Drug_Pk
				);

		DECLARE @TotalOrderedQuantity DECIMAL(18, 2);
		DECLARE @TotalDispensedQuantity DECIMAL(18, 2);

		SELECT @TotalOrderedQuantity = SUM(z.OrderedQuantity)
		FROM (
			SELECT Drug_Pk
				,ISNULL(OrderedQuantity, 0) AS 'OrderedQuantity'
			FROM dtl_patientpharmacyorder
			WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk
			GROUP BY Drug_Pk
				,OrderedQuantity
			) AS z;

		SELECT @TotalDispensedQuantity = SUM(ISNULL(DispensedQuantity, 0))
		FROM dtl_patientpharmacyorder
		WHERE ptn_pharmacy_pk = @ptn_Pharmacy_Pk;

		IF (@TotalDispensedQuantity = @TotalOrderedQuantity)
		BEGIN
			UPDATE ord_PatientPharmacyOrder
			SET OrderStatus = 2
			WHERE DispensedByDate IS NOT NULL
				AND ptn_pharmacy_pk = @ptn_pharmacy_pk;
		END;

		IF (
				@TotalDispensedQuantity > 0
				AND @TotalDispensedQuantity < @TotalOrderedQuantity
				)
		BEGIN
			UPDATE ord_PatientPharmacyOrder
			SET OrderStatus = 3
			WHERE DispensedByDate IS NOT NULL
				AND ptn_pharmacy_pk = @ptn_pharmacy_pk;
		END;

		IF (@TotalDispensedQuantity < 1)
		BEGIN
			UPDATE ord_PatientPharmacyOrder
			SET OrderStatus = 1
			WHERE DispensedByDate IS NOT NULL
				AND ptn_pharmacy_pk = @ptn_pharmacy_pk
		END
	END;
END;
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [dbo].[pr_SCM_GetSelectedDrugDetails]
  @Drug_id int
, @StoreID int

as

select top 1 a.Drug_Pk,a.DrugName
, '' [BatchNo]
, 0 as [BatchId], isnull(d.Name,'') [DispensingUnit]               
, isnull(d.Id,0) [DispensingId]
, 0 as [SellingPrice]
, a.SellingUnitPrice[ConfigSellingPrice]
, '01-Jan-1990' [ExpiryDate]                 
, dbo.fn_GetItemStock_Futures(a.Drug_Pk,0,'',@StoreId) [AvailQty]
, isnull(a.DispensingUnitPrice,0) [CostPrice]    
, 1 [Funded]             
, isnull(a.DispensingMargin,0) [DispensingMargin], 0  as StrengthId       
, a.Drug_pk [DisplayItemId]
, dbo.fn_GetDrugTypeId_futures(a.Drug_Pk) [DrugTypeId]
, isnull(a.DrugAbbreviation,'') [GenericAbb]
, 0 as [BatchQty]
, a.ItemInstructions,a.QtyUnitDisp,a.syrup
, a.DrugAbbreviation as GenericAbbrevation
, a.MorDose, a.MidDose,a.EvenDose,a.NightDose                  
from dbo.Mst_Drug a             
Left Outer Join dbo.Mst_DispensingUnit d on a.DispensingUnit = d.Id
where a.Drug_pk=@Drug_id
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_GetItemStock_Futures] (
	@ItemId INT
	,@BatchId INT
	,@ExpiryDate DATETIME
	,@StoreId INT
	)
RETURNS INT
AS
BEGIN
	DECLARE @Qty INT

	set @Qty = (select top 1 x.StoreBal from dtl_DrugStockTransactions x 
				where x.drug_pk=@ItemId and x.StoreId=@storeid order by x.id desc)
		
	RETURN @Qty
END
go
--==

if not exists(select * from mst_Regimen where RegimenName='TDF + 3TC + DTG')
begin
	insert into mst_Regimen(RegimenID,Purpose, RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(72,222,1,'AF2E','TDF + 3TC + DTG',0)
	insert into mst_Regimen(RegimenID,Purpose, RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(73,222,1,'AF1D','AZT + 3TC + DTG',0)
	insert into mst_Regimen(RegimenID,Purpose, RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(74,222,1,'AF4C','ABC + 3TC + DTG',0)
	insert into mst_Regimen(RegimenID,Purpose, RegimenLineID,RegimenCode,RegimenName,DeleteFlag) values(75,222,3,'AS6X','TDF + 3TC + DTG',0)
end
go
--==

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
		ORDER BY OV.Visit_Id asc;
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

if not exists(select * from lnk_groupfeatures where FacilityID>0 and ModuleID>0 and FeatureID=298)
begin
	insert into lnk_groupfeatures(FacilityID, ModuleID, GroupID, FeatureID, FeatureName, TabID, FunctionID, CreateDate)
	select 757, 203, GroupID, FeatureID, FeatureName, TabID, FunctionID, CreateDate from lnk_GroupFeatures where FeatureID=298

	insert into lnk_FormTabSection(TabID, SectionID, FeatureID, UserID, CreateDate)
	select TabID, 1, FeatureID, 1, getdate() from Mst_FormBuilderTab where FeatureID=298

	update mst_Feature set ModuleId=203 where FeatureID=298
end
go
--==

update mst_Drug set PurchaseUnit = 37 where PurchaseUnit is null
update mst_Drug set DispensingUnit=51 where DispensingUnit is null
go
--=

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
		,LO.ReportedbyDate [TestDate]
		--,Case When LR.TestResults IS NOT NULL Then LR.TestResults when LR.TestResults1 IS NOT NULL then LR.TestResults1 else pr.Result end [Result]
		,CASE WHEN LR.TestResultId IS NOT NULL THEN Convert(varchar(20),pr.Result)
			  WHEN LR.TestResults IS NOT NULL THEN Convert(varchar(20),LR.TestResults)
		      else Convert(varchar(20),LR.TestResults1)
		END [Result]
		,CASE  WHEN Convert(DATETIME, LO.ReportedbyDate) = convert(DATE, getdate(), 101) THEN Convert(BIT, '1')
			   ELSE Convert(BIT, '0')
		END [Order]
		,LR.TestResults
		,LR.TestResults1
	FROM ord_PatientLabOrder LO
	INNER JOIN dtl_PatientLabResults LR ON LO.LabID = LR.LabID
	JOIN lnk_TestParameter TP ON LR.ParameterID = TP.SubTestID
		AND LO.Ptn_pk = @patientID
	LEFT JOIN [lnk_parameterresult] pr ON LR.TestResultId = pr.ResultID
END
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER function [dbo].[fn_GetPatientStatus]    

(    
   @ptn_pk int,    
   @ModuleId int    
)    

returns varchar(50)    

as    

Begin    

  declare @PatStatus varchar(50)   

     set @PatStatus = '' 

     select top 1 @PatStatus = (Case @ModuleId when 1 then PMTCTCareEnded when 2 then CareEnded when 203 then CareEnded end) from

     VW_PatientCareEnd where Ptn_Pk = @Ptn_Pk order by CareEndedId desc   

	  if(@PatStatus = '1')   
		  set @PatStatus = 'Care Ended'  
      else  
		  set @PatStatus = 'Active'  

  return @PatStatus      
End
go
--==

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[pr_GetPharmacypriorPrescription_Web] @ptn_pk INT
AS
BEGIN
 SELECT DISTINCT '0' AS orderId
  ,a.Drug_Pk [DrugId]
  ,a.DrugName [DrugName]
  ,a.[Dispensing Unit Id] [DispensingUnitId]
  ,a.[Dispensing Unit] [Unit]
  ,dbo.fn_GetItemStock_Futures(a.Drug_Pk,0,'',a.StoreId) [AvailQty]
  ,a.BatchNo
  ,a.BatchId
  ,convert(VARCHAR(11), a.ExpiryDate, 113) [ExpiryDate]
  ,a.MorningDose AS Morning
  ,a.MiddayDose AS Midday
  ,a.EveningDose AS Evening
  ,a.NightDose AS Night
  ,a.Duration
  ,a.PillCount
  ,a.OrderedQuantity AS [QtyPrescribed]
  ,a.DispensedQuantity [QtyDispensed]
  ,a.Prophylaxis
  ,a.comments
  ,a.PatientInstructions AS [Instructions]
  ,a.PrintPrescriptionStatus
  ,a.RegimenType [GenericAbbrevation]
  ,isnull(a.QtyUnitDisp, 0) QtyUnitDisp
  ,isnull(a.syrup, 0) syrup
  ,a.UserID
  ,a.StoreId
  ,a.RegimenLine
  ,a.RegimenId
 FROM vw_patientpharmacy a
 WHERE a.VisitID IN (
   SELECT MAX(VisitId)
   FROM ord_PatientPharmacyOrder
   WHERE Ptn_pk = @ptn_pk and (DeleteFlag=0 or DeleteFlag IS NULL)
   )
END
go
--==