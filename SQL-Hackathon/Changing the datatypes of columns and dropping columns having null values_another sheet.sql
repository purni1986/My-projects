/* Altering the dataypes of all the columns*/
--------------------------------------------------------------------------
select * from demography

alter table demography alter column patientid type int
using patientid::integer;

alter table demography alter column hba1c type numeric
using hba1c::numeric;

ALTER TABLE DEMOGRAPHY ALTER COLUMN GENDER type VARCHAR(50)
---------------------------------------------------------------------------
select * from dexcom

alter table dexcom alter COLUMN indexval TYPE int
using indexval::int

ALTER table dexcom alter column timeof TYPE TIMESTAMP 
USING TO_TIMESTAMP(timeof, 'MM-DD-YYYY HH24:MI:SS');

ALTER TABLE dexcom alter column eventtype type varchar(50)

ALTER TABLE dexcom alter column eventsubtype type varchar(50)

ALTER TABLE dexcom alter column patientinfo type varchar(50)
ALTER TABLE dexcom alter column deviceinfo type varchar(50)
ALTER TABLE dexcom alter column sourcedeviceid type varchar(50)
ALTER TABLE dexcom alter glucosevaluemgdl type int using glucosevaluemgdl::INT
ALTER TABLE dexcom alter INSULINVALUE_U type int using insulinvalue_u::INT
ALTER TABLE dexcom alter carbvaluegrams type int using carbvaluegrams::INT
ALTER TABLE dexcom alter duration type interval using duration::interval
ALTER TABLE dexcom alter transmittertimelonginteger type BIGINT 
using transmittertimelonginteger::BIGINT
ALTER TABLE dexcom alter column patientid type int using patientid::int
---------------------------------------------------------------------------------
SELECT * FROM EDA

ALTER table eda alter column timeof TYPE TIMESTAMP 
USING TO_TIMESTAMP(timeof, 'yyyy-mm-dd HH24:MI:SS');

ALTER TABLE EDA ALTER eda type numeric using eda::numeric
ALTER TABLE EDA alter column patientid type int using patientid::int


SELECT patientid, DATE_TRUNC('minute', timeof) AS minute, ROUND(AVG(eda),2) AS avg_eda
FROM eda
GROUP BY patientid, minute
ORDER BY minute;
--------------------------------------------------------------------------------------------
select * from foodlog

ALTER table foodlog alter column dateof TYPE date
USING dateof::DATE

ALTER TABLE foodlog
ALTER COLUMN timeof TYPE TIMESTAMP
USING CASE
  
   WHEN timeof::text ~ '^\d{1,2}:\d{2}(:\d{2})?$'
      THEN dateof + timeof::time

   WHEN timeof::text ~ '^\d{4}-\d{2}-\d{2}'
      THEN TO_TIMESTAMP(timeof::text, 'YYYY-MM-DD HH24:MI:SS')
  
   WHEN timeof::text ~ '^\d{2}-\d{2}-\d{4}'
      THEN TO_TIMESTAMP(timeof::text, 'MM-DD-YYYY HH24:MI:SS')
   ELSE NULL
END;

delete from foodlog


insert into foodlog
select * from foodlog_3

ALTER table foodlog alter column time_begin TYPE TIMESTAMP 
USING TO_TIMESTAMP(time_begin, 'mm-dd-yyyy HH24:MI:SS');

ALTER table foodlog alter column time_end TYPE TIMESTAMP 
USING TO_TIMESTAMP(time_end, 'HH24:MI:SS');

ALTER table foodlog alter column logged_food type varchar(200)

ALTER table foodlog alter column amount type varchar(20)
ALTER table foodlog alter column unit type varchar(20)

ALTER table foodlog alter column searched_food type varchar(200)
ALTER table foodlog alter column calorie type numeric using calorie::numeric

ALTER table foodlog alter column total_carb type numeric using total_carb::numeric
ALTER table foodlog alter column dietary_fiber type numeric using dietary_fiber::numeric
ALTER table foodlog alter column sugar type numeric using sugar::numeric

ALTER table foodlog alter column protein type numeric using protein::numeric
ALTER table foodlog alter column total_fat type numeric using total_fat::numeric

