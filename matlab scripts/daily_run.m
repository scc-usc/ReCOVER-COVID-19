clear;
addpath('./hyper_params');
load_data_us;
load us_hyperparam_ref_64.mat
hyperparam_tuning; write_data_us;
write_unreported;
save us_clean.mat;

disp('Finished updating US forecasts');

clear;

load_data_global;
load global_hyperparam_ref_64.mat
hyperparam_tuning; write_data_global
write_unreported;
save global.mat;

disp('Finished updating Global forecasts');