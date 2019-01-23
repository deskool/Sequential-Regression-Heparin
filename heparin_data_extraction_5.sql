--CREATE MATERIALIZED VIEW Heparin_view_2 AS
--IMPLEMENT THE eGFR in the Query. 

--This captures all heparin infusions.
with first_hep as
  (select distinct 
          icud.icustay_id,
          first_value(me.realtime) over (partition by icud.icustay_id order by me.realtime)  as heparin_infusion_time
   from mimic2v26.icustay_detail icud
   join mimic2v26.medevents me on icud.icustay_id=me.icustay_id and me.itemid IN('25','209','185','321','315','186','381') 
   where icud.icustay_age_group='adult'
     and me.dose>0
     --and icud.subject_id<1000
     )

--SELECT * FROM mimic2v26.D_MEDITEMS WHERE LABEL LIKE '%hep%'     
--select * from first_hep;
     
,last_hep as
  (select distinct 
          icud.icustay_id,
          max(me.realtime) as fin_heparin_infusion_time 
   from mimic2v26.icustay_detail icud
   join mimic2v26.medevents me on icud.icustay_id=me.icustay_id and me.itemid IN('25','209','185','321','315','186','381') 
   where icud.icustay_age_group='adult'
     and me.dose>0
     --and icud.subject_id<1000
     GROUP BY icud.icustay_id
     )
--select * from last_hep;


,pre_basic_pop as
  (select distinct icud.subject_id,
          icud.hadm_id,
          icud.icustay_id,
          icud.hospital_admit_dt,
          icud.weight_first,
          icud.gender,
          --icud.sapsi_max,
          --icud.sofa_max,
          icud.ICUSTAY_FIRST_SERVICE,
          icud.ICUSTAY_ADMIT_AGE,
          --first_value(i.realtime) over (partition by icud.icustay_id order by me.realtime) as heparin_infusion_time,
          COUNT(me.realtime) as num_hep_events
  from mimic2v26.icustay_detail icud
   join mimic2v26.medevents me on icud.icustay_id=me.icustay_id and me.itemid IN('25','209','185','321','315','186','381') 
   where icud.icustay_age_group='adult'
   and me.dose>0
   --and icud.subject_id<1000
   GROUP BY(icud.subject_id,
          icud.hadm_id,
          icud.icustay_id,
          icud.hospital_admit_dt,
          icud.weight_first,
          icud.gender,
          icud.sapsi_max,
          --icud.sofa_max,
          icud.ICUSTAY_FIRST_SERVICE,
          icud.ICUSTAY_ADMIT_AGE) 
  )
  
  --select * from pre_basic_pop;
  
,basic_pop AS(
SELECT DISTINCT bp.*,
       dd.ethnicity_descr,
       fh.heparin_infusion_time,
       lh.fin_heparin_infusion_time
FROM pre_basic_pop bp   
JOIN first_hep fh on bp.icustay_id=fh.icustay_id
JOIN last_hep lh on bp.icustay_id=lh.icustay_id
JOIN mimic2v26.demographic_detail dd on bp.subject_id=dd.subject_id
)

--select * from basic_pop;

--, hep_intervals as
--  (select distinct bp.*,
--          me.realtime,
--          case 
--           when me.realtime-bp.heparin_infusion_time > interval '0' minute then me.realtime-bp.heparin_infusion_time
--           else bp.heparin_infusion_time-me.realtime
--          end as hep_interval
--   from basic_pop bp
--   join mimic2v26.medevents me on bp.icustay_id=me.icustay_id
--  )
 -- select * from hep_intervals;

,heparin_final AS(
SELECT DISTINCT bp.*,
                me.dose as hep_dose,
                me.doseuom as hep_uom
FROM mimic2v26.medevents me, basic_pop bp
where bp.icustay_id = me.icustay_id
  and bp.heparin_infusion_time = me.realtime
  and dose > 0
  and me.itemid IN('25','209','185','321','315','186','381')
  and me.doseuom LIKE 'Uhr' -- We have multiple measurements - we took Uhr
)

--select * from heparin_final;

--select *  from mimic2v26.D_meditems where itemid IN('25','209','185','321','315','186','381') 

, cr_intervals as
  (select bp.*,
          l.charttime,
          case 
           when l.charttime-bp.heparin_infusion_time > interval '0' minute then l.charttime-bp.heparin_infusion_time
           else bp.heparin_infusion_time-l.charttime
          end as cr_interval,
           --------------
           case 
           when l.charttime-bp.heparin_infusion_time > interval '0' minute then 1
           else 0
          end "CRE_AFTER_FLAG",
          l.valuenum
   from heparin_final bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50090 and l.valuenum>=0
  )
