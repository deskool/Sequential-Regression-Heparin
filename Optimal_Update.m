%The goal of this section is to ask - if I update the model every time with
%a new weight, then what is the optimal weight.

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
rep = 2000;
rep_growth = 1;
    
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
    
    
    %for each of the datasets we want to figure out what threshold will
    %generate the best testing set AUC.
    
    
    
    
%% UNDER
clear res_under
%For each patient

for j= 1:length(res(i).X_test)
    
    %For various setting of the parameters.
    
    
    for i= 1:8
        k = 1;
        for rep = 1:1000:5000
            
            %For the datasets that were extracted, we want. training and testing sets
            
            if(i > 1)
                X_train = [X_train; repmat(res(i-1).X_test(j,:),rep,1)];
                Y_train = [Y_train; (repmat(res(i-1).Y_test(j),rep,1)) < 60]; %<----------- IMPORTANT!
                rep = rep*rep_growth;
                
                
            else
                X_train = [res(1).X_train; res(2).X_train; res(3).X_train; res(4).X_train; res(5).X_train;res(6).X_train;res(7).X_train;res(8).X_train];
                Y_train = [res(1).Y_train; res(2).Y_train; res(3).Y_train; res(4).Y_train; res(5).Y_train;res(6).Y_train;res(7).Y_train;res(8).Y_train]...
                    < 60; %<----------- IMPORTANT!
            end
            
            %Do a regular regression with all the features.
            mdl = fitglm(X_train,Y_train,'linear','Distribution','binomial');
            
            X_test = res(i).X_test(j,:);
            Y_test = res(i).Y_test(j) < 60;
            yc_test{i,j,k} = num2str(Y_test);
            
            %regular predictions
            preds_test(i,j,k) = predict(mdl,X_test);
            j;
            k=k+1;
        end
    end
end
under.preds_test = preds_test;
under.yc_test = yc_test;
   
%% OVER
clear res_over
%For each patient
for j= 1:length(res(i).X_test)
    
    %For various setting of the parameters.
    for i= 1:8
        k = 1;
        for rep = 1:1000:5000
            
            %For the datasets that were extracted, we want. training and testing sets
            
            if(i > 1)
                X_train = [X_train; repmat(res(i-1).X_test(j,:),rep,1)];
                Y_train = [Y_train; (repmat(res(i-1).Y_test(j),rep,1)) > 100]; %<----------- IMPORTANT!
                rep = rep*rep_growth;
                
                
            else
                X_train = [res(1).X_train; res(2).X_train; res(3).X_train; res(4).X_train; res(5).X_train;res(6).X_train;res(7).X_train;res(8).X_train];
                Y_train = [res(1).Y_train; res(2).Y_train; res(3).Y_train; res(4).Y_train; res(5).Y_train;res(6).Y_train;res(7).Y_train;res(8).Y_train]...
                    >100; %<----------- IMPORTANT!
            end
            
            %Do a regular regression with all the features.
            mdl = fitglm(X_train,Y_train,'linear','Distribution','binomial');
            
            X_test = res(i).X_test(j,:);
            Y_test = res(i).Y_test(j) > 100;
            yc_test{i,j,k} = num2str(Y_test);
            
            %regular predictions
            preds_test(i,j,k) = predict(mdl,X_test);
            j;
            k=k+1;
        end
    end
end
over.preds_test = preds_test;
over.yc_test = yc_test;
   


for k = 1:5
    for i = 1:8
        try
        [~,~,~,AUC_test_under(k,i)] = perfcurve({under.yc_test{i,:,k}},under.preds_test(i,:,k),'1');
        catch
            AUC_test_under(k,i) = nan;
        end
    end
end


for k = 1:5
    for i = 1:8
        try
        [~,~,~,AUC_test_over(k,i)] = perfcurve({over.yc_test{i,:,k}},over.preds_test(i,:,k),'1');
        catch
            AUC_test_over(k,i) = nan;
        end
    end
end




    

    
    
    
    
    
    