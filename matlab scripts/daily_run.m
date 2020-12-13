clear; warning off;
addpath('./hyper_params');

%% For US
load_data_us;

smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

xx = load(['../results/unreported/' prefix '_all_unreported.csv']);
un_from_file = xx(2:end, end);
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un_from_file, size(data_4, 2));
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

xx = load(['../results/unreported/' prefix '_all_unreported.csv']);
un_from_file = xx(2:end, end);
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un_from_file, size(data_4, 2));
dhyperparams;
write_unreported;
save global_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;
add_to_history;
disp('Finished updating Global forecasts');

%% For US counties
clear;
write_county_files;

%% For Others (Currently only Germany, Poland)

clear;
load_data_other;
do_other_forecasts;
add_to_history;
disp('Writing quantile files for KIT hub');
KIT_submit;
disp('Finished other forecasts');

