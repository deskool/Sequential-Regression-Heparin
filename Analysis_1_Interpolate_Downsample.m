clear all;
%Load up the data.
cd('/home/mohammad/Dropbox (MIT)/Heparin_Reinforcement_Learning')
addpath('/home/mohammad/Dropbox (MIT)/MATLAB_TOOLBOXES/Toolboxes/biostatlib/trunk')
load data
load populationvShamim
%find where the aPTT are equall to 1
aPTT_index = find(strcmp(data.labels,'aPTT_sig') == 1);
aPTT_data = data.numbers(:,:,aPTT_index);


% interpolate when possible - nearest neighbor method
for i = 1:size(data.numbers,1)
    
    A = squeeze(data.numbers(i,:,:));
    for(j= 1:length(A))
        try
            this_A = A(:,j);
            this_A(isnan(this_A)) = interp1(find(~isnan(this_A)), this_A(~isnan(this_A)), find(isnan(this_A)),'nearest','extrap');
            A(:,j) = this_A;
        catch
        end
    end
    newdata(i,:,:) = A;
end



%For each of the patients.
for i = 1:size(aPTT_data,1)
    
    %Get the times of aPTT draw
    raw_times = find(~isnan(aPTT_data(i,:)));
    times = [0 raw_times(1:end-1)];
    times2 = raw_times;
    
    %from these construct the time ranges between the draws
    ranges = [times; times2];
    if(length(times) > 1)
        
        %Only consider doses where the draw is less than 6 hours from dosing
        trash = find(abs(ranges(1,:) - ranges(2,:)) < 6);
        ranges(:, trash) = [];
        
        %For each of the remaining ranges.

        %for each of the variables
        for j = 1:size(data.numbers,3)
            
            %grab the data.
            this_data = newdata(i,:,j);
            
            %for each of th e
            for k=1:size(ranges,2)
                these_values = this_data(ranges(1,k)+1:ranges(2,k));
                newdata2(i,k,j) = nanmedian(these_values);
                dat_length(i,k,j) = ranges(2,k) - ranges(1,k)+1;
            end
        end
    end
    
end

%Take the median sampled data.
newdata = newdata2;

%replace any zero locations with nans
newdata(newdata == 0) = nan;

%load newdata
save newdata newdata;
newdataint_full = newdata;
save newdataint_full newdataint_full;

%% Now, merge the population and individual data streams.
clear all;
load populationvShamim;
load newdataint;
load data;
newdataint = newdataint_full;
[unique_stays which_patients] = unique(populationvShamim.ICUSTAY_ID);
X_static = populationvShamim(which_patients,:);

%% CHECK FOR DIFFERENCES BETWEEN THE GROUPS BEFORE AND AFTER EXLCUSION
 X_static_sub = X_static(:,[9,13,34,35,24:25])
 mean(ismissing(X_static_sub))
 keep = find(sum(ismissing(X_static_sub)') == 0);
 [H,P,CI,STATS] = ttest2(X_static_sub{:,:},X_static_sub{keep,:})
 [X_static_sub.Properties.VariableNames(:)',num2cell(P')]
 
 [P] = ranksum(X_static_sub{:,3},X_static_sub{keep,3})
 [P] = ranksum(X_static_sub{:,4},X_static_sub{keep,4})
 [P] = ranksum(X_static_sub{:,5},X_static_sub{keep,5})
 [P] = ranksum(X_static_sub{:,6},X_static_sub{keep,6})
    
 [X_static_sub.Properties.VariableNames(:)',num2cell(P')]
 
 dump = [];
 for i = 1:8
     tmp_tab = array2table(squeeze(newdataint_full(:,i,:)),'VariableNames',data.labels);
     tmp_tab = tmp_tab(:,[1,2,8,9,10,11,13,15,16,21,22,24,25]);
     X_static_sub = X_static(:,[9,13,34,35,23:25]);
     tmp_tab = [X_static_sub, tmp_tab];
     dump = [dump;tmp_tab];    
 end
 
 keep = find(sum(ismissing(dump)') == 0);
 dump_no_miss = dump(keep,:)
 [nanmean(dump{:,:})',nanstd(dump{:,:})',...
 mean(dump_no_miss{:,:})',nanstd(dump_no_miss{:,:})']
 [H,P,CI,STATS] = ttest2(dump{:,:},dump_no_miss{:,:})
 [dump.Properties.VariableNames(:)',num2cell(P')]


%% HOW MANY PATIENTS ARE MISSING ANY APTT DRAWS. - REMOVE 587, LEAVING 3883
trash = isnan(squeeze(newdataint(:,:,3)));
trash_ind = find(sum(trash')==8)

%remove them
newdataint(trash_ind,:,:) = [];
X_static(trash_ind,:) = [];


save newdataint newdataint;
save X_static X_static;























