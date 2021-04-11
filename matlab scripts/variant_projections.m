if scenario_forecasts ~= 1
    data_var_s = cumsum([zeros(size(data_4_s, 1), 1) diff(data_4_s')'.*(variant_fact(:, 2:end))], 2);
    data_nvar_s = cumsum([zeros(size(data_4_s, 1), 1) diff(data_4_s')'.*(1 - variant_fact(:, 2:end))], 2);
    
    best_param_list_v = best_param_list;
    best_param_list_nv = best_param_list;
    
    compute_region = popu > -1;
    
    beta_var = var_ind_beta_un(data_var_s(:, :)+data_nvar_s(:, end), 0, best_param_list_v(:, 3)*0.1, best_param_list_v(:, 1), un, popu, best_param_list_v(:, 2), 0, compute_region, [], vacc_pre_immunity);
    beta_nvar = var_ind_beta_un(data_nvar_s(:, :)+data_var_s(:, end), 0, best_param_list_nv(:, 3)*0.1, best_param_list_nv(:, 1), un, popu, best_param_list_nv(:, 2), 0, compute_region, [], vacc_pre_immunity);
end

if scenario_forecasts == 1
    Feb_Rt = calc_Rt(beta_var, best_param_list_v(:, 1), best_param_list_v(:, 2), popu >0);
    %R_nvar = calc_Rt(beta_nvar, best_param_list_nv(:, 1), best_param_list_nv(:, 2), popu >0);
    Rt_init = Feb_Rt;
    Rt_final = Rt_init + max(zeros(size(Rt_init, 1), 1), npi_red*(Target_Rt(:, scen_list(simnum, 6)) - Rt_init));
    rate_change = intermed_betas([], [], [], [], horizon, Rt_init, Rt_final);
end

new_horizon = horizon;
this_horizon = 2;
infec_var = []; infec_nvar = []; base_infec = data_4(:, end);
while new_horizon > 0
    this_horizon = min([this_horizon; new_horizon]);
    this_vac_effect = vac_effect(:, 1+horizon-new_horizon:horizon);
    this_rate_change = rate_change(:, 1+horizon-new_horizon:horizon);
    this_data_var = [data_var_s infec_var];
    this_infec_var = var_simulate_pred_vac(this_data_var, 0, beta_var, popu, best_param_list_v(:, 1), this_horizon, best_param_list_v(:, 2), un, base_infec, this_vac_effect, this_rate_change);
    this_data_nvar = [data_nvar_s infec_nvar];
    this_infec_nvar = var_simulate_pred_vac(this_data_nvar, 0, beta_nvar, popu, best_param_list_nv(:, 1), this_horizon, best_param_list_nv(:, 2), un, base_infec, this_vac_effect, this_rate_change);
    
    infec_var = [infec_var this_infec_var-base_infec+this_data_var(:, end)];
    infec_nvar = [infec_nvar this_infec_nvar-base_infec+this_data_nvar(:, end)];
    new_horizon = new_horizon - this_horizon;
    base_infec = infec_var(:, end)+infec_nvar(:, end);
    
end

infec_net = infec_var + infec_nvar;
infec_net = infec_net - data_4_s(:, end) + data_4(:, end);