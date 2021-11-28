clear;
addpath('./utils/');
addpath('./scenario_projections/');
load_data_global;
load variants_global.mat

smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor/2);
deaths_s = smooth_epidata(deaths, smooth_factor);
% %%
% G_vacc_one = readtable('../results/forecasts/G_vacc_person.csv');
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
equiv_vacc_effi = 0.85;
vacc_fd = smooth_epidata(vacc_fd, 1);
for cid=1:length(countries)
    idx = vacc_fd(cid, :)./popu(cid) > 1;
    vacc_fd(cid, idx) = popu(cid);
end

vacc_future = get_vacc_preds(vacc_fd, popu, horizon);

vacc_effect = vacc_future*equiv_vacc_effi;
vac_effect_all = [zeros(length(countries), 14) vacc_future(:, 1:end-14)]*equiv_vacc_effi;
vac_effect_all = smooth_epidata(vac_effect_all, 7);
%% hyperparameters
best_param_list_v = zeros(ns, 3);
best_param_list_v(:, 1) = 3; best_param_list_v(:, 2) = 7; best_param_list_v(:, 3) = 9;
k_l = best_param_list_v(:, 1); jp_l = best_param_list_v(:, 2);
T_full = size(data_4, 2);
[best_death_hyperparam, one_hyperparam] = death_hyperparams(deaths, data_4_s, deaths_s, T_full, 7, popu, 0, best_param_list_v, un);

%% Create death rates
dlag_list = [0 7 14];

dalpha = 0.9;
dk = best_death_hyperparam(:, 1);
djp = best_death_hyperparam(:, 2);
dwin = best_death_hyperparam(:, 3);
lags = best_death_hyperparam(:, 4);
for j=1:length(dlag_list)
    [death_rates] = var_ind_deaths(data_4_s(:, 1:end-dlag_list(j)), deaths_s(:, 1:end-dlag_list(j)), dalpha, dk, djp, dwin, 0, popu>-1, lags);
    death_rates_list{j} = death_rates;
end


%% Fit transmission rates
% Readjust bounds to focus on uncertainty in the most prevelant strain
for cid=1:length(countries)
    [~, delta_idx] = max(squeeze(var_frac_all(cid, :, end)));
    xx = var_frac_all_low(cid, delta_idx, :);
    var_frac_all_low(cid, :, :) = var_frac_all(cid, :, :).*(1 - xx)./(1 - var_frac_all(cid, delta_idx, :));
    var_frac_all_low(cid, delta_idx, :) = xx;
    
    xx = var_frac_all_high(cid, delta_idx, :);
    var_frac_all_high(cid, :, :) = var_frac_all(cid, :, :).*(1 - xx)./(1 - var_frac_all(cid, delta_idx, :));
    var_frac_all_high(cid, delta_idx, :) = xx;
end
drate_smooth = 14;
rate_smooth = 14;
rlag_list = [0 0 0 1 2];
lag_list = [0];
un_list = [1 2 3]; un_array = [1.5 1.75 2].*ones(length(countries), 1);
var_prev_q = [1 2 3];
[X1, X2, X3, X4] = ndgrid(un_list, lag_list, var_prev_q, rlag_list);
scen_list = [X1(:), X2(:), X3(:) X4(:)];


%%
var_frac_range{1} = var_frac_all_low./nansum(var_frac_all_low, 2);
var_frac_range{3} = var_frac_all_high./nansum(var_frac_all_high, 2);
var_frac_range{2} = var_frac_all;
net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(size(scen_list, 1)*length(dlag_list), size(data_4, 1), horizon);
net_d_cell = cell(size(scen_list, 1), 1);

