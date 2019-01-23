CREATE MATERIALIZED VIEW Heparin_view_9 AS
              
WITH first_hep AS
  (SELECT DISTINCT icud.icustay_id,
    first_value(me.charttime) over (partition BY icud.icustay_id order by me.charttime) AS heparin_infusion_time
  FROM mimic2v26.icustay_detail icud
  JOIN mimic2v26.medevents me
  ON icud.icustay_id          =me.icustay_id
  AND me.itemid              IN('25','209','185','321','315','186','381')
  WHERE icud.icustay_age_group='adult'
  AND me.dose                 >0
  --and icud.subject_id<100
  )
  --SELECT * FROM mimic2v26.D_MEDITEMS WHERE LABEL LIKE '%hep%'
  --select * from first_hep;
  ,
  last_hep AS
  (SELECT DISTINCT icud.icustay_id,
    MAX(me.charttime) AS fin_heparin_infusion_time
  FROM mimic2v26.icustay_detail icud
  JOIN mimic2v26.medevents me
  ON icud.icustay_id          =me.icustay_id
  AND me.itemid              IN('25','209','185','321','315','186','381')
  WHERE icud.icustay_age_group='adult'
  AND me.dose                 >0
  --and icud.subject_id<100
  GROUP BY icud.icustay_id
  )
  
  
  --select * from last_hep;
  ,
  pre_basic_pop AS
  (SELECT DISTINCT icud.subject_id,
    icud.hadm_id,
    icud.icustay_id,
    icud.hospital_admit_dt,
    icud.height,
    CASE
      WHEN icud.weight_first < 30
      THEN NULL
      ELSE icud.weight_first
    END AS weight_first,
    icud.gender,
    --icud.sapsi_max,
    --icud.sofa_max,
    icud.ICUSTAY_FIRST_SERVICE,
    icud.ICUSTAY_ADMIT_AGE,
    --first_value(i.charttime) over (partition by icud.icustay_id order by me.charttime) as heparin_infusion_time,
    COUNT(me.charttime) AS num_hep_events
  FROM mimic2v26.icustay_detail icud
  JOIN mimic2v26.medevents me
  ON icud.icustay_id          =me.icustay_id
  AND me.itemid              IN('25','209','185','321','315','186','381')
  WHERE icud.icustay_age_group='adult'
  AND me.dose                 >0
  --and icud.subject_id<100
  GROUP BY(icud.subject_id, 
           icud.hadm_id, 
           icud.icustay_id, 
           icud.hospital_admit_dt, 
           icud.weight_first, 
           icud.gender, 
           icud.sapsi_max, 
           icud.ICUSTAY_FIRST_SERVICE, 
           icud.ICUSTAY_ADMIT_AGE,
           icud.height)
  )
  
  
  --select * from pre_basic_pop;
  ,
  basic_pop AS
  ( SELECT DISTINCT bp.*,
    dd.ethnicity_descr,
    fh.heparin_infusion_time,
    lh.fin_heparin_infusion_time
  FROM pre_basic_pop bp
  JOIN first_hep fh
  ON bp.icustay_id=fh.icustay_id
  JOIN last_hep lh
  ON bp.icustay_id=lh.icustay_id
  JOIN mimic2v26.demographic_detail dd
  ON bp.subject_id=dd.subject_id
  )
  --select * from basic_pop;
  --, hep_intervals as
  --  (select distinct bp.*,
  --          me.charttime,
  --          case
  --           when me.charttime-bp.heparin_infusion_time > interval '0' minute then me.charttime-bp.heparin_infusion_time
  --           else bp.heparin_infusion_time-me.charttime
  --          end as hep_interval
  --   from basic_pop bp
  --   join mimic2v26.medevents me on bp.icustay_id=me.icustay_id
  --  )
  
  
  -- select * from hep_intervals;
  ,
  heparin_final AS
  ( SELECT DISTINCT bp.*,
    me.dose    AS hep_dose,
    me.doseuom AS hep_uom
  FROM mimic2v26.medevents me,
    basic_pop bp
  WHERE bp.icustay_id          = me.icustay_id
  AND bp.heparin_infusion_time = me.charttime
  AND dose                     > 0
  AND me.itemid               IN('25','209','185','321','315','186','381')
  AND me.doseuom LIKE 'Uhr' -- We have multiple measurements - we took Uhr
  )
  --select * from heparin_final;
  --select *  from mimic2v26.D_meditems where itemid IN('25','209','185','321','315','186','381')
  ,
  cr_intervals AS
  (SELECT bp.*,
    l.charttime AS cre_charttime,
    l.valueuom,
    CASE
      WHEN l.charttime             -bp.heparin_infusion_time > interval '0' minute
      THEN l.charttime             -bp.heparin_infusion_time
      ELSE bp.heparin_infusion_time-l.charttime
    END AS cr_interval,
    --------------
    CASE
      WHEN l.charttime-bp.heparin_infusion_time > interval '0' minute
      THEN 1
      ELSE 0
    END "CRE_AFTER_FLAG",
    l.valuenum
  FROM heparin_final bp
  JOIN mimic2v26.labevents l
  ON bp.icustay_id=l.icustay_id
  AND l.itemid    =50090
  AND l.valuenum >=0
  )
  
  
  --select * from cr_intervals;
  --This is taking the closest creatnine lab value to the time of heparin injection - it could be before or after.
  ,
  pre_cr AS
  ( SELECT DISTINCT subject_id,
    hadm_id,
    icustay_id,
    cre_after_flag,
    heparin_infusion_time,
    first_value(valuenum) over (partition BY icustay_id order by cr_interval)      AS creatinine,
    first_value(cre_charttime) over (partition BY icustay_id order by cr_interval) AS charttime_c
  FROM cr_intervals
  WHERE CRE_AFTER_FLAG = 0
    --WHERE cr_interval > interval '0' minute
  ) ,
  af_cr AS
  ( SELECT DISTINCT subject_id,
    hadm_id,
    icustay_id,
    cre_after_flag,
    heparin_infusion_time,
    first_value(valuenum) over (partition BY icustay_id order by cr_interval)      AS creatinine,
    first_value(cre_charttime) over (partition BY icustay_id order by cr_interval) AS charttime_c
  FROM cr_intervals
  WHERE CRE_AFTER_FLAG = 1
  AND icustay_id NOT  IN
    (SELECT icustay_id FROM pre_cr
    )
  AND cr_interval < interval '72' hour -- 72 hours after
  ) ,
  cr AS
  ( SELECT * FROM
    (SELECT * FROM pre_cr
    UNION ALL
    SELECT * FROM af_cr
    )
  )
  --select * from cr;
  --CR 24hrs AFTER;
  ,
  cr_next AS
  (SELECT DISTINCT cr_intervals.subject_id,
    cr_intervals.hadm_id,
    cr_intervals.icustay_id,
    cr_intervals.heparin_infusion_time,
    first_value(valuenum) over (partition BY cr_intervals.icustay_id order by cr_intervals.cr_interval)                   AS creatinine,
    first_value(cr_intervals.cre_charttime) over (partition BY cr_intervals.icustay_id order by cr_intervals.cr_interval) AS charttime_c
  FROM cr_intervals
  JOIN cr
  ON cr.icustay_id               = cr_intervals.icustay_id
  WHERE cr_intervals.cr_interval < interval '72' hour
  AND cr.charttime_c             < cr_intervals.cre_charttime
  )
  --select * from cr_next;
  --select * from mimic2v26.d_labitems WHERE lower(loinc_description) like '%ptt%';
  
