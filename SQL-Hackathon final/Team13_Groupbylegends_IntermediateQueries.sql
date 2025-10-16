select * from gv_ibi
/* 1.Get the patients, number of days their ibi values were measured, along with their 
average ibi values*/

select patientid, count(distinct DATE_TRUNC('day', timeof)) as number_of_days_measured,
round(avg(ibi),2) as avg_ibi,
max(ibi) as max_ibi,
min(ibi) as min_ibi
from gv_ibi
group by patientid

/* 2.Rank the average ibi values using rank()*/

with ibi_summary as
(select patientid, count(distinct DATE_TRUNC('day', timeof)) 
as number_of_days_measured,
round(avg(ibi),2) as avg_ibi
from gv_ibi
group by patientid)
select a.patientid,a.number_of_days_measured,
a.avg_ibi,
rank() over (order by a.avg_ibi) as ibi_rank
from ibi_summary a
order by ibi_rank 



/* 3.Calculate the moving average of ibi values*/

select patientid,timeof,ibi,
avg(ibi) over (partition by patientid order by timeof
rows between 2 preceding and current row) as moving_avg_ibi
from gv_ibi
order by patientid

select * from gv_eda

/* 4.Calculate the average, maximum,minimum eda values*/

select patientid, count(distinct DATE_TRUNC('day', timeof)) as number_of_days_measured,
round(avg(eda),2) as avg_eda,
max(eda) as max_eda,
min(eda) as min_eda
from gv_eda
group by patientid

/* 5.How much can EDA fluctuate*/

select patientid,
count(distinct DATE_TRUNC('day', timeof)) as number_of_days_measured,
stddev(eda) as eda_variability
from gv_eda
group by patientid

/*Heart Rate variability*/

select patientid,
count(distinct DATE_TRUNC('day', timeof)) as number_of_days_measured,
stddev(hr) as hr_variability
from gv_hr
group by patientid

/*6.Rank the patients with high stress levels*/

with eda_values as
(select patientid,
count(distinct DATE_TRUNC('day', timeof)) as number_of_days_measured,
stddev(eda) as eda_variability
from gv_eda
group by patientid)
select a.patientid,a.number_of_days_measured,a.eda_variability,
rank() over (order by a.eda_variability) as eda_variability_ranking
from eda_values a
order by eda_variability_ranking desc

/*7.Calculate the daily EDA variability of patients*/

select patientid,
date_trunc('day',timeof) as day,
stddev(eda) as daily_eda_variability
from gv_eda
group by patientid,date_trunc('day',timeof)
order by patientid,day

/* 8.Calculate the cumulative eda values for each patient day wise*/

with eda_values as
(select patientid,
DATE_TRUNC('day', timeof) as DAY,
ROUND(avg(eda),2) as avg_eda
from gv_eda
group by patientid,TIMEOF
ORDER BY patientid),
overall_avg_eda_each_day as
(SELECT a.patientid,a.DAY,avg(a.avg_eda) as avg_eda
from eda_values a
group by a.DAY,a.patientid
order by a.patientid,a.DAY)
select b.patientid,
b.DAY,
b.avg_eda,
avg(b.avg_eda) over (partition by patientid order by b.DAY
rows between unbounded preceding and current row) as cumulative_avg_eda
from overall_avg_eda_each_day b


/*9.Display EDA variability with their gender*/

select d.gender,
d.patientid,
count(distinct DATE_TRUNC('day', e.timeof)) as number_of_days_measured,
round(avg(e.eda),2) as avg_eda,
stddev(e.eda) as eda_variability
from gv_eda e
INNER JOIN gv_demography d
ON e.patientid=d.patientid
group by d.patientid,d.gender

/* 10.Correlation between EDA and HR*/

with avg_eda_hr_values as
(select h.patientid,avg(h.hr) as avg_heart_rate,AVG(e.eda) as avg_eda
from gv_hr h
INNER JOIN gv_eda e
ON h.patientid=e.patientid
group by h.patientid)
select 
corr(a.avg_eda,a.avg_heart_rate)
from avg_eda_hr_values a

