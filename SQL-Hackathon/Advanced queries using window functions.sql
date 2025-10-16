/*1.Average glucose levels of patients overall*/

with avg_glucose_levels as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.glucosevaluemgdl),2) as avg_glucose_day_wise
from gv_dexcom g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,round(avg(a.avg_glucose_day_wise),2)as avg_glucose
from avg_glucose_levels a
group by a.patientid,a.gender
order by a.patientid

select g.patientid ,d.gender ,
ROUND(avg(g.glucosevaluemgdl),2) as avg_glucose
from gv_dexcom g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,d.gender
ORDER BY g.patientid

select patientid,gender,hba1c
from gv_demography
where hba1c=(select max(hba1c) from gv_demography)


/*which patient has maximum eda levels compared to all the other patients and 
on which day*/

with avg_eda_levels as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.eda),2) as avg_eda_day_wise
from gv_eda g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,a.DAY,a.avg_eda_day_wise as maximum_eda_day_wise
from avg_eda_levels a
where a.avg_eda_day_wise=(select max(a.avg_eda_day_wise) 
from avg_eda_levels a)

/*which patient has minimum ibi levels compared to all the other patients and 
on which day*/

with avg_ibi_levels as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.ibi),2) as avg_ibi_day_wise
from gv_ibi g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,a.DAY,a.avg_ibi_day_wise as maximum_ibi_day_wise
from avg_ibi_levels a	
where a.avg_ibi_day_wise=(select min(a.avg_ibi_day_wise) 
from avg_ibi_levels a)

select * from gv_ibi

/* On which day, all patients had minimum ibi*/

WITH min_ibi_per_patient AS (
SELECT 
patientid, 
Min(ibi) AS max_ibi
FROM gv_ibi
GROUP BY patientid
)
SELECT 
g.patientid,
DATE_TRUNC('day', g.timeof) AS day,
g.ibi AS min_ibi
FROM gv_ibi g
INNER JOIN min_ibi_per_patient m
ON g.patientid = m.patientid
AND g.ibi = m.max_ibi
ORDER BY g.patientid

/* On which day, a patient had maximum glucose*/

WITH max_glucose_per_patient AS (
SELECT 
patientid, 
max(glucosevaluemgdl) AS max_glucose
FROM gv_dexcom
GROUP BY patientid
)
SELECT 
g.patientid,
DATE_TRUNC('day', g.timeof) AS day,
g.glucosevaluemgdl AS max_glucose
FROM gv_dexcom g
INNER JOIN max_glucose_per_patient m
ON g.patientid = m.patientid
AND g.glucosevaluemgdl = m.max_glucose
ORDER BY g.patientid


/* To find the patient who has maximum avg_glucose across all days*/

with avg_glucose_levels as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.glucosevaluemgdl),2) as avg_glucose_day_wise
from gv_dexcom g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid),

avg_glucose_levels_all_days as
(select a.patientid,a.gender,round(avg(a.avg_glucose_day_wise),2)as avg_glucose
from avg_glucose_levels a
group by a.patientid,a.gender
order by a.patientid)

select b.patientid,b.gender,b.avg_glucose
from avg_glucose_levels_all_days b
where b.avg_glucose=(select max(b.avg_glucose) 
from avg_glucose_levels_all_days b)

/* To find the patient who has maximum avg_eda across all days*/

with avg_eda_levels as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.eda),2) as avg_eda_day_wise
from gv_eda g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid),

avg_eda_levels_all_days as
(select a.patientid,a.gender,round(avg(a.avg_eda_day_wise),2)as avg_eda
from avg_eda_levels a
group by a.patientid,a.gender
order by a.patientid)

select b.patientid,b.gender,b.avg_eda as maximum_avg_eda
from avg_eda_levels_all_days b
where b.avg_eda=(select max(b.avg_eda) 
from avg_eda_levels_all_days b)

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


/* To find the cumulative calories based on food taken by patients partioned over timeof*/

SELECT
g.patientid,
g.timeof,
f.calorie,
g.logged_food,
SUM(f.calorie) OVER (PARTITION BY g.timeof ORDER BY g.timeof) AS cumulative_calories
FROM
gv_food f
INNER JOIN gv_food_log g
ON f.food_id=g.food_id
ORDER BY
g.patientid, g.timeof

