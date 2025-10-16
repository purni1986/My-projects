select * from gv_glucose
/*Write a procedure to get all the patients who have glucose levels>110*/

CREATE OR REPLACE PROCEDURE public.high_glucose_patients_proc(
	INOUT ref refcursor)
LANGUAGE 'plpgsql'
AS $$
begin
open ref for
select * from gv_glucose where overall_avg_glucose>110
order by patientid;
END;
$$;

begin;
call high_glucose_patients_proc('refcursor');
FETCH ALL from refcursor

rollback

/* Function to categorize patients into three categories based on heartrate*/

create or replace function  heart_rate_category(p_patientid INT)
returns text as
$$
declare
patient_heart_rate_level numeric;
heart_rate_category TEXT;
begin
select overall_heart_rate into patient_heart_rate_level
from gv_heartrate
where patientid=p_patientid;
IF patient_heart_rate_level IS NULL THEN
  return 'No heart_rate measured';
END IF;
CASE
   WHEN patient_heart_rate_level<70 then 
   heart_rate_category :='Low Heart Rate/Bradycardia';
      WHEN patient_heart_rate_level>70 and patient_heart_rate_level<80  then 
   heart_rate_category :='Normal Heart Rate';
   WHEN patient_heart_rate_level>80 THEN
    heart_rate_category :='High Heart Rate/Tachycardia';
   ELSE
     heart_rate_category:='Invalid';
 END CASE;
 return  heart_rate_category;
 END;
 $$
 LANGUAGE PLPGSQL;

SELECT   heart_rate_category(16);
SELECT   heart_rate_category(2);
SELECT   heart_rate_category(5);
rollback
select * from gv_heartrate
/* Create a stored procedure to get all the critical parameters of patient 
with patientid as input*/

create or replace procedure get_patient_info_procedure(IN p_patientid INT,
out avg_glucose NUMERIC,
out avg_heart_rate numeric,
out avg_ibi numeric,
out avg_eda numeric,
out avg_temp numeric)
as
$$
BEGIN
select overall_avg_glucose,overall_average_heart_rate,
overall_average_eda,overall_average_ibi,overall_average_temperature
into avg_glucose,
avg_heart_rate,
avg_ibi,
avg_eda,
avg_temp
from critical_health_parameters where patientid=p_patientid;
IF NOT FOUND THEN 
RAISE EXCEPTION 'The patientid with id % does not exist',p_patientid;
END IF;
END;
$$
LANGUAGE plpgsql;

call get_patient_info_procedure(16,null,null,null,null,null)
call get_patient_info_procedure(21,null,null,null,null,null)

/* To get the patients who have hba1c>6*/

CREATE OR REPLACE PROCEDURE high_hba1c_levels_proc(
	INOUT ref refcursor)
LANGUAGE 'plpgsql'
AS $$
begin
open ref for
select * from gv_demography where hba1c>6;
END;
$$;

begin;
call high_hba1c_levels_proc('refcursor');
FETCH ALL from refcursor

/* To check if a patient exists in the table or not*/

begin;
call high_hba1c_levels_proc('refcursor');
FETCH ALL from refcursor

CREATE OR REPLACE PROCEDURE check_patient_exists(
	IN p_patientid integer,
	OUT exists_flag boolean)
LANGUAGE 'plpgsql'
AS $$
BEGIN
select exists (select 1 from gv_demography where patientid=p_patientid)
into exists_flag;
RAISE NOTICE 'Exists %', exists_flag;
END
$$;

DO
$$
DECLARE
 flag BOOLEAN;
BEGIN
call check_patient_exists(100,flag);
END;
$$

select * from gv_heartrate
select * from gv_eda_values

/* Write a function to get the abnormal vital parameters*/

create or replace function get_vital_parameters_abnormal(
min_glucose NUMERIC DEFAULT 110.0,
min_hr numeric DEFAULT 80.0,
min_eda numeric default 0.80,
min_ibi numeric default 0.96,
min_temperature numeric default 37.5
)
RETURNS TABLE (
patientid INT,
glucose numeric,
hr numeric,
eda numeric,
ibi numeric,
temperature numeric
) AS $$
begin
RETURN QUERY
select 
p.patientid,
p.overall_avg_glucose,
p.overall_average_heart_rate,
p.overall_average_eda,
p.overall_average_ibi,
p.overall_average_temperature
from 
critical_health_parameters p
where p.overall_avg_glucose>min_glucose
or p.overall_average_heart_rate>min_hr 
or p.overall_average_eda>min_eda
or p.overall_average_ibi<min_ibi
or p.overall_average_temperature< min_temperature
or p.overall_average_temperature> min_temperature;
end;
$$
language plpgsql;

select * from get_vital_parameters_abnormal();

/* Write a function to get all the abnormal parameters of a patient*/

create or replace function get_vital_parameters_abnormals(
min_glucose NUMERIC DEFAULT 110.0,
min_hr numeric DEFAULT 80.0
)
RETURNS TABLE (
patientid INT,
glucose numeric,
hr numeric
) AS $$
begin
RETURN QUERY
select 
p.patientid,
p.overall_avg_glucose,
p.overall_average_heart_rate
from 
critical_health_parameters p
where p.overall_avg_glucose>min_glucose
and p.overall_average_heart_rate>min_hr;
end;
$$
language plpgsql;

select * from get_vital_parameters_abnormals();
rollback

/* To get the glucose value measured on first day and last day and taking their 
difference*/

