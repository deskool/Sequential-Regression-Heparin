%% START FROM HERE --------------------------------------------------------
%% NOW FOR ERROR CORRECTION
%Take a patient and predict his/her ther state.
%record the error.
clear all;
load populationvShamim;
load newdataint;
load data;
load X_static;
load final_state;

%generate the matricies for each stage.
clear res
clear AUC
clear AUC_adjs
test_perc = 0.001;        %for each fold...
test_perc = 1- test_perc;
num_folds = 3000;
missing_thresh = 0.08; %how much data should be missing before you throw the column out.
rep = 5000;
rep_growth = 1;

%We want to use LOOCV for prediction.
%That is, we are training on everyone but one patient, then we are
%for that patient, running the linear model to predict the aPTT, and
%adjusting for his individual error.
for k = 1:size(newdataint,1)
    
    %For each of the 8 stages in the dosing.
    res = Generate_combined_data(newdataint,X_static,data, missing_thresh);    

    keep_me = final_state > 60;
    for i = 1:8
        res(i).X = res(i).X(keep_me,:);
        res(i).Y = res(i).Y(keep_me);
    end
    
    
    %generate the random testing and training sets.
    for i = 1:8        
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
    end
    
      X_train = [res(1).X_train; res(2).X_train; res(3).X_train; res(4).X_train; res(5).X_train;res(6).X_train;res(7).X_train;res(8).X_train];
      Y_train = [res(1).Y_train; res(2).Y_train; res(3).Y_train; res(4).Y_train; res(5).Y_train;res(6).Y_train;res(7).Y_train;res(8).Y_train];
   
      %regular glm
      mdl = fitglm(X_train,Y_train,'linear','Distribution','normal');            
 
      %lasso glm
      %it's providing the same answers.  
       
      %% FOR EACH STAGE
      clear Y_error
      Y_error = 0;
      for i= 1:8
            %FOR THE FIRST STAGE 
            %TRAIN THE MODEL.
            if i == 1
                 %GET TESTING DATA
                 X_test = res(i).X_test(:,:);
                 Y_test = res(i).Y_test(:);
                
                 %EXTRACT ERROR.
                 preds_test(i,k) = predict(mdl,X_test) + nanmean(Y_error);
                 pred_dr(i,k) = predict(mdl,X_test);
                 Y_error(i) = Y_test - preds_test(i,k);
            end
            
            %For the datasets that were extracted, we want. training and testing sets
            if(i > 1)
                 X_test = res(i).X_test(:,:);
                 Y_test = res(i).Y_test(:); 
                
                 if(~isnan(nanmean(Y_error)))
                    preds_test(i,k) = predict(mdl,X_test) + nanmean(Y_error);
                    pred_dr(i,k) = predict(mdl,X_test);
                 else
                    preds_test(i,k) = predict(mdl,X_test);
                    pred_dr(i,k) = predict(mdl,X_test);
                 end
                 %preds_test(:,i) = predict(mdl,X_test) + Y_error(:,i-1);
                 Y_error(i) = Y_test - preds_test(i,k);
                 Y_values(i,k) = Y_test;   
            end 
        
      end
      
      
end