select * from gv_dexcom

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

/*Maximum calorie intake by each patient*/

with max_calorie_intake as
(select g.patientid,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(max(f.calorie),2) as max_calories
from gv_food_log g
INNER JOIN gv_food f
ON g.food_id=f.food_id
group by g.patientid,DAY
ORDER BY g.patientid)
select a.patientid,round(max(a.max_calories),2)as max_calories_across_days
from max_calorie_intake a
group by a.patientid
order by a.patientid
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

select * from gv_hr

/*To find the average Heart Rate of all the patients*/

with average_hr as
(select patientid,
date_trunc('day',timeof) as day,
round(avg(hr),2)as avg_hr_day_wise
from gv_hr
group by patientid,day
order by patientid)
select a.patientid,round(avg(avg_hr_day_wise),2) as avg_hr
from average_hr a
group by a.patientid
order by a.patientid

/* average calories consumed across all days by patients*/

with day_wise_total_calories_consumption AS
(select f.patientid ,d.gender,
DATE_TRUNC('day',f.timeof) as DAY,
ROUND(sum(g.calorie),2) as total_calories_day_wise
from gv_food_log f
INNER JOIN gv_food g ON g.food_id=f.food_id
INNER JOIN gv_demography d
ON f.patientid=d.patientid
group by f.patientid,DAY,d.gender
ORDER BY f.patientid)
SELECT b.patientid,b.gender,
round(avg(b.total_calories_day_wise),2) as Avg_calories_consumed_across_days
from day_wise_total_calories_consumption b
group by b.patientid,b.gender
order by b.patientid

/* which patient consumed the maximum average calories among all the patients across
all days*/

with day_wise_total_calories_consumption AS
(select f.patientid ,d.gender,
DATE_TRUNC('day',f.timeof) as DAY,
ROUND(sum(g.calorie),2) as total_calories_day_wise
from gv_food_log f
INNER JOIN gv_food g ON g.food_id=f.food_id
INNER JOIN gv_demography d
ON f.patientid=d.patientid
group by f.patientid,DAY,d.gender
ORDER BY f.patientid),
max_avg_calorie_consumption as
(SELECT b.patientid,b.gender,
round(avg(b.total_calories_day_wise),2) as Avg_calories_consumed_across_days
from day_wise_total_calories_consumption b
group by b.patientid,b.gender
order by b.patientid)
select c.patientid,c.gender,c. Avg_calories_consumed_across_days
from max_avg_calorie_consumption c
where c. Avg_calories_consumed_across_days=(select max(c. Avg_calories_consumed_across_days) 
from max_avg_calorie_consumption c )

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





WITH ibi_values AS (
    SELECT
        patientid,
        AVG(ibi) AS patient_average_ibi
    FROM
        gv_ibi
    GROUP BY
        patientid
),
overall_stats AS (
    SELECT
        AVG(patient_average_ibi) AS overall_avg,
        STDDEV(patient_average_ibi) AS overall_stddev
    FROM
        ibi_values
)
SELECT
    a.patientid,
    a.patient_average_ibi,
	b.overall_stddev
FROM
    ibi_values a, overall_stats b
WHERE
    a.patient_average_ibi < (b.overall_avg + 2 * b.overall_stddev)
	OR a.patient_average_ibi > (b.overall_avg + 2 * b.overall_stddev)
ORDER BY a.patientid

/* Patients with individual average ibi values compare to overall average*/

WITH ibi_values AS (
    SELECT
        patientid,
        AVG(ibi) AS patient_average_ibi
    FROM
        gv_ibi
    GROUP BY
        patientid
),
overall_stats AS (
    SELECT
        AVG(patient_average_ibi) AS overall_avg
        FROM
        ibi_values
)
SELECT
    a.patientid,
    a.patient_average_ibi,
	b.overall_avg
FROM
    ibi_values a, overall_stats b
WHERE
    a.patient_average_ibi < b.overall_avg 
OR a.patient_average_ibi > b.overall_avg 
ORDER BY a.patientid

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

select * from critical_health_parameters