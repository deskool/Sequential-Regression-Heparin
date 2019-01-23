clear all;


load res_under_test
load res_under_pred
load res_over_test
load res_over_pred


%at this point I have the probabilities on the ther, sub and supra.
%     res_over_pred(1550:end,:) = []
%     res_over_test(1550:end,:) = [];
%     res_under_pred(1550:end,:) = [];
%     res_under_test(1550:end,:) = [];
    
    %% INFER THE TERAPEUTIC STATE
    
    %generate the therapeutic predictive probabilities.
    res_ther_pred = 1 - (res_under_pred + res_over_pred);
    logical_ther = (res_under_test == 0 & res_over_test == 0);
    res_ther_test = logical_ther;
    
    %% FIND THE AUC FOR EACH CLASS.
       
    %Each datapoint has a true label and an estiamte.  
    
%Over
    for i = 1:7
        try
            labels = res_over_test(:,i)';
            predictions = res_over_pred(:,i);
            [~,~,~,AUC_test_over(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_over(i) = nan;
        end
    end
    
%Under
    for i = 1:7
        try
            [~,~,~,AUC_test_under(i)] = perfcurve(res_under_test(:,i)',res_under_pred(:,i),1);
        catch
            AUC_test_under(i) = nan;
        end
    end
    
%Therapeutic
    for i = 1:7
        try
            [~,~,~,AUC_test_ther(i)] = perfcurve(double(res_ther_test(:,i)'),res_ther_pred(:,i),1);
        catch
            AUC_test_ther(i) = nan;
        end
    end
    
    %Plot the AUCs of the Classifiers over time.
    plot(AUC_test_under)
    hold on;
    plot(AUC_test_ther)
    hold on;
    plot(AUC_test_over)
    legend('under','ther','over')
    
    plot(1:7,.33*ones(1,7),'black--')
    
    
save categorical_rep_500_grow2_full_population
    
    %Figure 1: A comparison of the classification AUCs for our apporach.
    % errorbar(nanmean(AUC_test_over),nanstd(AUC_test_over),'r','LineWidth',2)
    % xlabel('Stage - Dose Adjustment')
    % ylabel('AUC')
    %
    % hold on;
    %
    % errorbar(nanmean(AUC_test_under),nanstd(AUC_test_under),'y','LineWidth',2)
    % xlabel('Stage - Dose Adjustment')
    % ylabel('AUC')
    %
    % hold on;
    
    % errorbar(nanmean(AUC_test_ther),nanstd(AUC_test_ther),'g','LineWidth',2)
    % xlabel('Stage - Dose Adjustment')
    % ylabel('AUC')
    %
    % legend('Overshoot','Undershoot','Therapeutic')
    % savefig('Figure 1 sub')
    % xlim([1 5])
    % ylim([0.5 1])
    
    
    %% NOW COMPARE THIS AGAINST THE DOCTORS... ASSUMING THEY WANT FOLKS TO BE THER.
    %but lets only inspect the people that eventually became therapeutic.
    
    %ind_final_ther = 1:find(strcmp(res_ther(k).yc_test(8,:),'1'));
    for i = 1:7
        try
            the_truth = cellfun(@str2num,{res_ther_test{:,i}});
            the_truth = res_ther_test(:,i);
            [xr,yr,~,AUC, jpnt] = perfcurve(res_ther_test(:,i),res_ther_pred(:,i),'1');
            %plot(xr,yr)
            the_preds = res_ther_pred(:,i)>jpnt(1);
            cp = classperf(the_truth,the_preds);
            correct_rate(i) = cp.CorrectRate;
            sensitivity(i) = cp.Sensitivity;
            specificity(i) = cp.Specificity;
        catch
            correct_rate(i) = nan;
        end
    end
    

    for k = 1:10
        %ind_final_ther = find(strcmp(res_ther(k).yc_test(8,:),'1'));
        for i = 1:8
            try
                the_truth = cellfun(@str2num,{res_ther(k).yc_test{i,:}});
                the_preds = ones(1,length(res_ther(k).yc_test));
                cp = classperf(the_truth,the_preds);
                correct_rate_doc(k,i) = cp.CorrectRate;
                sensitivity_doc(k,i) = cp.Sensitivity;
                specificity_doc(k,i) = cp.Specificity;
                
            catch
                corr_rate_doc(k,i) = nan;
            end
        end
    end
    
    errorbar(nanmean(correct_rate),nanstd(correct_rate),'b')
    hold on;
    errorbar(nanmean(correct_rate_doc),nanstd(correct_rate_doc),'r')
    
    %Figure 2: a comparison of our methods predictive performance compared
    %against the clincians, assuming that the goal was to make patients therapeutic
    xlabel('Stage - Dose Adjustment');
    ylabel('% Correct (jpnt classification)');
    legend('Our Method','Physician')
    
    %% CONFUSION MATRIX
    for k = 1:10
        
        for i = 1:8
            [a,p]=max([res_under(k).pred_test(i,:); res_ther(k).pred_test(i,:); res_over(k).pred_test(i,:)]);
            [a p2] = max([strcmp(res_under(k).yc_test(i,:),'1'); strcmp(res_ther(k).yc_test(i,:),'1'); strcmp(res_over(k).yc_test(i,:),'1')]);
            [C(:,:,i), order]= confusionmat(p2,p);
        end
        u=squeeze(C(1,:,:))';
        o=squeeze(C(2,:,:))';
        t=squeeze(C(3,:,:))';
        u_class(k,:) = u(:,1)./sum(u,2);
        t_class(k,:) =  t(:,1)./sum(t,2);
        o_class(k,:) =  o(:,1)./sum(o,2);
        
    end
    
    %Figure 3 - Classification % of total cases.
    plot(mean(u_class),'y')
    hold on;
    plot(mean(t_class),'g')
    hold on;
    plot(mean(o_class),'r')
    
    
    %% NOW COMPARE THIS AGAINST THE DOCTORS... LOOKING ONLY AT THE OVER AND THER.
    %but lets only inspect the people that eventually became therapeutic.
    
    clear AUC_test_doc;
    clear AUC_test_ther;
    for k = 1:10
        ind_final_ther = find(strcmp(res_under(k).yc_test(8,:),'0'));
        for i = 1:8
            try
                the_truth = cellfun(@str2num,{res_ther(k).yc_test{i,ind_final_ther}});
                the_preds = res_ther(k).pred_test(i,ind_final_ther)>0.5;
                cp = classperf(the_truth,the_preds);
                correct_rate(k,i) = cp.CorrectRate;
            catch
                correct_rate(k,i) = nan;
            end
        end
    end
    
    for k = 1:10
        %ind_final_ther = find(strcmp(res_ther(k).yc_test(8,:),'1'));
        for i = 1:8
            try
                the_truth = cellfun(@str2num,{res_ther(k).yc_test{i,ind_final_ther}});
                the_preds = ones(1,length(res_ther(k).yc_test(i,ind_final_ther)));
                cp = classperf(the_truth,the_preds);
                correct_rate_doc(k,i) = cp.CorrectRate;
            catch
            end
        end
    end
    
    errorbar(mean(correct_rate),std(correct_rate))
    hold on;
    
    errorbar(mean(correct_rate_doc),std(correct_rate_doc))
    
    