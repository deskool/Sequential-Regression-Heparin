%% PLOT THE COMPARISONS BETWEEN THE GROUPS.

%% The First Figure 
%Compares the AUC Measures for the overshot, undershot, and therapetutic
%Between the population and individual models.

file1 = 'all_onlydose_1_grow_sub_population2'
file2 = 'all_onlydose_100_grow_sub_population2'

% file1 = 'all_1_grow_full_population'
% file2 = 'all_100_grow_full_population'

% file1 = 'all_1_grow_sub_population2'
% file2 = 'all_100_grow_sub_population2'

eval(['load ' file1])
n = size(preds_test_over,1) - sum(isnan(preds_test_over))
sum(n)

%under
a = [AUC_test_under(2:end)]; 
a2 = [AUC_test_ther(2:end)];
a3 = [AUC_test_over(2:end)];

eval(['load ' file2])
b = [AUC_test_under(2:end)];
b2 = [AUC_test_ther(2:end)];
b3 = [AUC_test_over(2:end)];

under = nansum(n(2:end).*(b-a))/nansum(n(2:end))
ther = nansum(n(2:end).*(b2-a2))/nansum(n(2:end))
over = nansum(n(2:end).*(b3-a3))/nansum(n(2:end))


a = [.5 .5 .5 .5 .5 .5]
a2 = [.5 .5 .5 .5 .5 .5]
a3 = [.5 .5 .5 .5 .5 .5]

under = nansum(n(2:end).*(b-a))/nansum(n(2:end))
ther = nansum(n(2:end).*(b2-a2))/nansum(n(2:end))
over = nansum(n(2:end).*(b3-a3))/nansum(n(2:end))




for lll = 1
eval(['load ' file1])
subplot(3,1,1);plot(AUC_test_under,'y--','LineWidth',2)
hold on;

eval(['load ' file2])
plot(AUC_test_under,'y','LineWidth',3)
hold on;

plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')
%xlabel('Dosing Stage')
%ylabel('AUC')
ylim([.45 .9])
xlim([1 7])
grid on
%legend('population model','individual model')


%% PLOT THE THERAPEUTIC
eval(['load ' file1])
subplot(3,1,2);plot(AUC_test_ther,'g--','LineWidth',2)
hold on;
a = AUC_test_ther
% load categorical_rep_500_full_population
% plot(AUC_test_ther,'g')
hold on;

eval(['load ' file2])
plot(AUC_test_ther,'g','LineWidth',2)
nanmean(AUC_test_ther(2:5) - a(2:5))
plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')
hold on;
%load categorical_rep_5_grow_full_population
%plot(AUC_test_ther,'g o')

%xlabel('Dosing Stage')
set( gca                       , ...
    'FontName'   , 'Helvetica' );
ylabel('AUC')
ylim([.45 .9])
xlim([1 7])
grid on
%legend('population model','individual model')


%% PLOT THE OVERSHOOT
eval(['load ' file1])
subplot(3,1,3);plot(AUC_test_over,'r--','LineWidth',2)
a = AUC_test_over
hold on;

eval(['load ' file2])
plot(AUC_test_over,'r','LineWidth',2)
grid on
ylim([.45 .9])
xlim([1 7])
hold on;
plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')
set( gca                       , ...
    'FontName'   , 'Helvetica' );
xlabel('aPTT Draw Number')
end

eval(['print -dpng -r300 ' savename])

%% NOW, WE ALSO WANT TO ILLUSTRATE THE % CORRECT
%% FIGURE 2
file1 = 'all_1_grow_sub_population2'
file2 = 'all_10_grow_sub_population2'
savename = 'perc_comparison_of_sub_population'
%% CONSTRUCT THE % correct for this population.