select corr(e.eda,h.hr) from
gv_eda e
INNER JOIN
gv_hr h
ON e.patientid=h.patientid

/* 10.Correlation between IBI and HR*/

with avg_ibi_hr_values as
(select h.patientid,avg(h.hr) as avg_heart_rate,AVG(e.ibi) as avg_ibi
from gv_hr h
INNER JOIN gv_ibi e
ON h.patientid=e.patientid
group by h.patientid)
select 
corr(a.avg_ibi,a.avg_heart_rate)
from avg_ibi_hr_values a

select corr(e.ibi,h.hr) from
gv_ibi e
INNER JOIN
gv_hr h
ON e.patientid=h.patientid


/* 11.To find out the correlation between glucose and EDA*/

select corr(e.eda,g.glucosevaluemgdl)
from gv_eda e
INNER JOIN
gv_dexcom g
On e.patientid=g.patientid

/* 12.Row number added based on the glucose levels*/

select patientid,
timeof,
glucosevaluemgdl,
row_number() over (partition by patientid order by glucosevaluemgdl) 
as row_num_glucose
from gv_dexcom

/* 13.Using NTILE() to determine the ranking of patients based on their glucose levels*/

select patientid,gender,overall_avg_glucose,
ntile(3) over (order by overall_avg_glucose desc) as Qtileglucose
from gv_glucose

select * from gv_glucose


/*15. Calculate overall avg ibi values for all the patients*/

with avg_ibi as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.ibi),2) as avg_ibi_day_wise
from gv_ibi g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,
round(avg(a.avg_ibi_day_wise),2) as overall_avg_ibi
from avg_ibi a
group by a.patientid,a.gender
order by a.patientid


/* 17.Determine the ranking for the heart rate variability using rank()*/

with hr_values as
(select patientid,
count(distinct DATE_TRUNC('day', timeof)) as number_of_days_measured,
stddev(hr) as hr_variability
from gv_hr
group by patientid)
select a.patientid,a.number_of_days_measured,a.hr_variability,
rank() over (order by a.hr_variability) as hr_variability_ranking
from hr_values a
order by hr_variability_ranking desc


/*20. Calculate overall hr  for all the patients*/

with avg_hr as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.hr),2) as avg_hr_day_wise
from gv_hr g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,round(avg(a.avg_hr_day_wise),2) as overall_avg_hr
from avg_hr a
group by a.patientid,gender
order by a.patientid

select d.patientid,
d.gender,
round(avg(g.glucosevaluemgdl),2) as avg_glucose
from demography d
INNER JOIN gv_dexcom g
ON g.patientid=d.patientid
group by d.patientid,d.gender
order by d.patientid

/*21. Calculate the overall average temperature of patients*/

with avg_temperature as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.temperature),2) as avg_temperature_day_wise
from gv_temperature g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,
round(avg(a.avg_temperature_day_wise),2) as overall_average_temperature
from avg_temperature a
group by a.patientid,a.gender
order by a.patientid

/* 22.Calculate the overall average eda values of all patients*/

with avg_eda as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.eda),2) as avg_eda_day_wise
from gv_eda g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,
round(avg(a.avg_eda_day_wise),2) as overall_average_eda
from avg_eda a
group by a.patientid,a.gender
order by a.patientid

/*23. To find the average ibi per patient,avg ibi overall and their difference*/

SELECT
    patientid,
    AVG(ibi) AS patient_average_ibi,
    AVG(ibi) OVER () AS overall_average_ibi,
    AVG(ibi) - AVG(ibi) OVER () AS difference_from_overall
FROM
    gv_ibi
GROUP BY
    patientid,ibi

/* 24.Total weekly calorie intake of patients*/


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

/* To find the Heart Rate change using lead()*/

SELECT
  patientid,
  timeof,
  hr,
  LEAD(hr) OVER (PARTITION BY patientid ORDER BY timeof) - hr AS hr_change
FROM gv_hr;

/* To find the lowest heart rate and highest heart rate for each patient using
first_value() and last_value*/

