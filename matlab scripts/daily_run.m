load_data_us 
load us_hyperparam_ref_64.mat
hyperparam_tuning; varying_test; write_data_us
write_unreported
%save us_May4_hyperparam.mat best_param_list MAPEtable_s
save us_clean.mat

disp('Finished updating US forecasts');

clear;

load_data_global;
load global_hyperparam_ref_64.mat
hyperparam_tuning; varying_test; write_data_global
write_unreported
%save global_May4_hyperparam.mat best_param_list MAPEtable_s
save global.mat

disp('Finished updating Global forecasts');