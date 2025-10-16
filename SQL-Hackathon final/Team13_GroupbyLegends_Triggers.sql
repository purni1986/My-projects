/* Create a trigger function to log entry of new patient into new_patient_entry table
whenever a patient is inserted into the gv_demography table*/

create table new_patient_entry
(patientid INT PRIMARY KEY,
gender VARCHAR(100),
hba1c numeric,
action varchar(50),
date TIMESTAMP default CURRENT_TIMESTAMP)

drop table new_patient_entry

CREATE OR REPLACE function trg_after_insert_demography()
RETURNS trigger AS $$
BEGIN
INSERT INTO new_patient_entry (patientid, gender, hba1c, action, date)
VALUES(new.patientid, new.gender, new.hba1c, 'INSERT', DEFAULT);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_demography
AFTER INSERT ON gv_demography
FOR EACH ROW
EXECUTE FUNCTION trg_after_insert_demography();

select * from new_patient_entry

INSERT INTO gv_demography
values
(17,'FEMALE','6.5')

delete from gv_demography where patientid=17


SELECT * FROM new_patient_entry
delete from new_patient_entry

/* Write a trigger to log the old and new entry of hba1c patient into the hba1c change
table*/


create table hba1c_change_table
(patientid INT PRIMARY KEY,
OLD_hba1c numeric,
new_hba1c numeric)

create or replace function trg_after_update_hba1c()
returns trigger AS $$
BEGIN
IF OLD.hba1c<>new.hba1c THEN
insert into hba1c_change_table
values (NEW.patientid,OLD.hba1c,NEW.hba1c);
END IF;
RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER after_update_hba1c
AFTER UPDATE on gv_demography
FOR EACH ROW
EXECUTE FUNCTION trg_after_update_hba1c();

update  gv_demography set  hba1c=6.2
where patientid=17

select * from hba1c_change_table




