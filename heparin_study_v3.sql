WITH heparin AS(
SELECT DISTINCT 
        me.SUBJECT_ID,
        me.ICUSTAY_ID,
        MIN(me.charttime) AS heparin_infusion_time
       -- me.dose AS hep_dose,
       -- me.doseuom AS hep_uom
  FROM mimic2v26.medevents me
  WHERE me.itemid=25
  AND me.SUBJECT_ID < 4000
  AND me.icustay_id IN(SELECT ICUSTAY_ID FROM mimic2v26.icustay_detail WHERE icustay_age_group='adult')
  AND me.icustay_id IN(SELECT ICUSTAY_ID FROM mimic2v26.labevents WHERE ITEMID IN ( '50234','50440','50090','50399','50439','50073','50193','50146'))
  GROUP BY(icustay_id,subject_id)
),

--select MAX(SUBJECT_ID) FROM HEPARIN --

heparin_final AS(
SELECT DISTINCT h.*,
                me.dose AS hep_dose,
                me.doseuom AS hep_uom
FROM mimic2v26.medevents me, heparin h
where h.subject_id = me.subject_id
  and h.icustay_id = me.icustay_id
  and h.heparin_infusion_time = me.charttime
  and dose > 0
  and me.doseuom LIKE 'Uhr' -- We have multiple measurements - we took Uhr
),

--select * from heparin_final

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
    AND h.heparin_infusion_time < icud.icustay_outtime --Make sure that the icustay information extracted is on the same day as the heparin
    AND h.heparin_infusion_time > icud.icustay_intime
    --AND icud.subject_id < 40 -- This is to limit the (Klick)wery
    AND icud.icustay_id IN(SELECT ICUSTAY_ID FROM mimic2v26.medevents WHERE itemid=25 AND dose > 0) --Heparin and dose non zero
    AND icud.icustay_id IN(SELECT ICUSTAY_ID FROM mimic2v26.labevents WHERE ITEMID IN 
                                          (
                                          '50234','50440','50090','50399','50439','50073','50193','50146'
                                          ) -- ICU STAYS MUST ALSO BE STAYS WHERE WE HAD AT LEAST ONE THE LAB EVENTS
                          )    
),

--SELECT * FROM final_pop

--Creatanine intime AS (
-- SELECT DISTINCT

cre_times AS(
SELECT h.icustay_id, MAX(le.charttime) AS lab_time,le.itemid 
FROM mimic2v26.labevents le, heparin_final h 
WHERE h.icustay_id = le.icustay_id 
AND le.charttime < h.heparin_infusion_time
AND le.itemid IN(SELECT ITEMID FROM mimic2v26.D_LABITEMS WHERE TEST_NAME LIKE 'CREAT')--IN('50090')
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
),

ptt_times AS(
SELECT h.icustay_id, MIN(le.charttime) AS lab_time,le.itemid 
FROM mimic2v26.labevents le, heparin_final h 
WHERE h.icustay_id = le.icustay_id 
AND le.charttime > h.heparin_infusion_time
AND le.itemid IN(SELECT ITEMID FROM mimic2v26.D_LABITEMS WHERE TEST_NAME LIKE 'PTT')--IN('50090')
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
)

--SELECT COUNT(*) FROM ptt_n_hep2
--SELECT * FROM ptt_n_hep2

SELECT p.itemid AS ptt_itemid, c.*, p.ptt_time,p.ptt_val,p.ptt_uom
FROM ptt_n_hep2 p, cre_n_hep2 c
WHERE p.icustay_id = c.icustay_id
  AND p.hep_dose = c.hep_dose
