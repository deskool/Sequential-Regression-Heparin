function [ IDI ] = IDI(X_train_stage,Y_train_stage, mdl_under,mdl_under_base )
        pos_ind = Y_train_stage == 1; 
        neg_ind = Y_train_stage == 0;
        
        p_positives_ind = mdl_under.predict(X_train_stage(pos_ind,:));
        p_negatives_ind = mdl_under.predict(X_train_stage(neg_ind,:));
        
        p_positives_pop  = mdl_under_base.predict(X_train_stage(pos_ind,:));
        p_negatives_pop = mdl_under_base.predict(X_train_stage(neg_ind,:));
        
        IDI = ...
        (nanmean(p_positives_ind) - nanmean(p_negatives_ind)) -...
        (nanmean(p_positives_pop) - nanmean(p_negatives_pop)); 
end