,ptt_interval_6hr AS
  (
  SELECT bp.*,
    l.charttime AS ptt_charttime,
    l.valueuom,
    l.valuenum,
    CASE
      WHEN bp.heparin_infusion_time + interval '6' hour - l.charttime > interval '0' minute
        THEN bp.heparin_infusion_time + interval '6' hour - l.charttime
      ELSE l.charttime - bp.heparin_infusion_time - interval '6' hour
    END "PTT_INTERVAL"  
  FROM heparin_final bp
  JOIN mimic2v26.labevents l
  ON bp.icustay_id=l.icustay_id
  AND l.itemid    =50440
  AND l.valuenum >=0
  )
  
 -- select * from ptt_interval;
  ,
  ptt_6hr AS
  ( SELECT DISTINCT subject_id,
    hadm_id,
    icustay_id,
    first_value(valuenum) over (partition BY icustay_id order by p.ptt_interval)      AS ptt_val,
    heparin_infusion_time,
    first_value(ptt_charttime) over (partition BY icustay_id order by p.ptt_interval) AS charttime_ptt
  FROM ptt_interval_6hr p
  WHERE ptt_interval <= interval '2' hour
  )
  
  ,ptt_interval_12hr AS
  (
  SELECT bp.*,
    l.charttime AS ptt_charttime,
    l.valueuom,
    l.valuenum,
    CASE
      WHEN bp.heparin_infusion_time + interval '12' hour - l.charttime > interval '0' minute
        THEN bp.heparin_infusion_time + interval '12' hour - l.charttime
      ELSE l.charttime - bp.heparin_infusion_time - interval '12' hour
    END "PTT_INTERVAL"  
  FROM heparin_final bp
  JOIN mimic2v26.labevents l
  ON bp.icustay_id=l.icustay_id
  AND l.itemid    =50440
  AND l.valuenum >=0
  )
  
  
  ,ptt_12hr AS
  ( SELECT DISTINCT subject_id,
    hadm_id,
    icustay_id,
    first_value(valuenum) over (partition BY icustay_id order by p.ptt_interval)      AS ptt_val,
    heparin_infusion_time,
    first_value(ptt_charttime) over (partition BY icustay_id order by p.ptt_interval) AS charttime_ptt
  FROM ptt_interval_12hr p
  WHERE ptt_interval <= interval '2' hour
  )
  
