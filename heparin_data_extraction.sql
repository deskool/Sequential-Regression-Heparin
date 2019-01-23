with basic_pop as
  (select distinct icud.subject_id,
          icud.hadm_id,
          icud.icustay_id,
          first_value(i.charttime) over (partition by icud.icustay_id order by i.charttime) as heparin_infusion_time          
   from mimic2v26.icustay_detail icud
   join mimic2v26.ioevents i on icud.icustay_id=i.icustay_id and i.itemid=137
   where icud.icustay_age_group='adult'
     and i.volume>0
     and icud.subject_id<100     
  )
--select * from basic_pop;

, cr_intervals as
  (select bp.*,
          case 
           when l.charttime-bp.heparin_infusion_time > interval '0' minute then l.charttime-bp.heparin_infusion_time
           else bp.heparin_infusion_time-l.charttime
          end as cr_interval,
          l.valuenum
   from basic_pop bp
   join mimic2v26.labevents l on bp.icustay_id=l.icustay_id and l.itemid=50090 and l.valuenum>=0
  )
--select * from cr_intervals;

, cr as
  (select distinct subject_id,
          hadm_id,
          icustay_id,
          heparin_infusion_time,
          first_value(valuenum) over (partition by icustay_id order by cr_interval) as creatinine
   from cr_intervals   
  )

--select * from cr;

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
--select * from ptt_after;

, final_data as
  (select bp.*,
          cr.creatinine,
          pb.ptt_before_heparin,
          pa.ptt_after_heparin
   from basic_pop bp
   join cr on bp.icustay_id=cr.icustay_id
   join ptt_before pb on bp.icustay_id=pb.icustay_id
   join ptt_after pa on bp.icustay_id=pa.icustay_id
  )
select * from final_data;  --2616