--select * from cr_intervals;

--This is taking the closest creatnine lab value to the time of heparin injection - it could be before or after.
, pre_cr as(
select distinct subject_id,
          hadm_id,
          icustay_id,
          cre_after_flag,
          heparin_infusion_time,
          first_value(valuenum) over (partition by icustay_id order by cr_interval) as creatinine,
          first_value(charttime) over (partition by icustay_id order by cr_interval) as charttime_c
   from cr_intervals
   WHERE CRE_AFTER_FLAG = 0
   --WHERE cr_interval > interval '0' minute
  )

,af_cr AS(
select distinct subject_id,
          hadm_id,
          icustay_id,
          cre_after_flag,
          heparin_infusion_time,
          first_value(valuenum) over (partition by icustay_id order by cr_interval) as creatinine,
          first_value(charttime) over (partition by icustay_id order by cr_interval) as charttime_c
   from cr_intervals
   WHERE CRE_AFTER_FLAG = 1
   AND icustay_id NOT IN (SELECT icustay_id FROM pre_cr)
   AND cr_interval < interval '72' hour -- 72 hours after 
   )

,cr AS(
SELECT *
FROM(SELECT * FROM pre_cr
     UNION ALL
     SELECT * FROM af_cr
     )
)

--CR 24hrs AFTER;

, cr_after as
  (select distinct subject_id,
          hadm_id,
          icustay_id,
          heparin_infusion_time,
          first_value(valuenum) over (partition by icustay_id order by cr_interval) as creatinine,
          first_value(charttime) over (partition by icustay_id order by cr_interval) as charttime_c
   from cr_intervals
   WHERE cr_interval > interval '72' hour
   and heparin_infusion_time < charttime
  )

--select * from cr_after;
--select * from mimic2v26.d_labitems WHERE lower(loinc_description) like '%ptt%';

, ptt_before as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by bp.heparin_infusion_time-l.charttime) as ptt_before_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50440 and l.valuenum>=0
   where bp.heparin_infusion_time-l.charttime > interval '0' minute
  )
--select * from ptt_before;

, ptt_after as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by l.charttime-bp.heparin_infusion_time) as ptt_after_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50440 and l.valuenum>=0
   where l.charttime-bp.heparin_infusion_time > interval '0' hour
  )

, saps_after as
  (select distinct bp.icustay_id,
          first_value(value1num) over (partition by bp.icustay_id order by l.charttime-bp.heparin_infusion_time) as saps
   from basic_pop bp
   join mimic2v26.chartevents l on bp.icustay_id=l.icustay_id and l.itemid=20001
   where l.charttime-bp.heparin_infusion_time > interval '0' hour
   AND l.charttime-bp.heparin_infusion_time < interval '24' hour
  )
  
--select * from mimic2v26.chartevents where itemid = 20001
--select * from saps_after;
--select * from ptt_after;


--21 with Bolus.
,hep_bolus as(
select distinct icustay_id      
FROM mimic2v26.ioevents
WHERE itemid  IN(select itemid from mimic2v26.d_ioitems where lower(label) LIKE '%heparin%'
                                                          and lower(category) LIKE '%iv drip%'
                                                          and itemid != 117
                  )
AND icustay_id IN(SELECT icustay_id FROM heparin_final)
)                                                     
--select * from hep_bolus;
--THERE ARE NO PPI PEOPLE
--I am taking the PPI VALUES FROM THE IO TABLE BECAUSE I CAN'T FIND THESE MEDS IN THE MEDITEMS TABLE.
--pantopropozol is what Dr. Lynch told me they use, I didn't find that one. and using the ones that dan gave me
--I found only the following with an indication of an IV
,ppi_cohort AS(
SELECT DISTINCT bp.icustay_id,
                io.itemid,
                bp.heparin_infusion_time,
                first_value(io.realtime) over (partition by bp.icustay_id order by bp.heparin_infusion_time-io.realtime) as ppi_time
FROM basic_pop bp
JOIN mimic2v26.ioevents io on bp.icustay_id=io.icustay_id 
WHERE io.realtime-bp.heparin_infusion_time > interval '0' minute
AND io.ITEMID IN('1537', '328','4797','749','4125','5169','2285')
)

