%Cascade_Logistic_Regression_Optimistic_ending
%% NOW FOR ERROR CORRECTION
%Take a patient and predict his/her ther state.
%record the error.
clear all;
load populationvShamim;
load newdataint;
load data;
[unique_stays which_patients] = unique(populationvShamim.ICUSTAY_ID);
X_static = populationvShamim(which_patients,:);

%generate the matricies for each stage.
clear res
clear AUC
clear AUC_adjs
test_perc = 0.5;        %for each fold...
num_folds = 10;
missing_thresh = 0.31; %how much data should be missing before you throw the column out.
rep = 1000;
rep_growth = 1.25 ;
for k = 1:10%num_folds
    
    %For each of the 8 stages in the dosing.
    res = Generate_combined_data(newdataint,X_static,data, missing_thresh );
    
    keep_me = res(8).Y > 60;
    for i = 1:8
        res(i).X = res(i).X(keep_me);
        res(i).Y = res(i).Y(keep_me);
    end
    
    %Generate random incidies for this fold.
    fold_shuffle = randperm(length(res(1).Y))';
    for i = 1:8
        res(i).Y = res(i).Y(fold_shuffle);
        res(i).X = res(i).X(fold_shuffle,:);
    end
       
    %generate the random testing and training sets.
    for i = 1:8        
        %Y_under=find(res(i).Y<60)
        %Y_over=find(res(i).Y>100);
        %Y_ther=find(res(i).Y>=60 & res(i).Y <=100);
        
        %Y_test=res(i).Y([Y_under(1:round(test_perc*length(Y_under))); Y_over(1:round(test_perc*length(Y_over)));Y_ther(1:round(test_perc*length(Y_ther)));]);
        %X_test=res(i).X([Y_under(1:round(test_perc*length(Y_under))); Y_over(1:round(test_perc*length(Y_over)));Y_ther(1:round(test_perc*length(Y_ther)));],:);
        
        %Y_train = res(i).Y([Y_under(round(test_perc*length(Y_under))+1:length(Y_under)); Y_over(round(test_perc*length(Y_over))+1:length(Y_over)); Y_ther(round(test_perc*length(Y_ther))+1:length(Y_ther))]);
        %X_train = res(i).X([Y_under(round(test_perc*length(Y_under))+1:length(Y_under)); Y_over(round(test_perc*length(Y_over))+1:length(Y_over)); Y_ther(round(test_perc*length(Y_ther))+1:length(Y_ther))],:);
        
        X_train = res(i).X([1:round(test_perc*length(res(i).X))],:);
        Y_train = res(i).Y([1:round(test_perc*length(res(i).Y))]);

        X_test = res(i).X([round(test_perc*length(res(i).X)):length(res(i).X)],:);
        Y_test = res(i).Y([round(test_perc*length(res(i).Y)):length(res(i).Y)]);
        
        res(i).X_train = X_train;
        res(i).Y_train = Y_train;
        
        res(i).X_test = X_test;
        res(i).Y_test = Y_test;
    end
    
    %% UNDER
    %For each patient
    for j= 1:length(res(i).X_test)
      
      %for each stage.
        for i= 1:8
            %For the datasets that were extracted, we want. training and testing sets
            
            if(i > 1)
                X_train = [X_train; repmat(res(i-1).X_test(j,:),rep,1)];
                Y_train = [Y_train; (repmat(res(i-1).Y_test(j),rep,1)) < 60]; %<----------- IMPORTANT!
                rep = rep*rep_growth;
                %correction = -1*mean(error
                
            else
                 X_train = [res(1).X_train; res(2).X_train; res(3).X_train; res(4).X_train; res(5).X_train;res(6).X_train;res(7).X_train;res(8).X_train];
                 Y_train = [res(1).Y_train; res(2).Y_train; res(3).Y_train; res(4).Y_train; res(5).Y_train;res(6).Y_train;res(7).Y_train;res(8).Y_train]...
                           < 60; %<----------- IMPORTANT!
                 %correction = 0;
            end
            
            %Do a regular regression with all the features.
            mdl = fitglm(X_train,Y_train,'linear','Distribution','binomial');
            %preds_train{i,j}= predict(mdl{i,j},X_train);
            %yc_train{i,j} = num2str(Y_train);
            %[~,~,~,AUC_train{i,j}] = perfcurve(yc_train{i,j},preds_train{i,j},'1');
            
            X_test = res(i).X_test(j,:);
            Y_test = res(i).Y_test(j) < 60;
            yc_test{i,j} = num2str(Y_test);
            
            %regular predictions
            preds_test(i,j) = predict(mdl,X_test);
            pvalue(i,j,:) = mdl.Coefficients.pValue; 
            %[~,~,~,AUC_test{i,j}] = perfcurve(yc_test{i,j},preds_test{i,j},'1');
            %error_test(:,i) = 1 - preds_test{i,j}
            
            j
        end         
    end   
    
    res_under(k).pvalue = pvalue;
    res_under(k).pred_test = preds_test;
    res_under(k).yc_test = yc_test;
    save res_under_subset res_under;
   
 
 
%% OVER   
%For each stage
    for j= 1:length(res(i).X_test)
      
      %for each stage.
        for i= 1:8
            %For the datasets that were extracted, we want. training and testing sets
            
            if(i > 1)
                X_train = [X_train; repmat(res(i-1).X_test(j,:),rep,1)];
                Y_train = [Y_train; (repmat(res(i-1).Y_test(j),rep,1)) > 100]; %<----------- IMPORTANT!
                rep = rep*rep_growth;
                %correction = -1*mean(error
                
            else
                 X_train = [res(1).X_train; res(2).X_train; res(3).X_train; res(4).X_train; res(5).X_train;res(6).X_train;res(7).X_train;res(8).X_train];
                 Y_train = [res(1).Y_train; res(2).Y_train; res(3).Y_train; res(4).Y_train; res(5).Y_train;res(6).Y_train;res(7).Y_train;res(8).Y_train]...
                           > 100; %<----------- IMPORTANT!
                 %correction = 0;
            end
            
            %Do a regular regression with all the features.
            mdl = fitglm(X_train,Y_train,'linear','Distribution','binomial');
            %preds_train{i,j}= predict(mdl{i,j},X_train);
            %yc_train{i,j} = num2str(Y_train);
            %[~,~,~,AUC_train{i,j}] = perfcurve(yc_train{i,j},preds_train{i,j},'1');
            
            X_test = res(i).X_test(j,:);
            Y_test = res(i).Y_test(j) > 100;
            yc_test{i,j} = num2str(Y_test);
            
            
            
            %regular predictions
            preds_test(i,j) = predict(mdl,X_test);
            pvalue(i,j,:) = mdl.Coefficients.pValue; 
            %[~,~,~,AUC_test{i,j}] = perfcurve(yc_test{i,j},preds_test{i,j},'1');
            %error_test(:,i) = 1 - preds_test{i,j}
            
            j
        end              
    end   
    
    res_over(k).pvalue = pvalue;
    res_over(k).pred_test = preds_test;
    res_over(k).yc_test = yc_test;
    save res_over_subset res_over;
   

end 


%% INFER THE TERAPEUTIC STATE
%generate the therapeutic predictive probabilities.
for k = 1:10
res_ther(k).pred_test = 1 - (res_under(k).pred_test + res_over(k).pred_test);
end

%generate the outcome classes.
for k = 1:10
    logical_ther = strcmp(res_under(k).yc_test,'0') & strcmp(res_over(k).yc_test,'0');
    res_ther(k).yc_test = cellfun(@num2str, num2cell(logical_ther), 'UniformOutput', false);  
end

save res_ther_subset res_ther;


%% FIND THE AUC FOR EACH CLASS.
for k = 1:10
    for i = 1:8
        try
        [~,~,~,AUC_test_over(k,i)] = perfcurve({res_over(k).yc_test{i,:}},res_over(k).pred_test(i,:),'1');
        catch
            AUC_test_over(k,i) = nan;
        end
        end
end

for k = 1:10
    for i = 1:8
        try
        [~,~,~,AUC_test_under(k,i)] = perfcurve({res_under(k).yc_test{i,:}},res_under(k).pred_test(i,:),'1');
        catch
            AUC_test_over(k,i) = nan;
        end
    end
end

for k = 1:10
    for i = 1:8
        try
        [~,~,~,AUC_test_ther(k,i)] = perfcurve({res_ther(k).yc_test{i,:}},res_ther(k).pred_test(i,:),'1');
         catch
            AUC_test_over(k,i) = nan;
        end
        
        end
end


%Figure 1: A comparison of the classification AUCs for our apporach.
errorbar(nanmean(AUC_test_over),nanstd(AUC_test_over),'r','LineWidth',2)
xlabel('Stage - Dose Adjustment')
ylabel('AUC')

hold on;

errorbar(nanmean(AUC_test_under),nanstd(AUC_test_under),'y','LineWidth',2)
xlabel('Stage - Dose Adjustment')
ylabel('AUC')

hold on;

errorbar(nanmean(AUC_test_ther),nanstd(AUC_test_ther),'g','LineWidth',2)
xlabel('Stage - Dose Adjustment')
ylabel('AUC')

legend('Overshoot','Undershoot','Therapeutic')
savefig('Figure 1 sub')
xlim([1 3])
ylim([0.5 1])


%% NOW COMPARE THIS AGAINST THE DOCTORS... ASSUMING THEY WANT FOLKS TO BE THER.
%but lets only inspect the people that eventually became therapeutic.

clear AUC_test_doc;
clear AUC_test_ther;
for k = 1:10      
    %ind_final_ther = 1:find(strcmp(res_ther(k).yc_test(8,:),'1'));  
    for i = 1:8
        try            
        the_truth = cellfun(@str2num,{res_ther(k).yc_test{i,:}});
        [xr,yr,~,AUC, jpnt] = perfcurve({res_ther(k).yc_test{i,:}},res_ther(k).pred_test(i,:),'1');
        %plot(xr,yr)
        the_preds = res_ther(k).pred_test(i,:)>0.4;%%jpnt(1);
        cp = classperf(the_truth,the_preds);
        correct_rate(k,i) = cp.CorrectRate; 
        sensitivity(k,i) = cp.Sensitivity;
        specificity(k,i) = cp.Specificity;
        catch
            correct_rate(k,i) = nan;
        end   
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
            correct_rate_doc(k,i) = nan;
        end 
    end  
end

errorbar(nanmean(correct_rate),nanstd(correct_rate),'b')
hold on;
errorbar(nanmean(correct_rate_doc),nanstd(correct_rate_doc),'r')

%Figure 2: a comparison of our methods predictive performance compared 
%against the clincians, assuming that the goal was to make patients therapeutic
xlabel('Stage - Dose Adjustment');
ylabel('% Correct');
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











