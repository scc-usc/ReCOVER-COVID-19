clear; warning off;
addpath('./hyper_params');

%% For US
load_data_us;
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', 7, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', 7, 2), 2)];
load us_hyperparam_ref_64.mat
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dk = 3; djp = 7; dalpha = 1; dwin = 50; % Choose a lower number if death rates evolve
write_data_us;
write_unreported;
save us_hyperparam_latest.mat best_param_list MAPEtable_s;

disp('Finished updating US forecasts');
%% For Global
clear;

load_data_global;
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', 7, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', 7, 2), 2)];
load global_hyperparam_ref_64.mat
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dk = 3; djp = 7; dalpha = 1; dwin = 50; % Choose a lower number if death rates evolve
write_data_global;
write_unreported;
save global_hyperparam_latest.mat best_param_list MAPEtable_s;

disp('Finished updating Global forecasts');