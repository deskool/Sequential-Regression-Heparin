function [ NRI ] = NRI(X_train_stage,Y_train_stage,mdl_under,mdl_under_base)
      p_went_up = (mdl_under.predict(X_train_stage) > 0.5 & ...
                   mdl_under_base.predict(X_train_stage) <= 0.5);
               
        p_went_down = (mdl_under.predict(X_train_stage) <= 0.5 &...
                     mdl_under_base.predict(X_train_stage) > 0.5); 
                 
        p_up_given_pos = mean(p_went_up & Y_train_stage == 1);
        
        p_down_given_pos = mean(p_went_down & Y_train_stage == 1); 
        
        p_up_given_neg = mean(p_went_up & Y_train_stage == 0);
        
        p_down_given_neg = mean(p_went_down & Y_train_stage == 0);

        NRI = ...
            (p_up_given_pos - p_down_given_pos) -...
            (p_up_given_neg - p_down_given_neg); 

end

