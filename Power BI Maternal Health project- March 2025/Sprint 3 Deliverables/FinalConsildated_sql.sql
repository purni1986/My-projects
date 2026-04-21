/* MATERNAL HEALTH-TRANSFORMATION AND LOADING- FINAL TABLES -SPRINT2*/

/* Patient Info*/

CREATE TABLE IF NOT EXISTS "Maternal_Health".Patient_Info(
    patient_id VARCHAR(5),
    Age SMALLINT,
    color_ethnicity VARCHAR(10),
    hypertension_past_reported SMALLINT,
    hypertension_past_treatment VARCHAR(15),
	DM_Chronic_Past_reported SMALLINT,
	diabetes_mellitus_dm_reported TEXT,
    diabetes_mellitus_disease_gap TEXT,
	chronic_diabetes TEXT,
    diabetes_mellitus_treatment VARCHAR(15),
	maternal_weight_at_inclusion DECIMAL(5,2),
	height_at_inclusion DECIMAL(5,2),
	current_bmi VARCHAR,
	current_bmi_according_who TEXT,
	gestational_age_at_inclusion DECIMAL(5,2),
	prepregnant_weight DECIMAL(5,2),
	prepregnant_bmi TEXT,
	bmi_according_who VARCHAR 
);

ALTER TABLE "Maternal_Health".Patient_Info
ADD CONSTRAINT pk_patient_id PRIMARY KEY (patient_id);

/* Insert cleaned Patient_Info data into the analytics table */   
INSERT INTO"Maternal_Health".Patient_Info
SELECT 
    case_id,

    CAST(age_years_old AS SMALLINT) AS Age,
    /* ethnicity mapping */
    CASE 
        WHEN color_ethnicity = '0' THEN 'White'
        WHEN color_ethnicity = '1' THEN 'Black'
        WHEN color_ethnicity = '2' THEN 'Brown'
        WHEN color_ethnicity = '3' THEN 'Asian'
        ELSE 'Unknown'
    END,
    /* hypertension_past_reported → SMALLINT */
    CAST(
        CASE 
            WHEN hypertension_past_reported IS NULL
              OR TRIM(LOWER(hypertension_past_reported)) IN ('', 'null')
            THEN NULL
            WHEN TRIM(hypertension_past_reported) = '1' THEN 1
            WHEN TRIM(hypertension_past_reported) = '0' THEN 0
            ELSE NULL
        END AS SMALLINT
    ),
    /* hypertension_past_treatment cleaned */
    CASE
    -- Standardize 'not applicable' to 'unknown'
    WHEN TRIM(LOWER(hypertension_past_treatment)) IN ('not_applicable','not applicable') THEN 'unknown'
    -- Apply treatment logic based on hypertension_past_reported
    WHEN NULLIF(hypertension_past_reported,'')::SMALLINT = 0
         AND TRIM(hypertension_past_treatment) IN ('1.00','') THEN 'no_medicine'

    WHEN NULLIF(hypertension_past_reported,'')::SMALLINT = 1
         AND TRIM(hypertension_past_treatment) = '0' THEN 'medicine'

    WHEN NULLIF(hypertension_past_reported,'')::SMALLINT = 1
         AND TRIM(hypertension_past_treatment) = '1' THEN 'no_medicine'
  
    ELSE TRIM(hypertension_past_treatment)
END AS hypertension_past_treatment,


/* DM_Chronic_Past_reported derived */
CAST(
CASE
    WHEN TRIM(diabetes_mellitus_disease_gap)  ='0' or TRIM(chronic_diabetes) = '1' THEN 2
    WHEN TRIM(diabetes_mellitus_disease_gap) = '1' OR TRIM(diabetes_mellitus_dm_reported) = '1' THEN 1
    WHEN TRIM(diabetes_mellitus_disease_gap) = 'not_applicable' OR TRIM(diabetes_mellitus_dm_reported) = '0'
      OR (TRIM(diabetes_mellitus_disease_gap) = '0' AND TRIM(chronic_diabetes) = '0')
    THEN 0
    ELSE NULL
	END AS SMALLINT),

    diabetes_mellitus_dm_reported,
    diabetes_mellitus_disease_gap,
    chronic_diabetes,
 /* dm treatment cleaned */
    CASE 
        WHEN diabetes_mellitus_treatment IS NULL
          OR TRIM(LOWER(diabetes_mellitus_treatment)) IN ('', 'null','not_applicable','not applicable')
        THEN NULL
        WHEN TRIM(diabetes_mellitus_treatment) = '0' THEN 'No Treatment'
        WHEN TRIM(diabetes_mellitus_treatment) = '1' THEN 'Medicine'
        WHEN TRIM(diabetes_mellitus_treatment) = '2' THEN 'Diet'
        ELSE NULL
    END,

    /* maternal_weight_at_inclusion */
    CASE
        WHEN maternal_weight_at_inclusion IS NULL
          OR TRIM(LOWER(maternal_weight_at_inclusion)) IN ('', 'null', 'not_applicable','not applicable')
        THEN NULL
        WHEN REPLACE(TRIM(maternal_weight_at_inclusion), ',', '') ~ '^[0-9]+(\.[0-9]+)?$'
        THEN REPLACE(TRIM(maternal_weight_at_inclusion), ',', '')::DECIMAL(5,2)
        ELSE NULL
    END,

    /* height_at_inclusion */
    CASE
        WHEN hight_at_inclusion IS NULL
          OR TRIM(LOWER(hight_at_inclusion)) IN ('', 'null', 'not_applicable','not applicable')
        THEN NULL
        WHEN REPLACE(TRIM(hight_at_inclusion), ',', '') ~ '^[0-9]+(\.[0-9]+)?$'
        THEN REPLACE(TRIM(hight_at_inclusion), ',', '')::DECIMAL(5,2)
        ELSE NULL
    END,

    /* current_bmi categorized */
