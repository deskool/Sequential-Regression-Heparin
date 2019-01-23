clear all;

search_me = '/home/mohammad/Dropbox (MIT)/Heparin_Reinforcement_Learning'

% Extract all .mat files under this directory
file_list = getAllFiles([search_me]);
file_list = getSubsetWithKeywords(file_list,{'_sig','csv'});

%load up the population information.
load populationvShamim;
population = populationvShamim;
clear populationvShamim

%How many days of data are you expecting.
result = zeros(length(unique(population.ICUSTAY_ID)),49,length(file_list));
load result

for i = 2:length(file_list)
    %Format is patients x time(hours) x features
    [result(:,:,i)] = import_sig(file_list{i},population);
    %setup_email
    %sendmail(myaddress, 'Heparin', '.');
    save result result
end

data.numbers = result;
data.labels = {'CO2_sig','HR_sig','aPTT_sig','albumin_sig','arterial_bp_dias_sig','arterial_bp_sys_sig','billi_sig','creat_sig','gcs_sig','hematocrit_sig','hemoglobin_sig','heparin_sig','inr_sig','ph_sig','plat_sig','pt_sig','resp_rate_sig','sao2_sig','sofa_hema_sig','sofa_sig','spo2_sig','temp_sig','trop_sig','urea_sig','wbc_sig'}

save data data