,ptt_interval_24hr AS
  (
  SELECT bp.*,
    l.charttime AS ptt_charttime,
    l.valueuom,
    l.valuenum,
    CASE
      WHEN bp.heparin_infusion_time + interval '24' hour - l.charttime > interval '0' minute
        THEN bp.heparin_infusion_time + interval '24' hour - l.charttime
      ELSE l.charttime - bp.heparin_infusion_time - interval '24' hour
    END "PTT_INTERVAL"  
  FROM heparin_final bp
  JOIN mimic2v26.labevents l
  ON bp.icustay_id=l.icustay_id
  AND l.itemid    =50440
  AND l.valuenum >=0
  )
  
  
  ,ptt_24hr AS
  ( SELECT DISTINCT subject_id,
    hadm_id,
    icustay_id,
    first_value(valuenum) over (partition BY icustay_id order by p.ptt_interval)      AS ptt_val,
    heparin_infusion_time,
    first_value(ptt_charttime) over (partition BY icustay_id order by p.ptt_interval) AS charttime_ptt
  FROM ptt_interval_24hr p
  WHERE ptt_interval <= interval '4' hour
  )
  
 -- SELECT * FROM ptt_24hr;

  
  ,sofa_after AS
  (SELECT DISTINCT bp.icustay_id,
    first_value(l.value1num) over (partition BY bp.icustay_id order by l.charttime-bp.heparin_infusion_time) AS sofa_overall,
    first_value(k.value1num) over (partition BY bp.icustay_id order by k.charttime-bp.heparin_infusion_time) AS sofa_renal
  FROM basic_pop bp
  JOIN mimic2v26.chartevents l
  ON bp.icustay_id=l.icustay_id
  AND l.itemid    =20009
  JOIN mimic2v26.chartevents k
  ON bp.icustay_id                           =k.icustay_id
  AND k.itemid                               =20008
  WHERE l.charttime-bp.heparin_infusion_time > interval '0' hour
  AND l.charttime  -bp.heparin_infusion_time < interval '24' hour
  AND k.charttime  -bp.heparin_infusion_time > interval '0' hour
  AND k.charttime  -bp.heparin_infusion_time < interval '24' hour
  )
  --select * from mimic2v26.chartevents where itemid LIKE '20009';
  --select * from sofa_after;
  --select * from ptt_after;
  --21 with Bolus.
  ,
  hep_bolus AS
  ( SELECT DISTINCT icustay_id
  FROM mimic2v26.ioevents
  WHERE itemid IN
    (SELECT itemid
    FROM mimic2v26.d_ioitems
    WHERE lower(label) LIKE '%heparin%'
    AND lower(category) LIKE '%iv drip%'
    AND itemid != 117
    )
  AND icustay_id IN
    (SELECT icustay_id FROM heparin_final
    )
  )
  --select * from hep_bolus;
  --THERE ARE NO PPI PEOPLE
  --I am taking the PPI VALUES FROM THE IO TABLE BECAUSE I CAN'T FIND THESE MEDS IN THE MEDITEMS TABLE.
  --pantopropozol is what Dr. Lynch told me they use, I didn't find that one. and using the ones that dan gave me
  --I found only the following with an indication of an IV
  ,
  ppi_cohort AS
  ( SELECT DISTINCT bp.icustay_id,
    io.itemid,
    bp.heparin_infusion_time,
    first_value(io.charttime) over (partition BY bp.icustay_id order by bp.heparin_infusion_time-io.charttime) AS ppi_time
  FROM basic_pop bp
  JOIN mimic2v26.ioevents io
  ON bp.icustay_id                             =io.icustay_id
  WHERE io.charttime                           -bp.heparin_infusion_time > interval '0' minute
  AND io.ITEMID                               IN('1537', '328','4797','749','4125','5169','2285')
  )
  --select * from ppi_cohort;
  --SELECT * FROM mimic2v26.D_meditems WHERE LOWER(LABEL) LIKE '%pantoprazole%'
  --                                      OR LOWER(LABEL) LIKE '%proton%'
  --                                      OR LOWER(LABEL) LIKE '%ppi%'
  --SELECT * FROM ppi_cohort;
  --THERE ARE 227 OF THESE
  ,
  gi_bleed_cohort AS
  ( SELECT DISTINCT subject_id,
    hadm_id,
    description
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
  OR CODE LIKE '578.9%'
  AND hadm_id IN
    (SELECT hadm_id FROM heparin_final
    )
  )
  --select * FROM gi_bleed_cohort;
  ,
  pe_cohort AS -- pulmonary embolism patients
  ( SELECT DISTINCT subject_id,
    hadm_id,
    description
  FROM mimic2v26.ICD9
  WHERE CODE LIKE '415.1%'
  AND hadm_id IN
    (SELECT hadm_id FROM heparin_final
    )
  )
  --select * FROM pe_cohort;
  ,
  transfer_cohort AS
  (SELECT subject_id,
    hadm_id
  FROM mimic2v26.DEMOGRAPHIC_DETAIL
  WHERE lower(Admission_source_descr) LIKE '%trans%'
  AND hadm_id IN
    (SELECT hadm_id FROM heparin_final
    )
  ) ,
  ESRD_cohort AS
  ( SELECT DISTINCT subject_id,
    hadm_id,
    description
  FROM mimic2v26.ICD9
  WHERE CODE LIKE '585.6%'
  AND hadm_id IN
    (SELECT hadm_id FROM heparin_final
    )
  )
  --select * from transfer_cohort;
  ,
  final_data AS
  (SELECT DISTINCT bp.subject_id,
    bp.hadm_id,
    bp.icustay_id,
    bp.height,
    bp.weight_first,
    ---- http://www.manuelsweb.com/IBW.htm-------------------------------------
    CASE
     WHEN bp.GENDER = 'M'
     AND bp.HEIGHT >= 152
     THEN 50 + (bp.HEIGHT - 152) * 0.905
     WHEN bp.GENDER = 'F'
     AND bp.HEIGHT >= 152
     THEN 45.5 + (bp.HEIGHT - 152) * 0.905
     ELSE NULL
    END "IDEAL_WEIGHT",
    ---------------------------------------------------------------------------
    bp.gender,
    ---------------------------------------------------------------------------
    CASE
      WHEN bp.icustay_admit_age > 120
      THEN 92.4
      ELSE bp.icustay_admit_age
    END "AGE",
    ---------------------------------------------------------------------------
    bp.ethnicity_descr,
    bp.icustay_first_service,
    bp.hep_dose                          AS hep_dose_units_ph,
    ROUND(bp.hep_dose/bp.weight_first,2) AS dose_by_weight,
    bp.num_hep_events,

    ROUND(EXTRACT(DAY FROM bp.heparin_infusion_time    - cr.charttime_c)* 24 + EXTRACT(HOUR FROM bp.heparin_infusion_time - cr.charttime_c) + EXTRACT(MINUTE FROM bp.heparin_infusion_time - cr.charttime_c)/60,2) hr_bet_fir_cre_n_hep,
    ROUND(EXTRACT(DAY FROM bp.heparin_infusion_time    - cra.charttime_c)* 24 + EXTRACT(HOUR FROM bp.heparin_infusion_time - cra.charttime_c) + EXTRACT(MINUTE FROM bp.heparin_infusion_time - cra.charttime_c)/60,2) hr_bet_las_cre_n_hep,
    ROUND(EXTRACT(DAY FROM bp.heparin_infusion_time    -bp.hospital_admit_dt)* 24 + EXTRACT(HOUR FROM bp.heparin_infusion_time-bp.hospital_admit_dt) + EXTRACT(MINUTE FROM bp.heparin_infusion_time-bp.hospital_admit_dt)/60,2) hr_bet_adm_n_hep,
    ROUND(EXTRACT(DAY FROM bp.fin_heparin_infusion_time-bp.heparin_infusion_time)* 24 + EXTRACT(HOUR FROM bp.fin_heparin_infusion_time-bp.heparin_infusion_time) + EXTRACT(MINUTE FROM bp.fin_heparin_infusion_time-bp.heparin_infusion_time)/60,2) hr_bet_fir_n_las_hep,
   
    sa.sofa_overall                                    - sa.sofa_renal AS sofa_adjusted,
    
    cr.creatinine                                                      AS creatinin_before,
    cra.creatinine                                                     AS creatinin_after,
    
    CASE
      WHEN tc.hadm_id IS NULL
      THEN 0
      ELSE 1
    END "TRANSFER_FLAG",

    --          CASE
    --          WHEN bp.icustay_id=hb.icustay_id THEN 1
    --          ELSE 0
    --          END "HEP_BOLUS_FLAG",
    ----------------------------------------------------------------------------------------------------------
    --          CASE
    --          WHEN bp.subject_id=gib.subject_id and bp.hadm_id=gib.hadm_id THEN 1
    --          ELSE 0
    --          END "GI_BLEED_FLAG",
    ----------------------------------------------------------------------------------------------------------
    CASE
      WHEN esrd.hadm_id IS NULL
      THEN 0
      ELSE 1
    END "ESRD_FLAG",
    CASE
      WHEN pc.hadm_id IS NULL
      THEN 0
      ELSE 1
    END "PULMONARY_EMBOLISM",
    --------------------------------------------------------------------------------
    --          CASE
    --          WHEN bp.icustay_id=ppi.icustay_id THEN 1
    --          ELSE 0
    --          END "PPI_INFUSION_AFTER_FLAG",
    --------------------------------------------------------------------------------
    p6.ptt_val AS PTT_VAL_6HR,
    ROUND(EXTRACT(HOUR FROM p6.charttime_ptt - bp.heparin_infusion_time) +  EXTRACT(MINUTE FROM p6.charttime_ptt - bp.heparin_infusion_time)/60,2) AS PTT_6HR_TIME_FROM_HEP,
    p12.ptt_val AS PTT_VAL_12HR,
    ROUND(EXTRACT(HOUR FROM p12.charttime_ptt - bp.heparin_infusion_time) +  EXTRACT(MINUTE FROM p12.charttime_ptt - bp.heparin_infusion_time)/60,2) AS PTT_12HR_TIME_FROM_HEP,
    p24.ptt_val AS PTT_VAL_24HR,
    ROUND(EXTRACT(DAY FROM p24.charttime_ptt - bp.heparin_infusion_time)*24 + EXTRACT(HOUR FROM p24.charttime_ptt - bp.heparin_infusion_time) +  EXTRACT(MINUTE FROM p24.charttime_ptt - bp.heparin_infusion_time)/60,2) AS PTT_24HR_TIME_FROM_HEP,
        
    ex.twenty_eight_day_mort_pt AS elixhauser_pt

  FROM heparin_final bp
  LEFT JOIN cr
  ON bp.icustay_id=cr.icustay_id
  LEFT JOIN cr_next cra
  ON bp.icustay_id = cra.icustay_id
  LEFT JOIN ptt_6hr p6
  ON bp.icustay_id=p6.icustay_id
  LEFT JOIN ptt_12hr p12
  ON bp.icustay_id=p12.icustay_id
  LEFT JOIN ptt_24hr p24
  ON bp.icustay_id=p24.icustay_id
  LEFT JOIN mimic2devel.elixhauser_points ex
  ON bp.hadm_id=ex.hadm_id
    --   left join gi_bleed_cohort gib on bp.subject_id=gib.subject_id and bp.hadm_id=gib.hadm_id
    --   left join hep_bolus hb on bp.icustay_id=hb.icustay_id
  LEFT JOIN transfer_cohort tc
  ON bp.hadm_id=tc.hadm_id
  LEFT JOIN ESRD_cohort esrd
  ON bp.hadm_id=esrd.hadm_id
  LEFT JOIN sofa_after sa
  ON bp.icustay_id=sa.icustay_id
    --   left join ppi_cohort ppi on bp.icustay_id=ppi.icustay_id
  LEFT JOIN pe_cohort pc
  ON bp.hadm_id=pc.hadm_id
  )
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------------------------------------------------------------
--select * from final_data;
--SELECT * FROM VS_DOSE;