with avg_glucose_level as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.glucosevaluemgdl),2) as avg_glucose_day_wise
from gv_dexcom g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid),
first_day_last_day_glucose as
(select a.patientid,min(a.DAY) as first_day,max(a.DAY) as last_day,
min(a.avg_glucose_day_wise)
from avg_glucose_level a
group by a.patientid)
select a.patientid,b.first_day,b.last_day,
min(a.avg_glucose_day_wise) as first_day_glucose,
max(a.avg_glucose_day_wise) as last_day_glucose,
(max(a.avg_glucose_day_wise)-min(a.avg_glucose_day_wise)) as difference_in_glucose_measured
from first_day_last_day_glucose b
INNER JOIN avg_glucose_level a
ON a.patientid=b.patientid
where a.DAY in (b.first_day,b.last_day)
group by a.patientid,b.first_day,b.last_day

/* To find the patient who has minimum avg_ibi across all days*/

with avg_ibi_levels as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.ibi),2) as avg_ibi_day_wise
from gv_ibi g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid),

avg_ibi_levels_all_days as
(select a.patientid,a.gender,round(avg(a.avg_ibi_day_wise),2)as avg_ibi
from avg_ibi_levels a
group by a.patientid,a.gender
order by a.patientid)

select b.patientid,b.gender,b.avg_ibi as minimum_avg_ibi
from avg_ibi_levels_all_days b
where b.avg_ibi=(select min(b.avg_ibi) 
from avg_ibi_levels_all_days b)

/* To find the seven day moving average of glucose levels*/
WITH dailyglucoselevel AS (
 SELECT
patientid,
CAST(timeof AS DATE) AS date,
AVG(glucosevaluemgdl) AS avg_glucose_day_wise
FROM
gv_dexcom
GROUP BY patientid,
CAST(timeof AS DATE)
)
SELECT
d.patientid,
d.date,
d.avg_glucose_day_wise,
AVG(d.avg_glucose_day_wise) OVER (
PARTITION BY d.patientid
ORDER BY d.date
RANGE BETWEEN INTERVAL '6 day' PRECEDING AND CURRENT ROW
    ) AS seven_day_moving_avg_glucose_by_day
FROM
dailyglucoselevel d
ORDER BY
d.patientid, d.date;

/* to find the difference in calories intake by 
patients between current week and previous week*/

WITH calories_week_wise AS (
SELECT
fl.patientid,
 EXTRACT(YEAR FROM fl.timeof) AS year,
 EXTRACT(WEEK FROM fl.timeof) AS week_num, 
 SUM(f.calorie) AS total_weekly_calories
 FROM
 gv_food_log fl
 INNER JOIN gv_food f 
 ON fl.food_id=f.food_id
 GROUP BY
 fl.patientid,
 EXTRACT(YEAR FROM fl.timeof),
 EXTRACT(WEEK FROM fl.timeof)
 ORDER BY fl.patientid
)
select c.patientid,
c.year,
c.week_num,
c.total_weekly_calories,
lag(c.total_weekly_calories,1,0)OVER
(partition by c.patientid
order by c.year,c.week_num )AS calories_consumed_previous_week,
c.total_weekly_calories-lag(c.total_weekly_calories,1,0)
over (partition by c.patientid order by c.year,c.week_num) AS difference_in_calories
from 
calories_week_wise c
order by c.patientid, c.year,c.week_num;

/* Maximum calorie intake by patient and on which day based on calorie ranking*/

WITH DailyCalorieIntake AS (
SELECT
g.patientid,
g.logged_food,
DATE_TRUNC('day', g.timeof) as day,
MAX(f.calorie) as MAX_calories
FROM gv_food_log g
INNER JOIN gv_food f ON g.food_id = f.food_id
GROUP BY g.patientid, day,g.logged_food
),
RankedCalorieDays AS (
SELECT
 patientid,
 logged_food,
 day,
MAX_calories,
RANK() OVER (
PARTITION BY patientid
ORDER BY MAX_calories DESC
) AS rank_by_calories
FROM DailyCalorieIntake
)
SELECT
patientid,
day,
logged_food,
MAX_calories
FROM RankedCalorieDays
WHERE rank_by_calories = 1
ORDER BY patientid;

/* Maximum glucose levels measured and on which day based on glucose level ranking*/

WITH Dailyglucose AS (
SELECT
patientid,
DATE_TRUNC('day', timeof) as day,
MAX(GLUCOSEVALUEMGDL) as MAX_glucose_measured
FROM gv_dexcom 
GROUP BY patientid, day
),
RankedglucoseDays AS (
 SELECT
 patientid,
 day,
 MAX_glucose_measured,
 RANK() OVER (
 PARTITION BY patientid
 ORDER BY MAX_glucose_measured DESC
    ) AS rank_by_glucose
	FROM Dailyglucose
)

SELECT
patientid,
day,
MAX_glucose_measured
FROM RankedglucoseDays
WHERE rank_by_glucose = 1
ORDER BY patientid;

/*To calculate the RMSSD*/

WITH lagged_ibi AS (
    SELECT
        patientid,
        ibi,
        LAG(ibi, 1) OVER (PARTITION BY patientid ORDER BY timeof) AS previous_ibi
    FROM gv_ibi
    WHERE ibi IS NOT NULL
)
SELECT
    patientid,	
    SQRT(AVG(POWER(ibi - previous_ibi, 2))) AS RMSSD
FROM lagged_ibi
WHERE previous_ibi IS NOT NULL 
GROUP BY patientid
ORDER BY patientid;
