

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

/* On which day each patient had maximum glucose levels*/

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

select * from gv_dexcom