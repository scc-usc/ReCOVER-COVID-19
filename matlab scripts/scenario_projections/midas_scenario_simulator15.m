

%%
dh_sims = size(scen_list, 1)*num_dh_rates_sample;
net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(dh_sims, size(data_4, 1), horizon);
net_hosp_0 = zeros(dh_sims, size(data_4, 1), horizon);
% new_infec_ag_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon, size(vacc_ag, 3));
% new_death_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_ag, 3));
% new_hosp_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_ag, 3));
var_x_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
Rt_all = zeros(size(scen_list, 1), ns, nl);
err = zeros(size(scen_list, 1), ns, nl);

net_d_cell = cell(size(scen_list, 1), 1);
net_d_ag_cell = cell(size(scen_list, 1), 1);
net_h_cell = cell(size(scen_list, 1), 1);
net_h_ag_cell = cell(size(scen_list, 1), 1);

parfor simnum = 1:size(scen_list, 1)
    %% Waning matrix generation
    wan_idx = scen_list(simnum, 4);
    P_death = squeeze(P_death_list(:, wan_idx, :));
    P_hosp = squeeze(P_hosp_list(:, wan_idx, :));
    ag_wan_lb = ag_wan_lb_list(:, wan_idx);
    ag_wan_param = ag_wan_param_list(:, wan_idx);

    % convert to weekly to save space
    %waned_impact = zeros(T+horizon, T+horizon, ag);
    %tdiff_matrix = (1:(T+horizon))' - (1:(T+horizon));
    nw = ceil((T+horizon)/7)+1;
    waned_impact = zeros(nl, nw, nw, ag);
    tdiff_matrix = (0:7:7*(nw-1))' - (0:7:7*(nw-1));
    tdiff_matrix(tdiff_matrix <= 0) = -Inf;

    vacc_effi_60 = [0.9; 0.9; 0.9; 0.9; 0.8];
    for idx = 1:ag
        for ll=1:nl
            if pre_omic_idx(ll) > 0
                [k, theta] = gamma_param_med(ag_wan_param(idx), 0.5, vacc_effi_60(idx), 60);
                waned_impact(ll, :, :, idx) = (1-0.5).*gamcdf(tdiff_matrix, k, theta);
            else
                [k, theta] = gamma_param_med(ag_wan_param(idx), ag_wan_lb(idx), vacc_effi_60(idx), 60);
                waned_impact(ll, :, :, idx) = (1-ag_wan_lb(idx)).*gamcdf(tdiff_matrix, k, theta);
            end
        end
    end
    waned_impact(isinf(waned_impact)) = 0;
    waned_impact(isnan(waned_impact)) = 0;