for lll = 1
eval(['load ' file1])
for i = 1:7
    
   preds = [preds_test_over(:,i) , preds_test_ther(:,i), preds_test_under(:,i)]';
   truth = [yc_test_over(:,i) , yc_test_ther(:,i) , yc_test_under(:,i)]';  
   trash = find(sum(isnan(preds)) > 0);
   preds(:,trash) = [];
   truth(:,trash) = [];
   
   [a, predictions] = nanmax(preds); 
   [a, truth] = nanmax(truth);
   result(i) = mean(truth == predictions);
   
end
plot(result*100,'r','LineWidth',2)
hold on;

eval(['load ' file2])
for i = 1:7
   preds = [preds_test_over(:,i) , preds_test_ther(:,i), preds_test_under(:,i)]';
   truth = [yc_test_over(:,i) , yc_test_ther(:,i) , yc_test_under(:,i)]';   
   trash = find(sum(isnan(preds)) > 0);
   preds(:,trash) = [];
   truth(:,trash) = [];
   
   [a, predictions] = nanmax(preds); 
   [a, truth] = nanmax(truth);
   result(i) = mean(truth == predictions);
end
plot(result*100,'b','LineWidth',2)
hold on;

%Compared against the doctors
for i = 1:7
   preds = [preds_test_over(:,i) , preds_test_ther(:,i), preds_test_under(:,i)]';
   truth = [yc_test_over(:,i) , yc_test_ther(:,i) , yc_test_under(:,i)]';  
   trash = find(sum(isnan(preds)) > 0);
   preds(:,trash) = [];
   truth(:,trash) = [];
   [a, truth] = nanmax(truth);
   result(i) = mean(truth == 2);
   
end
plot(result*100,'black','LineWidth',2)
grid on;

xlabel('aPTT Draw Number')
ylabel('% Correctly Classified')
legend('Population Model','Individual Model','Clinician')
xlim([1 7])
end


eval(['print -dpng -r300 ' savename])


















%% FIGURE 3 %%%%%%%%%%%%%% 
%% SUB POPULATION

 
 %% PLOT THE UNDERSHOOT
 load all_onlydose_1_grow_sub_population
 subplot(3,1,1);plot(AUC_test_under,'y--','LineWidth',2)
 hold on;
 
 load all_onlydose_100_grow_sub_population
 plot(AUC_test_under,'y','LineWidth',3)
 hold on;
 
 plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')
 %xlabel('Dosing Stage')
 %ylabel('AUC')
 ylim([.4 .8])
 xlim([1 7])
 grid on
 %legend('population model','individual model')
 
 
 %% PLOT THE THERAPEUTIC
 load all_onlydose_1_grow_sub_population
 subplot(3,1,2);plot(AUC_test_ther,'g--','LineWidth',2)
 hold on;
 a = AUC_test_ther
 % load categorical_rep_500_full_population
 % plot(AUC_test_ther,'g')
 hold on;
 
 load all_onlydose_100_grow_sub_population
 plot(AUC_test_ther,'g','LineWidth',2)
 nanmean(AUC_test_ther(2:5) - a(2:5))
 plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')
 hold on;
 %load categorical_rep_5_grow_full_population
 %plot(AUC_test_ther,'g o')
 
 %xlabel('Dosing Stage')
 set( gca                       , ...
     'FontName'   , 'Helvetica' );
 ylabel('AUC')
 ylim([.4 .8])
 xlim([1 7])
 grid on
 %legend('population model','individual model')
 
 
 %% PLOT THE OVERSHOOT
 load all_onlydose_1_grow_sub_population
 subplot(3,1,3);plot(AUC_test_over,'r--','LineWidth',2)
 a = AUC_test_over
 hold on;
 load all_onlydose_100_grow_sub_population
 plot(AUC_test_over,'r','LineWidth',2)
 grid on
 ylim([.4 .8])
 xlim([1 7])
 hold on;
 plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')
 set( gca                       , ...
     'FontName'   , 'Helvetica' );
 xlabel('aPTT Draw Number')
 
 print -dpng -r300 Figure_DosingClass_subpopulation_AUC
 
 %% FIGURE 4
 
 load all_onlydose_1_grow_sub_population
 for i = 1:7
     
    preds = [preds_test_over(:,i) , preds_test_ther(:,i), preds_test_under(:,i)]';
    truth = [yc_test_over(:,i) , yc_test_ther(:,i) , yc_test_under(:,i)]';  
    trash = find(sum(isnan(preds)) > 0);
    preds(:,trash) = [];
    truth(:,trash) = [];
    
    [a, predictions] = nanmax(preds); 
    [a, truth] = nanmax(truth);
    result(i) = mean(truth == predictions);
    
 end
 plot(result*100,'r','LineWidth',2)
 hold on;
 
 load all_onlydose_100_grow_sub_population
 for i = 1:7
    preds = [preds_test_over(:,i) , preds_test_ther(:,i), preds_test_under(:,i)]';
    truth = [yc_test_over(:,i) , yc_test_ther(:,i) , yc_test_under(:,i)]';   
    trash = find(sum(isnan(preds)) > 0);
    preds(:,trash) = [];
    truth(:,trash) = [];
    
    [a, predictions] = nanmax(preds); 
    [a, truth] = nanmax(truth);
    result(i) = mean(truth == predictions);
 end
 plot(result*100,'b','LineWidth',2)
 hold on;
 
 %Compared against the doctors
 for i = 1:7
    preds = [preds_test_over(:,i) , preds_test_ther(:,i), preds_test_under(:,i)]';
    truth = [yc_test_over(:,i) , yc_test_ther(:,i) , yc_test_under(:,i)]';  
    trash = find(sum(isnan(preds)) > 0);
    preds(:,trash) = [];
    truth(:,trash) = [];
    [a, truth] = nanmax(truth);
    result(i) = mean(truth == 2);
    
 end
 plot(result*100,'black','LineWidth',2)
 grid on;
 
 xlabel('aPTT Draw Number')
 ylabel('% Correctly Classified')
 legend('Population Model','Individual Model','Clinician')
 xlim([1 7])
 print -dpng -r300 Figure_DosingClass_PercentCorrect
 
 
 
 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 



