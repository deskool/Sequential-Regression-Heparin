
%Extra info 2 compares a population model with all features as the baseline
%To the individual model that selects the features.
%load extra_info

%This is for a baseline model that only uses the first 7 features 
%load results_base_with_less_features


%% Rsq %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Rsq_under = sum(sum(Rsq_under))/(size(Rsq_under,1)*size(Rsq_under,2))
Rsq_under_base = sum(sum(Rsq_under_base))/(size(Rsq_under_base,1)*size(Rsq_under_base,2))

Rsq_over = sum(sum(Rsq_over))/(size(Rsq_over,1)*size(Rsq_over,2))
Rsq_over_base = sum(sum(Rsq_over_base))/(size(Rsq_over_base,1)*size(Rsq_over_base,2))

% plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure;
% errorbar([1:8],[0,mean(Rsq_under) - mean(Rsq_under_base)],[0,std(Rsq_under)/sqrt(length(Rsq_under))],'y','Linewidth',2)
% hold on;
% errorbar([1:8],[0,mean(Rsq_over) - mean(Rsq_over_base)],[0,std(Rsq_over)/sqrt(length(Rsq_over))],'r','Linewidth',2)
% grid on;
% legend('Sub-therapeutic model','Supra-therapeutic model','Location','NorthEast')
% ylabel('R^2 Individual Model - R^2 Population Model')
% xlabel('Dose Adjustment Interval')
% xlim([1 8])
% print('Rsq_7_20_0_0','-dpng')

%This makes sense because as we continue to tailor the model to the
%individual's data, the less applicable the model is to the general
%population, which in turn, drives down it's Rsq value.

%% BIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BIC_under = sum(sum(bic_under))/(size(bic_under,1)*size(bic_under,2))
BIC_under_base = sum(sum(bic_under_base))/(size(bic_under_base,1)*size(bic_under_base,2))

BIC_over = sum(sum(bic_over))/(size(bic_over,1)*size(bic_over,2))
BIC_over_base = sum(sum(bic_over_base))/(size(bic_over_base,1)*size(bic_over_base,2))

% plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% errorbar([1:8],[0,mean(bic_under) - mean(bic_under_base)],[0,std(bic_under)/sqrt(length(bic_under))],'y','Linewidth',2)
% hold on;
% errorbar([1:8],[0,mean(bic_over) - mean(bic_over_base)],[0,std(bic_over)/sqrt(length(bic_over))],'r','Linewidth',2)
% grid on;
% legend('Sub-therapeutic model','Supra-therapeutic model','Location','NorthWest')
% ylabel('BIC Individual Model - BIC Population Model')
% xlabel('Dose Adjustment')
% xlim([1 8])
% print('BIC_7_20_0_0','-dpng')
%The figure shows that the BIC of the 'individual model' increases at each
%dosing stage.



%% HL-test means %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
HL_under = sum(sum(HL_under))/(size(HL_under,1)*size(HL_under,2))
HL_under_base = sum(sum(HL_under_base))/(size(HL_under_base,1)*size(HL_under_base,2))

HL_over = sum(sum(HL_over))/(size(HL_over,1)*size(HL_over,2))
HL_over_base = sum(sum(HL_over_base))/(size(HL_over_base,1)*size(HL_over_base,2))


%plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure;
% errorbar([1:8],[0,mean(HL_under) - mean(HL_under_base)],[0,std(HL_under)/sqrt(length(HL_under))],'y','Linewidth',2)
% hold on;
% errorbar([1:8],[0,mean(HL_over) - mean(HL_over_base)],[0,std(HL_over)/sqrt(length(HL_over))],'r','Linewidth',2)
% grid on;
% legend('Sub-therapeutic model','Supra-therapeutic model','Location','NorthWest')
% ylabel('HL Individual Model - HL Population Model')
% xlabel('Dose Adjustment Interval')
% xlim([1 8])
% print('HL_7_20_0_0','-dpng')
%This clearly shows that our model improves the calibration according to
%the HL-test p-value.

%% MISSING DATA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find where we were able to predict, but the population model didn't have
% enough data.
use_these = ~isnan(yc_test);