SELECT fd.*,
  ntile(100) over(order by HEP_DOSE_UNITS_PH) as dose_ntile,
  
  CASE
    WHEN (CREATININ_AFTER - CREATININ_BEFORE)/(CREATININ_BEFORE) > 0.3
    THEN 1
    WHEN CREATININ_BEFORE IS NOT NULL
    AND CREATININ_AFTER   IS NOT NULL
    THEN 0
    ELSE NULL
  END "CREATININ_UP_30P",
  --
  CASE
   WHEN WEIGHT_FIRST/((HEIGHT * 0.01) * (HEIGHT * 0.01)) > 29.9
   THEN 1
   WHEN HEIGHT IS NOT NULL
   AND WEIGHT_FIRST IS NOT NULL
   THEN 0
   ELSE NULL
  END "OBESE_FLAG",
    
  CASE
    WHEN ICUSTAY_FIRST_SERVICE LIKE 'CSRU'
    OR   ICUSTAY_FIRST_SERVICE LIKE 'SICU'
    THEN 1
    WHEN ICUSTAY_FIRST_SERVICE LIKE 'MICU'
    OR   ICUSTAY_FIRST_SERVICE LIKE 'FICU'
    OR   ICUSTAY_FIRST_SERVICE LIKE 'CCU'
    THEN 0
    ELSE NULL
  END "ICUSTAY_GROUP_CSRU_SICU"
  
FROM final_data fd;