clear all;
load final_state
keep_me = final_state > 60;
%% SUBPOPULATION PLOT THE COMPARISONS BETWEEN THE GROUPS.

% PLOT THE UNDERSHOOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load all_1_grow_full_population

   [rows,cols] = find(preds_test_over > preds_test_under & preds_test_over > preds_test_ther);
    res_over_pred(rows,cols) = 1; 
   [rows,cols] = find(preds_test_under > preds_test_over & preds_test_under > preds_test_ther);
    res_under_pred(rows,cols) = 1; 
   [rows,cols] = find(preds_test_ther > preds_test_under & preds_test_ther > preds_test_over);
    res_ther_pred(rows,cols) = 1; 

%Over
    for i = 1:8
        try
            labels = double(yc_test_over(keep_me,i));
            predictions = double(res_over_pred(keep_me,i));
            [~,~,~,AUC_test_over(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_over(i) = nan;
        end
    end
    
    
    %Under
    for i = 1:8
        try
            labels = double(yc_test_under(keep_me,i));
            predictions = double(res_under_pred(keep_me,i));
            [~,~,~,AUC_test_under(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_under(i) = nan;
        end
    end
    
    %Therapeutic
    for i = 1:8
        try
            labels = double(yc_test_ther(keep_me,i));
            predictions = double(res_ther_pred(keep_me,i));
            [~,~,~,AUC_test_ther(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_ther(i) = nan;
        end
    end
subplot(3,1,1);plot(AUC_test_under,'y--','LineWidth',2)
hold on;
plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')

subplot(3,1,2);plot(AUC_test_ther,'g--','LineWidth',2)
hold on;
plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')

subplot(3,1,3);plot(AUC_test_over,'r--','LineWidth',2)
hold on;
plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')



load all_100_grow_full_population
[rows,cols] = find(preds_test_over > preds_test_under & preds_test_over > preds_test_ther);
res_over_pred(rows,cols) = 1; 
[rows,cols] = find(preds_test_under > preds_test_over & preds_test_under > preds_test_ther);
res_under_pred(rows,cols) = 1; 
[rows,cols] = find(preds_test_ther > preds_test_under & preds_test_ther > preds_test_over);
res_ther_pred(rows,cols) = 1; 

%Over
    for i = 1:8
        try
            labels = double(yc_test_over(keep_me,i));
            predictions = double(res_over_pred(keep_me,i));
            [~,~,~,AUC_test_over(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_over(i) = nan;
        end
    end
    
    
    %Under
    for i = 1:8
        try
            labels = double(yc_test_under(keep_me,i));
            predictions = double(res_under_pred(keep_me,i));
            [~,~,~,AUC_test_under(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_under(i) = nan;
        end
    end
    
    %Therapeutic
    for i = 1:8
        try
            labels = double(yc_test_ther(keep_me,i));
            predictions = double(res_ther_pred(keep_me,i));
            [~,~,~,AUC_test_ther(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_ther(i) = nan;
        end
    end
hold on;
subplot(3,1,1);plot(AUC_test_under,'y','LineWidth',2)

hold on;
subplot(3,1,2);plot(AUC_test_ther,'g','LineWidth',2)

hold on;
subplot(3,1,3);plot(AUC_test_over,'r','LineWidth',2)

    
    


    
plot(AUC_test_under,'y','LineWidth',2)

% hold on;
% load categorical_rep_500_grow2_full_population
% plot(AUC_test_under,'y o')
ylim([.3 1])
xlim([2 7])
grid on;




% PLOT THE THERAPEUTIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load categorical_rep_0_full_population
%Over
    for i = 1:8
        try
            labels = res_over_test(keep_me,i)';
            predictions = res_over_pred(keep_me,i);
            [~,~,~,AUC_test_over(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_over(i) = nan;
        end
    end    
%Under
    for i = 1:8
        try
            [~,~,~,AUC_test_under(i)] = perfcurve(res_under_test(keep_me,i)',res_under_pred(keep_me,i),1);
        catch
            AUC_test_under(i) = nan;
        end
    end
%Therapeutic
    for i = 1:8
        try
            [~,~,~,AUC_test_ther(i)] = perfcurve(double(res_ther_test(keep_me,i)'),res_ther_pred(keep_me,i),1);
        catch
            AUC_test_ther(i) = nan;
        end
    end

subplot(3,1,2);plot(AUC_test_ther,'g--','LineWidth',2)
a = AUC_test_ther;
hold on;
plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')

load categorical_rep_250_grow2_full_population
%Over
    for i = 1:8
        try
            labels = res_over_test(keep_me,i)';
            predictions = res_over_pred(keep_me,i);
            [~,~,~,AUC_test_over(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_over(i) = nan;
        end
    end    
%Under
    for i = 1:8
        try
            [~,~,~,AUC_test_under(i)] = perfcurve(res_under_test(keep_me,i)',res_under_pred(keep_me,i),1);
        catch
            AUC_test_under(i) = nan;
        end
    end
%Therapeutic
    for i = 1:8
        try
            [~,~,~,AUC_test_ther(i)] = perfcurve(double(res_ther_test(keep_me,i)'),res_ther_pred(keep_me,i),1);
        catch
            AUC_test_ther(i) = nan;
        end
    end
plot(AUC_test_ther,'g','LineWidth',2)
nanmean(AUC_test_ther(2:5) - a(2:5))
ylabel('AUC')
grid on;
ylim([.3 1])
xlim([2 7])


% PLOT THE OVERSHOOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load categorical_rep_0_full_population
%Over
    for i = 1:8
        try
            labels = res_over_test(keep_me,i)';
            predictions = res_over_pred(keep_me,i);
            [~,~,~,AUC_test_over(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_over(i) = nan;
        end
    end    
%Under
    for i = 1:8
        try
            [~,~,~,AUC_test_under(i)] = perfcurve(res_under_test(keep_me,i)',res_under_pred(keep_me,i),1);
        catch
            AUC_test_under(i) = nan;
        end
    end  
%Therapeutic
    for i = 1:8
        try
            [~,~,~,AUC_test_ther(i)] = perfcurve(double(res_ther_test(keep_me,i)'),res_ther_pred(keep_me,i),1);
        catch
            AUC_test_ther(i) = nan;
        end
    end
subplot(3,1,3);plot(AUC_test_over,'r--','LineWidth',2)
a = AUC_test_over;
hold on;
plot((1:7),[.5 .5 .5 .5 .5 .5 .5],'--black')
load categorical_rep_250_grow2_full_population
%Over
    for i = 1:8
        try
            labels = res_over_test(keep_me,i)';
            predictions = res_over_pred(keep_me,i);
            [~,~,~,AUC_test_over(i)] = perfcurve(labels,predictions,1);
        catch
            AUC_test_over(i) = nan;
        end
    end    
%Under
    for i = 1:8
        try
            [~,~,~,AUC_test_under(i)] = perfcurve(res_under_test(keep_me,i)',res_under_pred(keep_me,i),1);
        catch
            AUC_test_under(i) = nan;
        end
    end  
%Therapeutic
    for i = 1:8
        try
            [~,~,~,AUC_test_ther(i)] = perfcurve(double(res_ther_test(keep_me,i)'),res_ther_pred(keep_me,i),1);
        catch
            AUC_test_ther(i) = nan;
        end
    end
plot(AUC_test_over,'r','LineWidth',2)
nanmean(AUC_test_over(2:5) - a(2:5))
xlabel('Dosing Stage')
grid on;
ylim([.3 1])
xlim([2 7])

print -dpng -r300 Figure_DosingClass_AUC_partial




%% Correct percentage exlcuding the undershoot! %%%%%%%%%%%%%%%%%%%%%%%%%%%


%load categorical_rep_0_full_population
load all_1_grow_full_population
for i = 1:7
    
   preds = [res_over_pred(keep_me,i) , res_ther_pred(keep_me,i), res_under_pred(keep_me,i)]';
   truth = [res_over_test(keep_me,i) , res_ther_test(keep_me,i) , res_under_test(keep_me,i)]';  
   trash = find(sum(isnan(preds)) > 0);
   preds(:,trash) = [];
   truth(:,trash) = [];
   
   [a, predictions] = nanmax(preds); 
   [a, truth] = nanmax(truth);
   result(i) = mean(truth == predictions);
   
end
plot(result*100,'r','LineWidth',2)
hold on;

load all_100_grow_full_population

for i = 1:7
    
   preds = [res_over_pred(keep_me,i) , res_ther_pred(keep_me,i), res_under_pred(keep_me,i)]';
   truth = [res_over_test(keep_me,i) , res_ther_test(keep_me,i) , res_under_test(keep_me,i)]';  
   trash = find(sum(isnan(preds)) > 0);
   preds(:,trash) = [];
   truth(:,trash) = [];
   
   [a, predictions] = nanmax(preds); 
   [a, truth] = nanmax(truth);
   result(i) = mean(truth == predictions);
   
end
plot(result*100,'b','LineWidth',2)
hold on;

%Compared against the doctors
for i = 1:7
   preds = [res_over_pred(:,i) , res_ther_pred(:,i), res_under_pred(:,i)]';
   truth = [res_over_test(:,i) , res_ther_test(:,i) , res_under_test(:,i)]';  
   trash = find(sum(isnan(preds)) > 0);
   preds(:,trash) = [];
   truth(:,trash) = [];
   [a, truth] = nanmax(truth);
   result(i) = mean(truth == 2);
   
end
plot(result*100,'black','LineWidth',2)
hold on;

grid on;
xlabel('aPTT Draw Number')
ylabel('% Correctly Classified')
legend('Population Model','Individual Model','Clinician')
xlim([1 7])
print -dpng -r300 Figure_DosingClass_PercentCorrect_partial