missing_ind = mean(isnan(preds_test_under(use_these)))
missing_base = mean(isnan(preds_test_under_base((use_these))))
missing_at_stage = mean(isnan(preds_test_under_base) == 1 & use_these == 1)

%plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure;
% plot([1:8],100*[missing_at_stage,0],'r','Linewidth',2)
% grid on;
% ylabel('% Patients Missing Features')
% xlabel('Dose Adjustment Interval')
% xlim([1 8])
% print('Missing_7_20_0_0','-dpng')
% note that our appraoch does not miss any of these patients.


%% HL TEST - Collapsed across patients and intervals.
% let's compare the models on the shared subset of patients for which 
% they were both able to make predictions. That is, the model that 
% has 
test_on_these = ~isnan(preds_test_under_base)

%HL Test across all patients, across all dosing intervals.
%under
n = 22;
HL_under = HosmerLemeshowTest(preds_test_under(test_on_these),yc_test_under(test_on_these),n)
HL_under_base = HosmerLemeshowTest(preds_test_under_base(test_on_these),yc_test_under(test_on_these),n)

HL_over = HosmerLemeshowTest(preds_test_over(test_on_these),yc_test_over(test_on_these),n)
HL_over_base = HosmerLemeshowTest(preds_test_over_base(test_on_these),yc_test_over(test_on_these),n)

% plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear jj
% %over
% for i = 1:50
% jj(i) = HosmerLemeshowTest(preds_test_over_base(test_on_these),yc_test_over(test_on_these),i)
% end
% plot(jj)
% hold on;
% for i = 1:50
% jj(i) = HosmerLemeshowTest(preds_test_over(test_on_these),yc_test_over(test_on_these),i)
% end
% plot(jj)
% hold on;
% plot([1 50],[0.05 0.05],'black--')
% ylabel('HL Test p-value')
% xlabel('Number of groups')
% legend('Population Model','Individual Model','Significance Threshold','Location','NorthWest')
% xlim([1 50])
% print('HL_over_7_20_0_0','-dpng')
% 
% figure;
% clear jj
% %over
% for i = 1:50
% jj(i) = HosmerLemeshowTest(preds_test_under_base(test_on_these),yc_test_under(test_on_these),i)
% end
% plot(jj)
% hold on;
% for i = 1:50
% jj(i) = HosmerLemeshowTest(preds_test_under(test_on_these),yc_test_under(test_on_these),i)
% end
% plot(jj)
% hold on;
% plot([1 50],[0.05 0.05],'black--')
% ylabel('HL Test p-value')
% xlabel('Number of groups')
% legend('Population Model','Individual Model','Significance Threshold','Location','NorthWest')
% xlim([20 40])
% print('HL_under_7_20_0_0','-dpng')


% One criticism of the HL test is that the number of groups chosen
% by the investgator can dramatically impact the significance of the 
% estimate. Hence, we provide a plot of the HL-test's
% reuslts for both the individual and population model 
% across a range of values.


%%  RCS Test  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A test base on HL that compares the observed and expected number of events
% within each cell of a reclassification table. It should generally be
% restricted to 20 observations. for this, you want p > 0.05
n = 22;
% under %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
test_on_these =(...
        (preds_test_under > 0.5 & ...
         preds_test_under_base <= 0.5) | ...
        (preds_test_under <= 0.5 &...
         preds_test_under_base > 0.5));    

RSC_under = HosmerLemeshowTest(preds_test_under(test_on_these),yc_test_under(test_on_these),n)

% over %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
test_on_these =(...
        (preds_test_over > 0.5 & ...
         preds_test_over_base <= 0.5) | ...
        (preds_test_over <= 0.5 &...
         preds_test_over_base > 0.5));  
 
RSC_over = HosmerLemeshowTest(preds_test_over(test_on_these),yc_test_over(test_on_these),n)
   
     

%% NRI Across All Patients, and dosing. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%The net increase vs. decrease in risk categories among cases minus that
%among non-cases.

