%% Waning matrix generation

P_death = P_death_list(:, wan_idx);
P_hosp = P_hosp_list(:, wan_idx);
ag_wan_lb = ag_wan_lb_list(:, wan_idx);
ag_wan_param = ag_wan_param_list(:, wan_idx);

waned_impact = zeros(T+horizon, T+horizon, ag);
tdiff_matrix = (1:(T+horizon))' - (1:(T+horizon));
tdiff_matrix(tdiff_matrix <= 0) = -Inf;

vacc_effi_60 = [0.9; 0.9; 0.9; 0.9; 0.8];
for idx = 1:ag
    [k, theta] = gamma_param(ag_wan_param(idx), ag_wan_lb(idx), vacc_effi_60(idx), 60);
    waned_impact(:, :, idx) = (1-ag_wan_lb(idx)).*gamcdf(tdiff_matrix, k, theta);
end
waned_impact(isinf(waned_impact)) = 0;
waned_impact(isnan(waned_impact)) = 0;

%%
dh_sims = size(scen_list, 1)*length(dhlags_list);
net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(dh_sims, size(data_4, 1), horizon);
net_hosp_0 = zeros(dh_sims, size(data_4, 1), horizon);
new_infec_ag_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon, size(vacc_ag, 3));
new_death_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_ag, 3));
new_hosp_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_ag, 3));

net_d_cell = cell(size(scen_list, 1), 1);
net_d_ag_cell = cell(size(scen_list, 1), 1);
net_h_cell = cell(size(scen_list, 1), 1);
net_h_ag_cell = cell(size(scen_list, 1), 1);

parfor simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1)); % Under-reporting (low-1, mean-2, high-3)
    dom_idx = scen_list(simnum, 2); % uncertainty in the dominant variant/VOC
    target_rt_idx = scen_list(simnum, 4);
    current_rt_idx = scen_list(simnum, 3);
    rlag = scen_list(simnum, 5);
    booster_delay = scen_list(simnum, 6);
    
    ns = length(popu);
    vac_effect_all = vacc_ag;
    booster_effect = booster_given_by_age;
    vlag = 14;
    for v = 1:size(vacc_ag, 3)
        vac_effect_all(:, :, v) = [zeros(ns, vlag) squeeze(vacc_ag(:, 1:end-vlag, v)*(vacc_effi2 + vacc_effi1))];
        booster_effect(:, :, v) = [zeros(ns, vlag) squeeze(booster_given_by_age(:, 1:end-vlag, v)*(vacc_effi2 + vacc_effi1))];
    end
    
    compute_region = popu > -1;
    
    %% Cases
    
    % Fit variants transmission rates
    
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
    
    [all_betas, all_cont, fC] = multivar_beta_wan_custom(all_data_vars(:, :, 1:thisday-rlag), 0, popu, k_l, 0.9, jp_l, un, vac_effect_all, ...
        ag_case_frac, ag_popu_frac, waned_impact, ag_wan_lb, booster_effect, booster_delay);
    rate_change = nan(length(popu), horizon);
    rate_change(:, 1) = 1;
    rate_change(:, end) = Target_Rt(:, target_rt_idx)./current_Rt(:, current_rt_idx);
    rate_change = fillmissing(rate_change, 'linear', 2);
    winter_rt = nan(length(popu), horizon);
    temp = rt_winter_effect(scen_list(simnum, 7), :);
    winter_rt(:, 1:length(temp)) = repmat(temp, [ns 1]);
    winter_rt = fillmissing(winter_rt, 'previous', 2);
    rate_change = rate_change.*winter_rt;

    base_beta = all_betas{delta_idx}; missing_base = valid_lins(:, delta_idx)<1;
    base_beta(missing_base) = all_betas{other_idx}(missing_base);
