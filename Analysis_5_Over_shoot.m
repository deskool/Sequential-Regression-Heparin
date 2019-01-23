%Cascade_Logistic_Regression_Optimistic_ending
%% NOW FOR ERROR CORRECTION
%Take a patient and predict his/her ther state.
%record the error.
clear all;
load populationvShamim;
load newdataint;
load data;
load X_static;
load final_state;

%Generate the matricies for each stage.
clear res
clear AUC
clear AUC_adjs
test_perc = 0.1;        %for each fold...
num_folds = 10;
missing_thresh = 0.1; %how much data should be missing before you throw the column out.
rep_r = 500;
rep_growth = 2;

%For each of the 8 stages in the dosing.
res = Generate_combined_data(newdataint,X_static,data, missing_thresh );


res_under_pred = zeros(length(res(1).X),length(res));
res_over_pred = zeros(length(res(1).X),length(res));

res_under_test = zeros(length(res(1).X),length(res));
res_over_test = zeros(length(res(1).X),length(res));

%    keep_me = final_state > 60;
%    for i = 1:8
%        res(i).X = res(i).X(keep_me,:);
%        res(i).Y = res(i).Y(keep_me);
%    end

%% OverSHOOT!
for k = 1:length(res(1).X) %num_folds
    
    %generate the random testing and training sets -  0.3 secs
    for i = 1:length(res)
        
        X_train = res(i).X;
        Y_train = res(i).Y;
        
        X_test = X_train(k,:);
        Y_test = Y_train(k);
        
        X_train(k,:) = [];
        Y_train(k) = [];
        
        res(i).X_train = X_train;
        res(i).Y_train = Y_train;
        
        res(i).X_test = X_test;
        res(i).Y_test = Y_test;
        
        
        %Y_under=find(res(i).Y<60)
        %Y_over=find(res(i).Y>100);
        %Y_ther=find(res(i).Y>=60 & res(i).Y <=100);
        
        %Y_test=res(i).Y([Y_under(1:round(test_perc*length(Y_under))); Y_over(1:round(test_perc*length(Y_over)));Y_ther(1:round(test_perc*length(Y_ther)));]);
        %X_test=res(i).X([Y_under(1:round(test_perc*length(Y_under))); Y_over(1:round(test_perc*length(Y_over)));Y_ther(1:round(test_perc*length(Y_ther)));],:);
        
        %Y_train = res(i).Y([Y_under(round(test_perc*length(Y_under))+1:length(Y_under)); Y_over(round(test_perc*length(Y_over))+1:length(Y_over)); Y_ther(round(test_perc*length(Y_ther))+1:length(Y_ther))]);
        %X_train = res(i).X([Y_under(round(test_perc*length(Y_under))+1:length(Y_under)); Y_over(round(test_perc*length(Y_over))+1:length(Y_over)); Y_ther(round(test_perc*length(Y_ther))+1:length(Y_ther))],:);
        
        %X_train = res(i).X([1:round(test_perc*length(res(i).X))],:);
        %Y_train = res(i).Y([1:round(test_perc*length(res(i).Y))]);
        
        %test_perc*k
        
        %X_test = res(i).X([round(test_perc*length(res(i).X)):length(res(i).X)],:);
        %Y_test = res(i).Y([round(test_perc*length(res(i).Y)):length(res(i).Y)]);
        
        %res(i).X_train = X_train;
        %res(i).Y_train = Y_train;
        
        %res(i).X_test = X_test;
        %res(i).Y_test = Y_test;
    end
    
    
    %% UNDER
    %For each patient
    rep = rep_r;
    
    %% for each aPTT Stage
    for i= 1:length(res)
        %% Construct the training set
        if(i == 1)
            X_train = [res(1).X_train; res(2).X_train; res(3).X_train; res(4).X_train; res(5).X_train;res(6).X_train;res(7).X_train];
            Y_train = [res(1).Y_train; res(2).Y_train; res(3).Y_train; res(4).Y_train; res(5).Y_train;res(6).Y_train;res(7).Y_train]...
                >100; %<----------- IMPORTANT!
        elseif(i > 1)
            X_train = [X_train; repmat(res(i-1).X_test,rep,1)];
            Y_train = [Y_train; (repmat(res(i-1).Y_test,rep,1)) >100]; %<----------- IMPORTANT!
            
            if i < 3
                rep = rep*rep_growth;
            end
        end
        
        %% Extract the testing Set
        X_test = res(i).X_test;
        Y_test = res(i).Y_test >100;
        
        %% Do a regular regression with all the features if this isn't a nan.
        if(sum(isnan(X_test)) == 0)
            
            %keepers = find(not(isnan(res(i).X_test)));
            mdl = fitglm(X_train,Y_train,'linear','Distribution','binomial');
            pvals{i} = mdl.Coefficients.pValue;
            %mdl = fitglm(X_train(:,keepers),Y_train,'linear','Distribution','binomial');
            %preds_train{i,j}= predict(mdl{i,j},X_train);
            %yc_train{i,j} = num2str(Y_train);
            %[~,~,~,AUC_train{i,j}] = perfcurve(yc_train{i,j},preds_train{i,j},'1');
            
            yc_test(i) = Y_test;
            
            %regular predictions
            preds_test(i) = predict(mdl,X_test);
            %[~,~,~,AUC_test{i,j}] = perfcurve(yc_test{i,j},preds_test{i,j},'1');
            %error_test(:,i) = 1 - preds_test{i,j}
            
            %If this has trash
        else
            yc_test(i) =  Y_test;
            preds_test(i) = nan;
            pvals{i} = nan;
        end
        
    end
    res_over_pred(k,:) = preds_test;
    res_over_test(k,:) = yc_test;
    res_over_pvals(k,:) = pvals;
    k
end

save res_over_pvals res_over_pvals
save res_over_pred res_over_pred;
save res_over_test res_over_test;

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

eval(['save categorical_rep_' num2str(rep) '_grow' num2str(rep_growth) '_full_population'])














