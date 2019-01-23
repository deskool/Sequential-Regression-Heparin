
WITH heparin AS(
SELECT DISTINCT 
        me.SUBJECT_ID,
        me.ICUSTAY_ID,
        FIRST_VALUE(me.charttime) OVER (partition by me.icustay_id order by me.charttime) AS first_hep_time 
  FROM mimic2v26.medevents me
  WHERE me.itemid=25
  AND me.SUBJECT_ID < 50
  AND me.icustay_id IN(SELECT ICUSTAY_ID FROM mimic2v26.icustay_detail WHERE icustay_age_group='adult')
  AND me.icustay_id IN(SELECT ICUSTAY_ID FROM mimic2v26.labevents WHERE ITEMID IN ( '50234','50440','50090','50399','50439','50073','50193','50146'))
),

heparin_final AS(
SELECT DISTINCT h.*,
                me.dose AS hep_dose,
                me.doseuom AS hep_uom
FROM mimic2v26.medevents me, heparin h
where h.subject_id = me.subject_id
  and h.icustay_id = me.icustay_id
  and h.first_hep_time = me.charttime
  and dose > 0
  and me.doseuom LIKE 'Uhr' -- We have multiple measurements - we took Uhr
),

final_pop AS(
          SELECT DISTINCT
          icud.subject_id,
          icud.hadm_id,        
          icud.icustay_id,
          icud.weight_first,
          icud.gender,
          icud.sapsi_max,
          icud.sofa_max,
          icud.ICUSTAY_FIRST_SERVICE,
          icud.ICUSTAY_ADMIT_AGE
          
   FROM mimic2v26.icustay_detail icud, heparin_final h
   WHERE icud.icustay_age_group='adult' --Looking at only adults
    AND icud.icustay_id = h.icustay_id
    AND h.heparin_infusion_time < icud.icustay_outtime --Make sure that the icustay information extracted is on the same day as the heparin
    AND h.heparin_infusion_time > icud.icustay_intime
    AND icud.icustay_id IN(SELECT ICUSTAY_ID FROM heparin_final)
),

--SELECT * FROM final_pop


cre_times AS(
SELECT h.icustay_id, MAX(le.charttime) AS lab_time,le.itemid 
FROM mimic2v26.labevents le, heparin_final h 
WHERE h.icustay_id = le.icustay_id 
AND le.charttime < h.heparin_infusion_time
AND le.itemid IN(SELECT ITEMID FROM mimic2v26.D_LABITEMS WHERE TEST_NAME LIKE 'CREAT')--IN('50090')
AND le.icustay_id IN(SELECT ICUSTAY_ID FROM heparin_final)
GROUP BY(h.ICUSTAY_ID,le.ITEMID)
),

--SELECT * FROM cre_times

cre_n_hep AS( 
SELECT lt.itemid,
       h.*, 
       lt.lab_time AS CREAT_TIME
FROM 
       heparin_final h, 
       cre_times lt
WHERE   
       lt.icustay_id = h.icustay_id
),

cre_n_hep2 AS( 
SELECT 
  h.*, 
  le.value AS creat_val, 
  le.valueuom AS creat_uom
FROM 
  cre_n_hep h, 
  mimic2v26.labevents le
WHERE h.icustay_id = le.icustay_id
  AND h.itemid = le.itemid
  AND h.CREAT_TIME = le.charttime
  AND h.ITEMID IN('50090') -- remove this to expand the query to the other values of interest.
  AND le.icustay_id IN(SELECT ICUSTAY_ID FROM heparin_final)
),

ptt_times AS(
SELECT h.icustay_id, MIN(le.charttime) AS lab_time,le.itemid 
FROM mimic2v26.labevents le, heparin_final h 
WHERE h.icustay_id = le.icustay_id 
AND le.charttime > h.heparin_infusion_time
AND le.itemid IN(SELECT ITEMID FROM mimic2v26.D_LABITEMS WHERE TEST_NAME LIKE 'PTT')--IN('50090')
AND le.icustay_id IN(SELECT ICUSTAY_ID FROM heparin_final)
GROUP BY(h.ICUSTAY_ID,le.ITEMID)
),

--SELECT * FROM ptt_times

ptt_n_hep AS( 
SELECT DISTINCT lt.itemid,
       h.*, 
       lt.lab_time AS ptt_time
FROM 
       heparin_final h, 
       ptt_times lt
WHERE  lt.icustay_id = h.icustay_id
),

ptt_n_hep2 AS( 
SELECT 
  h.*, 
  le.value AS ptt_val, 
  le.valueuom AS ptt_uom
FROM 
  ptt_n_hep h, 
  mimic2v26.labevents le
WHERE h.icustay_id = le.icustay_id
  AND h.itemid = le.itemid
  AND h.ptt_time = le.charttime
  AND h.ITEMID IN('50440') -- remove this to expand the query to the other values of interest.
  AND le.icustay_id IN(SELECT ICUSTAY_ID FROM heparin_final)
)

--SELECT COUNT(*) FROM ptt_n_hep2
--SELECT * FROM ptt_n_hep2

CREATE VIEW [results] AS
SELECT p.itemid AS ptt_itemid, c.*, p.ptt_time,p.ptt_val,p.ptt_uom
FROM ptt_n_hep2 p, cre_n_hep2 c
WHERE p.icustay_id = c.icustay_id
  AND p.hep_dose = c.hep_dose
