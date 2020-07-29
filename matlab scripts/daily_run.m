clear; warning off;
addpath('./hyper_params');

%% For US
load_data_us;
smooth_factor = 14;
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', smooth_factor, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', smooth_factor, 2), 2)];
load us_hyperparam_ref_64.mat
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
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', smooth_factor, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', smooth_factor, 2), 2)];
load global_hyperparam_ref_64.mat
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dhyperparams;
write_unreported;
save global_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;
add_to_history;
disp('Finished updating Global forecasts');