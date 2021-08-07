net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(size(scen_list, 1)*length(lags_list), size(data_4, 1), horizon);
net_hosp_0 = zeros(size(scen_list, 1)*length(lags_list), size(data_4, 1), horizon);
net_var_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);

for simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1));
    lags = scen_list(simnum, 2);
    %beta_after = var_ind_beta_un(data_4_s(:, 1:end-lags), 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, popu>-1);
    j = find(lags_list==lags); uid = find(un_list==scen_list(simnum, 1));
    %beta_after = infec_rates_list{j(1)}{uid(1)};
    
    vac_distributed_ts = squeeze(sum(vacc_given_by_age, 3));
    all_vacc_ts = [vacc_fd vac_distributed_ts];
    
    vac_effect_all = all_vacc_ts*vacc_effi1 + [zeros(length(popu), 28), all_vacc_ts(:, 29:end)]*vacc_effi2;
    vac_effect = vac_effect_all(:, (size(data_4, 2)-size(vacc_lag_rate, 2)+1):(size(data_4, 2)-size(vacc_lag_rate, 2)+horizon));
    vacc_pre_immunity = [vacc_lag_rate*0, (1 - un.*data_4./popu).*vac_effect_all(:, 1:size(data_4, 2))];
    vacc_pre_immunity = vacc_pre_immunity(:, 1:size(data_4, 2));
    
    vac_effect_all_delta = all_vacc_ts*vacc_effi1_delta + [zeros(length(popu), 28), all_vacc_ts(:, 29:end)]*vacc_effi2_delta;
    vac_effect_delta = vac_effect_all_delta(:, (size(data_4, 2)-size(vacc_lag_rate, 2)+1):(size(data_4, 2)-size(vacc_lag_rate, 2)+horizon));
    
    
    dom_idx = scen_list(simnum, 4); 
    ll = scen_list(simnum, 2);
    compute_region = popu > -1;
    
    %%% Cases
    
    % Fit variants transmission rates
    ns = length(popu);
    best_param_list_v = zeros(ns, 3);
    best_param_list_v(:, 1) = 2; best_param_list_v(:, 2) = 7; best_param_list_v(:, 3) = 9;
    var_frac_all = var_frac_range{dom_idx};
    all_betas = cell(length(lineages), 1);
    all_data_vars0 = cell(length(lineages), 1);
    %all_data_vars = zeros(length(popu), length(lineages), size(data_4, 2));
    for l=1:length(lineages)
        variant_fact = squeeze(var_frac_all(:, l, :));
        data_var_s = cumsum([zeros(ns, 1) diff(data_4_s')'].*(variant_fact), 2);
        all_data_vars0{l} = data_var_s;
        compute_region = popu > -1;
        all_betas{l} = var_ind_beta_un(data_var_s(:, 1:(end-7*(ll))), 0, best_param_list_v(:, 3)*0.1, best_param_list_v(:, 1), un, popu, best_param_list_v(:, 2), 0, compute_region, [], vacc_pre_immunity + un.*(data_4_s - data_var_s));
    end
    
    rate_change = nan(length(popu), horizon);
    rate_change(:, 1) = 1;
    rate_change(:, end) = Target_Rt(:, scen_list(simnum, 6))./current_Rt(:, scen_list(simnum, 5));
    rate_change = fillmissing(rate_change, 'linear', 2);
    
    base_beta = all_betas{b117_idx}; missing_b117 = valid_lins(:, b117_idx)<1;
    base_beta(missing_b117) = all_betas{other_idx}(missing_b117);
    delta_beta = cellfun(@(x)(trans_adv*x), base_beta, 'UniformOutput', false);
    
    all_data_vars = all_data_vars0;
    new_horizon = horizon;
    this_horizon = 2;
    infec_var = []; total_infec = data_4(:, end);
    while new_horizon > 0
        this_horizon = min([this_horizon; new_horizon]);
        new_infec = 0;
        for l=1:length(lineages)
            variant_fact = squeeze(var_frac_all(:, l, :));
            if l == delta_idx
                this_vac_effect = vac_effect_delta(:, 1+horizon-new_horizon:horizon);
                these_betas = delta_beta;
            else
                this_vac_effect = vac_effect(:, 1+horizon-new_horizon:horizon);
                these_betas = all_betas{l};
            end
            this_data_var = all_data_vars{l};
            base_infec = total_infec;
            this_infec_var = var_simulate_pred_vac(this_data_var, 0, these_betas,...
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
    infec_net = infec_data(:, T_full+1:end) - data_4_s(:, end) + data_4(:, end);
    infec_var = squeeze(all_data_vars_matrix(:, delta_idx, T_full+1:end));
    net_infec_0(simnum, :, :) = infec_net;
    net_var_0(simnum, :, :) = infec_var;
    
    
    % Changing death rates and hospitlization rates is no longer necessary
    dh_rate_change(:) = 1; h_rate_change(:) = 1;
    
    % Deaths
    for jj = 1:length(death_rates_list)
        death_rates = death_rates_list{1};
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        dh_rate_change = intermed_betas(death_rates, best_death_hyperparam, death_rates_list{jj}, best_death_hyperparam, rate_smooth);
        [pred_deaths] = var_simulate_deaths_vac(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1, dh_rate_change);
        net_death_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_deaths(:, 1:horizon);
    end
    % Hosp
    for jj = 1:length(hosp_rates_list)
        hosp_rates = hosp_rates_list{1};
        T_full = hosp_data_limit;
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        base_hosp = hosp_cumu(:, T_full);
        h_rate_change = intermed_betas(hosp_rates, best_hosp_hyperparam, hosp_rates_list{jj}, best_hosp_hyperparam, rate_smooth);
        pred_hosps = var_simulate_deaths_vac(infec_data, hosp_rates, hk, hjp, hhorizon, base_hosp, T_full-1, h_rate_change);
        h_start = size(data_4, 2)-T_full+1;
        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
    end
    fprintf('.');
end
fprintf('\n');