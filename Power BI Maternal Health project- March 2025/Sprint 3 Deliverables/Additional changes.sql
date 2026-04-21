select * from "Maternal_Health".Hospitalization_labor
select * from "Maternal_Health".patient_info
select * from "Maternal_Health".anthropometry where current_maternal_weight_3rd_tri=999
select * from "Maternal_Health".lab 
select * from "Maternal_Health".newborn_info
select * from "Maternal_Health".substance_usage
select * from "Maternal_Health".ultrasound

select * from "Maternal_Health".Hospitalization_labor where patient_id='171'

update "Maternal_Health".anthropometry set current_maternal_weight_3rd_tri= null
where current_maternal_weight_3rd_tri=999

update "Maternal_Health".Hospitalization_labor set 
disease_diagnose_during_pregnancy = 'VDRL'
where disease_diagnose_during_pregnancy ='VDRL ,'


select * from "Maternal_Health".Hospitalization_labor where delivery_mode is null