%And now we need to take the number of non-nans in each of the rows.
for i = 1:8 
n(i)= size(res(i).X,1) -  sum(isnan(mean(res(i).X')))
end


for i = 1:8
    
    thing = 80*ones(1,1549)
    thing(isnan(preds_test(i,:))) = nan;
    
    m = sqrt((Y_values(i,:)-preds_test(i,:)).^2);
    md = sqrt((Y_values(i,:)-pred_dr(i,:)).^2); 
    mdd = sqrt((Y_values(i,:)-thing).^2);
   
   [P] =  ranksum(m,mdd);
   better_than_doc(i) = P;
   [P] =  ranksum(m,md);
   better_than_pop(i) = P;

end

%save continuous_gt60

for i = 1:8
    m(i) = nanmean(sqrt((Y_values(i,:)-preds_test(i,:)).^2));
    s(i) = nanstd(sqrt((Y_values(i,:)-preds_test(i,:)).^2))/sqrt(n(i));
    
    md(i) = nanmean(sqrt((Y_values(i,:)-pred_dr(i,:)).^2));
    sd(i) = nanstd(sqrt((Y_values(i,:)-pred_dr(i,:)).^2))/sqrt(n(i));
   
    mdd(i) = nanmean(sqrt((Y_values(i,:)-80*ones(1,1549)).^2));
    sdd(i) = nanstd(sqrt((Y_values(i,:)-80*ones(1,1549)).^2))/sqrt(n(i));
    
end


y_mean = [m(2:7);...
         md(2:7);...
         mdd(2:7);];
y_ste = [s(2:7);...
         sd(2:7);...
         sdd(2:7)];

x = (2:7);

% Plot
mseb(x,y_mean,y_ste,[],1);
grid on
legend('Individual Model','Population Model','Clinician')
ax = gca;
ax.XTick = [2 3 4 5 6 7]
set( gca                       , ...
    'FontName'   , 'Helvetica' );
hXLabel = xlabel('aPTT Draw Number');
hYLabel = ylabel('|aPTT Estimate Error|');

savefig('Figure_Analysis_3_Continuous_gt60')

print -dpng -r300 Figure_Analysis_3_Continuous_gt60



















































%% START FROM HERE --------------------------------------------------------
%% NOW FOR ERROR CORRECTION
%Take a patient and predict his/her ther state.
%record the error.
clear all;
load populationvShamim;
load newdataint;
load data;
load X_static;
load final_state;


%generate the matricies for each stage.
clear res
clear AUC
clear AUC_adjs
test_perc = 0.5;        %for each fold...
test_perc = 1- test_perc;
num_folds = 1;
missing_thresh = 0.31; %how much data should be missing before you throw the column out.
rep = 5000;
rep_growth = 1;
for k = 1:num_folds
    
    %For each of the 8 stages in the dosing.
    res = Generate_combined_data(newdataint,X_static,data, missing_thresh);
    
    %Keep only the people that were therapeutic of supra- by the end.    
    keep_me = final_state > 60;
    for i = 1:8
        res(i).X = res(i).X(keep_me,:);
        res(i).Y = res(i).Y(keep_me);
    end
    
    
    %% Generate random incidies for this fold.
    %that is, which patients will represent the population
    %and which will represent hte individuals.
    fold_shuffle = randperm(length(res(1).Y))'
    for i = 1:8
        res(i).Y = res(i).Y(fold_shuffle);
        res(i).X = res(i).X(fold_shuffle,:);
    end
       
    %generate the random testing and training sets.
    for i = 1:8        
        X_train = res(i).X([1:round(test_perc*length(res(i).X))],:);
        Y_train = res(i).Y([1:round(test_perc*length(res(i).Y))]);

        X_test = res(i).X([round(test_perc*length(res(i).X)):length(res(i).X)],:);
        Y_test = res(i).Y([round(test_perc*length(res(i).Y)):length(res(i).Y)]);
        
        res(i).X_train = X_train;
        res(i).Y_train = Y_train;
        
        res(i).X_test = X_test;
        res(i).Y_test = Y_test;
    end
    
    
      X_train = [res(1).X_train; res(2).X_train; res(3).X_train; res(4).X_train; res(5).X_train;res(6).X_train;res(7).X_train;res(8).X_train];
      Y_train = [res(1).Y_train; res(2).Y_train; res(3).Y_train; res(4).Y_train; res(5).Y_train;res(6).Y_train;res(7).Y_train;res(8).Y_train];
      
      %regular glm
      mdl = fitglm(X_train,Y_train,'linear','Distribution','normal');            
      
      %lasso glm
      %it's providing the same answers.  
       
      %% FOR EACH STAGE
      clear Y_error preds_test Y_values
      Y_error = zeros(length(res(1).X_test),1)
      for i= 1:8
            %FOR THE FIRST STAGE
                
            %TRAIN THE MODEL.
                if i == 1
                 %GET TESTING DATA
                 X_test = res(i).X_test(:,:);
                 Y_test = res(i).Y_test(:);
                
                 %EXTRACT ERROR.
                 preds_test = predict(mdl,X_test) + nanmean(Y_error);
                 Y_error(:,i) = Y_test - preds_test;

            end
            
            %For the datasets that were extracted, we want. training and testing sets
            if(i > 1)
                
                 X_test = res(i).X_test(:,:);
                 Y_test = res(i).Y_test(:); 
                
                 preds_test(:,i) = predict(mdl,X_test) + nanmean(Y_error,2);
                 %preds_test(:,i) = predict(mdl,X_test) + Y_error(:,i-1);
                 Y_error(:,i) = Y_test - preds_test(:,i);
                 Y_values(:,i) = Y_test;   
            end 
        
        end 
           
end
    
%This shows the error in the prediction.
x_values = nanmean(abs(Y_values - preds_test))
y_values = nanstd(abs(Y_values - preds_test))
errorbar(x_values, y_values)

%How far from the therapeutic state were they.
lt = res(i).Y_test(:) < 60 
gt = res(i).Y_test(:) > 100 
eq = not(or(lt,gt))

for i = 1:8
doctors(:,i) = [res(i).Y_test(:)-80];
end

subplot(1,2,1);boxplot(doctors)
xlabel('dose iteration')
ylabel('aPTT error')
ylim([-100 100])
xlim([1.5 8])
title('Physician')
hold on;
plot([0:9], [0 0 0 0 0 0 0 0 0 0],'black')

subplot(1,2,2);boxplot(Y_values - preds_test)
ylim([-100 100])
xlim([1.5 8])
xlabel('dose iteration')
title('Our Method')
hold on;
plot([0:9], [0 0 0 0 0 0 0 0 0 0],'black')

print -dpng -r300 Figure_Comparison_of_dosing_errors_gt60

