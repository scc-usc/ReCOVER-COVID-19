smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

un = 1.5; % Select the ratio of true cases to reported cases. 1 for default.
un_from_file = un; % Change this when calculating un for "other" forecasts
no_un_idx = un.*data_4(:, end)./popu > 0.2;
un(no_un_idx) = 1;

[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un, size(data_4, 2));
%[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, un_from_file, size(data_4, 2), 0, [3], [7], [10], 50);

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