%%    
    for cid = 1:ns
        % Last variant in the list is the wildcard
        all_betas{length(lineages)}{cid} = wildcard_ad * base_beta{cid};
    end
    
    base_infec = data_4;
   
    [infec, waned_popu, deltemp, reinfec_frac] = multivar_simulate_pred_wan_custom(all_data_vars, 0, ...
        all_betas, popu, k_l, horizon, jp_l, un, base_infec, vac_effect_all, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, ag_wan_lb, all_cont, 0, booster_effect, booster_delay);

    T_full = size(data_4, 2);
    all_data_vars_matrix = cumsum(squeeze(sum(deltemp, 4)), 3);
    pred_new_cases = squeeze(sum(deltemp, 2)); 
    all_data_age_matrix = cumsum(pred_new_cases, 2); 
    pred_new_cases = pred_new_cases(:, thisday+1 : thisday+horizon, :);
    infec_data = squeeze(sum(all_data_vars_matrix, 2));
    infec_net = infec_data(:, T_full+1:end) - infec_data(:, T_full) + data_4(:, end);
    infec_var = squeeze(all_data_vars_matrix(:, delta_idx, T_full+1:end));
    net_infec_0(simnum, :, :) = infec_net;
    reinfec_frac(isnan(reinfec_frac(:))) = 0;
    
    new_infec_ag_0(simnum, :, :, :) = pred_new_cases;
    
    % Changing death rates and hospitlization rates is no longer necessary
    dh_rate_change(:) = 1; 
%%    
    % Deaths
    P = P_death;
    temp_res = zeros(length(dhlags_list), length(countries), horizon);
    temp_res_ag = zeros(length(dhlags_list), length(countries), horizon, size(vacc_ag, 3));
    for jj = 1:length(dhlags_list)
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        [death_rate] = var_ind_deaths_wan(all_data_age_matrix(:, 1:T_full-dhlags_list(jj), :), reinfec_frac, P, ...
            deaths_ag(:, 1:T_full-dhlags_list(jj), :),  dalpha, dk, djp, dwin, 0, popu>-1, dlags);

        if jj==1
            base_death_rate = death_rate;
        end
        
        dh_rate_change = intermed_betas(base_death_rate, best_death_hyperparam, death_rate, ...
            best_death_hyperparam, rate_smooth);
        
        [pred_deaths, pred_new_deaths_ag] = simulate_deaths_wan(all_data_age_matrix, reinfec_frac, P, base_death_rate, dk, djp, ...
            horizon, base_deaths, T_full-1, dh_rate_change);
        temp_res(jj, :, :) = pred_deaths(:, 1:horizon);
        temp_res_ag(jj, :, :, :) = pred_new_deaths_ag(:, 1:horizon, :);
%        net_death_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_deaths(:, 1:horizon);
%        new_death_ag_0(simnum+(jj-1)*size(scen_list, 1), :, :, :) = pred_new_deaths_ag(:, 1:horizon, :);
    end
    net_d_cell{simnum} = temp_res;
    net_d_ag_cell{simnum} = temp_res_ag;

%%
    % Hosp
    P = P_hosp;
    for jj = 1:length(dhlags_list)
        T_full = hosp_data_limit;
        base_hosp = hosp_cumu(:, T_full);
        
        [hosp_rate] = var_ind_deaths_wan(all_data_age_matrix(:, 1:T_full-dhlags_list(jj), :), reinfec_frac, P, ...
            hosp_cumu_ag(:, 1:T_full-dhlags_list(jj), :),  halpha, hk, hjp, hwin, 0, popu>-1, hlags);
        if jj==1
            base_hosp_rate = hosp_rate;
        end
        
         dh_rate_change = intermed_betas(base_hosp_rate, best_hosp_hyperparam, hosp_rate, ...
             best_hosp_hyperparam, rate_smooth);
        
        [pred_hosps, pred_new_hosps_ag] = simulate_deaths_wan(all_data_age_matrix, reinfec_frac, P, base_hosp_rate, hk, hjp, ...
            horizon, base_hosp, T_full-1, dh_rate_change);
        
        h_start = size(data_4, 2)-T_full+1;
        temp_res(jj, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
        temp_res_ag(jj, :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
%        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
%        new_hosp_ag_0(simnum+(jj-1)*size(scen_list, 1), :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
    end
    net_h_cell{simnum} = temp_res;
    net_h_ag_cell{simnum} = temp_res_ag;
    fprintf('.');
end

for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:length(dhlags_list)-1]*size(scen_list, 1);
    net_death_0(idx, :, :) = net_d_cell{simnum};
    new_death_ag_0(idx, :, :, :) = net_d_ag_cell{simnum};
    net_hosp_0(idx, :, :) = net_h_cell{simnum};
    new_hosp_ag_0(idx, :, :, :) = net_h_ag_cell{simnum};
end
%clear net_*_cell
fprintf('\n');

