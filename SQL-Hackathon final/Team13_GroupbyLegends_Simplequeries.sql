select * from gv_demography

/*Select total count of patients from the demography table*/

select count(DISTINCT patientid) from gv_demography

/*Select total count of male/female from the demography table*/

select count(DISTINCT patientid) count_of_patients,gender
from gv_demography
group by gender

/*What percentage of dataset is maleVsfemale*/

SELECT ROUND(COUNT(CASE WHEN gender = 'FEMALE' THEN 1 END) * 100.0 / COUNT(*),2) 
AS Female_percentage,
ROUND(COUNT(CASE WHEN gender = 'MALE' THEN 1 END) * 100.0 / COUNT(*),2) 
AS Male_percentage FROM gv_demography;


/* Which patient have the maximum hba1c*/

select patientid,gender,hba1c
from gv_demography
where hba1c=(select max(hba1c) from gv_demography)

SELECT * FROM gv_dexcom

/* Average glucose level of patients day wise with their gender*/

select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.glucosevaluemgdl),2) as avg_glucose_day_wise
from gv_dexcom g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid

-- Categorize patients based on their average glucose levels
SELECT
    patientid,
    CASE
        WHEN AVG(glucosevaluemgdl) < 100 THEN 'Normal'
        WHEN AVG(glucosevaluemgdl) BETWEEN 100 AND 125 THEN 'Prediabetic'
        WHEN AVG(glucosevaluemgdl) > 125 THEN 'Diabetic'
        ELSE 'Unknown'
    END AS glucose_category
FROM public.gv_dexcom
GROUP BY patientid
ORDER BY patientid;


--Show total calorie intake of patients in a day

SELECT
l.patientid,
SUM(f.calorie) AS total_calorie_intake
FROM gv_food AS f
JOIN gv_food_log AS l ON f.food_id = l.food_id
GROUP BY l.patientid
ORDER BY l.patientid;

/* Total calories day wise calories consumed by patients*/

select f.patientid ,d.gender,
DATE_TRUNC('day',f.timeof) as DAY,
ROUND(sum(g.calorie),2) as total_calories_day_wise
from gv_food_log f
INNER JOIN gv_food g ON g.food_id=f.food_id
INNER JOIN gv_demography d
ON f.patientid=d.patientid
group by f.patientid,DAY,d.gender
ORDER BY f.patientid

--Follow-up to the above Query: Compare calorie intake of patient per day with gender

SELECT d.patientid, d.gender,Total_Calorie_intake, f.dateof 
FROM gv_demography d
JOIN (
    SELECT gv_food_log.patientid,
           SUM(gv_food.calorie) AS Total_Calorie_intake,
           gv_food_log.dateof 
    FROM gv_food
    JOIN gv_food_log ON gv_food.food_id = gv_food_log.food_id
    GROUP BY gv_food_log.dateof, gv_food_log.patientid
    ORDER BY gv_food_log.patientid
) AS f ON d.patientid = f.patientid;

-- 7. Average glucose within 3 hours after food logged

SELECT f.patientid, f.logged_food,
       ROUND(AVG(d.glucosevaluemgdL), 2) AS avg_postmeal_glucose
FROM gv_food_log f
JOIN gv_dexcom d
ON f.patientid = d.patientid
AND d.timeof BETWEEN f.timeof AND f.timeof + interval '3 hour'
GROUP BY f.patientid, f.logged_food
ORDER BY avg_postmeal_glucose DESC;

/* List all the foods with their calories from highest to lowest*/

select max(calorie) as maximum_calorie_food,logged_food as food
from gv_food
group by food_id,logged_food
order by maximum_calorie_food desc

/* Food with the maximum sugar content*/

select distinct logged_food as high_sugar_food,sugar 
from gv_food
where sugar=(select max(sugar) as high_sugar_food
from gv_food )


/* Food with minimum calorific value*/


select distinct logged_food as low_calorie_food,calorie 
from gv_food
where calorie=(select min(calorie) as low_calorie_food
from gv_food )
order by calorie desc

/* List the foods which have maximum protein content*/


