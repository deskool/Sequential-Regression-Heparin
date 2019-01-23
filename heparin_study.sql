with basic_pop as
  (select distinct icud.subject_id,
          icud.hadm_id,
          icud.icustay_id,
          icud.weight_first,
          icud.gender,
          icud.sapsi_first,
          icud.sapsi_max,
          icud.sofa_first,
          icud.sofa_max,
          icud.ICUSTAY_FIRST_CAREUNIT,
          icud.ICUSTAY_LAST_CAREUNIT,
          i.volume  AS HEP_VOLUME,
          i.volumeuom AS HEP_UOM,
          i.charttime as heparin_infusion_time
          
   from mimic2v26.icustay_detail icud
   join mimic2v26.ioevents i on icud.icustay_id=i.icustay_id and i.itemid=137
   where icud.icustay_age_group='adult'
     and i.volume>0
     --and icud.subject_id<25
     ORDER BY icud.subject_id,heparin_infusion_time
  ),

-- FIND THE AGE
first_admission_date AS (
 SELECT DISTINCT p.subject_id, p.dob,
 a.hadm_id, a.admit_dt,
 MIN(a.admit_dt)
 OVER(PARTITION BY a.hadm_id, p.subject_id)
 AS first_adm_dt
 FROM mimic2v26.admissions a,
 mimic2v26.d_patients p
 WHERE p.subject_id = a.subject_id
 AND p.dob IS NOT NULL
 ORDER BY a.hadm_id, p.subject_id
),

age AS(
 SELECT subject_id,
 ROUND(months_between(first_adm_dt, dob) /12) first_adm_age
 FROM first_admission_date
),
-- END --

labs AS(
SELECT HADM_ID,
       CHARTTIME AS LAB_TIME,
       VALUE AS LAB_VALUE,
       VALUEUOM AS LAB_VALUEUOM,
       ITEMID AS LAB_ITEM
FROM mimic2v26.labevents
WHERE ITEMID IN('50234','50440','50090','50399','50439','50073','50193','50146')
),

--------------- RESULTS --------------------------------------------------------

results AS(
SELECT DISTINCT basic_pop.*,D.ethnicity_descr,age.first_adm_age, labs.LAB_TIME,labs.lab_value,labs.lab_valueuom,labs.lab_item
FROM basic_pop,mimic2v26.demographic_detail D,age,labs 
WHERE basic_pop.subject_id = age.subject_id
AND basic_pop.subject_id = D.subject_id
AND basic_pop.hadm_id = labs.hadm_id
ORDER BY basic_pop.subject_id,heparin_infusion_time, lab_time
),

subj_info AS
(
select DISTINCT SUBJECT_ID, HADM_ID, ICUSTAY_ID, 
                WEIGHT_FIRST, GENDER, SAPSI_FIRST,
                SAPSI_MAX, SOFA_FIRST, SOFA_MAX,
                ICUSTAY_FIRST_CAREUNIT, ICUSTAY_LAST_CAREUNIT,
                ETHNICITY_DESCR, FIRST_ADM_AGE
FROM results
),

heparin_times AS(
SELECT DISTINCT SUBJECT_ID, HADM_ID,HEPARIN_INFUSION_TIME, HEP_VOLUME, HEP_UOM
FROM results
),

lab_times AS(
SELECT DISTINCT SUBJECT_ID, HADM_ID,LAB_ITEM, LAB_TIME, LAB_VALUE, LAB_VALUEUOM
FROM results
)
--------------------------------------------------------------------------------




------------------------NUMBER OF DISTINCT SUBJECTS: 4142 ----------------------
--SELECT COUNT(DISTINCT SUBJECT_ID),COUNT(DISTINCT HADM_ID)
--FROM basic_pop
--------------------------------------------------------------------------------

------------------------NUMBER OF DISTINCT SUBJECTS: 4142 ----------------------
-- MALES: 2378
-- FEMALES: 1764
SELECT *
FROM subj_info
--WHERE basic_pop.gender LIKE 'M'
--------------------------------------------------------------------------------