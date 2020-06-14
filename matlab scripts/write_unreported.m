% Writes forecasts to files with various scenarios of unreported cases

file_prefix =  ['../results/forecasts/' prefix];  % edit this to change the destination

un_array = [1, 2, 5, 10, 20, 40]; % Select the ratio of total to reported cases
horizon = 100; % days of predcitions

for un_id = 1:length(un_array)
    % Train with hyperparams before and after
    un = un_array(un_id); % Select the ratio of true cases to reported cases. 1 for default.
    
    beta_notravel = var_ind_beta_un(data_4_s(:, 1:T_tr), passengerFlow*0, best_param_list_no(:, 3)*0.1, best_param_list_no(:, 1), un, popu, best_param_list_no(:, 2));
    beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2));
        
    alpha_l = MAPEtable_notravel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
    k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
    jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
    beta_notravel_f = var_ind_beta_un(data_4_s(:, 1:T_tr), passengerFlow*0, alpha_l, k_l, un, popu, jp_l);
    
    alpha_l = MAPEtable_s(1, 3)*0.1*ones(length(popu), 1);
    k_l = MAPEtable_s(1, 1)*ones(length(popu), 1);
    jp_l = MAPEtable_s(1, 2)*ones(length(popu), 1);
    beta_after_f = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, alpha_l, k_l, un, popu, jp_l);
    
    disp('trained');
    
    % Predict with unreported cases
    
    infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un);
    infec_released_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_notravel, popu, best_param_list_no(:, 1), horizon, best_param_list_no(:, 2), un);
    
    k_l = MAPEtable_s(1, 1)*ones(length(popu), 1);
    jp_l = MAPEtable_s(1, 2)*ones(length(popu), 1);
    infec_f_un = var_simulate_pred_un(data_4(:, 1:T_full), passengerFlow*0, beta_after_f, popu, k_l, horizon, jp_l, un);
    
    k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
    jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
    infec_released_f_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_notravel_f, popu, k_l, horizon, jp_l, un);
    
    
    disp('predicted')
    
    file_suffix = num2str(un); % Factor for unreported cases
    writetable(infec2table(infec_un, countries), [file_prefix '_forecasts_quarantine_' file_suffix '.csv']);
    writetable(infec2table(infec_f_un, countries), [file_prefix '_forecasts_quarantine1_' file_suffix '.csv']);
    writetable(infec2table(0.5*(infec_f_un+infec_un), countries), [file_prefix '_forecasts_quarantine_avg_' file_suffix '.csv']);
    writetable(infec2table(infec_released_un, countries, lowidx), [file_prefix '_forecasts_released_' file_suffix '.csv']);
    writetable(infec2table(infec_released_f_un, countries, lowidx), [file_prefix '_forecasts_released1_' file_suffix '.csv']);
    writetable(infec2table(0.5*(infec_released_un+infec_released_f_un), countries, lowidx), [file_prefix '_forecasts_released_avg_' file_suffix '.csv']);
    
    disp(['Files written for ', num2str(un)]);
    
end