% ns = length(popu);
% best_param_list_v = zeros(ns, 3);
% best_param_list_v(:, 1) = 2; best_param_list_v(:, 2) = 7; best_param_list_v(:, 3) = 9;
% var_frac_this = var_frac_range{2};
% base_betas = cell(length(un_list), 1);
% 
% for uu = 1:length(un_list)
%     var_frac_this(isnan(var_frac_this)) = 0;
%     all_betas = cell(length(lineages), 1);
%     un = un_array(:, uu);
%     no_un_idx = (un.*data_4(:, end)+vacc_effect(:, 1))./popu > 0.9;
%     un(no_un_idx) = 1;
% 
%     for l=1:length(lineages)
%         variant_fact = squeeze(var_frac_this(:, l, :));
%         data_var_s = cumsum([zeros(ns, 1) diff(data_4_s')'].*(variant_fact), 2);
%         compute_region = popu > -1;
%         all_betas{l} = var_ind_beta_un(data_var_s(:, :), 0, best_param_list_v(:, 3)*0.1, best_param_list_v(:, 1), un, popu, best_param_list_v(:, 2), 0, compute_region, 50, vacc_pre_immunity + un.*(data_4_s - data_var_s));
%     end
%     base_betas{uu} = all_betas;
% end

%%

tic;
parfor simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1));
    no_un_idx = (un.*data_4(:, end)+vacc_effect(:, 1))./popu > 0.9;
    un(no_un_idx) = 1;

    ll = scen_list(simnum, 2);
    rl = scen_list(simnum, 4);
    dom_idx = scen_list(simnum, 3); 
    
    compute_region = popu > -1;
    
    % Cases
    
    % Fit variants transmission rates
    ns = length(popu);
    var_frac_this = var_frac_range{dom_idx};
    var_frac_this(isnan(var_frac_this)) = 0;
    all_betas = cell(length(lineages), 1);
    all_data_vars0 = cell(length(lineages), 1);
    all_data_vars = zeros(length(popu), length(lineages), size(data_4, 2));
    for l=1:length(lineages)
        variant_fact = squeeze(var_frac_all(:, l, :));
        data_var_s = cumsum([zeros(ns, 1) diff(data_4_s')'].*(variant_fact), 2);
        all_data_vars0{l} = data_var_s;
        all_data_vars(:, l, :) =  data_var_s;
    end
    
    rate_change = nan(length(popu), horizon);
    rate_change(:, 1) = 1;
    rate_change(:, end) = 1;
    rate_change = fillmissing(rate_change, 'linear', 2);
    
    
    [all_betas, ~, ~] = multivar_beta_wan(all_data_vars(:, :, 1:(end-7*rl)), 0, popu, k_l, 0.9, jp_l, un, vac_effect_all);

    base_infec = data_4;
   
    [infec, ~, deltemp, ~] = multivar_simulate_pred_wan(all_data_vars, 0, ...
        all_betas, popu, k_l, horizon, jp_l, un, base_infec, vac_effect_all, rate_change);

    all_data_vars_matrix = cumsum(squeeze(sum(deltemp, 4)), 3);
    
    
    T_full = size(data_4, 2);
    infec_data = squeeze(sum(all_data_vars_matrix, 2));
    infec_data = smooth_epidata(infec_data, 7);
    infec_net = infec_data(:, T_full+1:end) - data_4_s(:, end-7*ll) + data_4(:, end-7*ll);
    net_infec_0(simnum, :, :) = infec_net;
    
    % Deaths
    temp_res = zeros(length(dlag_list), length(countries), horizon);
    for jj = 1:length(dlag_list)
        death_rates = death_rates_list{1};
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        dh_rate_change = intermed_betas(death_rates, best_death_hyperparam, death_rates_list{jj}, best_death_hyperparam, drate_smooth);
        [pred_deaths] = var_simulate_deaths_vac(infec_data, death_rates, dk, djp, horizon+10, base_deaths, T_full-1, dh_rate_change);
        temp_res(jj, :, :) = pred_deaths(:, 1:horizon);
    end
    net_d_cell{simnum} = temp_res;
    fprintf('.');
end
 for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:length(dlag_list)-1]*size(scen_list, 1);
    net_death_0(idx, :, :) = net_d_cell{simnum};
end                       
base_deaths = deaths(:, T_full);
base_infec = data_4(:, T_full);
toc
%%
infec_un_0 = squeeze(trimmean(net_infec_0, 90, 1));
deaths_un_0 = squeeze(trimmean(net_death_0, 90, 1));

infec_un_lb = squeeze(min(net_infec_0, [], 1));
deaths_un_lb = squeeze(min(net_death_0, [], 1));

infec_un_ub = squeeze(max(net_infec_0, [], 1));
deaths_un_ub = squeeze(max(net_death_0, [], 1));

save global_results.mat net_death_0 net_infec_0 data_4 data_4_s popu countries best_death_hyperparam best_param_list* un_array;
%%
file_suffix = '0';
prefix = 'global';
file_prefix =  ['../results/forecasts/' prefix];
writetable(infec2table(infec_un_0, countries), [file_prefix '_forecasts_current_' file_suffix '.csv']);
writetable(infec2table(deaths_un_0, countries), [file_prefix '_deaths_current_' file_suffix '.csv']);

add_to_history;
disp('Files Written');

%%
now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end
lowidx = zeros(length(countries), 1);

writetable(infec2table(infec_un_lb, countries), [file_prefix '_forecasts_current_' file_suffix '_lb.csv']);
writetable(infec2table(deaths_un_lb, countries), [file_prefix '_deaths_current_' file_suffix '_lb.csv']);

writetable(infec2table(infec_un_ub, countries), [file_prefix '_forecasts_current_' file_suffix '_ub.csv']);
writetable(infec2table(deaths_un_ub, countries), [file_prefix '_deaths_current_' file_suffix '_ub.csv']);


writetable(infec2table([base_infec infec_un_lb], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases_lb.csv']);
writetable(infec2table([base_deaths deaths_un_lb], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths_lb.csv']);

writetable(infec2table([base_infec infec_un_ub], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases_ub.csv']);
writetable(infec2table([base_deaths deaths_un_ub], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths_ub.csv']);