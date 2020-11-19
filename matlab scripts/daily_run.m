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
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

un = 10; % Select the ratio of true cases to reported cases. 1 for default.
un_from_file = un; % Change this when calculating un for "other" forecasts
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un, size(data_4, 2));
dhyperparams;

T_full = size(data_4, 2); % Consider all data for predictions
horizon = 100; dhorizon = horizon;
passengerFlow = 0; 
base_infec = data_4(:, T_full);
compute_region = popu > -1; % Compute for all regions!
    

beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, compute_region);
infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec);
infec_un_re = infec_un - repmat(base_infec - data_4_s(:, T_full), [1, size(infec_un, 2)]);
infec_data = [data_4_s(:, 1:T_full), infec_un_re];
base_deaths = deaths(:, T_full);
[death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin, 0, compute_region, lags);
[deaths_un_20] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
infec_un_20 = infec_un;
add_to_history;
disp('Finished other forecasts');