select distinct logged_food as food,protein 
from gv_food
where protein=(select max(protein) as high_protein_food
from gv_food )



/* List the foods which have maximum fiber content*/

select distinct logged_food as food,dietary_fiber 
from gv_food
where dietary_fiber=(select max(dietary_fiber) as high_fiber_food
from gv_food where dietary_fiber is not null)



/* List all the foods with their fiber content highest to lowest*/

select distinct logged_food as food, max(dietary_fiber) as dietary_fiber
from gv_food
where dietary_fiber is not null
group by food_id,logged_food,dietary_fiber
order by dietary_fiber desc


/* List the food which is high on fat*/

select distinct logged_food as high_fat_food,total_fat 
from gv_food
where total_fat=(select max(total_fat) as high_fat_food
from gv_food )


/* List the foods which are low on fat*/

select distinct logged_food as low_fat_food,total_fat 
from gv_food
where total_fat=(select min(total_fat) as low_fat_food
from gv_food )
order by total_fat desc

/* Relationship between IBI and HR*/

select i.patientid,i.overall_ibi,h.overall_heart_rate
from gv_ibi_values i
INNER JOIN gv_heartrate h
ON i.patientid=h.patientid

/*Categorize patients based on their temperature levels*/

select * from gv_temperature_values

select patientid,
overall_average_temperature,
gender,
CASE
when overall_average_temperature <35 then 'Low body temperature/Hypothermia'
when overall_average_temperature BETWEEN 35 and 37 then 'Normal body temperature'
when overall_average_temperature>37.5 then 'Fever'
END as Temperature_category
FROM gv_temperature_values
order by patientid


select patientid,
temperature,
timeof,
CASE
when temperature <35 then 'Low body temperature/Hypothermia'
when temperature BETWEEN 35 and 37 then 'Normal body temperature'
when temperature>37.5 then 'Fever'
END as Temperature_category
FROM gv_temperature
order by patientid

/*To calculate day wise ibi values for all the patients*/

select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.ibi),2) as avg_ibi_day_wise
from gv_ibi g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid

/* 16.Calculate the average heart rate per day for each patient*/

select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.hr),2) as avg_hr_day_wise
from gv_hr g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid

/* 18.Calculate the average EDA per day for each patient*/

select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.eda),2) as avg_eda_day_wise
from gv_eda g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid

/* 19.Calculate the average temperature measured per day for each patient*/

select g.patientid ,d.gender ,
DATE_TRUNC('day',g.timeof) as DAY,
ROUND(avg(g.temperature),2) as avg_temperature_day_wise
from gv_temperature g
INNER JOIN gv_demography d
ON g.patientid=d.patientid
group by g.patientid,DAY,d.gender
ORDER BY g.patientid

/*21: Use a CASE statement on the foodlog table to create a new column, Meal_Type:
If total_carb >50, label as 'High-Carb Meal'. Otherwise, label as 'Standard Meal'.
List the patientid, total_carb, and the Meal_Type*/
SELECT
    food_id,
	logged_food,
    total_carb,
    CASE
        WHEN total_carb > 50 THEN 'High-Carb Meal'
        ELSE 'Standard Meal'
    END AS Meal_Type
FROM
    gv_food;


/*Q5: List the top 5 high carb foods*/

SELECT
    food_id,
	logged_food,
    total_carb
FROM
    gv_food
ORDER BY
    total_carb DESC
LIMIT 5;

/* Display the maximum glucose level of each patient and also the food they ate 
with its calorie content and sugar content*/

SELECT
    d.patientid,
    d.gender,
    MAX(x.glucosevaluemgdl) AS max_glucose_reading,
	f.logged_food,
	f.calorie,
	f.sugar,
	x.timeof
FROM
    gv_demography d
INNER JOIN
    gv_dexcom x ON d.patientid = x.patientid
INNER JOIN
	gv_food_log l ON l.timeof=x.timeof
INNER JOIN
    gv_food f ON f.food_id=l.food_id
GROUP BY
    d.patientid, d.gender,x.timeof,f.sugar,f.logged_food,f.calorie
order by
    max_glucose_reading desc



select * from gv_food