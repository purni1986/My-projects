
------------------------------------------------------------------------------
create table gv_heartrate
(patientid INT PRIMARY KEY,
gender VARCHAR(50),
heart_rate numeric)

insert into gv_heartrate
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

select * from gv_heartrate
--------------------------------------------------------------------------------
select * from gv_glucose
alter table gv_glucose rename glucosevaluesmgdl to overall_avg_glucose

alter table gv_heartrate rename heart_rate to overall_heart_rate

create table gv_ibi_values
(patientid INT primary key,
gender VARCHAR(50),
overall_ibi numeric)

insert into gv_ibi_values
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
round(avg(a.avg_ibi_day_wise),2)
from avg_ibi a
group by a.patientid,a.gender
order by a.patientid
-
select * from gv_ibi_values
----------------------------------------------------------------------------------
create table gv_temperature_values
(patientid INT primary key,
gender VARCHAR(50),
overall_temperature numeric)

insert into gv_temperature_values
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
--------------------------------------------------------------------------------
select * from gv_temperature_values
alter table gv_temperature_values 
rename overall_temperature to overall_average_temperature

create table gv_eda_values
(patientid INT primary key,
gender VARCHAR(50),
overall_average_eda numeric)

insert into gv_eda_values
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
-------------------------------------------------------------------------------
create table critical_health_parameters
(patientid INT,
gender varchar(50),
overall_avg_glucose numeric,
overall_average_heart_rate numeric,
overall_average_eda numeric,
overall_average_idi numeric,
overall_average_temperature numeric,
FOREIGN KEY (patientid) references gv_demography(patientid))

select * from gv_glucose
select * from gv_heartrate
select * from gv_eda_values
select * from gv_ibi_values
select * from gv_temperature_values

select a.patientid,
a.gender,
b.overall_avg_glucose,
c.overall_heart_rate,
d.overall_average_eda,
e.overall_ibi,
f.overall_average_temperature
from demography a
INNER JOIN gv_glucose b on a.patientid=b.patientid
INNER JOIN gv_heartrate c  on a.patientid=c.patientid
INNER JOIN gv_eda_values d on a.patientid=d.patientid
INNER JOIN gv_ibi_values e on  a.patientid=e.patientid
INNER JOIN gv_temperature_values f on a.patientid=f.patientid
order by b.patientid

insert into critical_health_parameters
select a.patientid,
a.gender,
b.overall_avg_glucose,
c.overall_heart_rate,
d.overall_average_eda,
e.overall_ibi,
f.overall_average_temperature
from demography a
INNER JOIN gv_glucose b on a.patientid=b.patientid
INNER JOIN gv_heartrate c  on a.patientid=c.patientid
INNER JOIN gv_eda_values d on a.patientid=d.patientid
INNER JOIN gv_ibi_values e on  a.patientid=e.patientid
INNER JOIN gv_temperature_values f on a.patientid=f.patientid
order by b.patientid

select * from critical_health_parameters
-----------------------------------------------------------------------------
alter table  critical_health_parameters rename 
overall_average_idi to overall_average_ibi
