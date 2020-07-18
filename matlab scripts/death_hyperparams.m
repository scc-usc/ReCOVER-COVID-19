function [best_death_hyperparam, one_hyperparam] = death_hyperparams(deaths, data_4_s, deaths_s, T_full, T_val, popu, passengerFlow, best_param_list, un, param_list)
dalpha = 1;
dkrange = (2:4);
djprange = [7];
dwin = [25, 50, 100];

T_tr = T_full-T_val;
best_death_hyperparam = zeros(size(deaths, 1), 3);

if nargin < 10
    [X, Y, Z] = meshgrid(dkrange, djprange, dwin);
    param_list = [X(:), Y(:), Z(:)];
    idx = (param_list(:, 1).*param_list(:, 2) <=21) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2));
    param_list = param_list(idx, :);
end
RMSE_all = zeros(size(deaths, 1), size(param_list, 1));

for ii = 1:size(param_list, 1)
    dk = param_list(ii, 1);
    djp = param_list(ii, 2);
    dwin = param_list(ii, 3);
    
    [death_rates] = var_ind_deaths(data_4_s(:, 1:T_tr), deaths_s(:, 1:T_tr), dalpha, dk, djp, dwin);   
    
    beta_after = var_ind_beta_un(data_4_s(:, 1:T_tr), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2));
    infec_un = var_simulate_pred_un(data_4_s(:, 1:T_tr), passengerFlow*0, beta_after, popu, best_param_list(:, 1), 2*T_val, best_param_list(:, 2), un);
        
    infec_data = [data_4_s(:,1:T_tr) infec_un];
    base_deaths = deaths(:, T_tr);
    [pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, T_val+1, base_deaths, T_tr-1);
    gtruth = diff(deaths(:, T_tr:T_tr+T_val)')';
    predvals = diff([base_deaths pred_deaths(:, 1:T_val)]')';
    
    [~, ~, thisrmse] = calc_errors(gtruth, predvals, 7);
    %thisrmse = sum((gtruth - predvals).^2, 2);
    
    RMSE_all(:, ii) = thisrmse;
    fprintf('.');
end

% Pick best for each region

for jj=1:size(deaths, 1)
    [~, ii] = min(RMSE_all(jj, :));
    best_death_hyperparam(jj, :) = param_list(ii, :);
end

[minval, ii] = min(sqrt(nanmean(RMSE_all, 1)));
one_hyperparam = param_list(ii, :);