%under %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p_went_up = (preds_test_under > 0.5 & ...
               preds_test_under_base <= 0.5);

p_went_down = (preds_test_under <= 0.5 &...
               preds_test_under_base > 0.5); 

         
p_up_given_pos = sum(p_went_up(yc_test_under))/length(yc_test_under(yc_test_under == 1));
p_down_given_pos = sum(p_went_down(yc_test_under))/length(yc_test_under(yc_test_under == 1));
p_up_given_neg = sum(p_went_up(yc_test_under))/length(yc_test_under(yc_test_under == 0));
p_down_given_neg = sum(p_went_down(yc_test_under))/length(yc_test_under(yc_test_under == 0));

NRI_under = ...
    (p_up_given_pos - p_down_given_pos) -...
    (p_up_given_neg - p_down_given_neg) 
% Compared to the population model, our individual appraoch 
% was 0.5% more likly to classify overdosed patient's as overdosed.

%The NRI is the sum of the two, or 9.8%. 
%This means that compared to controls, 
%cases were almost 10 percent more likely to move up a category than down

%over %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p_went_up = (preds_test_over > 0.5 & ...
               preds_test_over_base <= 0.5);

p_went_down = (preds_test_over <= 0.5 &...
               preds_test_over_base > 0.5); 
       
p_up_given_pos = sum(p_went_up(yc_test_over))/length(yc_test_over(yc_test_over == 1));
p_down_given_pos = sum(p_went_down(yc_test_over))/length(yc_test_over(yc_test_over == 1));
p_up_given_neg = sum(p_went_up(yc_test_over))/length(yc_test_over(yc_test_over == 0));
p_down_given_neg = sum(p_went_down(yc_test_over))/length(yc_test_over(yc_test_over == 0));

NRI_over = ...
    (p_up_given_pos - p_down_given_pos) -...
    (p_up_given_neg - p_down_given_neg) 
% Compared to the population model, our individual appraoch 
% was 2.5% more likly to classify overdosed patient's as overdosed.


%% IDI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The difference in Yates slopes between models, where the Yate slope is
% the mean difference in predicted probability between cases
%under %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pos_ind = yc_test_under == 1 & ~isnan(preds_test_under_base); 
neg_ind = yc_test_under == 0 & ~isnan(preds_test_under_base);

p_positives_ind = preds_test_under(pos_ind);
p_negatives_ind =preds_test_under(neg_ind);

p_positives_pop  = preds_test_under_base(pos_ind);
p_negatives_pop = preds_test_under_base(neg_ind);

IDI_under = ...
(mean(p_positives_ind) - mean(p_negatives_ind)) -...
(mean(p_positives_pop) - mean(p_negatives_pop)); 

%over %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pos_ind = yc_test_over == 1 & ~isnan(preds_test_over_base); 
neg_ind = yc_test_over == 0 & ~isnan(preds_test_over_base);

p_positives_ind = preds_test_over(pos_ind);
p_negatives_ind =preds_test_over(neg_ind);

p_positives_pop  = preds_test_over_base(pos_ind);
p_negatives_pop = preds_test_over_base(neg_ind);

IDI_over = ...
(mean(p_positives_ind) - mean(p_negatives_ind)) -...
(mean(p_positives_pop) - mean(p_negatives_pop)); 

%% VUS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%individual model %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
predictions = [preds_test_under(~isnan(preds_test_over_base)),...
               preds_test_ther(~isnan(preds_test_over_base)),...
               preds_test_over(~isnan(preds_test_over_base))];

actuals =  [yc_test_under(~isnan(preds_test_over_base)),...
            yc_test_ther(~isnan(preds_test_over_base)),...
            yc_test_over(~isnan(preds_test_over_base))]