CASE
    WHEN current_bmi IS NULL
         OR TRIM(LOWER(current_bmi)) IN ('', 'null', 'not_applicable')
    THEN NULL
    WHEN REPLACE(TRIM(current_bmi), ',', '') ~ '^[0-9]+(\.[0-9]+)?$'
         AND REPLACE(TRIM(current_bmi), ',', '')::NUMERIC < 18.5
    THEN 'Underweight'
    WHEN REPLACE(TRIM(current_bmi), ',', '')::NUMERIC < 25
    THEN 'Normal'
    WHEN REPLACE(TRIM(current_bmi), ',', '')::NUMERIC < 30
    THEN 'Overweight'
    ELSE 'Obese'
END,
    current_bmi_according_who,

    /* gestational_age_at_inclusion */
    CASE 
        WHEN gestational_age_at_inclusion IS NULL
          OR TRIM(LOWER(gestational_age_at_inclusion)) IN ('', 'na','n/a','none','not applicable','not_applicable','null')
        THEN NULL 
        ELSE NULLIF(REGEXP_REPLACE(gestational_age_at_inclusion,'[^0-9.\-]','','g'),'')::DECIMAL(5,2)
    END, 

    /* prepregnant_weight */
    CASE 
        WHEN prepregnant_weight IS NULL
          OR TRIM(LOWER(prepregnant_weight)) IN ('', 'null', 'no_answer','not_applicable','not applicable')
        THEN NULL
        WHEN REPLACE(TRIM(prepregnant_weight), ',', '') ~ '^[0-9]+(\.[0-9]+)?$'
        THEN REPLACE(TRIM(prepregnant_weight), ',', '')::DECIMAL(5,2)
        ELSE NULL
    END,

    prepregnant_bmi,
    bmi_according_who

FROM "Maternal_Fetal_Data_Raw".raw_maternal_fetal_data
WHERE case_id IS NOT NULL;

UPDATE "Maternal_Health".patient_info
SET hypertension_past_reported = 'No'
WHERE hypertension_past_reported = '0';

UPDATE "Maternal_Health".patient_info
SET hypertension_past_reported = 'Yes'
WHERE hypertension_past_reported = '1';


alter table "Maternal_Health".patient_info 

ALTER TABLE "Maternal_Health".patient_info 
ALTER COLUMN hypertension_past_reported TYPE varchar(15);

SELECT * FROM "Maternal_Health".patient_info

select hypertension_past_reported from "Maternal_Health".patient_info

-- Deleting and renaming columns
ALTER TABLE "Maternal_Health".patient_info DROP COLUMN diabetes_mellitus_dm_reported;
ALTER TABLE "Maternal_Health".patient_info DROP COLUMN diabetes_mellitus_disease_gap;
ALTER TABLE "Maternal_Health".patient_info DROP COLUMN chronic_diabetes;
ALTER TABLE "Maternal_Health".patient_info DROP COLUMN current_bmi_according_who;
ALTER TABLE "Maternal_Health".patient_info DROP COLUMN prepregnant_bmi;
ALTER TABLE "Maternal_Health".patient_info RENAME COLUMN bmi_according_who TO prepregnant_bmi;

-- New Prepregnant column categorization 
UPDATE "Maternal_Health".Patient_Info
SET prepregnant_bmi =
 CASE TRIM(prepregnant_bmi)
    WHEN '0' THEN 'underweight'
    WHEN '1' THEN 'Normal'
    WHEN '2' THEN 'overweight'
    WHEN '3' THEN 'obese'
    WHEN 'not applicable' THEN NULL
    ELSE NULL
END ;

select * from "Maternal_Health".patient_info


drop table  "Maternal_Health".Patient_Info CASCADE 

------------------------------------------------------------------------------------------------------------
/* Dietary habits*/

CREATE TABLE "Maternal_Health". Dietary_Habits
(
patient_id VARCHAR(5),
breakfast_meal VARCHAR(15),
morning_snack VARCHAR(15),
lunch_meal VARCHAR(15),
afternoon_snack VARCHAR(15),
meal_dinner VARCHAR(15),
supper_meal VARCHAR(15),
bean VARCHAR(15),
fruits VARCHAR(15),
vegetables VARCHAR(15),
embedded_food VARCHAR(15),
pasta VARCHAR(15),
cookies VARCHAR(15)
)

