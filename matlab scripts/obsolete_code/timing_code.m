load_data_county;

%%

alltime = tic;
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', 7, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', 7, 2), 2)];

un = 20; horizon = 100;
dk = 3; djp = 7; dalpha = 1; dwin = 50; dhorizon = 100;
T_full = size(data_4, 2);

%xx = tic;[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2)); toc(xx)
best_param_list =best_param_list_no;

for t=1:1
xx = tic; beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2)); thistime(t) = toc(xx);
end
mean(thistime)

for t=1:1
xx = tic; infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full),0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un); thistime(t) = toc(xx);
end
mean(thistime)

infec_data = [data_4_s(:, 1:T_full), infec_un];
base_deaths = deaths(:, T_full);

for t=1:1
xx = tic ; [death_rates] = var_ind_deaths(data_4, deaths, dalpha, dk, djp, dwin); thistime(t) = toc(xx);
end
mean(thistime)

for t=1:1
xx = tic; [pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1); thistime(t) = toc(xx);
end
mean(thistime)

toc(alltime)