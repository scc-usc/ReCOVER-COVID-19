
clear; warning off;
load variants.mat
CDC_sero;

smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor/2, 0);
deaths_s = smooth_epidata(deaths, smooth_factor/2);
horizon = 100;
%% Vaccine data

xx = load('vacc_data.mat');
un = un_array(:, 2);
vacc_effi1 = 0.5; vacc_effi2 = 0.9 - vacc_effi1;
vacc_all = xx.u_vacc(:, 1:end); vacc_full = xx.u_vacc_full(:, 1:end); 
vacc_all = fillmissing(vacc_all, 'previous', 2); vacc_all(isnan(vacc_all)) = 0;
vacc_full = fillmissing(vacc_full, 'previous', 2); vacc_full(isnan(vacc_full)) = 0;
vacc_fd = vacc_all - vacc_full; vacc_fd(:, end-14:end) = [];
vacc_fd = [zeros(size(data_4, 1), size(data_4, 2)-size(vacc_fd, 2)), vacc_fd];
vac_effect = vacc_fd*vacc_effi1 + [zeros(ns, 28), vacc_fd(:, 1:end-28)]*vacc_effi2;

vacc_pre_immunity = [(1 - un.*data_4./popu).*vac_effect(:, 1:size(data_4, 2))];
vacc_pre_immunity = vacc_pre_immunity(:, 1:size(data_4, 2));

elig_frac = 0.81;
vacc_ffd = vacc_fd(:, end) + (1:60).*(elig_frac*0.8.*popu - vacc_fd(:, end))./60;
vacc_effect = vacc_ffd*vacc_effi1 + [vacc_fd(:, end-27:end), vacc_ffd(:, 1:end-28)]*vacc_effi2;
vacc_effect = [vacc_effect, repmat(vacc_effect(:, end), [1 (horizon - size(vacc_effect, 2))])];

%% hyperparameters
best_param_list_v = zeros(ns, 3);
best_param_list_v(:, 1) = 2; best_param_list_v(:, 2) = 7; best_param_list_v(:, 3) = 8;
T_full = size(data_4, 2);
[best_death_hyperparam, one_hyperparam] = death_hyperparams(deaths, data_4_s, deaths_s, T_full, 7, popu, 0, best_param_list_v, un);


%% Create death rates
dlag_list = [0 3 7 10 14];
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

% Readjust bounds to focus on uncertainty in delta
delta_idx = find(strcmpi(lineages, 'B.1.617.2'));
xx = var_frac_all_low(:, delta_idx, :);
var_frac_all_low = var_frac_all.*(1 - xx)./(1 - var_frac_all(:, delta_idx, :));
var_frac_all_low(:, delta_idx, :) = xx;

xx = var_frac_all_high(:, delta_idx, :);
var_frac_all_high = var_frac_all.*(1 - xx)./(1 - var_frac_all(:, delta_idx, :));
var_frac_all_high(:, delta_idx, :) = xx;

drate_smooth = 7;
rate_smooth = 14;
rlag_list = [0:1:2];
lag_list = [0:-1:0];
un_list = [1 3 2];
var_prev_q = [1 3 2];
[X1, X2, X3, X4] = ndgrid(un_list, lag_list, var_prev_q, rlag_list);
scen_list = [X1(:), X2(:), X3(:) X4(:)];


%%
var_frac_range{1} = var_frac_all_low./(1e-10 + nansum(var_frac_all_low, 2));
var_frac_range{3} = var_frac_all_high./nansum(var_frac_all_high, 2);
var_frac_range{2} = var_frac_all;

for dom_idx=1:3
    var_frac_range{dom_idx}(isnan(var_frac_range{dom_idx})) = 0;
end


net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(size(scen_list, 1)*length(dlag_list), size(data_4, 1), horizon);

for simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1));
    ll = scen_list(simnum, 2);
    rl = scen_list(simnum, 4);
    dom_idx = scen_list(simnum, 3); 
    
    compute_region = popu > -1;
    
    % Cases
    
    % Fit variants transmission rates
    ns = length(popu);
    best_param_list_v = zeros(ns, 3);
    best_param_list_v(:, 1) = 2; best_param_list_v(:, 2) = 7; best_param_list_v(:, 3) = 9;
    var_frac_this = var_frac_range{dom_idx};
    all_betas = cell(length(lineages), 1);
    all_data_vars0 = cell(length(lineages), 1);
    %all_data_vars = zeros(length(popu), length(lineages), size(data_4, 2));
    for l=1:length(lineages)
        variant_fact = squeeze(var_frac_this(:, l, :));
        data_var_s = cumsum([zeros(ns, 1) diff(data_4_s')'].*(variant_fact), 2);
        all_data_vars0{l} = data_var_s(:, 1:end-7*ll);
        compute_region = popu > -1;
        all_betas{l} = var_ind_beta_un(data_var_s(:, 1:(end-7*(rl))), 0, best_param_list_v(:, 3)*0.1, best_param_list_v(:, 1), un, popu, best_param_list_v(:, 2), 0, compute_region, 50, vacc_pre_immunity + un.*(data_4_s - data_var_s));
    end
    
    if abs(rl) < 0.5 % rl == 0
        base_betas = all_betas;
    end
    
    rate_change = nan(length(popu), horizon);
    rate_change(:, 1) = 1;
    rate_change(:, end) = 1;
    rate_change = fillmissing(rate_change, 'linear', 2);
    
    all_data_vars = all_data_vars0;
    new_horizon = horizon + 7*ll;
    this_horizon = 2;
    infec_var = []; total_infec = data_4(:, end - 7*ll);
    while new_horizon > 0
        this_horizon = min([this_horizon; new_horizon]);
        new_infec = 0;
        for l=1:length(lineages)
            variant_fact = squeeze(var_frac_this(:, l, :));
            this_vac_effect = vacc_effect(:, (1+7*ll+horizon-new_horizon):(horizon+7*ll));
            these_betas = all_betas{l};
            this_data_var = all_data_vars{l};
            base_infec = total_infec;
            rate_change = intermed_betas(base_betas{l}, best_param_list_v, these_betas, best_param_list_v, rate_smooth);
            this_infec_var = var_simulate_pred_vac(this_data_var, 0, base_betas{l},...
                popu, best_param_list_v(:, 1), this_horizon, best_param_list_v(:, 2), un, ...
                base_infec, this_vac_effect, rate_change);
            this_infec_var = this_infec_var - total_infec + this_data_var(:, end);
            all_data_vars{l} = [this_data_var this_infec_var];
            new_infec = new_infec + this_infec_var(:, end) - this_data_var(:, end);
        end
        new_horizon = new_horizon - this_horizon;
        total_infec = total_infec + new_infec;
        %fprintf('.');
    end
    
    all_data_vars_matrix = zeros(length(popu), length(lineages), size(data_4, 2)+horizon);
    for l=1:length(lineages)
        all_data_vars_matrix(:, l, :) = all_data_vars{l};
    end
    T_full = size(data_4, 2);
    infec_data = squeeze(sum(all_data_vars_matrix, 2));
    infec_net = infec_data(:, T_full+1:end) - data_4_s(:, end-7*ll) + data_4(:, end-7*ll);
    net_infec_0(simnum, :, :) = infec_net;
    
    % Deaths
    for jj = 1:length(death_rates_list)
        death_rates = death_rates_list{1};
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        dh_rate_change = intermed_betas(death_rates, best_death_hyperparam, death_rates_list{jj}, best_death_hyperparam, drate_smooth);
        [pred_deaths] = var_simulate_deaths_vac(infec_data, death_rates, dk, djp, horizon+10, base_deaths, T_full-1, dh_rate_change);
        net_death_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_deaths(:, 1:horizon);
    end
    fprintf('.');
end

%%
infec_un_0 = squeeze(nanmean(net_infec_0, 1));
deaths_un_0 = squeeze(nanmean(net_death_0, 1));

save us_results.mat net_death_0 net_infec_0 data_4 data_4_s popu countries best_death_hyperparam best_param_list* un_array;
%%
file_suffix = '0';
prefix = 'us';
file_prefix =  ['../results/forecasts/' prefix];
writetable(infec2table(infec_un_0, countries), [file_prefix '_forecasts_current_' file_suffix '.csv']);
writetable(infec2table(deaths_un_0, countries), [file_prefix '_deaths_current_' file_suffix '.csv']);

add_to_history;
disp('Files Written');