clear; warning off;
addpath('./hyper_params');

%% For US
load_data_us;

smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dhyperparams;
write_unreported;
save us_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;
add_to_history;
disp('Finished updating US forecasts');
%% For Global
clear;
load_data_global;
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dhyperparams;
write_unreported;
save global_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;
add_to_history;
disp('Finished updating Global forecasts');