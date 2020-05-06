% Performs default forecasts not considering unreported cases

%% Set dates
%data_4_s = movmean(data_4, 2, 5);
data_4_s = data_4;
T_tr = 60; % Set reference day (Jan 21 is day 0)
T_full = size(data_4, 2); % Set reference day (Jan 21 is day 0)
%T_full = 80;
horizon = 100;

%% Train with hyperparams before and after
beta_travel = var_ind_beta(data_4_s(:, 1:T_tr), passengerFlow, best_param_list_yes(:, 3)*0.1, best_param_list_yes(:, 1), T_tr, popu, best_param_list_yes(:, 2));
beta_notravel = var_ind_beta(data_4_s(:, 1:T_tr), passengerFlow*0, best_param_list_no(:, 3)*0.1, best_param_list_no(:, 1), T_tr, popu, best_param_list_no(:, 2));
beta_after = var_ind_beta(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), T_tr, popu, best_param_list(:, 2));

alpha_l = MAPEtable_travel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_travel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_travel_fixed_s(1, 2)*ones(length(popu), 1);
beta_travel_f = var_ind_beta(data_4_s(:, 1:T_tr), passengerFlow, alpha_l, k_l, T_tr, popu, jp_l);

alpha_l = MAPEtable_notravel_fixed_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
beta_notravel_f = var_ind_beta(data_4_s(:, 1:T_tr), passengerFlow*0, alpha_l, k_l, T_tr, popu, jp_l);

alpha_l = MAPEtable_s(1, 3)*0.1*ones(length(popu), 1);
k_l = MAPEtable_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_s(1, 2)*ones(length(popu), 1);
beta_after_f = var_ind_beta(data_4_s(:, 1:T_full), passengerFlow*0, alpha_l, k_l, T_tr, popu, jp_l);

disp('trained');

%% Predict with hyperparams before and after
% infec_travel = var_simulate_pred(data_4(:, 1:T_tr), passengerFlow, beta_travel, popu, best_param_list_yes(:, 1), horizon, best_param_list_yes(:, 2));
% infec_notravel = var_simulate_pred(data_4(:, 1:T_tr), passengerFlow*0, beta_notravel, popu, best_param_list_no(:, 1), horizon, best_param_list_no(:, 2));

infec = var_simulate_pred(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2));
infec_released = var_simulate_pred(data_4_s(:, 1:T_full), passengerFlow*0, beta_notravel, popu, best_param_list_no(:, 1), horizon, best_param_list_no(:, 2));

k_l = MAPEtable_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_s(1, 2)*ones(length(popu), 1);
infec_f = var_simulate_pred(data_4(:, 1:T_full), passengerFlow*0, beta_after_f, popu, k_l, horizon, jp_l);

k_l = MAPEtable_notravel_fixed_s(1, 1)*ones(length(popu), 1);
jp_l = MAPEtable_notravel_fixed_s(1, 2)*ones(length(popu), 1);
infec_released_f = var_simulate_pred(data_4_s(:, 1:T_full), passengerFlow*0, beta_notravel_f, popu, k_l, horizon, jp_l);


disp('predicted')
