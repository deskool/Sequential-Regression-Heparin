%TITLE:     Personalized Medication Dosing via Squential Regression: 
%           A Focus on Unfractionated Heparin
%AUTHOR:    Mohammad Mahdi Ghassemi, PhD Candidate, MIT
%           ghassemi@mit.edu
%OVERVIEW:  This script implements a sequential dosing algorithm that
%           trains a personalized model using a combination of data from
%           a population of existing patients, and an individual data
%           stream.
%LICENCE:   https://opensource.org/licenses/MIT
%%
clear all;
load populationvShamim;load newdataint;
load data;load X_static;load final_state;

%% PARAMETERS OF THE ALGORITHM

% This controls the weight of an individual data point in the 
% regression cost funtion relative to an indivudal point from the population. 
rep_r =200;   

%what subset of features to use for the baseline model.
subset_of_features = 1:20; 

% This controls the increase in the strength of 'rep_r', across dosing
% intervals. 1 means that the relative weight is constant.
rep_growth = 1;

%This defines the 'therapeutic range'.
lower_bound_therapeutic = 60; upper_bound_therapeutic = 100;

%how much data should be missing before you throw the column out.
missing_thresh = 0.1; 

%Generate the matricies for each stage.
clear res; clear AUC; clear AUC_adjs
       

%% Remove features missing lots of data.
%For each of the 8 stages in the dosing.
res = Generate_combined_data(newdataint,X_static,data, missing_thresh );
res_under_pred = zeros(length(res(1).X),length(res));
res_over_pred = zeros(length(res(1).X),length(res));
res_under_test = zeros(length(res(1).X),length(res));
res_over_test = zeros(length(res(1).X),length(res));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UNCOMMENT THIS TO SEE THE ALGORITHM FOR PATINTS WHO'S FINAL STATE WAS NOT SUBTHERAPEUTIC.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  for i = 1:length(res)
%      keep_me = final_state > 60;
%      res(i).X = res(i).X(keep_me,:);
%      res(i).Y = res(i).Y(keep_me);
%  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UNCOMMENT THIS IF YOU JUST WANT TO USE DOSE/WEIGHT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%for i = 1:length(res)
%    res(i).X = res(i).X(:,2)
%end

%% TRANDFORM THE DATA SO IT CAN BE PROCESSED IN PARALLEL.
Y = [res.Y];
for i = 1:7
    X(:,:,i) = [res(i).X];
end


