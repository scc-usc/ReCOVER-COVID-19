function [best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, passengerFlow, un, T_full)
% Script to identify optimal hyperparameters of the model
%% Configure

T_val = 7;
T_tr = T_full - T_val; % Jan 21 is day 0

k_array = (1:4);
jp_array = (7:7:14);
ff_array = (5:10);

[X, Y, Z] = meshgrid(k_array, jp_array, ff_array);
param_list = [X(:), Y(:), Z(:)];

idx = param_list(:, 1).*param_list(:, 2) <=14;
param_list = param_list(idx, :);

RMSE_all = zeros(size(data_4, 1), size(param_list, 1));

%% Full
inf_thres = -1;

for ii = 1:size(param_list, 1)
    
    k = param_list(ii, 1);
    jp = param_list(ii, 2);
    alpha = 0.1*param_list(ii, 3);
    F_notravel = 0;
    F_travel = passengerFlow;
    
    %            beta_withtravel = var_ind_beta(data_4_s(:, 1:T_tr), F_travel, ones(sum(cidx), 1)*alpha, ones(sum(cidx), 1)*k, T_tr, popu(cidx), ones(sum(cidx), 1)*jp);
    %            infec_travel = var_simulate_pred(data_4_s(:, 1:T_tr), F_travel, beta_withtravel, popu(cidx), ones(sum(cidx), 1)*k, T_val, ones(sum(cidx), 1)*jp);
    beta_notravel = var_ind_beta_un(data_4_s(:, 1:T_tr), F_notravel, alpha, k, un, popu, jp);
    infec_notravel = var_simulate_pred_un(data_4_s(:, 1:T_tr), F_notravel, beta_notravel, popu, k, T_val, jp, un);
    RMSE_all(:, ii) = sum((data_4(:, T_tr+1 : T_tr + T_val) -  infec_notravel).^2, 2);
    
    fprintf('.');
end
fprintf('\n');


%% Identify best param per country
best_param_list = zeros(length(popu), 3);
for jj=1:length(popu)
    [~, ii] = min(RMSE_all(jj, :));
    best_param_list(jj, :) = param_list(ii, :);
end
    
%% Identify single best params
xx = nanmean(RMSE_all, 1);
[~, ii] = min(xx);
MAPEtable_s = param_list(ii, :);
