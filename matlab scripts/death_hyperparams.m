function best_death_hyperparam = death_hyperparams(deaths, data_4_s, deaths_s, T_full)
dalpha = 1;
dkrange = (1:4);
djprange = [7];
dwin = [25, 50, 100];
T_val = 7;
T_tr = T_full-T_val;
best_death_hyperparam = zeros(size(deaths, 1), 3);

[X, Y, Z] = meshgrid(dkrange, djprange, dwin);
param_list = [X(:), Y(:), Z(:)];
RMSE_all = zeros(size(deaths, 1), size(param_list, 1));

for ii = 1:size(param_list, 1)
    dk = param_list(ii, 1);
    djp = param_list(ii, 2);
    dwin = param_list(ii, 3);
    
    if dwin < djp*dk || djp*dk > 21
        RMSE_all(:, ii) = Inf;
        continue;
    end
    
    [death_rates] = var_ind_deaths(data_4_s(:, 1:T_tr), deaths_s(:, 1:T_tr), dalpha, dk, djp, dwin);
    base_deaths = deaths_s(:, T_tr);
    [pred_deaths] = var_simulate_deaths(data_4_s(:, 1: end), death_rates, dk, djp, T_val+1, base_deaths, T_tr-1);
    gtruth = diff(deaths(:, T_tr:T_tr+T_val)')';
    predvals = diff([base_deaths pred_deaths(:, 1:T_val)]')';
    
    [~, ~, thisrmse] = calc_errors(gtruth, predvals);
    %thisrmse = sum((gtruth - predvals).^2, 2);
    
    RMSE_all(:, ii) = thisrmse;
    fprintf('.');
end

% Pick best for each region

for jj=1:size(deaths, 1)
    [~, ii] = min(RMSE_all(jj, :));
    best_death_hyperparam(jj, :) = param_list(ii, :);
end
)