pred_class = [predictions == repmat(max(predictions')',1,3)]*[1; 2 ;3];
act_class = actuals*[1;2;3];        

accuracy = mean(pred_class == act_class)
accuracy_clinician = mean(actuals(:,2))        

%VUS = perfSurface(actuals,predictions) %0.46

%base model %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
predictions = [preds_test_under_base(~isnan(preds_test_over_base)),...
               preds_test_ther_base(~isnan(preds_test_over_base)),...
               preds_test_over_base(~isnan(preds_test_over_base))];

actuals =  [yc_test_under(~isnan(preds_test_over_base)),...
            yc_test_ther(~isnan(preds_test_over_base)),...
            yc_test_over(~isnan(preds_test_over_base))]
     
pred_class = [predictions == repmat(max(predictions')',1,3)]*[1; 2 ;3];
act_class = actuals*[1;2;3];    

accuracy_base = mean(pred_class == act_class)        

%VUS_base = perfSurface(actuals,predictions) %0.41

%% AUC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%under %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use_these = find(~isnan(preds_test_under_base));

labels = yc_test_under(use_these)
predictions = preds_test_under(use_these)
[~,~,~,AUC_test_under] = perfcurve(1*labels,predictions,1)

labels = yc_test_under(use_these)
predictions = preds_test_under_base(use_these)
[~,~,~,AUC_test_under_base] = perfcurve(1*labels,predictions,1)

%over %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
use_these = find(~isnan(preds_test_over_base));

labels = yc_test_over(use_these)
predictions = preds_test_over(use_these)
[~,~,~,AUC_test_over] = perfcurve(1*labels,predictions,1)

labels = yc_test_over(use_these)
predictions = preds_test_over_base(use_these)
[~,~,~,AUC_test_over_base] = perfcurve(1*labels,predictions,1)



% 
% 
% %%GET THE AUCs
% for i = 1:7
%     try
%         labels = yc_test_over(:,i)';
%         predictions = preds_test_over(:,i);
%         
%         [~,~,~,AUC_test_over(i)] = perfcurve(1*labels,predictions,1);
%         
%     catch
%         AUC_test_over(i) = nan;
%     end
%     
%     try
%         labels = yc_test_under(:,i)';
%         predictions = preds_test_under(:,i);
%         
%         [~,~,~,AUC_test_under(i)] = perfcurve(1*labels,predictions,1);
%         
%     catch
%         AUC_test_under(i) = nan;
%     end
%     
%     try
%         labels = yc_test_ther(:,i)';
%         predictions = preds_test_ther(:,i);
%         
%         [~,~,~,AUC_test_ther(i)] = perfcurve(1*labels,predictions,1);
%         
%     catch
%         AUC_test_over(i) = nan;
%     end
%     
%     
% end
































% 
% 
% 
% 
% %% ACCURACY ONLY
% 
% 
% for i = 1:7
% %GLOBAL HL TEST %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %under
% keep = find(~isnan(preds_test_under_base(:,i)))
% try
% HL_under_base_g(i) = HosmerLemeshowTest(preds_test_under_base(keep,i), yc_test(keep,i) < lower_bound_therapeutic)
% catch
%  HL_under_base_g(i) = nan   
% end
% 
% try
% HL_under_g(i) = HosmerLemeshowTest(preds_test_under(keep,i), yc_test(keep,i) < lower_bound_therapeutic)
% catch
%    HL_under_base_g(i) =nan 
% end
% %over
% keep = find(~isnan(preds_test_over_base(:,i)))
% try
% HL_over_base_g(i) = HosmerLemeshowTest(preds_test_over_base(keep,i), yc_test(keep,i) > upper_bound_therapeutic)
% HL_over_g(i) = HosmerLemeshowTest(preds_test_over(keep,i), yc_test(keep,i) > upper_bound_therapeutic)
% catch
%     HL_over_base_g(i) = nan
%     HL_over_g(i) = nan
% end
% 
% %GLOBAL RCS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %under
% ch_ind = find(...
%         (preds_test_under(:,i) > 0.5 & ...
%          preds_test_under_base(:,i) <= 0.5) | ...
%         (preds_test_under(:,i) <= 0.5 &...
%          preds_test_under_base(:,i) > 0.5));
%      try
% RCS_under_g(i) = HosmerLemeshowTest(preds_test_under(ch_ind,i),  yc_test(:,i) < lower_bound_therapeutic);
%      catch
%          RCS_under_g(i) = nan
%      end
% %over
% ch_ind = find(...
%         (preds_test_over(:,i) > 0.5 & ...
%          preds_test_over_base(:,i) <= 0.5) | ...
%         (preds_test_over(:,i) <= 0.5 &...
%          preds_test_over_base(:,i) > 0.5));
% try
%      RCS_over_g(i) = HosmerLemeshowTest(preds_test_over(ch_ind,i), yc_test(:,i) > upper_bound_therapeutic)
%      catch
%          RCS_under_g(i) = nan
%      end
%         
% %GLOBAL NRI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %under
% p_went_up = (preds_test_under(:,i) > 0.5 & ...
%                preds_test_under_base(:,i) <= 0.5);
% 
% p_went_down = (preds_test_under(:,i) <= 0.5 &...
%                preds_test_under_base(:,i) > 0.5); 
% 
% p_up_given_pos = mean(p_went_up & (yc_test(:,i) < lower_bound_therapeutic) == 1);
% 
% p_down_given_pos = mean(p_went_down & (yc_test(:,i) < lower_bound_therapeutic) == 1); 
% 
% p_up_given_neg = mean(p_went_up & (yc_test(:,i) < lower_bound_therapeutic) == 0);
% 
% p_down_given_neg = mean(p_went_down & (yc_test(:,i) < lower_bound_therapeutic) == 0);
% 
% NRI_under_g(i) = ...
%     (p_up_given_pos - p_down_given_pos) -...
%     (p_up_given_neg - p_down_given_neg); 
% 
% 
% %over
% p_went_up = (preds_test_over(:,i) > 0.5 & ...
%                preds_test_over_base(:,i) <= 0.5);
% 
% p_went_down = (preds_test_over(:,i) <= 0.5 &...
%                preds_test_over_base(:,i) > 0.5); 
% 
% p_up_given_pos = mean(p_went_up & (yc_test(:,i) > upper_bound_therapeutic) == 1);
% 
% p_down_given_pos = mean(p_went_down & (yc_test(:,i) > upper_bound_therapeutic) == 1); 
% 
% p_up_given_neg = mean(p_went_up & (yc_test(:,i) > upper_bound_therapeutic) == 0);
% 
% p_down_given_neg = mean(p_went_down & (yc_test(:,i) > upper_bound_therapeutic) == 0);
% 
% NRI_over_g(i) = ...
%     (p_up_given_pos - p_down_given_pos) -...
%     (p_up_given_neg - p_down_given_neg);
% 
% 
% %GLOBAL IDI %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %under
% pos_ind = (yc_test(:,i) < lower_bound_therapeutic) == 1; 
% neg_ind = (yc_test(:,i) < lower_bound_therapeutic) == 0;
% 
% p_positives_ind = preds_test_under(pos_ind,i);
% p_negatives_ind =preds_test_under(neg_ind,i);
% 
% p_positives_pop  = preds_test_under_base(pos_ind,i);
% p_negatives_pop = preds_test_under_base(neg_ind,i);
% 
% IDI_under_g(i) = ...
% (nanmean(p_positives_ind) - nanmean(p_negatives_ind)) -...
% (nanmean(p_positives_pop) - nanmean(p_negatives_pop)); 
% 
% 
% %over
% pos_ind = (yc_test(:,i) > upper_bound_therapeutic) == 1; 
% neg_ind = (yc_test(:,i) > upper_bound_therapeutic) == 0;
% 
% p_positives_ind = preds_test_over(pos_ind,i);
% p_negatives_ind =preds_test_over(neg_ind,i);
% 
% p_positives_pop  = preds_test_over_base(pos_ind,i);
% p_negatives_pop = preds_test_over_base(neg_ind,i);
% 
% IDI_over_g(i) = ...
% (nanmean(p_positives_ind) - nanmean(p_negatives_ind)) -...
% (nanmean(p_positives_pop) - nanmean(p_negatives_pop)); 
% 
% end
% 
% 
% 
% 
% %% FIND THE AUC FOR EACH CLASS.
% %Each datapoint has a true label and an estiamte.
% eval(['save all_' num2str(rep_r) '_grow_sub_population2'])





