net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(size(scen_list, 1)*length(dhlags_list), size(data_4, 1), horizon);
net_hosp_0 = zeros(size(scen_list, 1)*length(dhlags_list), size(data_4, 1), horizon);
net_var_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);

for simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1));
    lags = scen_list(simnum, 2);
    %beta_after = var_ind_beta_un(data_4_s(:, 1:end-lags), 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, popu>-1);
    j = find(lags_list==lags); uid = find(un_list==scen_list(simnum, 1));
    %beta_after = infec_rates_list{j(1)}{uid(1)};
    
    vac_effect_all = vacc_ag;
    for v = 1:size(vacc_ag, 3)
    vac_effect_all(:, :, v) = vacc_ag(:, :, v)*vacc_effi1 + ...
        [zeros(length(popu), 28), squeeze(vacc_ag(:, 29:end, v))]*vacc_effi2;
    %   vac_effect = vac_effect_all(:, (size(data_4, 2)-size(vacc_lag_rate, 2)+1):(size(data_4, 2)-size(vacc_lag_rate, 2)+horizon));
    end
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
    all_data_vars = zeros(length(popu), length(lineages), size(data_4, 2));
    for l=1:length(lineages)
        variant_fact = squeeze(var_frac_all(:, l, :));
        data_var_s = cumsum([zeros(ns, 1) diff(data_4_s')'].*(variant_fact), 2);
        all_data_vars0{l} = data_var_s;
        all_data_vars(:, l, :) =  data_var_s;
    end
    
    [all_betas] = multivar_beta_wan(all_data_vars, 0, popu, k_l, 0.8, jp_l, un, vac_effect_all, ...
        ag_case_frac, ag_popu_frac, ag_wan_param, ag_wan_lb);
    rate_change = nan(length(popu), horizon);
    rate_change(:, 1) = 1;
    rate_change(:, end) = Target_Rt(:, scen_list(simnum, 6))./current_Rt(:, scen_list(simnum, 5));
    rate_change = fillmissing(rate_change, 'linear', 2);
    
    base_beta = all_betas{b117_idx}; missing_b117 = valid_lins(:, b117_idx)<1;
    base_beta(missing_b117) = all_betas{other_idx}(missing_b117);
    
    base_infec = data_4;
    
    [infec, waned_popu, deltemp, reinfec_frac] = multivar_simulate_pred_wan(all_data_vars, 0, ...
        all_betas, popu, k_l, horizon, jp_l, un, base_infec, vac_effect_all, rate_change, ...
        ag_case_frac, ag_popu_frac, ag_wan_param, ag_wan_lb);

    T_full = size(data_4, 2);
    all_data_vars_matrix = cumsum(deltemp, 3);
    infec_data = squeeze(sum(all_data_vars_matrix, 2));
    infec_net = infec_data(:, T_full+1:end) - data_4_s(:, end) + data_4(:, end);
    infec_var = squeeze(all_data_vars_matrix(:, delta_idx, T_full+1:end));
    net_infec_0(simnum, :, :) = infec_net;
    net_var_0(simnum, :, :) = infec_var;
    
    
    % Changing death rates and hospitlization rates is no longer necessary
    dh_rate_change(:) = 1; h_rate_change(:) = 1;
    
    % Deaths
    for jj = 1:length(dhlags_list)
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        [death_rate] = var_ind_deaths_wan(data_4_s(:, 1:T_full-dhlags_list(jj)), reinfec_frac, P, ...
            deaths_s(:, 1:T_full-dhlags_list(jj)),  dalpha, dk, djp, dwin, 0, popu>-1, lags);

        if jj==1
            base_death_rate = death_rate;
        end
        
        dh_rate_change = intermed_betas(base_death_rate, best_death_hyperparam, death_rate, ...
            best_death_hyperparam, rate_smooth);
        
        pred_deaths = simulate_deaths_wan(infec_data, reinfec_frac, P, base_death_rate, dk, djp, ...
            horizon, base_deaths, T_full-1, dh_rate_change);
        
        net_death_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_deaths(:, 1:horizon);
    end
    % Hosp
    for jj = 1:length(dhlags_list)
        T_full = hosp_data_limit;
        base_hosp = hosp_cumu(:, T_full);
        
        [hosp_rate] = var_ind_deaths_wan(data_4_s(:, 1:T_full-dhlags_list(jj)), reinfec_frac, P, ...
            hosp_cumu_s(:, 1:T_full-dhlags_list(jj)),  halpha, hk, hjp, hwin, 0, popu>-1, hlags);
        if jj==1
            base_hosp_rate = hosp_rate;
        end
        
        dh_rate_change = intermed_betas(base_hosp_rate, best_hosp_hyperparam, hosp_rate, ...
            best_hosp_hyperparam, rate_smooth);
        
        pred_hosps = simulate_deaths_wan(infec_data, reinfec_frac, P, base_hosp_rate, hk, hjp, ...
            horizon, base_hosp, T_full-1, dh_rate_change);
        
        h_start = size(data_4, 2)-T_full+1;
        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
    end
    fprintf('.');
end
fprintf('\n');