%% GENERATE A POPULATION, AND INDIVIDUAL MODEL FOR EACH PATIENT
for k = 1:length(X)
    
    % reset the growth-rate, and training data.
    rep = rep_r; X_train = X; Y_train = Y; 
    
    %% CREATE THE TRAINING AND TESTING SET FOR THIS PATIENT.
    %take the kth patient as 'testing' patient. 
    X_test = squeeze(X_train(k,:,:));
    if size(X_test,2) == 1
        X_test = X_test'
    end
    Y_test = Y_train(k,:);
    
    % remove the kth patient from the training set, everyone else in the data
    % is going to simulate the 'population' of known patients.
    X_train(k,:,:) = [];
    Y_train(k,:) = [];
    
    % Patients in the population set may have more than one dose-adjustment
    % We are treating each recorded dose-response relationships as 
    % independent, even if they come from the same patient. 
    % To do this, we will concatenate along the 3rd dimnetion
    temp = [];
    for j = 1:size(X_train,3)
        
        temp = [temp; X_train(:,:,j)];
    end

    %% Train the "population model" for this patient.
    % base_X and base_Y represent the 'population model' for patient k.
    base_X = temp;
    base_Y = Y_train(:);
    
    % Using base_X and base_Y, we can train the two logistic regresssion
    % models, which make up the 'population' model.

    mdl_under_base = fitglm(base_X(:,subset_of_features),base_Y < lower_bound_therapeutic,'linear','Distribution','binomial');
    mdl_over_base = fitglm(base_X(:,subset_of_features),base_Y > upper_bound_therapeutic,'linear','Distribution','binomial');
    
    %%Neural Network Baseline:
    for i = 20%2:2:20
        for j = 20%2:2:20
            keep = ~(sum(isnan(base_X')) > 0)
            X_nn = base_X(keep,subset_of_features)';
            Y_nn = double(([base_Y < lower_bound_therapeutic, ...
                     (base_Y >= lower_bound_therapeutic &...
                     base_Y <= upper_bound_therapeutic),...
                     base_Y > upper_bound_therapeutic]));
            Y_nn = Y_nn(keep,:)
            net.trainFcn = 'trainbr'; %baysian regularized backpropogation.     
            net = patternnet([i,j]); [net,tr] = train(net,X_nn,Y_nn')
            preds{i,j} = sim(net,X_nn);
        end
    end
    for i = 2:2:20
        for j = 2:2:20
           this_perf = preds{i,j};
           VUS(i,j) = perfSurface(Y_nn,this_perf'); 
        end
    end
    
    
    %%  Save performance of population model.
    
    % p-values
    pvals_under_base{k} = mdl_under_base.Coefficients.pValue;
    pvals_over_base{k} = mdl_over_base.Coefficients.pValue;

    % Pseudo R-squared
    Rsq_under_base(k) = mdl_under_base.Rsquared.AdjGeneralized;
    Rsq_over_base(k) = mdl_over_base.Rsquared.AdjGeneralized;

    % BIC
    [~,bic_under_base(k)] = aicbic(mdl_under_base.LogLikelihood,size(base_X(:,subset_of_features),2)+1,length(base_Y));
    [~,bic_over_base(k)] = aicbic(mdl_over_base.LogLikelihood,size(base_X(:,subset_of_features),2)+1,length(base_Y));

    % HL Test
    keep = find(~(sum(isnan([base_X,base_Y])') > 0));
    HL_under_base(k) = HosmerLemeshowTest(mdl_under_base.predict(base_X(keep,subset_of_features)),base_Y(keep),10);
    HL_over_base(k) =  HosmerLemeshowTest(mdl_over_base.predict(base_X(keep,subset_of_features)),base_Y(keep),10);

    
    %% For each Dose Adjustment, we want to see how well we predict the next aPTT
    parfor i= 1:size(X,3)
        
        %% Construct the training set for the 'individual model'
        % this is simply the population level data, 
        % plus all the available information from prior dose-response
        % for the individual. The importance of the individual data
        % points, relative to the population is controlled by 'rep'.
        stage_add_X = repmat(X_test(:,1:i-1)',rep,1);
        stage_add_Y = repmat(Y_test(:,1:i-1),rep,1);
        
        X_train_stage = [base_X;stage_add_X];
        Y_train_stage = [base_Y;stage_add_Y(:)];
        
        %% Extract the testing Set
        % this is simply the features for patient 'k' and their response
        % at dose adjustment 'i'.
        X_test_stage = X_test(:,i)';
        Y_test_stage = Y_test(i);
             
        %% Remove Invalid features, and samples. 
        % Our method can be used such that only the available features,
        % per patient, are used.
        
        %Throw away columns with missing data for the test..
        has_features = find(~isnan(X_test_stage));
        X_train_stage = X_train_stage(:,has_features);
        X_test_stage = X_test_stage(has_features)
        
        %throw away rows with missing data for the train.
        keep = find(~(sum(isnan([X_train_stage,Y_train_stage])') > 0));
        X_train_stage = X_train_stage(keep,:);
        Y_train_stage = Y_train_stage(keep,:);
        
        
        %% Do an ordinary linear regression with all the features
        % As shown in the Online Data Supplement, we can also use a
        % standard linear regression to estimate the dose-response
        % relationship for the individual patient.
        model = fitglm(X_train_stage,Y_train_stage);
        
        % save the predictions, and other evaluation information
        % for patient 'k' at dose interval 'i'.
        preds_test(k,i) = predict(model,X_test_stage);  % predicted values.
        yc_test(k,i) = Y_test_stage;                    % actual values.
        pvals{k,i} = model.Coefficients.pValue;         % p-vals from the linear model.
        
        %% Train the 'indivudal model' 
        % We will train two logistic regression models
        
        % 1. for the overshoot 
        mdl_over = fitglm(X_train_stage,Y_train_stage > upper_bound_therapeutic,'linear','Distribution','binomial');
        
        % 2. for the undershoot
        mdl_under = fitglm(X_train_stage,Y_train_stage < lower_bound_therapeutic,'linear','Distribution','binomial');
         
        %% Save 'individual model' performance.
        %get the predictions
        preds_test_under(k,i) = predict(mdl_under,X_test_stage);
        preds_test_over(k,i) = predict(mdl_over,X_test_stage);
        preds_test_ther(k,i) = 1 - (preds_test_under(k,i) + preds_test_over(k,i));
        
        %get the predictions of the baseline 'population model'
        %but only if we don't have any missing features.
        if size(has_features,2) == size(X_test(:,i)',2)      
            preds_test_under_base(k,i) = predict(mdl_under_base,X_test_stage(:,subset_of_features));
            preds_test_over_base(k,i) = predict(mdl_over_base,X_test_stage(:,subset_of_features));
            preds_test_ther_base(k,i) = 1 - (preds_test_under(k,i) + preds_test_over(k,i));
        else
            preds_test_under_base(k,i) = nan;
            preds_test_over_base(k,i) = nan;
            preds_test_ther_base(k,i) = nan;                        
        end
        
        %Get the ground truth
        yc_test_under(k,i) = Y_test_stage < lower_bound_therapeutic;
        yc_test_over(k,i) = Y_test_stage > upper_bound_therapeutic;
        yc_test_ther(k,i) = not(yc_test_under(k,i) | yc_test_over(k,i));
        
        % p_values for the features
        pvals_under{k,i} = mdl_under.Coefficients.pValue;
        pvals_over{k,i} = mdl_over.Coefficients.pValue;
        
        % Pseudo R-squared
        Rsq_under(k,i) = mdl_under.Rsquared.AdjGeneralized;
        Rsq_over(k,i) = mdl_over.Rsquared.AdjGeneralized;
             
        % BIC
        [~,bic_under(k,i)] = aicbic(mdl_under.LogLikelihood,size(X_train_stage,2)+1,length(Y_train_stage));
        [~,bic_over(k,i)] = aicbic(mdl_over.LogLikelihood,size(X_train_stage,2)+1,length(Y_train_stage));

        % HL Test
        HL_under(k,i) = HosmerLemeshowTest(mdl_under.predict(X_train_stage),Y_train_stage < lower_bound_therapeutic,22);
        HL_over(k,i) =  HosmerLemeshowTest(mdl_over.predict(X_train_stage),Y_train_stage > upper_bound_therapeutic,22);
        
        
        %% Compare the population and individual models.
        % See Cook et al. 2009 for more information on the metrics below.
        % RECLASSIFICATION CALIBRATION STATISTIC.
        %RCS_under(k,i) = RCS(X_train_stage, Y_train_stage < lower_bound_therapeutic, mdl_under, mdl_under_base);
        %RCS_over(k,i) = RCS(X_train_stage, Y_train_stage > upper_bound_therapeutic, mdl_over, mdl_over_base);
        
        % NET RECLASSIFICATION IMPROVEMENT.
        %NRI_under(k,i)  = NRI(X_train_stage,Y_train_stage < lower_bound_therapeutic,mdl_under,mdl_under_base);
        %NRI_over(k,i)  = NRI(X_train_stage,Y_train_stage > upper_bound_therapeutic,mdl_over,mdl_over_base);
        
        % INTEGRATED DISCRIMINATION IMPROVEMENT
        %IDI_under(k,i) = IDI(X_train_stage,Y_train_stage < lower_bound_therapeutic, mdl_under,mdl_under_base);
        %IDI_over(k,i)  = IDI(X_train_stage,Y_train_stage > upper_bound_therapeutic, mdl_over, mdl_over_base);
        
    end
    k
end

%For results from the first experiment.
save(['results_repr_' num2str(rep_r) '_features_' num2str(length(subset_of_features)) '_VUS_del_' num2str(VUS_new - VUS_base)])
%clear all;











