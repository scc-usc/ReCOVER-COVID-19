

%%
dh_sims = size(scen_list, 1)*num_dh_rates_sample;
net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(dh_sims, size(data_4, 1), horizon);
%net_hosp_0 = zeros(dh_sims, size(data_4, 1), horizon);
new_infec_ag_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon, size(vacc_ag, 3));
new_death_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_ag, 3));
%new_hosp_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_ag, 3));
Rt_all = zeros(size(scen_list, 1), ns, nl);

net_d_cell = cell(size(scen_list, 1), 1);
net_d_ag_cell = cell(size(scen_list, 1), 1);
% net_h_cell = cell(size(scen_list, 1), 1);
% net_h_ag_cell = cell(size(scen_list, 1), 1);

parfor simnum = 1:size(scen_list, 1)
    %% Waning matrix generation
    wan_idx = scen_list(simnum, 7);
    P_death = squeeze(P_death_list(:, wan_idx, :));
    P_hosp = squeeze(P_hosp_list(:, wan_idx, :));
    ag_wan_lb = ag_wan_lb_list(:, wan_idx);
    ag_wan_param = ag_wan_param_list(:, wan_idx);

    waned_impact = zeros(T+horizon, T+horizon, ag);
    tdiff_matrix = (1:(T+horizon))' - (1:(T+horizon));
    tdiff_matrix(tdiff_matrix <= 0) = -Inf;

    vacc_effi_60 = [0.9; 0.9; 0.9; 0.9; 0.8];
    for idx = 1:ag
        [k, theta] = gamma_param_med(ag_wan_param(idx), ag_wan_lb(idx), vacc_effi_60(idx), 60);
        waned_impact(:, :, idx) = (1-ag_wan_lb(idx)).*gamcdf(tdiff_matrix, k, theta);
    end
    waned_impact(isinf(waned_impact)) = 0;
    waned_impact(isnan(waned_impact)) = 0;


    un = un_array(:, scen_list(simnum, 1)); % Under-reporting (low-1, mean-2, high-3)
    bad_un = un.*data_4(:, end).*(1-vacc_ag(:, end)./popu) + vacc_ag(:, end) > 0.9*popu;
    un(bad_un) = 1;

    dom_idx = scen_list(simnum, 2); % uncertainty in the dominant variant/VOC
    target_rt_idx = scen_list(simnum, 4);
    current_rt_idx = scen_list(simnum, 3);
    rlag = scen_list(simnum, 5);
    booster_cov_idx = scen_list(simnum, 6);

    ns = length(popu);
    vac_effect_all = vacc_ag;

    booster_given_by_age = all_boosters_ts{booster_cov_idx};
    booster_effect = booster_given_by_age;
    
    %fd_effect_all = fd_given_by_age;
    
    vlag = 14;
    for v = 1:size(vacc_ag, 3)
        vac_effect_all(:, :, v) = [zeros(ns, vlag) squeeze(vacc_ag(:, 1:end-vlag, v)*(vacc_effi2 + vacc_effi1))];
        booster_effect(:, :, v) = [zeros(ns, vlag) squeeze(booster_given_by_age(:, 1:end-vlag, v)*(vacc_effi2 + vacc_effi1))];
        %fd_effect_all(:, :, v) = [zeros(ns, vlag) squeeze(fd_effect_all(:, 1:end-vlag, v)*(vacc_effi2 + vacc_effi1))];
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

    [all_betas, all_cont, fC,immune_infec, ALL_STATS] = multivar_beta_escape(all_data_vars, 0, popu, k_l, 0.98, ...
        jp_l, un, vacc_ag, ag_case_frac, ag_popu_frac, waned_impact, booster_effect, booster_delay, ...
        rel_vacc_effi, rel_booster_effi, cross_protect, rlag);
    rate_change = nan(length(popu), horizon);
    rate_change(:, 1) = 1;
    rate_change(:, end) = Target_Rt(:, target_rt_idx)./current_Rt(:, current_rt_idx);
    rate_change = fillmissing(rate_change, 'linear', 2);
    %     winter_rt = nan(length(popu), horizon);
    %     temp = rt_winter_effect(scen_list(simnum, 7), :);
    %     winter_rt(:, 1:length(temp)) = repmat(temp, [ns 1]);
    %     winter_rt = fillmissing(winter_rt, 'previous', 2);
    rate_change = rate_change.*mobility_effect(scen_list(simnum, 8), 1:horizon);

    [this_Rt] = calc_Rt_all(all_betas, all_cont, ag_popu_frac, k_l, jp_l);
    Rt_all(simnum, :, :) = this_Rt;
    %%
    temp = this_Rt; temp(:, ~omic_idx) = 0;
    for jj=1:ns
        [maxR, high_lin] = max(temp(jj, :));
        all_betas{wildcard_idx}{jj} = all_betas{high_lin}{jj};
    end
    %%
    base_infec = data_4;

    [infec, deltemp, immune_infec1, ALL_STATS_new, protected_popu_frac] = multivar_pred_escape(all_data_vars, 0, ...
        all_betas, popu, k_l, horizon, jp_l, un, base_infec, vacc_ag, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, all_cont, external_infec_perc, ...
        booster_effect, booster_delay, rel_vacc_effi, rel_booster_effi, cross_protect, ALL_STATS);

    T_full = size(data_4, 2);
    all_data_vars_matrix = cumsum(squeeze(sum(deltemp, 4)), 3);
    pred_new_cases = squeeze(sum(deltemp, 2));
    all_data_age_matrix = cumsum(pred_new_cases, 2);
    pred_new_cases = pred_new_cases(:, thisday+1 : thisday+horizon, :);
    infec_data = squeeze(sum(all_data_vars_matrix, 2));
    infec_net = infec_data(:, T_full+1:end) - infec_data(:, T_full) + data_4(:, end);
    
    infec_net = cumsum([infec_net(:, 1) movmean(diff(infec_net, 1, 2), 7, 2)], 2);
    net_infec_0(simnum, :, :) = infec_net;

    immune_infec = movmean(immune_infec1, 7, 3);
    new_infec_ag_0(simnum, :, :, :) = pred_new_cases;
    bad_idx = (deltemp - immune_infec) < 0;
    immune_infec(bad_idx) = deltemp(bad_idx);
    
    %%
    % Deaths
    P = 1 - (1-P_death)./(1-ag_wan_lb);
    temp_res = zeros(num_dh_rates_sample, length(countries), horizon);
    temp_res_ag = zeros(num_dh_rates_sample, length(countries), horizon, size(vacc_ag, 3));

    T_full = size(data_4, 2);
    base_deaths = deaths(:, T_full);

    dk = 7; djp = 7; dwin = 75; dalpha = 0.95; dlags = 3;

    [death_rate, ci_d, fC_d] = get_death_rates_escape(deltemp(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates, P, ...
        deaths_ag(:, 1:thisday, :),  dalpha, dk, djp, dwin, 0.95, popu>-1, dlags);
%%

    for rr = 1:num_dh_rates_sample
        this_rate = death_rate;

        if rr ~= (num_dh_rates_sample + 1)/2
            for cid=1:ns
                for g=1:ag
                    this_rate{cid, g} = ci_d{cid, g}(:, 1) + (ci_d{cid, g}(:, 2) - ci_d{cid, g}(:, 1))*(rr-1)/(num_dh_rates_sample-1);
                end
            end
        end
        
        [pred_deaths, pred_new_deaths_ag] = simulate_deaths_escape(deltemp, immune_infec, rel_lineage_rates, P, this_rate, dk, djp, ...
            horizon, base_deaths, T_full-1);
        temp_res(rr, :, :) = pred_deaths(:, 1:horizon);
        temp_res_ag(rr, :, :, :) = pred_new_deaths_ag(:, 1:horizon, :);
    end
    net_d_cell{simnum} = temp_res;
    net_d_ag_cell{simnum} = temp_res_ag;

    %%
%     % Hosp
%     P = 1 - (1-P_hosp)./(1-ag_wan_lb);
% 
%     T_full = hosp_data_limit;
%     base_hosp = hosp_cumu(:, T_full);
%         % Search hyperparam
% %     halpha = 1; dkrange = (3:4); lag_range = (0:3); djprange = [7];
% %     dwin = [50, 75];
% % 
% %     [X, Y, Z, A] = ndgrid(dkrange, djprange, dwin, lag_range);
% %     param_list = [X(:), Y(:), Z(:), A(:)];
% %     idx = (param_list(:, 1).*param_list(:, 2) <=28) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))>0;
% %     param_list = param_list(idx, :);
% %     [best_hosp_hyperparam] = dh_age_hyper(deltemp, immune_infec, rel_lineage_rates, P, ...
% %     hosp_cumu_ag, thisday, 7, [], halpha);
% %     hk = best_hosp_hyperparam(:, 1);
% %     hjp = best_hosp_hyperparam(:, 2);
% %     hwin = best_hosp_hyperparam(:, 3);
% %     hlags = best_hosp_hyperparam(:, 4);
%     hk = 3; hjp = 2; hwin = 100; halpha = 0.9; hlags = 0;
% 
%     [hosp_rate, ci_h, fC_h] = get_death_rates_escape(deltemp(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates, P, ...
%         hosp_cumu_ag(:, 1:thisday, :),  halpha, hk, hjp, hwin, 0.95, popu>-1, hlags);
% 
%     for rr = 1:num_dh_rates_sample
%         this_rate = hosp_rate;
% 
%         if rr ~= (num_dh_rates_sample + 1)/2
%             for cid=1:ns
%                 for g=1:ag
%                     this_rate{cid, g} = ci_h{cid, g}(:, 1) + (ci_h{cid, g}(:, 2) - ci_h{cid, g}(:, 1))*(rr-1)/(num_dh_rates_sample-1);
%                 end
%             end
%         end
% 
%         [pred_hosps, pred_new_hosps_ag] = simulate_deaths_escape(deltemp, immune_infec, rel_lineage_rates, P, this_rate, hk, hjp, ...
%             horizon, base_hosp, T_full-1);
% 
%         h_start = size(data_4, 2)-T_full+1;
%         temp_res(rr, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
%         temp_res_ag(rr, :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
%         %        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
%         %        new_hosp_ag_0(simnum+(jj-1)*size(scen_list, 1), :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
%     end
%     net_h_cell{simnum} = temp_res;
%     net_h_ag_cell{simnum} = temp_res_ag;
    fprintf('.');
end

for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
    net_death_0(idx, :, :) = net_d_cell{simnum};
    new_death_ag_0(idx, :, :, :) = net_d_ag_cell{simnum};
%     net_hosp_0(idx, :, :) = net_h_cell{simnum};
%     new_hosp_ag_0(idx, :, :, :) = net_h_ag_cell{simnum};
end
clear net_*_cell
fprintf('\n');

% Remove unusual zeros
for cid=1:length(popu)
    thisdata = net_infec_0(:, cid, :);
    approx_target = interp1([1 2], [data_4_s(cid, end-1)-data_4_s(cid, end-2), data_4_s(cid, end) - data_4_s(cid, end-1)], 3, 'linear', 'extrap');
    bad_idx = (thisdata(:, 1)-data_4(cid, end)) < 0.3*approx_target;
    net_infec_0(bad_idx, cid, :) = nan; 
    thisdata = net_death_0(:, cid, :);
    approx_target = interp1([1 2], [deaths_s(cid, end-1)-deaths_s(cid, end-2), deaths_s(cid, end) - deaths_s(cid, end-1)], 3);
    bad_idx = (thisdata(:, 1)-deaths(cid, end)) < 0.3*approx_target;
    net_death_0(bad_idx, cid, :) = nan;

%     if cid==57
%         fprintf('.');
%     end
end