--select * from ppi_cohort;
--SELECT * FROM mimic2v26.D_meditems WHERE LOWER(LABEL) LIKE '%pantoprazole%'
--                                      OR LOWER(LABEL) LIKE '%proton%' 
--                                      OR LOWER(LABEL) LIKE '%ppi%'
--SELECT * FROM ppi_cohort;

--THERE ARE 227 OF THESE
,gi_bleed_cohort AS(
SELECT DISTINCT subject_id, hadm_id, description
FROM mimic2v26.ICD9
WHERE CODE LIKE '456.0%'
   OR CODE LIKE '456.20%'
   OR CODE LIKE '530.7%'
   OR CODE LIKE '530.82%'
   OR CODE LIKE '531.00%'
   OR CODE LIKE '531.01%'
   OR CODE LIKE '531.20%'
   OR CODE LIKE '531.21%'
   OR CODE LIKE '531.40%'
   OR CODE LIKE '531.41%'
   OR CODE LIKE '531.60%'
   OR CODE LIKE '531.61%'
   OR CODE LIKE '532.00%'
   OR CODE LIKE '532.01%'
   OR CODE LIKE '532.20%'
   OR CODE LIKE '532.21%'
   OR CODE LIKE '532.40%'
   OR CODE LIKE '532.41%'
   OR CODE LIKE '532.60%'
   OR CODE LIKE '532.61%'
   OR CODE LIKE '533.00%'
   OR CODE LIKE '533.01%'
   OR CODE LIKE '533.20%'
   OR CODE LIKE '533.21%'
   OR CODE LIKE '533.40%'
   OR CODE LIKE '533.41%'
   OR CODE LIKE '533.60%'
   OR CODE LIKE '533.61%'
   OR CODE LIKE '534.00%'
   OR CODE LIKE '534.01%'
   OR CODE LIKE '534.20%'
   OR CODE LIKE '534.21%'
   OR CODE LIKE '534.40%'
   OR CODE LIKE '534.41%'
   OR CODE LIKE '534.60%'
   OR CODE LIKE '534.61%'
   OR CODE LIKE '569.3%'
   OR CODE LIKE '578.0%'
   OR CODE LIKE '578.1%'
   OR CODE LIKE'578.9%'
AND hadm_id IN(SELECT hadm_id FROM heparin_final)
)
--select * FROM gi_bleed_cohort;

, transfer_cohort AS (
SELECT subject_id,hadm_id
FROM mimic2v26.DEMOGRAPHIC_DETAIL WHERE lower(Admission_source_descr) LIKE '%trans%'
AND hadm_id IN(SELECT hadm_id FROM heparin_final)
)

,ESRD_cohort AS(
SELECT DISTINCT subject_id, hadm_id, description
FROM mimic2v26.ICD9
WHERE CODE IN('585.6%')
AND hadm_id IN(SELECT hadm_id FROM heparin_final)
)

--select * from transfer_cohort;
--SELECT * FROM gi_bleed_cohort;

