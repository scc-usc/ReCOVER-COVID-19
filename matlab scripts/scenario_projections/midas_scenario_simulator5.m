net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(size(scen_list, 1)*length(lags_list), size(data_4, 1), horizon);
net_hosp_0 = zeros(size(scen_list, 1)*length(lags_list), size(data_4, 1), horizon);

for simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1));
    lags = scen_list(simnum, 2);
    %beta_after = var_ind_beta_un(data_4_s(:, 1:end-lags), 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, popu>-1);
    j = find(lags_list==lags); uid = find(un_list==scen_list(simnum, 1));
    %beta_after = infec_rates_list{j(1)}{uid(1)};
    
    vac_distributed_ts = squeeze(sum(vacc_given_by_age, 3));
    vac_effect = [vacc_fd vac_distributed_ts]*equiv_vacc_effi;
    vac_effect = vac_effect(:, (size(data_4, 2)-size(vacc_lag_rate, 2)+1):(size(data_4, 2)-size(vacc_lag_rate, 2)+horizon));
    vacc_pre_immunity = [vacc_lag_rate*0 equiv_vacc_effi*((1 - un.*data_4./popu).*vacc_fd)];
    vacc_pre_immunity = vacc_pre_immunity(:, 1:size(data_4, 2));
    
    
    dom_idx = scen_list(simnum, 4);
    variant_fact = squeeze(variant_rt_change_list(dom_idx, :, :));
    data_var = cumsum([zeros(size(data_4_s, 1), 1) diff(data_4_s')'.*(variant_fact(:, 2:end))], 2);
    data_nvar = cumsum([zeros(size(data_4_s, 1), 1) diff(data_4_s')'.*(1 - variant_fact(:, 2:end))], 2);
    % variant_rt_change = 1+0.5*squeeze(variant_rt_change_list(dom_idx, :, :));
    % rate_change = variant_rt_change.*rate_change;
    %%% Cases
    un = un_array(:, scen_list(simnum, 1));
    
    data_var_s = cumsum([zeros(size(data_4_s, 1), 1) diff(data_4_s')'.*(variant_fact(:, 2:end))], 2);
    data_nvar_s = cumsum([zeros(size(data_4_s, 1), 1) diff(data_4_s')'.*(1 - variant_fact(:, 2:end))], 2);
    
    best_param_list_v = best_param_list;
    best_param_list_nv = best_param_list;
    
    compute_region = popu > -1;
    ll = scen_list(simnum, 5);
    beta_var = var_ind_beta_un(data_var_s(:, 1:(end-7*(ll)))+data_nvar_s(:, end), 0, best_param_list_v(:, 3)*0.1, best_param_list_v(:, 1), un, popu, best_param_list_v(:, 2), 0, compute_region, [], vacc_pre_immunity);
    beta_nvar = var_ind_beta_un(data_nvar_s(:, 1:(end-7*(ll)))+data_var_s(:, end), 0, best_param_list_nv(:, 3)*0.1, best_param_list_nv(:, 1), un, popu, best_param_list_nv(:, 2), 0, compute_region, [], vacc_pre_immunity);
    
    variant_projections;
    % infec_un2 = infec_var + infec_nvar;
    % base_infec = data_4(:, end);
    % infec_un2 = var_simulate_pred_vac(data_4_s, 0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec, vac_effect, rate_change);
    
    net_infec_0(simnum, :, :) = infec_net;
    
    dh_rate_change = get_rate_change_vac(dr_by_age, popu_for_vacc', 0.75, zeros(length(popu), horizon), vacc_given_by_age);
    h_rate_change = get_rate_change_vac(hr_by_age, popu_for_vacc', 0.75, zeros(length(popu), horizon), vacc_given_by_age);
        
    % Deaths
    for jj = 1:length(death_rates_list)
        death_rates = death_rates_list{1};
        this_rate_change = intermed_betas(death_rates, best_death_hyperparam, death_rates_list{jj}, best_death_hyperparam, rate_smooth);
        this_rate_change = [this_rate_change, repmat(this_rate_change(:, end), [1 2*size(dh_rate_change, 2)-size(this_rate_change, 2)])];
        dh_rate_change1 = dh_rate_change;
        dh_rate_change1 = [vacc_lag_rate, dh_rate_change1./dh_rate_change1(:, 1)].*this_rate_change(:, 1:(size(dh_rate_change1, 2)+size(vacc_lag_rate, 2)));
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        [pred_deaths] = var_simulate_deaths_vac(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1, dh_rate_change1);
        net_death_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_deaths(:, 1:horizon);
    end
    % Hosp
    for jj = 1:length(death_rates_list)
        hosp_rates = hosp_rates_list{1};
        this_rate_change = intermed_betas(hosp_rates, best_hosp_hyperparam, hosp_rates_list{jj}, best_hosp_hyperparam, rate_smooth);
        this_rate_change = [this_rate_change, repmat(this_rate_change(:, end), [1 2*size(dh_rate_change, 2)-size(this_rate_change, 2)])];
        dh_rate_change1 = h_rate_change;
        dh_rate_change1 = [vacc_lag_rate, dh_rate_change1./dh_rate_change1(:, 1)].*this_rate_change(:, 1:(size(dh_rate_change1, 2)+size(vacc_lag_rate, 2)));
        T_full = hosp_data_limit;
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        base_hosp = hosp_cumu(:, T_full);
        pred_hosps = var_simulate_deaths_vac(infec_data, hosp_rates, hk, hjp, hhorizon, base_hosp, T_full-1, dh_rate_change1);
        h_start = size(data_4, 2)-T_full+1;
        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1);
    end
    fprintf('.');
end
fprintf('\n');