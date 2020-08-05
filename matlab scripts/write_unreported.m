% Writes forecasts to files with various scenarios of unreported cases

file_prefix =  ['../results/forecasts/' prefix];  % edit this to change the destination
T_full = size(data_4, 2); % Consider all data for predictions
un_array = [1, 2, 5, 10, 20, 40]; % Select the ratio of total to reported cases
horizon = 100; % days of predcitions
dhorizon = horizon;
passengerFlow = 0; % No travel considered

%% Identify best and worst infection rates from the past
% Assumes that "generate_score" is run once a week
start_day = 52; skip_length = 7;
[beta_best, beta_worst, param_best, param_worst, Rt_mat] = best_and_worst((start_day:skip_length:(size(data_4, 2))-2), prefix);
%%
base_infec = data_4(:, T_full);
compute_region = popu > -1; % Compute for all regions!
for un_id = 1:length(un_array)
    
    un = un_array(un_id); % Select the ratio of true cases to reported cases. 1 for default.
    
    % Current trend prediction
    beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, compute_region);
    infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec);
       
    % Predict for released or restricted
        
    infec_released_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_worst, popu, param_worst(:, 1), horizon, param_worst(:, 2), un, base_infec);
    infec_restricted_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_best, popu, param_best(:, 1), horizon, param_best(:, 2), un, base_infec);
    
    disp('predicted reported cases');
    
    infec_un_re = infec_un - repmat(base_infec - data_4_s(:, T_full), [1, size(infec_un, 2)]);
    infec_data = [data_4_s(:, 1:T_full), infec_un_re];
    infec_data_released = [data_4_s(:, 1:T_full), infec_released_un];
    infec_data_restricted = [data_4_s(:, 1:T_full), infec_restricted_un];
    base_deaths = deaths(:, T_full);
    
    [death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin, 0, compute_region);
    disp('trained deaths');
    
    [pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
    [pred_deaths_released] = var_simulate_deaths(infec_data_released, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
    [pred_deaths_restricted] = var_simulate_deaths(infec_data_restricted, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);

    disp('predicted deaths');
    
    % Store values for later analysis
    eval(['deaths_un_' num2str(un) '= pred_deaths;']);
    eval(['infec_un_' num2str(un) '= infec_un;']);
    eval(['deaths_released_un_' num2str(un) '= pred_deaths_released;']);
    eval(['deaths_restricted_un_' num2str(un) '= pred_deaths_restricted;']);
    
    file_suffix = num2str(un); % Factor for unreported cases
    
    writetable(infec2table(infec_un, countries), [file_prefix '_forecasts_current_' file_suffix '.csv']);
    writetable(infec2table(infec_released_un, countries, lowidx), [file_prefix '_forecasts_released_' file_suffix '.csv']);
    writetable(infec2table(infec_restricted_un, countries, lowidx), [file_prefix '_forecasts_restricted_' file_suffix '.csv']);
    
    writetable(infec2table(pred_deaths, countries), [file_prefix '_deaths_current_' file_suffix '.csv']);
    writetable(infec2table(pred_deaths_released, countries, lowidx), [file_prefix '_deaths_released_' file_suffix '.csv']);
    writetable(infec2table(pred_deaths_restricted, countries, lowidx), [file_prefix '_deaths_restricted_' file_suffix '.csv']);

    
    disp(['Files written for ', num2str(un)]);
    
end