, final_data as
  (select DISTINCT bp.*,
          sa.saps,
          ROUND(months_between(bp.heparin_infusion_time,bp.hospital_admit_dt)*30*24,2) AS hr_bet_adm_n_hep,
          ROUND(months_between(bp.fin_heparin_infusion_time,bp.heparin_infusion_time)*30*24,2) AS hr_bet_fir_n_las_hep,
          cr.creatinine as creatinin_before,
          cra.creatinine as creatinin_after,
          CASE 
          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cr.creatinine <=0.7 THEN 
            ROUND(166 *POWER(cr.creatinine/.7,-0.329)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cr.creatinine >0.7 THEN 
            ROUND(166 *POWER(cr.creatinine/.7,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cr.creatinine <=0.9 THEN 
            ROUND(163 *POWER(cr.creatinine/.9,-0.411)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cr.creatinine >0.9 THEN 
           ROUND(163 *POWER(cr.creatinine/.9,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)

          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR NOT LIKE '%AFRICAN%' AND cr.creatinine <=0.7 THEN 
            ROUND(144 *POWER(cr.creatinine/.7,-0.329)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR NOT LIKE '%AFRICAN%' AND cr.creatinine >0.7 THEN 
            ROUND(144 *POWER(cr.creatinine/.7,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR  NOT LIKE '%AFRICAN%' AND cr.creatinine <=0.9 THEN 
            ROUND(141 *POWER(cr.creatinine/.9,-0.411)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR NOT LIKE '%AFRICAN%' AND cr.creatinine >0.9 THEN 
            ROUND(141 *POWER(cr.creatinine/.9,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)  
          END "EGFR_BEFORE",
------------------------------------------------------------------------------------------------------          
          CASE 
          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cra.creatinine <=0.7 THEN 
            ROUND(166 *POWER(cra.creatinine/.7,-0.329)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cra.creatinine >0.7 THEN 
            ROUND(166 *POWER(cra.creatinine/.7,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cra.creatinine <=0.9 THEN 
            ROUND(163 *POWER(cra.creatinine/.9,-0.411)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR LIKE '%AFRICAN%' AND cra.creatinine >0.9 THEN 
            ROUND(163 *POWER(cra.creatinine/.9,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)

          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR NOT LIKE '%AFRICAN%' AND cra.creatinine <=0.7 THEN 
            ROUND(144 *POWER(cra.creatinine/.7,-0.329)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'F' AND bp.ETHNICITY_DESCR NOT LIKE '%AFRICAN%' AND cra.creatinine >0.7 THEN 
            ROUND(144 *POWER(cra.creatinine/.7,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR  NOT LIKE '%AFRICAN%' AND cra.creatinine <=0.9 THEN 
            ROUND(141 *POWER(cra.creatinine/.9,-0.411)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)
          
          WHEN bp.gender = 'M' AND bp.ETHNICITY_DESCR NOT LIKE '%AFRICAN%' AND cra.creatinine >0.9 THEN 
            ROUND(141 *POWER(cra.creatinine/.9,-1.209)*POWER(.993,bp.ICUSTAY_ADMIT_AGE),2)  
          END "EGFR_AFTER",
----------------------------------------------------------------------------------------------------------
          CASE
          WHEN bp.subject_id=tc.subject_id and bp.hadm_id=tc.hadm_id THEN 1
          ELSE 0
          END "TRANSFER_FLAG",
----------------------------------------------------------------------------------------------------------
          CASE
          WHEN bp.icustay_id=hb.icustay_id THEN 1
          ELSE 0
          END "HEP_BOLUS_FLAG",
----------------------------------------------------------------------------------------------------------
          CASE
          WHEN bp.subject_id=gib.subject_id and bp.hadm_id=gib.hadm_id THEN 1
          ELSE 0
          END "GI_BLEED_FLAG",
----------------------------------------------------------------------------------------------------------
          CASE
          WHEN bp.subject_id=esrd.subject_id and bp.hadm_id=esrd.hadm_id THEN 1
          ELSE 0
          END "ESRD_FLAG",
--------------------------------------------------------------------------------
          pb.ptt_before_heparin,
          pa.ptt_after_heparin,
          ex.congestive_heart_failure,
          ex.Cardiac_Arrhythmias,
          ex.Valvular_Disease,
          ex.Pulmonary_Circulation,
          ex.Peripheral_Vascular,
          ex.Hypertension,
          ex.Paralysis,
          ex.Other_Neurological,
          ex.Chronic_Pulmonary,
          ex.Diabetes_Uncomplicated,
          ex.Diabetes_Complicated,
          ex.Hypothyroidism,
          ex.Renal_Failure,
          ex.Liver_Disease,
          ex.Peptic_Ulcer,
          ex.AIDS,
          ex.Lymphoma,
          ex.Metastatic_Cancer,
          ex.Solid_Tumor,
          ex.Rheumatoid_Arthritis,
          ex.Coagulopathy,
          ex.Obesity,
          ex.Weight_Loss,
          ex.Fluid_Electrolyte,
          ex.Blood_Loss_Anemia,
          ex.Deficiency_Anemias,
          ex.Alcohol_Abuse,
          ex.Drug_Abuse,
          ex.Psychoses,
          ex.Depression 
   from heparin_final bp
   left join cr on bp.icustay_id=cr.icustay_id
   left join cr_after cra on bp.icustay_id = cra.icustay_id
   left join ptt_before pb on bp.icustay_id=pb.icustay_id
   left join ptt_after pa on bp.icustay_id=pa.icustay_id
   left join mimic2devel.elixhauser_revised ex on bp.subject_id=ex.subject_id and bp.hadm_id=ex.hadm_id
   left join gi_bleed_cohort gib on bp.subject_id=gib.subject_id and bp.hadm_id=gib.hadm_id
   left join hep_bolus hb on bp.icustay_id=hb.icustay_id
   left join transfer_cohort tc on bp.subject_id=tc.subject_id and bp.hadm_id=tc.hadm_id
   left join ESRD_cohort esrd on bp.subject_id=esrd.subject_id and bp.hadm_id=esrd.hadm_id
   left join saps_after sa on bp.icustay_id=sa.icustay_id
  )
  
select * from final_data;
