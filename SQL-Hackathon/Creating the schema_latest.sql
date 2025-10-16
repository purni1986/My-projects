----------------------------------------------------------------------------
/* Create table gv_demography*/

create table gv_demography
(    patientid INTEGER PRIMARY KEY,
    gender varchar(50),
    hba1c NUMERIC(4,2)
)

insert into gv_demography 
select * from public.demography

select * from gv_demography
-------------------------------------------------------------------------------------
/* Create table gv_dexcom*/

CREATE TABLE gv_dexcom (
    row_id SERIAL PRIMARY KEY,
	indexval INT,
	timeof TIMESTAMP,
    eventtype VARCHAR(100) NOT NULL,
    sourcedeviceid VARCHAR(100),
    glucosevaluemgdl NUMERIC(5,2),
    duration INTERVAL,
    transmittertimelonginteger BIGINT,
    patientid INT,
    eventsubtype VARCHAR(50),
    FOREIGN KEY (patientid) REFERENCES gv_demography(patientid)
);

INSERT INTO gv_dexcom (
  indexval,
  timeof,
  eventtype,
  sourcedeviceid,
  glucosevaluemgdl,
  duration,
  transmittertimelonginteger,
  patientid,
  eventsubtype
 
)
SELECT
  indexval,
  timeof,
  eventtype,
  sourcedeviceid,
  glucosevaluemgdl,
  duration,
  transmittertimelonginteger,
  patientid,
  eventsubtype
 FROM public.dexcom;

 
select * from gv_dexcom
-------------------------------------------------------------------------------------
/* Create table gv_eda*/

CREATE TABLE gv_eda
(
timeof TIMESTAMP,
eda numeric(10,7),
patientid INT,
FOREIGN KEY (patientid) REFERENCES gv_demography(patientid)
)

INSERT INTO gv_eda
SELECT  DATE_TRUNC('minute', timeof) AS minute, ROUND(AVG(eda),2) AS avg_eda,patientid
FROM eda
GROUP BY patientid, minute
ORDER BY minute;

select * from gv_eda
----------------------------------------------------------------------------------------
/* Create table gv_food_log*/

create table gv_food_log
(
food_id SERIAL PRIMARY KEY,
patientid INT,
dateof TIMESTAMP,
timeof TIMESTAMP,
time_begin TIMESTAMP,
time_end TIMESTAMP,
logged_food VARCHAR(200),
amount VARCHAR(20),
unit VARCHAR(20),
searched_food varchar(200),
FOREIGN KEY (patientid) REFERENCES gv_demography(patientid)
)

INSERT INTO gv_food_log
(
  patientid,
  dateof,
  timeof,
  time_begin,
  time_end,
  logged_food,
  amount,
  unit,
  searched_food
)
SELECT
  patientid,
  dateof,
  timeof,
  time_begin,
  time_end,
  logged_food,
  amount,
  unit,
  searched_food
FROM foodlog;

ALTER TABLE gv_food_log
ALTER COLUMN time_end TYPE TIMESTAMP WITHOUT TIME ZONE
USING (dateof + time_end::TIME);

ALTER TABLE gv_food_log drop column time_begin

select * from gv_food_log
----------------------------------------------------------------------------------
/* Create table gv_food*/

create table gv_food
(
food_id INT,
patientid INT,
logged_food varchar(200),
calorie numeric,
total_carb numeric,
dietary_fiber numeric,
sugar numeric,
protein numeric,
total_fat numeric,
FOREIGN KEY (food_id) REFERENCES gv_food(food_id),
FOREIGN KEY (patientid) REFERENCES gv_demography(patientid)
)
/*Before inserting data into this table add a column called food_id in foodlog table as
with serial as the datatype*/

ALTER TABLE foodlog add column food_id SERIAL 

INSERT INTO gv_food
(
  food_id,
  patientid,
  logged_food,
  calorie,
  total_carb,
  dietary_fiber,
  sugar,
  protein,
  total_fat
)
SELECT
  food_id,
  patientid,
  logged_food,
  calorie,
  total_carb,
  dietary_fiber,
  sugar,
  protein,
  total_fat
FROM foodlog;

select * from gv_food

----------------------------------------------------------------------------------------
/* Create table gv_hr*/

create table gv_hr
(
timeof TIMESTAMP,
hr numeric,
patientid INT,
FOREIGN KEY (patientid) REFERENCES gv_demography(patientid)
)

INSERT INTO gv_hr
SELECT 
 DATE_TRUNC('min', timeof) AS minute,
 ROUND(AVG(hr), 2) AS avg_hr,
 patientid
FROM hr_new
GROUP BY patientid, minute
ORDER BY patientid, minute;

select * from gv_hr
---------------------------------------------------------------------------------------
/* Create table gv_ibi*/

CREATE TABLE gv_ibi
(
timeof TIMESTAMP,
ibi numeric,
patientid INT,
FOREIGN KEY (patientid) REFERENCES gv_demography(patientid)
)

INSERT INTO gv_ibi
SELECT  DATE_TRUNC('minute', timeof) AS minute, ROUND(AVG(ibi),2) AS ibi,patientid
FROM ibi
GROUP BY patientid, minute
ORDER BY minute;

select * from gv_ibi
-----------------------------------------------------------------------------------------
/* Create table gv_temperature*/

CREATE TABLE gv_temperature
(
timeof TIMESTAMP,
temperature numeric,
patientid INT,
FOREIGN KEY (patientid) REFERENCES gv_demography(patientid)
)

INSERT INTO gv_temperature
SELECT 
  DATE_TRUNC('min', timeof) AS minute,
  ROUND(AVG(temparature), 2) AS avg_temp,
  patientid
FROM temperature
GROUP BY patientid, minute
ORDER BY patientid, minute;

select * from gv_temperature
--------------------------------------------------------------------------------------

