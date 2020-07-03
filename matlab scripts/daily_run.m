clear; warning off;
addpath('./hyper_params');

%% For US
load_data_us;
load us_hyperparam_ref_64.mat
hyperparam_tuning;
death_hyperparams;
write_data_us;
write_unreported;
save us_hyperparam_latest.mat best_param_list MAPEtable_s;

disp('Finished updating US forecasts');
%% For Global
clear;

load_data_global;
load global_hyperparam_ref_64.mat
hyperparam_tuning;
death_hyperparams;
write_data_global
write_unreported;
save global_hyperparam_latest.mat best_param_list MAPEtable_s;

disp('Finished updating Global forecasts');