INSERT INTO "Maternal_Health". Dietary_Habits
(
patient_id,
breakfast_meal,
morning_snack,
lunch_meal,
afternoon_snack,
meal_dinner,
supper_meal,
bean,
fruits,
vegetables,
embedded_food,
pasta,
cookies
)
select
case_id,
CASE
	    WHEN breakfast_meal IS NULL THEN NULL
        WHEN CAST(breakfast_meal AS INT)= 0 THEN 'No'
		WHEN CAST(breakfast_meal AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as breakfast_meal,
CASE
	    WHEN morning_snack IS NULL THEN NULL
        WHEN CAST(morning_snack AS INT)= 0 THEN 'No'
		WHEN CAST(morning_snack AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as morning_snack,
CASE
	    WHEN lunch_meal IS NULL THEN NULL
        WHEN CAST(lunch_meal AS INT)= 0 THEN 'No'
		WHEN CAST(lunch_meal AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as lunch_meal,
CASE
	    WHEN afternoon_snack IS NULL THEN NULL
        WHEN CAST(afternoon_snack AS INT)= 0 THEN 'No'
		WHEN CAST(afternoon_snack AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as afternoon_snack,
CASE
	    WHEN meal_dinner IS NULL THEN NULL
        WHEN CAST(meal_dinner AS INT)= 0 THEN 'No'
		WHEN CAST(meal_dinner AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as meal_dinner,
CASE
	    WHEN supper_meal IS NULL THEN NULL
        WHEN CAST(supper_meal AS INT)= 0 THEN 'No'
		WHEN CAST(supper_meal AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as supper_meal,
CASE
	    WHEN bean IS NULL THEN NULL
        WHEN CAST(bean AS INT)= 0 THEN 'No'
		WHEN CAST(bean AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as bean,
CASE
	    WHEN fruits IS NULL THEN NULL
        WHEN CAST(fruits AS INT)= 0 THEN 'No'
		WHEN CAST(fruits AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as fruits,
CASE
	    WHEN vegetables IS NULL THEN NULL
        WHEN CAST(vegetables AS INT)= 0 THEN 'No'
		WHEN CAST(vegetables AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as vegetables,
CASE
	    WHEN embedded_food IS NULL THEN NULL
        WHEN CAST(embedded_food AS INT)= 0 THEN 'No'
		WHEN CAST(embedded_food AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as embedded_food,
CASE
	    WHEN pasta IS NULL THEN NULL
        WHEN CAST(pasta AS INT)= 0 THEN 'No'
		WHEN CAST(pasta AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as pasta,
CASE
	    WHEN cookies IS NULL THEN NULL
        WHEN CAST(cookies AS INT)= 0 THEN 'No'
		WHEN CAST(cookies AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as cookies
from
"Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage

select * from "Maternal_Health". Dietary_Habits

------------------------------------------------------------------------------------------------------------
/* Pregnancy_history*/

CREATE TABLE  "Maternal_Health".Pregnancy_History(
    patient_id VARCHAR(5) PRIMARY KEY,
    past_newborn_1_weight Text, 
    gestational_age_past_newborn_1 Text,
    past_newborn_2_weight Text,
    gestational_age_past_newborn_2 Text,
    past_newborn_3_weight Text,
    gestational_age_past_newborn_3 Text,
    past_newborn_4_weight Text,
    gestational_age_past_4_newborn text,
    past_pregnancies_number Text,
    miscarriage Text,
    FOREIGN KEY (patient_id) REFERENCES "Maternal_Health".Patient_Info(patient_id)
);

INSERT INTO "Maternal_Health".Pregnancy_History
select
    case_id,
    past_newborn_1_weight , 
    gestational_age_past_newborn_1 ,
    past_newborn_2_weight ,
    gestational_age_past_newborn_2 ,
    past_newborn_3_weight ,
    gestational_age_past_newborn_3 ,
    past_newborn_4_weight ,
    gestational_age_past_4_newborn ,
    past_pregnancies_number ,
    miscarriage 
    from "Maternal_Fetal_Data_Raw".raw_maternal_fetal_data

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_1_weight = NULL
WHERE past_newborn_1_weight IN ('not_applicable', 'no_answer', '');

/* Removing separator from numeric */
UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_1_weight = REPLACE(past_newborn_1_weight, ',', '');

/* Updating datatype */
ALTER TABLE "Maternal_Health".Pregnancy_History
ALTER COLUMN past_newborn_1_weight TYPE Integer USING past_newborn_1_weight::Integer;

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_newborn_1 = NULL
WHERE gestational_age_past_newborn_1 IN ('not_applicable', 'no_answer', '');

/* Convert coded values 0,1 to Meaningful Reporting Labels*/    

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_newborn_1 = CASE gestational_age_past_newborn_1
    WHEN '0' THEN 'Preterm'
    WHEN '1' THEN 'Fullterm'
    ELSE gestational_age_past_newborn_1
END;

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_2_weight = NULL
WHERE past_newborn_2_weight IN ('not_applicable', 'no_answer', '');

/* Removing separator from numeric */
UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_2_weight = REPLACE(past_newborn_2_weight, ',', '');

/* Updating datatype */
ALTER TABLE "Maternal_Health".Pregnancy_History
ALTER COLUMN past_newborn_2_weight TYPE Integer USING past_newborn_2_weight::Integer;

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_newborn_2 = NULL
WHERE gestational_age_past_newborn_2 IN ('not_applicable', 'no_answer', '');

/* Convert coded values 0,1 to Meaningful Reporting Labels    */    

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_newborn_2 = CASE gestational_age_past_newborn_2
    WHEN '0' THEN 'Preterm'
    WHEN '1' THEN 'Fullterm'
    ELSE gestational_age_past_newborn_2
END;

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_3_weight = NULL
WHERE past_newborn_3_weight IN ('not_applicable', 'no_answer', '');

/* Removing separator from numeric */
UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_3_weight = REPLACE(past_newborn_3_weight, ',', '');

/* Updating datatype */
ALTER TABLE "Maternal_Health".Pregnancy_History
ALTER COLUMN past_newborn_3_weight TYPE Integer USING past_newborn_3_weight::Integer;

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_newborn_3 = NULL
WHERE gestational_age_past_newborn_3 IN ('not_applicable', 'no_answer', '');

/* Convert coded values 0,1 to Meaningful Reporting Labels    */    

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_newborn_3 = CASE gestational_age_past_newborn_3
    WHEN '0' THEN 'Preterm'
    WHEN '1' THEN 'Fullterm'
    ELSE gestational_age_past_newborn_3
END;

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_4_weight = NULL
WHERE past_newborn_4_weight IN ('not_applicable', 'no_answer', '');

/* Removing separator from numeric */
UPDATE "Maternal_Health".Pregnancy_History
SET past_newborn_4_weight = REPLACE(past_newborn_4_weight, ',', '');

/* Updating datatype */
ALTER TABLE "Maternal_Health".Pregnancy_History
ALTER COLUMN past_newborn_4_weight TYPE Integer USING past_newborn_4_weight::Integer;

/* Replace missing placeholders in all the columns */

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_4_newborn = NULL
WHERE gestational_age_past_4_newborn IN ('not_applicable', 'no_answer', '');

/* Convert coded values 0,1 to Meaningful Reporting Labels    */    

UPDATE "Maternal_Health".Pregnancy_History
SET gestational_age_past_4_newborn = CASE gestational_age_past_4_newborn
    WHEN '0' THEN 'Preterm'
    WHEN '1' THEN 'Fullterm'
    ELSE gestational_age_past_4_newborn
END;

/* Rename column name */

ALTER TABLE "Maternal_Health".Pregnancy_History
RENAME COLUMN gestational_age_past_4_newborn TO gestational_age_past_newborn_4;  

/* Calculate past_pregnancies_number for rows with null values from past_newborn_weight columns */
UPDATE "Maternal_Health".Pregnancy_History
SET past_pregnancies_number =
    (CASE WHEN past_newborn_1_weight IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN past_newborn_2_weight IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN past_newborn_3_weight IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN past_newborn_4_weight IS NOT NULL THEN 1 ELSE 0 END)
WHERE past_pregnancies_number = '';

/* Updating datatype */
ALTER TABLE "Maternal_Health".Pregnancy_History
ALTER COLUMN past_pregnancies_number TYPE Integer USING past_pregnancies_number::Integer;

/* Updating datatype */
ALTER TABLE "Maternal_Health".Pregnancy_History
ALTER COLUMN miscarriage TYPE SMALLINT USING miscarriage::SMALLINT;

/* Update miscarriage 2,3 to 1 */
UPDATE "Maternal_Health".Pregnancy_History
SET miscarriage = 1
WHERE miscarriage IN (2, 3);


----------------------------------------------------------------------------------
/* Hospitalization table*/

CREATE TABLE "Maternal_Health".Hospitalization_labor
(
patient_id VARCHAR(5),
delivery_mode VARCHAR(50),
cesarean_section_reason VARCHAR(50),
prepartum_maternal_weight NUMERIC,
hospital_systolic_blood_pressure INTEGER,
hospital_diastolic_blood_pressure INTEGER,
hospital_hypertension VARCHAR(10),
gestational_diabetes_mellitus VARCHAR(30),
disease_diagnose_during_pregnancy VARCHAR(100),
treatment_disease_pregnancy VARCHAR(100),
chronic_diseases VARCHAR(10),
preeclampsia_record_pregnancy VARCHAR(10),
number_prenatal_appointments  INTEGER,
expected_weight_for_the_newborn NUMERIC,
mothers_hospital_stay INTEGER
)


INSERT INTO "Maternal_Health".Hospitalization_labor
(
patient_id ,
delivery_mode ,
cesarean_section_reason ,
prepartum_maternal_weight ,
hospital_systolic_blood_pressure ,
hospital_diastolic_blood_pressure ,
hospital_hypertension ,
gestational_diabetes_mellitus ,
disease_diagnose_during_pregnancy ,
treatment_disease_pregnancy ,
chronic_diseases ,
preeclampsia_record_pregnancy,
number_prenatal_appointments  ,
expected_weight_for_the_newborn ,
mothers_hospital_stay 
)
SELECT
case_id,
CASE
	    WHEN delivery_mode IS NULL THEN NULL
		WHEN CAST(delivery_mode AS INT)=1 THEN 'Vaginal'
		WHEN CAST(delivery_mode AS INT)=2 THEN 'Vaginal forcipe'
		WHEN CAST(delivery_mode AS INT)=5 THEN 'Cesarean section'
		WHEN CAST(delivery_mode AS INT)=6 THEN 'Cesarean section by jeopardy'
		WHEN CAST(delivery_mode AS INT)=7 THEN 'Vaginal with episiotomy'
		WHEN CAST(delivery_mode AS INT)=8 THEN 'Vaginal without episiotomy'
		WHEN CAST(delivery_mode AS INT)=9 THEN 'Vaginal with episiotomy plus forcipe'
		WHEN CAST(delivery_mode AS INT)=12 THEN 'Cesarean section'
        ELSE NULL
    END as delivery_mode,
CASE
    when cesarean_section_reason='no answer' then ' '
    when cesarean_section_reason='8' then 'NA' 
    when  cesarean_section_reason='12' then ' '
     else cesarean_section_reason
	 end as ascesarean_section_reason,
prepartum_maternal_weight,
hospital_systolic_blood_pressure,
hospital_diastolic_blood_pressure,
CASE
	    WHEN hospital_hypertension IS NULL THEN NULL
        WHEN CAST(hospital_hypertension AS INT)= 0 THEN 'No'
		WHEN CAST(hospital_hypertension AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as hospital_hypertension,

CASE
	    WHEN gestational_diabetes_mellitus IS NULL THEN NULL
        WHEN CAST(gestational_diabetes_mellitus AS INT)= 0 THEN 'No'
		WHEN CAST(gestational_diabetes_mellitus AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as gestational_diabetes_mellitus,
CASE
  WHEN disease_diagnose_during_pregnancy= 'Has secundária' then 'Hypertension'
  WHEN disease_diagnose_during_pregnancy ='HAS na baixa hospitalar' then 'Hyptertension'
  WHEN disease_diagnose_during_pregnancy ='HAS Gestation' then 'Gestational Hyptertension'
  WHEN disease_diagnose_during_pregnancy ='has gestational' then 'Gestational Hyptertension'
  WHEN disease_diagnose_during_pregnancy ='HAS' then 'Hyptertension'
  WHEN disease_diagnose_during_pregnancy ='has' then 'Hyptertension'
  WHEN disease_diagnose_during_pregnancy ='Has' then 'Hyptertension'
  WHEN disease_diagnose_during_pregnancy = 'HAS Gestation' then 'Gestational Hyptertension'
  WHEN disease_diagnose_during_pregnancy ='NA' then ''
  WHEN disease_diagnose_during_pregnancy ='itu' then 'UTI'
 WHEN disease_diagnose_during_pregnancy ='ITU' then 'UTI'
 WHEN disease_diagnose_during_pregnancy ='colestase' then 'cholestasis'
 WHEN disease_diagnose_during_pregnancy ='0' then ''
 WHEN disease_diagnose_during_pregnancy ='DMG' then 'GDM'
 WHEN disease_diagnose_during_pregnancy ='Has + DMG' then 'Gestational Hyptertension'
 WHEN disease_diagnose_during_pregnancy ='thb' then 'TB'
  WHEN disease_diagnose_during_pregnancy ='HAS +DMG' then 'Gestational Hyptertension'
 WHEN disease_diagnose_during_pregnancy ='not_applicable+CX20' then 'Cervix dilation 20'
WHEN disease_diagnose_during_pregnancy = '' then 'NA'
 ELSE disease_diagnose_during_pregnancy
 END as  disease_diagnose_during_pregnancy,
 
CASE
   WHEN treatment_disease_pregnancy= 'Sem tto' then ''
   WHEN treatment_disease_pregnancy= 'Sem TTo' then ''
  WHEN treatment_disease_pregnancy ='insulina' then 'Insulin'
  WHEN treatment_disease_pregnancy ='predinisolona' then 'Prednisolone'
  WHEN treatment_disease_pregnancy ='Medicamento' then 'Medication'
  WHEN treatment_disease_pregnancy ='medicamento' then 'Medication'
  WHEN treatment_disease_pregnancy ='medication' then 'Medication'
  WHEN treatment_disease_pregnancy ='Fluxetina' then 'Fluoxetine'
  WHEN treatment_disease_pregnancy='fluoxetina' then 'Fluoxetine'
  WHEN treatment_disease_pregnancy ='aspirina' then 'Aspirin'
  WHEN treatment_disease_pregnancy ='Metildopa' then 'Methyldopa'
    WHEN treatment_disease_pregnancy ='tapazol' then 'Tapazole'
  WHEN treatment_disease_pregnancy='metformina' then 'Metformine'
 WHEN treatment_disease_pregnancy ='ac valproico,' then 'Valproic acid'
 WHEN treatment_disease_pregnancy='sim' then 'Medication'
ELSE treatment_disease_pregnancy
END as treatment_disease_pregnancy,

CASE
	    WHEN chronic_diseases IS NULL THEN NULL
        WHEN CAST(chronic_diseases AS INT)= 0 THEN 'No'
		WHEN CAST(chronic_diseases AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as chronic_diseases,

CASE
	    WHEN preeclampsia_record_pregnancy IS NULL THEN NULL
        WHEN CAST(preeclampsia_record_pregnancy AS INT)= 0 THEN 'No'
		WHEN CAST(preeclampsia_record_pregnancy AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as preeclampsia_record_pregnancy,
number_prenatal_appointments,
expected_weight_for_the_newborn,
mothers_hospital_stay
from
"Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage;

select * from "Maternal_Health".Hospitalization_labor

/*Transformations for Hospitalization_labor table*/

UPDATE"Maternal_Health".Hospitalization_labor SET 
disease_diagnose_during_pregnancy='NA' WHERE
disease_diagnose_during_pregnancy=''

UPDATE "Maternal_Health".Hospitalization_labor
SET disease_diagnose_during_pregnancy =
    REPLACE(disease_diagnose_during_pregnancy, '+', ',')
WHERE disease_diagnose_during_pregnancy LIKE '%+%';

UPDATE "Maternal_Health".Hospitalization_labor
SET disease_diagnose_during_pregnancy =
    REPLACE(disease_diagnose_during_pregnancy, 'and', ',')
WHERE disease_diagnose_during_pregnancy LIKE '%and%';

 UPDATE "Maternal_Health".Hospitalization_labor
SET disease_diagnose_during_pregnancy = 'Cognitive deficit - depression,Gestational Hypertension'
where 
disease_diagnose_during_pregnancy = 'Cognitive deficit - depression , HAS Gestation'

UPDATE "Maternal_Health".Hospitalization_labor
SET disease_diagnose_during_pregnancy = 'VDRL ,'
where 
disease_diagnose_during_pregnancy = 'VDRL'

UPDATE "Maternal_Health".Hospitalization_labor
set treatment_disease_pregnancy = 'NA'
where treatment_disease_pregnancy ='45'

UPDATE "Maternal_Health".Hospitalization_labor
set treatment_disease_pregnancy = ''
where treatment_disease_pregnancy ='0'

UPDATE "Maternal_Health".Hospitalization_labor
set disease_diagnose_during_pregnancy = 'Hypertension'
where disease_diagnose_during_pregnancy ='Hyptertension'

UPDATE "Maternal_Health".Hospitalization_labor
set treatment_disease_pregnancy = null
where treatment_disease_pregnancy =''


UPDATE "Maternal_Health".Hospitalization_labor
SET (hospital_systolic_blood_pressure, hospital_diastolic_blood_pressure) =
    (hospital_diastolic_blood_pressure, hospital_systolic_blood_pressure)
WHERE hospital_systolic_blood_pressure < hospital_diastolic_blood_pressure;


UPDATE "Maternal_Health".Hospitalization_labor
set
hospital_hypertension ='No'
where
hospital_systolic_blood_pressure<=120 and
hospital_diastolic_blood_pressure<=80 

update  "Maternal_Health".Hospitalization_labor
set
hospital_hypertension = null where
hospital_systolic_blood_pressure is null and
hospital_diastolic_blood_pressure is null

UPDATE "Maternal_Health".Hospitalization_labor
set
hospital_hypertension ='Yes'
where
hospital_systolic_blood_pressure>120 or
hospital_diastolic_blood_pressure>80


select * from "Maternal_Health".Hospitalization_labor where cesarean_section_reason is not null
and 
------------------------------------------------------------------------------
/* Anthropometry*/

CREATE TABLE "Maternal_Health".Anthropometry
(
patient_id VARCHAR(5),
maternal_brachial_circumference  NUMERIC(3,1),
circumference_maternal_calf NUMERIC(3,1),
maternal_neck_circumference NUMERIC(3,1),
maternal_waist_circumference NUMERIC(4,1),
maternal_hip_circumference NUMERIC(4,1),
mean_tricciptal_skinfold NUMERIC(3,1),
mean_subscapular_skinfold NUMERIC(3,1),
mean_supra_iliac_skin_fold NUMERIC(3,1),
current_maternal_weight_1st_tri NUMERIC(5,2),
current_maternal_weight_2nd_tri NUMERIC(5,2),
current_maternal_weight_3rd_tri NUMERIC(5,2),
right_systolic_blood_pressure INTEGER,
right_diastolic_blood_pressure INTEGER,
left_systolic_blood_pressure INTEGER,
left_diastolic_blood_pressure INTEGER,
periumbilical_subcutanous_fat NUMERIC(3,1),
periumbilical_visceral_fat NUMERIC(3,1),
periumbilical_total_fat NUMERIC(4,1),
preperitoneal_subcutaneous_fat NUMERIC(3,1),
preperitoneal_visceral_fat NUMERIC(3,1)
)

insert into "Maternal_Health".Anthropometry
(
patient_id ,
maternal_brachial_circumference  ,
circumference_maternal_calf ,
maternal_neck_circumference ,
maternal_waist_circumference ,
maternal_hip_circumference ,
mean_tricciptal_skinfold ,
mean_subscapular_skinfold ,
mean_supra_iliac_skin_fold ,
current_maternal_weight_1st_tri,
current_maternal_weight_2nd_tri ,
current_maternal_weight_3rd_tri ,
right_systolic_blood_pressure ,
right_diastolic_blood_pressure ,
left_systolic_blood_pressure ,
left_diastolic_blood_pressure ,
periumbilical_subcutanous_fat,
periumbilical_visceral_fat ,
periumbilical_total_fat ,
preperitoneal_subcutaneous_fat ,
preperitoneal_visceral_fat 
)
select
case_id ,
maternal_brachial_circumference  ,
circumference_maternal_calf ,
maternal_neck_circumference ,
maternal_waist_circumference ,
maternal_hip_circumference ,
mean_tricciptal_skinfold ,
mean_subscapular_skinfold ,
mean_supra_iliac_skin_fold ,
current_maternal_weight_1st_tri ::numeric,
current_maternal_weight_2nd_tri :: numeric ,
current_maternal_weight_3rd_tri :: numeric ,
right_systolic_blood_pressure ,
right_diastolic_blood_pressure ,
left_systolic_blood_pressure ,
left_diastolic_blood_pressure ,
periumbilical_subcutanous_fat,
periumbilical_visceral_fat ,
periumbilical_total_fat ,
preperitoneal_subcutaneous_fat ,
preperitoneal_visceral_fat 
from
"Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage

select * from "Maternal_Health".Anthropometry

update "Maternal_Health".Anthropometry
set
periumbilical_total_fat =
periumbilical_subcutanous_fat + periumbilical_visceral_fat
where
periumbilical_total_fat is null

update "Maternal_Health".Anthropometry
set
periumbilical_total_fat =
periumbilical_subcutanous_fat + periumbilical_visceral_fat
where
periumbilical_subcutanous_fat is not null
and
periumbilical_visceral_fat is not null

drop table "Maternal_Health".Anthropometry

----------------------------------------------------------------------------------
/* Newborn_Info*/

CREATE TABLE "Maternal_Health".Newborn_Info
(
patient_id VARCHAR(5),
newborn_weight DECIMAL(7,2),
newborn_height DECIMAL(5,2),
gestational_age_at_birth DECIMAL(5,1),
newborn_head_circumference DECIMAL (5,2),
thoracic_perimeter_newborn DECIMAL(5,1),
meconium_labor VARCHAR(15),
apgar_1st_min SMALLINT,
apgar_5th_min SMALLINT,
pediatric_resuscitation_maneuvers VARCHAR(15),
newborn_intubation VARCHAR(15),
newborn_airway_aspiration VARCHAR(15)
)

INSERT INTO "Maternal_Health".Newborn_Info
(
patient_id ,
newborn_weight ,
newborn_height ,
gestational_age_at_birth ,
newborn_head_circumference ,
thoracic_perimeter_newborn ,
meconium_labor ,
apgar_1st_min ,
apgar_5th_min ,
pediatric_resuscitation_maneuvers ,
newborn_intubation ,
newborn_airway_aspiration 
)
select
case_id ,
newborn_weight ,
newborn_height ,
gestational_age_at_birth ,
newborn_head_circumference ,
thoracic_perimeter_newborn ,
 CASE
	    WHEN meconium_labor IS NULL THEN NULL
        WHEN CAST(meconium_labor AS INT)= 0 THEN 'No'
		WHEN CAST(meconium_labor AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as meconium_lab,
apgar_1st_min ,
apgar_5th_min ,
 CASE
	    WHEN pediatric_resuscitation_maneuvers IS NULL THEN NULL
        WHEN CAST(pediatric_resuscitation_maneuvers AS INT)= 0 THEN 'No'
		WHEN CAST(pediatric_resuscitation_maneuvers AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as pediatric_resuscitation_maneuvers,
 CASE
	    WHEN newborn_intubation IS NULL THEN NULL
        WHEN CAST(newborn_intubation AS INT)= 0 THEN 'No'
		WHEN CAST(newborn_intubation AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as newborn_intubation,
 CASE
	    WHEN newborn_airway_aspiration  IS NULL THEN NULL
        WHEN CAST(newborn_airway_aspiration  AS INT)= 0 THEN 'No'
		WHEN CAST(newborn_airway_aspiration  AS INT)= 1 THEN 'Yes'
        ELSE NULL
    END as newborn_airway_aspiration  
from
"Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage

DROP TABLE "Maternal_Health".Newborn_Info

select * from "Maternal_Health".Newborn_Info

update "Maternal_Health".Newborn_Info set 
apgar_1st_min = null
where apgar_1st_min =99


---------------------------------------------------------------------------------

/* Creation of table Substance_Usage*/

create table "Maternal_Health".Substance_Usage
(
patient_id varchar(5),
tobacco_use VARCHAR(15),
tobacco_use_in_months NUMERIC(5,2),
tobacco_quantity_by_day NUMERIC(5,2),
alcohol_use VARCHAR(15),
alcohol_quantity_milliliters INTEGER,
alcohol_preference VARCHAR(20),
drugs_preference VARCHAR(15),
drugs_years_use NUMERIC(5,2),
drugs_during_pregnancy VARCHAR(15)
)

INSERT INTO "Maternal_Health".Substance_Usage
(
patient_id,
tobacco_use,
tobacco_use_in_months,
tobacco_quantity_by_day,
alcohol_use,
alcohol_quantity_milliliters,
alcohol_preference,
drugs_preference,
drugs_years_use,
drugs_during_pregnancy
)
SELECT 
case_id,
 CASE 
	   WHEN tobacco_use IS NULL THEN NULL
       WHEN CAST(tobacco_use AS INT)=0 THEN 'No'
       WHEN  CAST(tobacco_use AS INT)=1 THEN 'Yes'
	   ELSE NULL
   END as tobacco_use,

tobacco_use_in_months,
tobacco_quantity_by_day,
 CASE 
	   WHEN alcohol_use IS NULL THEN NULL
       WHEN CAST(alcohol_use AS INT)=0 THEN 'No'
       WHEN  CAST(alcohol_use AS INT)=1 THEN 'Yes'
	   ELSE NULL
   END as alcohol_use,
alcohol_quantity_milliliters,
CASE 
	   WHEN alcohol_preference  IS NULL THEN NULL
       WHEN CAST(alcohol_preference AS INT)=0 THEN 'Fermented'
       WHEN  CAST(alcohol_preference AS INT)=1 THEN 'Distilled'
	   ELSE NULL
   END as Alcohol_preference,
 CASE 
	   WHEN drugs_preference  IS NULL THEN NULL
       WHEN CAST(drugs_preference AS INT)=0 THEN 'No'
       WHEN  CAST(drugs_preference AS INT)=1 THEN 'Yes'
	   ELSE NULL
   END as drugs_preference,
   
drugs_years_use,
CASE 
	   WHEN drugs_during_pregnancy  IS NULL THEN NULL
       WHEN CAST(drugs_during_pregnancy AS INT)=0 THEN 'No'
       WHEN  CAST(drugs_during_pregnancy  AS INT)=1 THEN 'Yes'
	   ELSE NULL
   END as drugs_during_pregnancy
FROM "Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage;

select * from "Maternal_Health".Substance_Usage

drop table "Maternal_Health".Substance_Usage
-------------------------------------------------------------------------------

/* Ultrasound*/

CREATE TABLE "Maternal_Health".Ultrasound
(
patient_id varchar(5),
fetal_weight_at_ultrasound INTEGER,
weight_fetal_percentile VARCHAR(50),
ultrasound_gestational_age NUMERIC(3,1)
)

INSERT INTO "Maternal_Health".Ultrasound
(
patient_id,
fetal_weight_at_ultrasound,
weight_fetal_percentile,
ultrasound_gestational_age
)
SELECT 
case_id,
fetal_weight_at_ultrasound,
CASE 
	   WHEN weight_fetal_percentile  IS NULL THEN NULL
       WHEN CAST(weight_fetal_percentile AS INT)=0 THEN 'percentile 10'
       WHEN  CAST(weight_fetal_percentile AS INT)=1 THEN 'percentile 10-25'
	   WHEN  CAST(weight_fetal_percentile AS INT)=2 THEN 'percentile 25'
	   WHEN  CAST(weight_fetal_percentile AS INT)=3 THEN 'percentile 25-50'
	   WHEN  CAST(weight_fetal_percentile AS INT)=4 THEN 'percentile 50'
	   WHEN  CAST(weight_fetal_percentile AS INT)=5 THEN 'percentile 50-75'
	   WHEN  CAST(weight_fetal_percentile AS INT)=6 THEN 'percentile 75'
	   WHEN  CAST(weight_fetal_percentile AS INT)=7 THEN 'percentile 75-90'
	   WHEN  CAST(weight_fetal_percentile AS INT)=8 THEN 'percentile 90'
	   ELSE NULL
   END as weight_fetal_percentile,
  ultrasound_gestational_age
FROM "Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage;
 
select * from  "Maternal_Health".Ultrasound 

select * from  "Maternal_Health".Ultrasound where patient_id='283'
------------------------------------------------------------------------------------

/* Lab */

CREATE TABLE "Maternal_Health".Lab
(
patient_id VARCHAR(5),
first_trimester_hematocrit NUMERIC(3,1),
second_trimester_hematocrit NUMERIC(3,1) ,
third_trimester_hematocrit NUMERIC(3,1),
first_trimester_hemoglobin NUMERIC(3,1),
second_trimester_hemoglobin NUMERIC(3,1),
third_trimester_hemoglobin NUMERIC(3,1),
first_tri_fasting_blood_glucose INTEGER,
second_tri_fasting_blood_glucose INTEGER,
third_tri_fasting_blood_glucose INTEGER,
"1st_hour_ogtt75_1st_tri" INTEGER,
"1st_hour_ogtt75_2tri" INTEGER,
"1st_hour_ogtt75_3tri" INTEGER,
"2nd_hour_ogtt_1tri" INTEGER,
"2nd_hour_ogtt75_2tri" INTEGER,
"2nd_hour_ogtt_3tri" INTEGER,
hiv_1tri VARCHAR(15),
syphilis_1tri VARCHAR(15),
c_hepatitis_1tri VARCHAR(15)
)

/* Correct the invalid value 121 to 12.1 for patient_id 177*/

update "Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage 
set third_trimester_hemoglobin=12.1
where case_id=177

INSERT INTO "Maternal_Health".Lab
(
patient_id,
first_trimester_hematocrit,
second_trimester_hematocrit,
third_trimester_hematocrit,
first_trimester_hemoglobin,
second_trimester_hemoglobin,
third_trimester_hemoglobin,
first_tri_fasting_blood_glucose,
second_tri_fasting_blood_glucose,
third_tri_fasting_blood_glucose,
"1st_hour_ogtt75_1st_tri",
"1st_hour_ogtt75_2tri",
"1st_hour_ogtt75_3tri",
"2nd_hour_ogtt_1tri",
"2nd_hour_ogtt75_2tri",
"2nd_hour_ogtt_3tri",
hiv_1tri,
syphilis_1tri,
c_hepatitis_1tri
)
SELECT
case_id,
first_trimester_hematocrit,
second_trimester_hematocrit,
third_trimester_hematocrit,
first_trimester_hemoglobin,
second_trimester_hemoglobin,
third_trimester_hemoglobin,
first_tri_fasting_blood_glucose,
second_tri_fasting_blood_glucose,
third_tri_fasting_blood_glucose,
"1st_hour_ogtt75_1st_tri",
"1st_hour_ogtt75_2tri",
"1st_hour_ogtt75_3tri",
"2nd_hour_ogtt_1tri",
"2nd_hour_ogtt75_2tri",
"2nd_hour_ogtt_3tri",
CASE 
	   WHEN hiv_1tri  IS NULL THEN NULL
       WHEN CAST(hiv_1tri AS INT)=0 THEN 'No'
       WHEN  CAST(hiv_1tri AS INT)=1 THEN 'Yes'
	   ELSE NULL
   END as hiv_1tri,
CASE 
	   WHEN syphilis_1tri IS NULL THEN NULL
       WHEN CAST(syphilis_1tri AS INT)=0 THEN 'No'
       WHEN  CAST(syphilis_1tri AS INT)=1 THEN 'Yes'
	   ELSE NULL
   END as syphilis_1tri,
 CASE 
	   WHEN c_hepatitis_1tri IS NULL THEN NULL
       WHEN CAST(c_hepatitis_1tri AS INT)=0 THEN 'No'
       WHEN  CAST(c_hepatitis_1tri AS INT)=1 THEN 'Yes'
	   ELSE NULL
   END as c_hepatitis_1tri
   
from
"Maternal_Fetal_Data_Raw".stage_maternal_fetal_stage

ALTER TABLE "Maternal_Health".Lab RENAME "1st_hour_ogtt75_1st_tri" TO
first_hour_ogtt75_1tri

ALTER TABLE "Maternal_Health".Lab RENAME "1st_hour_ogt1_2tri" TO
first_hour_ogtt75_2tri

ALTER TABLE "Maternal_Health".Lab RENAME "1st_hour_ogtt75_3tri" TO
first_hour_ogtt75_3tri

ALTER TABLE "Maternal_Health".Lab RENAME "2nd_hour_ogtt_1tri" TO
second_hour_ogtt75_1tri

ALTER TABLE "Maternal_Health".Lab RENAME "2nd_hour_ogtt75_2tri" TO
second_hour_ogtt75_2tri

ALTER TABLE "Maternal_Health".Lab RENAME "2nd_hour_ogtt_3tri" TO
second_hour_ogtt75_3tri

SELECT * FROM "Maternal_Health".Lab


/* update null hematocrit values wherever there in null*/

update "Maternal_Health".Lab set first_trimester_hematocrit=
first_trimester_hemoglobin*2.94 where first_trimester_hematocrit is null
and first_trimester_hemoglobin is not null

update "Maternal_Health".Lab set second_trimester_hematocrit=
second_trimester_hemoglobin*2.94 where second_trimester_hematocrit is null
and second_trimester_hemoglobin is not null

update "Maternal_Health".Lab set third_trimester_hematocrit=
third_trimester_hemoglobin*2.94 where third_trimester_hematocrit is null
and third_trimester_hemoglobin is not null

/* update hemoglobin values which are null*/

update "Maternal_Health".Lab set first_trimester_hemoglobin=
first_trimester_hematocrit/2.94 where first_trimester_hemoglobin is null
and first_trimester_hematocrit is not null

update "Maternal_Health".Lab set second_trimester_hemoglobin=
second_trimester_hematocrit/2.94 where second_trimester_hemoglobin is null
and second_trimester_hematocrit is not null

update "Maternal_Health".Lab set third_trimester_hemoglobin=
third_trimester_hematocrit/2.94 where third_trimester_hemoglobin is null
and third_trimester_hematocrit is not null


SELECT * FROM "Maternal_Health".Lab where patient_id='42'

SELECT * FROM "Maternal_Health".Lab

delete from "Maternal_Health".Lab

drop table "Maternal_Health".Lab

-----------------------------------------------------------------------------------------
/* Adding foreign key constraints for patient_id*/

ALTER TABLE "Maternal_Health". Dietary_Habits
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

ALTER TABLE "Maternal_Health". Newborn_Info
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

ALTER TABLE "Maternal_Health".Anthropometry
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

ALTER TABLE "Maternal_Health".Hospitalization_labor
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

ALTER TABLE "Maternal_Health".Substance_Usage
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

ALTER TABLE "Maternal_Health".Ultrasound
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

ALTER TABLE "Maternal_Health".Lab
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

ALTER TABLE "Maternal_Health".Pregnancy_history
ADD FOREIGN KEY(patient_id) REFERENCES "Maternal_Health".patient_info(patient_id)

---------------------------------------------------------------------------------------
/*Making patient_id as unique for creating 1:1 relationship*/

ALTER TABLE "Maternal_Health". Dietary_Habits
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".dietary_habits
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);

ALTER TABLE "Maternal_Health".Newborn_Info
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".Newborn_Info
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);

ALTER TABLE "Maternal_Health".Anthropometry
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".Anthropometry
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);


ALTER TABLE "Maternal_Health".Hospitalization_labor
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".Hospitalization_labor
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);


ALTER TABLE "Maternal_Health".Substance_Usage
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".Substance_Usage
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);


ALTER TABLE "Maternal_Health".Ultrasound
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".Ultrasound
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);

ALTER TABLE "Maternal_Health".Lab
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".Lab
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);

ALTER TABLE "Maternal_Health".Pregnancy_history
ADD PRIMARY KEY (patient_id);

ALTER TABLE "Maternal_Health".Pregnancy_history
ADD 
FOREIGN KEY (patient_id)
REFERENCES "Maternal_Health".patient_info(patient_id);
-------------------------------------------------------------------------------------
select * from "Maternal_Health".patient_info
select * from "Maternal_Health".Anthropometry
select * from "Maternal_Health".Newborn_Info
select * from "Maternal_Health".Hospitalization_labor
select * from "Maternal_Health".Substance_Usage
select * from "Maternal_Health".Ultrasound
select * from "Maternal_Health".Lab
select * from "Maternal_Health".Pregnancy_history
select * from "Maternal_Health".Dietary_habits
-------------------------------------------------------------------------------------------
alter table "Maternal_Health". Dietary_Habits drop column dietary_id



alter table "Maternal_Health".Anthropometry drop column anthropometry_id

alter table "Maternal_Health".Newborn_Info drop column newborn_id

alter table "Maternal_Health".Hospitalization_labor drop column labor_id

alter table "Maternal_Health".Substance_Usage drop column substance_id

alter table "Maternal_Health".Ultrasound drop column ultrasound_id

alter table "Maternal_Health".Pregnancy_history drop column Pregnancy_history_id

alter table "Maternal_Health".lab drop column lab_id
------------------------------------------------------------------------------------------------------------

update "Maternal_Health".Hospitalization_labor set cesarean_section_reason='not applicable'
where delivery_mode ='Vaginal without episiotomy'

update "Maternal_Health".Hospitalization_labor set cesarean_section_reason='not applicable'
where delivery_mode ='Vaginal with episiotomy'

delete from "Maternal_Health".Hospitalization_labor

select * from "Maternal_Health".Hospitalization_labor