ALTER TABLE foodlog alter column patientid type int using patientid::int

ALTER TABLE foodlog alter column time_of_day type  varchar(100)
---------------------------------------------------------------------------------------------
select * from hr

create table hr_new
(timeof text,
hr text,
patientid text)

insert into hr_new
select * from hr

UPDATE hr_new
SET timeof = REGEXP_REPLACE(timeof, '^0020', '2020');

ALTER TABLE hr_new
ALTER COLUMN timeof TYPE TIMESTAMP
USING CASE
  WHEN timeof ~ '^\d{4}-\d{2}-\d{2}' THEN TO_TIMESTAMP(timeof, 'YYYY-MM-DD HH24:MI:SS')
  ELSE TO_TIMESTAMP(timeof, 'MM-DD-YYYY HH24:MI')
END;

select * from hr_new order by timeof

SELECT patientid, DATE_TRUNC('minute', timeof) AS minute, AVG(hr) AS avg_hr
FROM hr
GROUP BY patientid, minute
ORDER BY minute;



CREATE EXTENSION IF NOT EXISTS dblink;


INSERT INTO hr_new (timeof, hr, patientid)
SELECT * FROM dblink(
  'host=localhost dbname=GV_Raw user=postgres password=1986',
  'SELECT * FROM public.hr'
) AS hr(timeof TEXT, hr TEXT, patientid TEXT);

select * from hr_new order by timeof


select * from hr_new order by timeof

UPDATE hr_new
SET timeof = TO_TIMESTAMP(
  REGEXP_REPLACE(timeof::TEXT, '^0020', '2020'),
  'YYYY-MM-DD HH24:MI:SS'
)
WHERE timeof::TEXT LIKE '0020%';

SELECT DISTINCT EXTRACT(YEAR FROM timeof) AS year
FROM hr_new
ORDER BY year;

alter table hr_new alter column hr type numeric using hr::numeric
alter table hr_new alter column patientid type int using patientid::integer

SELECT patientid, DATE_TRUNC('minute', timeof) AS minute, AVG(hr) AS avg_hr
FROM hr_new
GROUP BY patientid, minute
ORDER BY minute;
----------------------------------------------------------------------------------------------
select * from ibi

ALTER table ibi alter column timeof TYPE TIMESTAMP 
USING TO_TIMESTAMP(timeof, 'yyyy-mm-dd HH24:MI:SS');

alter table ibi alter column ibi type numeric using ibi::numeric

alter table ibi alter column patientid type integer using patientid::integer
---------------------------------------------------------------------------------------------
select * from temperature

ALTER table temperature alter column timeof TYPE TIMESTAMP 
USING TO_TIMESTAMP(timeof, 'yyyy-mm-dd HH24:MI:SS');

alter table temperature alter column temparature type numeric using temparature::numeric
alter table temperature alter column patientid type integer using patientid::integer
---------------------------------------------------------------------------------------------

/*Dropping unnecessary columns from dexcom table*/

select * from dexcom

alter table dexcom drop column eventsubtype

select * from dexcom where insulinvalue_u is not null

alter table dexcom drop column insulinvalue_u

select * from dexcom where carbvaluegrams is not null

alter table dexcom drop column carbvaluegrams

select * from dexcom where patientinfo is not null

alter table dexcom drop column patientinfo

select * from dexcom where deviceinfo is not null

alter table dexcom drop column deviceinfo

select * from dexcom where duration is not null

select * from dexcom where glucoserateofchangemgdlmin is not null

alter table dexcom drop column glucoserateofchangemgdlmin

ALTER TABLE dexcom
ADD COLUMN eventsubtype VARCHAR(50);

INSERT INTO DEXCOM
VALUES
(200,'6/6/2020 8:05','exercise','Android G6',null,'0:55:00',null,14,'Light')

INSERT INTO DEXCOM
VALUES
(456,'6/7/2020 5:20','exercise','Android G6',null,'0:45:00',null,14,'Medium')

select * from dexcom where indexval=456
select * from dexcom where indexval=200

select * from dexcom

