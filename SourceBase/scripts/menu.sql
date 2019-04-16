
alter table mst_feature add FeatureCategoryId int
go

if not exists(select * from mst_Code where name='FeatureCategory')
begin
	insert into mst_Code(Name,DeleteFlag)values('FeatureCategory', 0)

	declare @id int = (select top 1 CodeID from mst_code where Name='FeatureCategory')
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Nursing',@id,1,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Clinical Review',@id,2,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Psychosocial Support',@id,3,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Nutrition',@id,4,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Specialized Care',@id,5,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Laboratory',@id,6,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Pharmacy',@id,7,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Targeted Strategies',@id,8,0,0,0) 
	insert into mst_Decode(name, Codeid, SRNo, UpdateFlag,DeleteFlag,SystemId)values('Retention',@id,9,0,0,0) 
end
go

declare @id int = (select top 1 CodeID from mst_code where Name='FeatureCategory')
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='Initial and Follow up Visits'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='ART History'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='ART Therapy'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='Green Card Form'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Psychosocial Support') where featurename='Treatment Preparation'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Psychosocial Support') where featurename='ART Readiness Assessment'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Psychosocial Support') where featurename='Transition from Paediatric to Adolescent Services'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Psychosocial Support') where featurename='Alcohol, GBV and Depression Screening'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='Clinical Encounter'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='Refill Encounter'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Psychosocial Support') where featurename='Enhance Adherence Counselling'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Psychosocial Support') where featurename='Morisky Adherence Screening'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='Clinical Notes'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Retention') where featurename='CareEnd_CCC Patient Card MoH 257'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='Intensive Case Finding'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='Cervical Cancer Screening Form'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='01a Mile Stones Immunization and Tanners Staging'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='01 Initial Evaluation Form'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Clinical Review') where featurename='02 Follow Up Form'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Psychosocial Support') where featurename='Adherence Form'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Retention') where featurename='Patient Tracer Form'
update mst_feature set FeatureCategoryId=(select top 1 id from mst_decode where CodeID=@id and name='Retention') where featurename='Patient Home-Visit Form'
go

if exists(select * from sysobjects where name='pr_admin_GetUserForms' and type='p')
	drop proc pr_admin_GetUserForms
go

create proc pr_admin_GetUserForms
 @Userid int
,@moduleid int
as
begin
	select distinct e.SRNo, e.ID, e.Name 
	from lnk_GroupFeatures a
	inner join lnk_UserGroup b on a.GroupID=b.GroupID
	inner join mst_User c on b.UserID=c.UserID
	inner join mst_Feature d on a.FeatureID=d.FeatureID
	inner join mst_Decode e on d.FeatureCategoryId=e.ID
	where c.UserID=@Userid and d.Published=2 and d.ModuleId=@moduleid
	order by e.SRNo

	select distinct d.FeatureID
	, case when d.FeatureName like 'careend_%' then 'Care End' else d.FeatureName end as FeatureName
	, d.FeatureCategoryId
	, e.name as FeatureCategory
	from lnk_GroupFeatures a
	inner join lnk_UserGroup b on a.GroupID=b.GroupID
	inner join mst_User c on b.UserID=c.UserID
	inner join mst_Feature d on a.FeatureID=d.FeatureID
	inner join mst_Decode e on d.FeatureCategoryId=e.ID
	where c.UserID=@Userid and d.Published=2 and d.ModuleId=@moduleid
end
go
--==

exec pr_admin_GetUserForms 42, 203