with avg_hr_day as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.hr),2) as avg_hr_day_wise
from gv_hr g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
SELECT
a.patientid,
a.DAY,
a.avg_hr_day_wise,
first_VALUE(a.avg_hr_day_wise) OVER (PARTITION BY patientid ORDER BY a.avg_hr_day_wise)
  AS lowest_heart_rate,
last_VALUE(a.avg_hr_day_wise) OVER (PARTITION BY patientid ORDER BY a.avg_hr_day_wise rows
between unbounded preceding and unbounded following) 
  AS highest_heart_rate
 fROM avg_hr_day a;

/* Calculating the median value of glucose values for each patient using
percentile_cont() and percentile_disc()*/

with avg_glucose_per_day as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.glucosevaluemgdl),2) as avg_glucose_day_wise
from gv_dexcom g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,
percentile_cont(0.5) within group (order by a.avg_glucose_day_wise)  
as median_50_glucose,
percentile_disc(0.5) within group (order by a.avg_glucose_day_wise) 
as median_50_glucose_disc
from avg_glucose_per_day a
group by a.patientid
order by a.patientid

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

--Show Coefficient of variation for each patient.

SELECT patientid, 
       ROUND(AVG(glucosevaluemgdl), 2) AS avg_gl,
       ROUND(STDDEV_POP(glucosevaluemgdl) / AVG(glucosevaluemgdl), 2) * 100 AS Coeff_Var
FROM gv_dexcom
GROUP BY patientid
ORDER BY Coeff_Var DESC;

/* Calculate the maximum EDA measured for each patient and on which 
day based on their EDA ranking*/

WITH DailyEDA AS (
SELECT
patientid,
DATE_TRUNC('day', timeof) as day,
MAX(eda) as MAX_eda_measured
FROM gv_eda
GROUP BY patientid, day
),
RankedEDADays AS (
 SELECT
 patientid,
 day,
 MAX_eda_measured,
 RANK() OVER (
 PARTITION BY patientid
 ORDER BY MAX_eda_measured DESC
    ) AS rank_by_eda
	FROM Dailyeda
)

SELECT
patientid,
day,
MAX_eda_measured
FROM RankedEDADays
WHERE rank_by_eda = 1
ORDER BY patientid;

/*which patient has maximum glucose level compared to all the other patients and 
on which day*/

with avg_glucose_levels as
(select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.glucosevaluemgdl),2) as avg_glucose_day_wise
from gv_dexcom g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid)
select a.patientid,a.gender,a.DAY,a.avg_glucose_day_wise as maximum_avg_glucose_day_wise
from avg_glucose_levels a
where a.avg_glucose_day_wise=(select max(a.avg_glucose_day_wise) 
from avg_glucose_levels a)

---- Calculate the average Heart Rate (HR) for all patients, 
---grouped by the hour of the day (0-23)

SELECT
  EXTRACT(HOUR FROM timeof) AS hour_of_day,
  ROUND(AVG(hr), 2) AS average_hr
FROM gv_hr
GROUP BY hour_of_day
ORDER BY hour_of_day;

--Identify the average IBI for male patients versus female patients specifically 
--during the assumed sleep window (10 PM to 6 AM).
SELECT
    d.gender,
    ROUND(AVG(i.ibi), 2) AS avg_ibi_during_sleep
FROM
    gv_demography d
JOIN
    gv_ibi i ON d.patientid = i.patientid
WHERE
    EXTRACT(HOUR FROM i.timeof) >= 22 OR EXTRACT(HOUR FROM i.timeof) <= 6 -- 10 PM to 6 AM
GROUP BY
    d.gender
ORDER BY
    d.gender;
	
--For each patient and day, find the difference between the maximum 
--and minimum recorded temperature (daily temperature fluctuation).

SELECT
  patientid,
  DATE_TRUNC('day', timeof) AS observation_day,
  MAX(temperature) AS max_temp,
  MIN(temperature) AS min_temp,
  ROUND(MAX(temperature) - MIN(temperature), 2) AS daily_temp_fluctuation
FROM gv_temperature
GROUP BY patientid, observation_day
ORDER BY patientid, observation_day;