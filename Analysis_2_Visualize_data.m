%Analysis_2_Visualize_data;
clear all;
load populationvShamim;
load newdataint;
load data;
load X_static;

%% Figure 1:Proportion of Patients, and dosing range, over time.
for i = 1:8
    Y = newdataint(:,i,3);
    ind_u(i) = nansum(Y < 60);
    ind_o(i) = nansum(Y > 100);
    ind_t(i) = nansum(Y > 60 & Y < 100);
    ind_q(i) = size(Y,1) - ind_u(i) - ind_o(i) - ind_t(i);
end

hbar = bar(1:8, [ind_q' ind_u' ind_t' ind_o'], 1, 'stack')

hbar(1).FaceColor =[0.75 0.75 0.75]
hbar(2).FaceColor =[1 1 0]
hbar(3).FaceColor =[0 1 0]
hbar(4).FaceColor =[1 0 0]

xlabel('aPTT Draw Number')
ylabel('Number of Subjects')
xlim([0.5 6.5])
ylim([0 3883])
% Add a legend
legend('Not Measured', 'Subtherapeutic', 'Therapeutic','Supratherapeutic','Location','SouthEast')

print -dpng -r300 Figure1_DosingClass


%% HOW ABOUT ONLY THOSE WHICH EVENTUALLY BECAME THERAPEUTIC.
%% OR REMAINED OVERSHOT BY THE END. n = 1557
%This is the subset of patients who's 'final state' at exit was therapeutic
% or supratherapeutic. this information can be used for subgroup analysis.
%A ssuming that tho
% for i = 1:8
%     weight_norm_data = newdataint(:,i,12)./X_static.WEIGHT_FIRST;
%     Y = newdataint(:,i,3);
%     ind = Y < 60 & final_state >= 60;
%     plot( weight_norm_data(ind),Y(ind),'y.')
%     hold on;
%     ind = Y > 100 & final_state >= 60;
%     plot( weight_norm_data(ind),Y(ind),'r.')
%     hold on;
%     ind = Y > 60 & Y < 100 & final_state >= 60;
%     plot( weight_norm_data(ind),Y(ind),'g.')
%     hold off
%     xlim([0 25])
%     ylim([0 150])
%     waitforbuttonpress;
% end
% 
% %% HOW ABOUT ONLY THOSE WHICH EVENTUALLY BECAME THERAPEUTIC.
% % n = 1251
% for i = 1:8
%     weight_norm_data = newdataint(:,i,12)./X_static.WEIGHT_FIRST;
%     Y = newdataint(:,i,3);
%     ind = Y < 60 & final_state >= 60 & final_state <= 100;
%     plot( weight_norm_data(ind),Y(ind),'y.')
%     hold on;
%     ind = Y > 100 & final_state >= 60 & final_state <= 100;
%     plot( weight_norm_data(ind),Y(ind),'r.')
%     hold on;
%     ind = Y > 60 & Y < 100 & final_state >= 60 & final_state <= 100;
%     plot( weight_norm_data(ind),Y(ind),'g.')
%     hold off
%     xlim([0 25])
%     ylim([0 150])
%     waitforbuttonpress;
% end
% 
% keepers = final_state >= 60 & final_state <= 100;
