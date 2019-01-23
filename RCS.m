function [  RCS ] = RCS( X_train_stage, Y_train_stage, mdl_under, mdl_under_base)
        ch_ind = find(...
        (mdl_under.predict(X_train_stage) > 0.5 & ...
         mdl_under_base.predict(X_train_stage) <= 0.5) | ...
        (mdl_under.predict(X_train_stage) <= 0.5 &...
         mdl_under_base.predict(X_train_stage) > 0.5));
        
     try
        RCS = HosmerLemeshowTest(mdl_under.predict(X_train_stage(ch_ind,:)),Y_train_stage(ch_ind));
     catch
         RCS = nan;
     end
end

