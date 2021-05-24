% G_vacc_one = readtable('../results/forecasts/G_vacc_person.csv');
load_data_global;
% %%
% all_cidx = contains(G_vacc_one.Var2, '|||');
% G_countries = G_vacc_one.Var2(all_cidx);
% G_countries = strrep(G_countries, '|||', '');
% G_countries1 = strrep(G_countries, 'United States of America', 'US');
% 
% countries1 = readcell('ihme_global.txt');
% 
% [aa1, bb1] = ismember(countries1, G_countries1);
% [aa, bb] = ismember(countries, G_countries1);
% 
% bb(aa==0 & aa1==1) = bb1(aa==0 & aa1==1);
% %%
% vacc_one = zeros(size(data_4));
% G_vacc = G_vacc_one{all_cidx, 3:end-1};
% vlen = size(G_vacc, 2);
% for cid = 1:length(countries)
%     if bb(cid)==0
%         continue;
%     end
%     vacc_one((cid), end-vlen+1:end) = G_vacc(bb(cid), :);
% end

%% Prepare vaccine data
xx = load('vacc_data.mat');
%nidx = isnan(latest_vac); latest_vac(nidx) = popu(nidx).*(mean(latest_vac(~nidx))/mean(popu(~nidx)));
vacc_lag_rate = ones(length(popu), 14);
vacc_ad_dist(:) = 1; 
vacc_all = xx.g_vacc(:, 1:end); vacc_full = xx.g_vacc_full(:, 1:end); 
vacc_all = fillmissing(vacc_all, 'previous', 2); vacc_all(isnan(vacc_all)) = 0;
vacc_full = fillmissing(vacc_full, 'previous', 2); vacc_full(isnan(vacc_full)) = 0;

vacc_fd = vacc_all - vacc_full;

vacc_fd = [zeros(size(data_4, 1), size(data_4, 2)-size(vacc_fd, 2)), vacc_fd];
latest_vac = vacc_fd(:, end);


%%
horizon = 100; 
un = 2*ones(length(countries), 1);
no_un_idx = un.*data_4(:, end)./popu > 0.2;
un(no_un_idx) = 1;
equiv_vacc_effi = 0.75;

vacc_pre_immunity = equiv_vacc_effi*((1 - un.*data_4./popu).*vacc_fd);
vacc_per_day = (vacc_fd(:, end) - vacc_fd(:, end-14))/14;
vacc_future  = vacc_fd(:, end) + cumsum(vacc_per_day*ones(1, horizon), 2);
vac_effect = vacc_future*equiv_vacc_effi;
%%
smooth_factor = 14; rate_change = ones(length(popu), horizon);
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

best_param_list = zeros(length(countries), 3);
best_param_list(:, 1) = 2; best_param_list(:, 2) = 7; best_param_list(:, 3) = 8;
compute_region = popu > -1;
base_infec = data_4(:, end);

beta_after= var_ind_beta_un(data_4_s, 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, compute_region, [], vacc_pre_immunity);
infec_un_0 = var_simulate_pred_vac(data_4_s, 0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec, vac_effect);

%% Death Forecasts
load global_hyperparam_latest.mat;
dk = best_death_hyperparam(:, 1);
djp = best_death_hyperparam(:, 2);
dwin = best_death_hyperparam(:, 3);
lags = best_death_hyperparam(:, 4);
dalpha = 1;
dhorizon = 100;
T_full = size(data_4, 2);
base_deaths = deaths(:, T_full);
infec_data = [data_4_s infec_un_0];
[death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin, 0, compute_region, lags);
[deaths_un_0] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
%%
file_suffix = '0';
prefix = 'global';
file_prefix =  ['../results/forecasts/' prefix];
writetable(infec2table(infec_un_0, countries), [file_prefix '_forecasts_current_' file_suffix '.csv']);
writetable(infec2table(deaths_un_0, countries), [file_prefix '_deaths_current_' file_suffix '.csv']);

add_to_history;
disp('Files Written');
    