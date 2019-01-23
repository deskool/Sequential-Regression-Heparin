WITH basic_pop AS
  (SELECT DISTINCT 
          icud.subject_id,
          icud.hadm_id,
          icud.icustay_id,
          icud.weight_first,
          icud.gender,
          icud.sapsi_first,
          icud.sapsi_max,
          icud.sofa_first,
          icud.sofa_max,
          icud.ICUSTAY_FIRST_CAREUNIT,
          icud.ICUSTAY_LAST_CAREUNIT
          
   FROM mimic2v26.icustay_detail icud
   join mimic2v26.ioevents i on icud.icustay_id=i.icustay_id and i.itemid=137
  where icud.icustay_age_group='adult'
    and i.volume>0
    and icud.subject_id<50
    and icud.ICUSTAY_ID IN(
                         SELECT ICUSTAY_ID
                         FROM mimic2v26.labevents
                         WHERE ITEMID IN(
                                          '50234','50440','50090','50399','50439','50073','50193','50146'
                                        )
         )
  ),
  
  -- FIND THE AGE
first_admission_date AS(
 SELECT DISTINCT 
        p.subject_id, 
        p.dob,
        a.hadm_id,  
        a.admit_dt,
        MIN(a.admit_dt) OVER(PARTITION BY a.hadm_id, p.subject_id) AS first_adm_dt
 FROM mimic2v26.admissions a,
      mimic2v26.d_patients p
 WHERE p.subject_id = a.subject_id
 AND p.dob IS NOT NULL
 ORDER BY a.hadm_id, p.subject_id
),

age AS(
 SELECT subject_id,hadm_id,
 ROUND(months_between(first_adm_dt, dob) /12) first_adm_age
 FROM first_admission_date
),

final_pop AS(
SELECT basic_pop.*, age.first_adm_age, a.disch_dt,a.admit_dt 
FROM basic_pop,age,mimic2v26.admissions a
WHERE basic_pop.subject_id = age.subject_id 
AND basic_pop.hadm_id = a.hadm_id
),

--SELECT * FROM final_pop
--------------------------------------------------------------------------------

heparin as
  (select distinct 
          i.subject_id,
          i.icustay_id,
          i.volume  AS HEP_VOLUME,
          i.volumeuom AS HEP_UOM,
          i.charttime as heparin_infusion_time
          
    FROM mimic2v26.ioevents i
    WHERE i.ICUSTAY_ID IN(
                          SELECT ICUSTAY_ID
                          FROM final_pop
                          )
--    WHERE i.ICUSTAY_ID IN(
--                         SELECT ICUSTAY_ID
--                         FROM mimic2v26.labevents
--                         WHERE ITEMID IN(
--                                         '50234','50440','50090','50399','50439','50073','50193','50146'
--                                        )                         
--                         AND ICUSTAY_ID IN(
--                                  select icud.icustay_id
--                                  from mimic2v26.icustay_detail icud
--                                  join mimic2v26.ioevents i on icud.icustay_id = i.icustay_id and i.itemid=137 
--                                  where icud.icustay_age_group='adult'
--                                  and i.volume>0
--                                 --and icud.subject_id<25
--                          )
--         ) 
),

--select * from heparin
heparin_final AS(
SELECT heparin.*, months_between(heparin.heparin_infusion_time,final_pop.admit_dt)*30*24 AS hep_time_min
FROM heparin, final_pop
WHERE heparin.icustay_id = final_pop.icustay_id
),

labs AS(
SELECT SUBJECT_ID,
       HADM_ID,
       ICUSTAY_ID,
       CHARTTIME AS LAB_TIME,
       VALUE AS LAB_VALUE,
       VALUEUOM AS LAB_VALUEUOM,
       ITEMID AS LAB_ITEM
FROM mimic2v26.labevents
WHERE ITEMID IN('50234','50440','50090','50399','50439','50073','50193','50146')
AND ICUSTAY_ID IN(select icud.icustay_id
               from mimic2v26.icustay_detail icud
               join mimic2v26.ioevents i on icud.icustay_id=i.icustay_id and i.itemid=137
               where icud.icustay_age_group='adult'
               and i.volume>0
               --and icud.subject_id<25
               )
),

labs_final AS(
SELECT labs.*, months_between(labs.lab_time,final_pop.admit_dt)*30*24 AS lab_time_min 
FROM labs,final_pop
WHERE labs.hadm_id = final_pop.hadm_id
)

--SELECT * FROM labs_final

--SELECT final_pop.*,(months_between(a.disch_dt,a.admit_dt)*30*24*60) 
--FROM final_pop, mimic2v26.admissions a
--WHERE final_pop.hadm_id = a.hadm_id


SELECT * FROM basic_pop
