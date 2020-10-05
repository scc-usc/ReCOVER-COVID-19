clear; warning off;
addpath('./hyper_params');

%% Load data and hyperparameters
load_data_county;
load us_hyperparam_latest.mat

%%
param_state = best_param_list;
param_state_deaths = best_death_hyperparam;
best_param_list = zeros(length(countries), size(param_state, 2));
best_death_hyperparam = zeros(length(countries), size(param_state_deaths, 2));
for idx = 1:length(countries)
    best_param_list(idx, :) = param_state(county_to_state(idx), :);
    best_death_hyperparam(idx, :) = param_state_deaths(county_to_state(idx), :);
end

%% Set hyper-parameters and prepare data generation

dk = best_death_hyperparam(:, 1);
djp = best_death_hyperparam(:, 2);
dwin = best_death_hyperparam(:, 3);
dalpha = 1;

bad_idx = data_4(:, end) < 1 | popu < 1 | data_4(:, end) > popu ; % Only predict for counties with at least one case
lowidx = data_4(:, 60) < 50; % Note the regions with unreliable data on reference day

prefix = 'county';
file_prefix =  ['../results/forecasts/' prefix];  % edit this to change the destination
T_full = size(data_4, 2);
reference_day = 64; % reference day for "released"
horizon = 100;
dhorizon = 100;
smooth_factor = 14;
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', smooth_factor, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', smooth_factor, 2), 2)];

no_un_idx = data_4(:, end)./popu > 0.1; % Treat them as if there are no unreported cases, forcasts are likely not affected by this


%%
tic;
compute_region = ~bad_idx; % Compute only for these regions
passengerFlow = 0;
un_array = [0];
un = zeros(length(popu), 1);
for un_id = 1:length(un_array)
    % Train with hyperparams before and after
    
    if un_array(un_id) > 0
        un(:) = un_array(un_id); % Select the ratio of true cases to reported cases. 1 for default.
    else
        un = load('..\results\unreported\countiesunreported.txt');
    end
    un(no_un_idx) = 1;
    beta_notravel = var_ind_beta_un(data_4_s(:, 1:reference_day), passengerFlow, best_param_list_no(:, 3)*0.1, best_param_list_no(:, 1), un, popu, best_param_list_no(:, 2), 0, compute_region);
    beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, compute_region);
    disp('trained reported cases');
    alpha_l = MAPEtable_notravel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
    k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
    jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
    beta_notravel_f = var_ind_beta_un(data_4_s(:, 1:reference_day), passengerFlow*0, alpha_l, k_l, un, popu, jp_l, 0, compute_region);
    
    base_infec = data_4(:, T_full);
    
    infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec);
    infec_released_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_notravel, popu, best_param_list_no(:, 1), horizon, best_param_list_no(:, 2), un, base_infec);
    disp('predicted reported cases');
    k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
    jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
    infec_released_f_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_notravel_f, popu, k_l, horizon, jp_l, un, base_infec);
    
    infec_released_avg = 0.5*(infec_released_f_un + infec_released_un);
    
    infec_data = [data_4_s(:, 1:T_full), infec_un];
    infec_data_released = [data_4_s(:, 1:T_full), infec_released_f_un];
    base_deaths = deaths(:, T_full);
    
    [death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin, 0, compute_region);
    disp('trained deaths');
    
    [pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
    [pred_deaths_released] = var_simulate_deaths(infec_data_released, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);

    disp('predicted deaths');
    
    un = un_array(un_id);
    eval(['deaths_un_' num2str(un) '= pred_deaths;']);
    eval(['infec_un_' num2str(un) '= infec_un;']);    
    
    startdate = datetime(2020, 1, 23) + caldays(T_full);
    file_suffix = num2str(un_array(un_id)); % Factor for unreported cases
    writetable(infec2table(infec_un, cellstr(num2str(FIP_data.FIPS)), bad_idx, startdate), [file_prefix '_forecasts_quarantine_' file_suffix '.csv']);
    writetable(infec2table(0.5*(infec_released_un+infec_released_f_un), cellstr(num2str(FIP_data.FIPS)), bad_idx|lowidx, startdate), [file_prefix '_forecasts_released_avg_' file_suffix '.csv']);
    writetable(infec2table(pred_deaths, cellstr(num2str(FIP_data.FIPS)), bad_idx, startdate), [file_prefix '_deaths_quarantine_' file_suffix '.csv']);
    writetable(infec2table(pred_deaths_released, cellstr(num2str(FIP_data.FIPS)), bad_idx|lowidx, startdate), [file_prefix '_deaths_released_' file_suffix '.csv']);
end


disp('Finished updating county forecasts');
toc