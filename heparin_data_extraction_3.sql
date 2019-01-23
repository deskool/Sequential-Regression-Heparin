with basic_pop as
  (select distinct icud.subject_id,
          icud.hadm_id,
          icud.icustay_id,
          icud.weight_first,
          icud.gender,
          icud.sapsi_max,
          icud.sofa_max,
          icud.ICUSTAY_FIRST_SERVICE,
          icud.ICUSTAY_ADMIT_AGE,
          first_value(i.charttime) over (partition by icud.icustay_id order by i.charttime) as heparin_infusion_time          
   from mimic2v26.icustay_detail icud
   join mimic2v26.ioevents i on icud.icustay_id=i.icustay_id and i.itemid=137
   where icud.icustay_age_group='adult'
     and i.volume>0
     and icud.subject_id<20     
  ),
--select * from basic_pop

heparin_final AS(
SELECT DISTINCT bp.*,
                me.dose AS hep_dose,
                me.doseuom AS hep_uom
FROM mimic2v26.medevents me, basic_pop bp
where bp.subject_id = me.subject_id
  and bp.icustay_id = me.icustay_id
  and bp.heparin_infusion_time = me.charttime
  and dose > 0
  and me.doseuom LIKE 'Uhr' -- We have multiple measurements - we took Uhr
)

--select * from heparin_final

, cr_intervals as
  (select bp.*,
          l.charttime,
          bp.heparin_infusion_time-l.charttime as cr_interval,
          l.valuenum
   from heparin_final bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50090 and l.valuenum>=0
  )
--select * from cr_intervals


--This is taking the closest creatnine lab value to the time of heparin injection - it could be before or after.
, cr as
  (select distinct subject_id,
          hadm_id,
          icustay_id,
          weight_first,
          sapsi_max,
          sofa_max,
          icustay_first_service,
          icustay_admit_age,
          heparin_infusion_time,
          hep_dose,
          first_value(valuenum) over (partition by icustay_id order by cr_interval) as creatinine,
          first_value(charttime) over (partition by icustay_id order by cr_interval) as charttime_c

   from cr_intervals
   WHERE cr_interval > interval '0' minute
  )
--select * from cr

, ptt_before as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by bp.heparin_infusion_time-l.charttime) as ptt_before_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50440 and l.valuenum>=0
   where bp.heparin_infusion_time-l.charttime > interval '0' minute
  )
--select * from ptt_before;

--select the ptt after the injection
, ptt_after as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by l.charttime-bp.heparin_infusion_time) as ptt_after_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50440 and l.valuenum>=0
   where l.charttime-bp.heparin_infusion_time > interval '0' minute
  )

-- OF OUR SUBJECTS ONLY 71 HAVE THESE VALUES.
, alb_after as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by l.charttime-bp.heparin_infusion_time) as alb_after_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50234-- and l.valuenum>=0
   where l.charttime-bp.heparin_infusion_time > interval '0' minute
  )

-- EVERYONE HAS GOT THIS VALUE 
, pt_after as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by l.charttime-bp.heparin_infusion_time) as pt_after_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50439 -- and l.valuenum>=0
   where l.charttime-bp.heparin_infusion_time > interval '0' minute
  )
 
--1836 SUBJECTS HAVE THIS VALUE
  , ast_after as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by l.charttime-bp.heparin_infusion_time) as ast_after_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50073 -- and l.valuenum>=0
   where l.charttime-bp.heparin_infusion_time > interval '0' minute
  )
  
-- Only 17 subjects have got This value
    , exi_after as
  (select distinct bp.*,
          first_value(valuenum) over (partition by bp.icustay_id order by l.charttime-bp.heparin_infusion_time) as exi_after_heparin
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50146 -- and l.valuenum>=0
   where l.charttime-bp.heparin_infusion_time > interval '0' minute
  )
--select COUNT(*) from exi_after

, final_data as
  (select bp.*,
          cr.creatinine,
          pb.ptt_before_heparin,
          pa.ptt_after_heparin,
 --         alb.alb_after_heparin,
          pt.pt_after_heparin
 --         ast.ast_after_heparin,
 --         exi.exi_after_heparin
   from heparin_final bp
   join cr on bp.icustay_id=cr.icustay_id
   join ptt_before pb on bp.icustay_id=pb.icustay_id
   join ptt_after pa on bp.icustay_id=pa.icustay_id
--   join alb_after alb on bp.icustay_id=alb.icustay_id
   join pt_after pt on bp.icustay_id=pt.icustay_id
 --  join ast_after ast on bp.icustay_id=ast.icustay_id
  -- join exi_after exi on bp.icustay_id=exi.icustay_id
  )
select * from final_data;  --2616

