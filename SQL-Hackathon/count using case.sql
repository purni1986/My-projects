

WITH avg_glucose AS (
  SELECT 
    patientid,
    AVG(glucosevaluemgdl) AS avg_glucose
  FROM gv_dexcom
  GROUP BY patientid
),
categorized AS (
  SELECT 
    CASE 
      WHEN avg_glucose < 100 THEN 'Normal'
      WHEN avg_glucose >= 100 AND avg_glucose < 125 THEN 'Prediabetic'
      WHEN avg_glucose >= 125 THEN 'Diabetic'
    END AS glucose_category
  FROM avg_glucose
)
SELECT 
  glucose_category,
  COUNT(*) AS count_of_patients
FROM categorized
GROUP BY glucose_category;

select * from gv_glucose

with categorized AS (
  SELECT 
    CASE 
      WHEN overall_avg_glucose < 100 THEN 'Normal'
      WHEN overall_avg_glucose >= 100 AND overall_avg_glucose < 125 THEN 'Prediabetic'
      WHEN overall_avg_glucose >= 125 THEN 'Diabetic'
    END AS glucose_category
  FROM gv_glucose
 )
 SELECT 
  glucose_category,
  COUNT(*) AS count_of_patients
FROM categorized
GROUP BY glucose_category;