%%
    esc_param = 0.5; % For omicron over delta
    esc_param2 = esc_param2_list(scen_list(simnum, 6)); % For BA4 and BA5 over BA1
    b_effi = booster_imm_list(scen_list(simnum, 7));
    esc_param_w = 0.6;
    rel_vacc_effi = ones(nl, 1);
    rel_vacc_effi(omic_idx) = esc_param;
    rel_vacc_effi(omic_idx2) = esc_param2*esc_param;
    rel_vacc_effi(wildcard_idx) = esc_param_w*esc_param;

    cross_protect = ones(length(lineages), length(lineages));
    cross_protect(omic_idx, pre_omic_idx) = esc_param ;
    cross_protect(omic_idx, omic_idx) = 1;

    esc_param2 = 0.5; % For ba4 and ba5 over omicron
    cross_protect(omic_idx2, :) = esc_param2;
    cross_protect(omic_idx2, omic_idx2|wildcard_idx) = 1;

    cross_protect(wildcard_idx, :) = esc_param_w;
    %cross_protect(wildcard_idx, pre_omic_idx) = esc_param_w*esc_param;
    cross_protect(wildcard_idx, wildcard_idx) = 1;

    rel_booster_effi = cell(5, 1);
    rel_booster_effi{1} = rel_vacc_effi*fd_effi;
    rel_booster_effi{2} = rel_vacc_effi;
    for bb=3:5
        rel_booster_effi{bb} = ones(nl, T+horizon);
        rel_booster_effi{bb}(omic_idx2, :) = b_effi + esc_param2*esc_param*(1-b_effi);
        rel_booster_effi{bb}(omic_idx, :) = b_effi + esc_param*(1-b_effi);
        rel_booster_effi{bb}(wildcard_idx, :) = b_effi +esc_param_w*(1-b_effi);
        rel_booster_effi{bb}(:, reform_boost_day:end) = 1;
        rel_booster_effi{bb}(wildcard_idx, reform_boost_day:end) = esc_param_w;
    end
    %rel_booster_effi{5}(:) = 1; rel_booster_effi{5}(wildcard_idx) = 1*esc_param_w; % reformulated booster is better!!


    un = un_array{scen_list(simnum, 1)}; % Under-reporting
    if isvector(un)
        bad_un = un.*data_4(:, end).*(1-vacc_ag(:, end)./popu) + vacc_ag(:, end) > 0.9*popu;
        un(bad_un) = max(1, (0.9*popu(bad_un)-vacc_ag(bad_un, end))./(data_4(bad_un, end).*(1-vacc_ag(bad_un, end))));
    end

    dom_idx = scen_list(simnum, 2); % uncertainty in the dominant variant/VOC
    rlag = scen_list(simnum, 3);

    ns = length(popu);

    vlag = 14;
    booster_effect = cell(length(all_boosters_ts), 1);
    for v = 1:size(vacc_ag, 3)
        for bb = 1:length(all_boosters_ts)
            booster_effect{bb}(:, :, v) = [zeros(ns, vlag) squeeze(all_boosters_ts{bb}(:, 1:end-vlag, v))];
        end
    end

    compute_region = popu > -1;

    %% Cases

    % Fit variants transmission rates

    var_frac_all = var_frac_range{dom_idx};
    all_betas = cell(length(lineages), 1);
    all_data_vars0 = cell(length(lineages), 1);
    all_data_vars = zeros(length(popu), length(lineages), size(data_4, 2));

    if isvector(un) % Vector implies constant underreporting
        dd = [zeros(ns, 1) diff(data_4_s')'];
        un_fact = un;
    else  % non-vector implies un represents true cases
        dd = un;
        un_fact = 1;
    end
    for l=1:length(lineages)
        variant_fact = squeeze(var_frac_all(:, l, :));
        data_var_s = cumsum(dd.*(variant_fact), 2);
        all_data_vars0{l} = data_var_s;
        all_data_vars(:, l, :) =  data_var_s;
    end

    [all_betas, all_cont, fC,immune_infec, ALL_STATS] = Sp_multivar_beta_escape(all_data_vars, 0, popu, k_l, 0.98, ...
        jp_l, un_fact, ag_case_frac, ag_popu_frac, waned_impact, booster_effect, booster_delay, ...
        rel_booster_effi, cross_protect, rlag);
    rate_change = nan(length(popu), horizon);
    rate_change(:) = 1;
    rate_change = rate_change.*mobility_effect(scen_list(simnum, 5), 1:horizon);

    [this_Rt] = calc_Rt_all(all_betas, all_cont, ag_popu_frac, k_l, jp_l);
    %Rt_all(simnum, :, :) = this_Rt;
    this_err = calc_error_fC(fC);
    
    for jj=1:ns
        nf = 1; % Max number observed in cases (normalizes for various case ascertainments)
        for ll=1:nl
            if ~isempty(fC{ll}{jj})
                nf = max(nf, max(fC{ll}{jj}(:, 2)));
            end
        end
        this_err(jj, :) = sqrt(this_err(jj, :))./nf;
    end
    err(simnum, :, :) = this_err;
    
    %%
    temp = this_Rt; temp(:, ~(omic_idx|contains(lineages, 'other'))) = 0;
    for jj=1:ns
        [maxR, high_lin] = max(temp(jj, :));
        all_betas{wildcard_idx}{jj} = all_betas{high_lin}{jj};
        if this_Rt(jj, foc_idx) > maxR % Enforce that the VoC does not have too high R advantage
            all_betas{foc_idx}{jj} = all_betas{foc_idx}{jj}* maxR/this_Rt(jj, foc_idx);
            this_Rt(jj, foc_idx) = maxR;
        end
    end
    Rt_all(simnum, :, :) = this_Rt;
    %%
    base_infec = data_4;

    [infec, deltemp, immune_infec1, ALL_STATS_new, protected_popu_frac] = Sp_multivar_pred_escape(all_data_vars, 0, ...
        all_betas, popu, k_l, horizon, jp_l, un_fact, base_infec, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, all_cont, external_infec_perc, ...
        booster_effect, booster_delay, rel_booster_effi, cross_protect, ALL_STATS);

    if ~isvector(un) % If un was true infections, readjust to caliberate with recent reporting
        infec = base_infec(:, end) + (infec - base_infec(:, end)).*(data_4_s(:, end) - data_4_s(:, end-7))./(1+sum(un(:, end-6:end),2));
    end

    T_full = size(data_4, 2);
    all_data_vars_matrix = cumsum(squeeze(sum(deltemp, 4)), 3);
    var_x_0(simnum, :, :) = sum(deltemp(:, wildcard_idx, thisday+1 : thisday+horizon, :), 4)./(sum(deltemp(:, :, thisday+1 : thisday+horizon, :), [2 4])+1e-10);
    pred_new_cases = squeeze(sum(deltemp, 2));
%     all_data_age_matrix = cumsum(pred_new_cases, 2);
%     pred_new_cases = pred_new_cases(:, thisday+1 : thisday+horizon, :);
    infec_data = squeeze(sum(all_data_vars_matrix, 2));
    infec_net = infec_data(:, T_full+1:end) - infec_data(:, T_full) + data_4(:, end);

    infec_net = cumsum([infec_net(:, 1) movmean(diff(infec_net, 1, 2), 7, 2)], 2);
    net_infec_0(simnum, :, :) = infec;

    immune_infec = movmean(immune_infec1, 7, 3);
    %new_infec_ag_0(simnum, :, :, :) = pred_new_cases;
    bad_idx = (deltemp - immune_infec) < 0;
    immune_infec(bad_idx) = deltemp(bad_idx);


    %%
    % Hosp
    P = 1 - (rel_lineage_rates'./max(rel_lineage_rates)).*((1-P_death)./(1-ag_wan_lb));

    T_full = hosp_data_limit;
    base_hosp = hosp_cumu(:, T_full);
    % Search hyperparam
    %     halpha = 1; dkrange = (3:4); lag_range = (0:3); djprange = [7];
    %     dwin = [50, 75];
    %
    %     [X, Y, Z, A] = ndgrid(dkrange, djprange, dwin, lag_range);
    %     param_list = [X(:), Y(:), Z(:), A(:)];
    %     idx = (param_list(:, 1).*param_list(:, 2) <=28) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))>0;
    %     param_list = param_list(idx, :);
    %     [best_hosp_hyperparam] = dh_age_hyper(deltemp, immune_infec, rel_lineage_rates, P, ...
    %     hosp_cumu_ag, thisday, 7, [], halpha);
    %     hk = best_hosp_hyperparam(:, 1);
    %     hjp = best_hosp_hyperparam(:, 2);
    %     hwin = best_hosp_hyperparam(:, 3);
    %     hlags = best_hosp_hyperparam(:, 4);
    hk = 3; hjp = 2; hwin = 100; halpha = 0.9; hlags = 0;

    [hosp_rate, ci_h, fC_h] = get_death_rates_escape(deltemp(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates, P, ...
        hosp_cumu_ag(:, 1:thisday, :),  halpha, hk, hjp, hwin, 0.95, popu>-1, hlags);

    for rr = 1:num_dh_rates_sample
        this_rate = hosp_rate;

        if rr ~= (num_dh_rates_sample + 1)/2
            for cid=1:ns
                for g=1:ag
                    this_rate{cid, g} = ci_h{cid, g}(:, 1) + (ci_h{cid, g}(:, 2) - ci_h{cid, g}(:, 1))*(rr-1)/(num_dh_rates_sample-1);
                end
            end
        end

        [pred_hosps, pred_new_hosps_ag] = simulate_deaths_escape(deltemp, immune_infec, rel_lineage_rates, P, this_rate, hk, hjp, ...
            horizon, base_hosp, T_full-1);

        h_start = size(data_4, 2)-T_full+1;
        temp_res(rr, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
        temp_res_ag(rr, :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
        %        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
        %        new_hosp_ag_0(simnum+(jj-1)*size(scen_list, 1), :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
    end
    net_h_cell{simnum} = temp_res;
    %net_h_ag_cell{simnum} = temp_res_ag;


    %%
    % Deaths
    %%%%% From hospitalizations
    mid_idx = (num_dh_rates_sample + 1)/2;
    hosp_preds_lins = zeros(ns, nl, T+horizon, ag);
    for l=1:nl
        for gg=1:ag
            hosp_preds_lins(:, l, :, gg) = rel_lineage_rates(l)*squeeze(deltemp(:, l, :, gg)./sum(deltemp(:, :, :, gg), 2)).*[diff([ zeros(ns, 1) squeeze(hosp_cumu_ag(:, 1:thisday, gg))], 1, 2) ...
                squeeze(temp_res_ag(mid_idx, :, 1:horizon, gg))];
        end
    end
    hosp_preds_lins(isnan(hosp_preds_lins)) = 0;
    %%%%%%%%%%%%%%%%
    %%
    P = 1 - (rel_lineage_rates'./max(rel_lineage_rates)).*((1-P_death)./(1-ag_wan_lb));
    temp_res = zeros(num_dh_rates_sample, length(countries), horizon);
    temp_res_ag = zeros(num_dh_rates_sample, length(countries), horizon, size(vacc_ag, 3));

    T_full = size(data_4, 2);
    base_deaths = deaths(:, T_full);

    %dk = 7; djp = 7; dwin = 75; dalpha = 0.95; dlags = 3;
    rel_lineage_rates1 = repmat(rel_lineage_rates(:)', [ns 1]); rel_lineage_rates1(:) = 1; % high severity already captured
    dalpha = 0.98;
    [X, Y, Z, A, A1] = ndgrid([3:7], 7, [100], [1:6], [1]);
    param_list = [X(:), Y(:), Z(:), A(:), A1(:)];
    val_idx = (param_list(:, 1).*param_list(:, 2) <=49) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))>2 & (param_list(:, 1) - param_list(:, 4))<5;
    param_list = param_list(val_idx, :);
    [best_death_hyperparam] = dh_age_hyper(hosp_preds_lins, immune_infec, rel_lineage_rates1, P_death, deaths_ag(:, 1:thisday, :), thisday, 0, param_list, dalpha);
    dk = best_death_hyperparam(:, 1); djp = best_death_hyperparam(:, 2);
    dwin = best_death_hyperparam(:, 3); dlags = best_death_hyperparam(:, 4); rel_lineage_rates1(:, wildcard_idx) = repmat(best_death_hyperparam(:, 5), [1 sum(wildcard_idx)]);

    [death_rate, ci_d, fC_d] = get_death_rates_escape(hosp_preds_lins(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates, P, ...
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

        [pred_deaths, pred_new_deaths_ag] = simulate_deaths_escape(hosp_preds_lins, immune_infec, rel_lineage_rates, P, this_rate, dk, djp, ...
            horizon, base_deaths, T_full-1);
        temp_res(rr, :, :) = pred_deaths(:, 1:horizon);
        temp_res_ag(rr, :, :, :) = pred_new_deaths_ag(:, 1:horizon, :);
    end
    net_d_cell{simnum} = temp_res;
    %net_d_ag_cell{simnum} = temp_res_ag;

    fprintf('.');
end

%%
for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
    net_death_0(idx, :, :) = net_d_cell{simnum};
    %new_death_ag_0(idx, :, :, :) = net_d_ag_cell{simnum};
    net_hosp_0(idx, :, :) = net_h_cell{simnum};
    %new_hosp_ag_0(idx, :, :, :) = net_h_ag_cell{simnum};
end
clear net_*_cell
fprintf('\n');

