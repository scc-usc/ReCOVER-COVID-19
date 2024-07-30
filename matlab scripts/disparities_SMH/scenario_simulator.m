

%%
dh_sims = size(scen_list, 1)*num_dh_rates_sample;
net_infec_0 = zeros(size(scen_list, 1), ns, horizon);
net_death_0 = zeros(dh_sims, ns, horizon);
net_hosp_0 = zeros(dh_sims, ns, horizon);
new_infec_ag_0 = zeros(size(scen_list, 1), ns, horizon, ag);
new_death_ag_0 = zeros(dh_sims, ns, horizon, ag);
new_hosp_ag_0 = zeros(dh_sims, ns, horizon, ag);
var_x_0 = zeros(size(scen_list, 1), ns, horizon);
Rt_all = zeros(size(scen_list, 1), ns, nl);
err = zeros(size(scen_list, 1), ns, nl);

net_d_cell = cell(size(scen_list, 1), 1);
net_d_ag_cell = cell(size(scen_list, 1), 1);
net_h_cell = cell(size(scen_list, 1), 1);
net_h_ag_cell = cell(size(scen_list, 1), 1);

comp_h = cell(size(scen_list, 1), 1);
comp_d = cell(size(scen_list, 1), 1);

%%
parfor simnum = 1:size(scen_list, 1)
%for simnum = 1:size(scen_list, 1)
    % Waning matrix generation
    wan_idx = scen_list.num_wan(simnum);
    P_death = squeeze(P_death_list(:, wan_idx, :));
    P_hosp = squeeze(P_hosp_list(:, wan_idx, :));
    ag_wan_lb = ag_wan_lb_list(:, wan_idx);
    ag_wan_param = ag_wan_param_list(:, wan_idx);

    % convert to weekly to save space
    %waned_impact = zeros(T+horizon, T+horizon, ag);
    %tdiff_matrix = (1:(T+horizon))' - (1:(T+horizon));
    nw = ceil((T+horizon)/1)+1;
    waned_impact = zeros(nl, nw, nw, ag);
    tdiff_matrix = (0:1:(nw-1))' - (0:1:(nw-1));
    tdiff_matrix(tdiff_matrix <= 0) = -Inf;

    vacc_effi_60 = 0.95*ones(ag, 1);
    for idx = 1:ag
        for ll=1:nl
            [k, theta] = gamma_param_med(ag_wan_param(idx), ag_wan_lb(idx), vacc_effi_60(idx), 9);
            waned_impact(ll, :, :, idx) = (1-ag_wan_lb(idx)).*gamcdf(tdiff_matrix, k, theta);
        end
    end
    
    waned_impact(isinf(waned_impact)) = 0;
    waned_impact(isnan(waned_impact)) = 0;

%%
    
    %b_effi = booster_imm_list(scen_list(simnum, 7));
    
    rel_vacc_effi = scen_list.vacc_effi(simnum) * ones(nl, 1);
    
    rel_booster_effi = cell(length(all_boosters_ts), 1);
    rel_booster_effi{1} = rel_vacc_effi*fd_effi.*ones(nl, T+horizon);
    rel_booster_effi{2} = rel_vacc_effi.*ones(nl, T+horizon);
    
    un = un_array{scen_list.un_list(simnum)}; % Under-reporting

    dom_idx = scen_list.var_prev_q(simnum); % uncertainty in the dominant variant/VOC
    
    
    vlag = 1;
    booster_effect = cell(length(all_boosters_ts), 1);
    for v = 1:ag
        for bb = 1:length(all_boosters_ts)
            booster_effect{bb}(:, :, v) = [zeros(ns, vlag) squeeze(all_boosters_ts{bb}(:, 1:end-vlag, v))];
        end
    end

    compute_region = popu > -1;

    %% Cases

    % Fit variants transmission rates

    var_frac_all = var_frac_range{dom_idx};
    all_betas = cell(nl, 1);
    all_data_vars0 = cell(nl, 1);
    all_data_vars = zeros(ns, ns, thisday);

    dd = un;
    un_fact = 1;
    
    for l=1:nl
        variant_fact = squeeze(var_frac_all(:, l, :));
        data_var_s = cumsum(dd.*(variant_fact), 2);
        all_data_vars0{l} = data_var_s;
        all_data_vars(:, l, :) =  data_var_s;
    end

    rlag = scen_list.rlag(simnum);

    [all_betas, all_cont, fC,immune_infec, ALL_STATS, fC_age, rel_booster_effi] = Sp_multivar_beta_escape(all_data_vars, 0, total_population, k_l, scen_list.alpha(simnum), ...
        jp_l, un_fact, ag_case_frac, ag_popu_frac, waned_impact, booster_effect, booster_delay, ...
        rel_booster_effi, cross_protect, rlag, 1, 1);
    rate_change = nan(ns, horizon);
    rate_change(:) = 1;
    rate_change = rate_change.*mobility_effect(scen_list.mobility_scenarios(simnum), 1:horizon);
%%
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
    
    %% Adjust rates based on Rt
    % temp = this_Rt; 
    % unlearn_idx = [3:4];
    % for jj=1:ns
    %     for ii = 1:length(unlearn_idx)
    %         ll = unlearn_idx(ii);
    %         all_betas{ll}{jj} = all_betas{ll}{jj}*0;
    %         this_Rt(jj, ll) = 0;
    %     end
    %     all_betas{nl}{jj} = all_betas{nl}{jj}*scen_list.wild_advantage(simnum);
    % end
    Rt_all(simnum, :, :) = this_Rt;
    %%
    base_infec = dd*0;

    [infec, deltemp, immune_infec1, ALL_STATS_new, protected_popu_frac] = Sp_multivar_pred_escape(all_data_vars, 0, ...
        all_betas, total_population, k_l, horizon, jp_l, un_fact, base_infec, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, all_cont, external_infec_perc, ...
        booster_effect, booster_delay, rel_booster_effi, cross_protect, ALL_STATS, 1, 1); 

%     if ~isvector(un) % If un was true infections, readjust to caliberate with recent reporting
%         infec = base_infec(:, end) + (infec - base_infec(:, end)).*(data_4_s(:, end) - data_4_s(:, end-14))./(1+sum(un(:, end-13:end),2));
%         % Special treatment for Florida sawtooth!
%         %infec(11, :) = base_infec(11, end) + (infec(11, :) - base_infec(11, end)).*(data_4_s(11, end) - data_4_s(11, end-28))./(1+sum(un(11, end-27:end),2));
%     end
%% Fix high peaks
%     deltemp_allin = squeeze(sum(deltemp, 2));
%     for gg = 1:ag
%         deltemp_allin(:, :, gg) = smooth_fix_scale(deltemp_allin(:, :, gg), thisday, 1.2, 10);
%     end
%     deltemp1 = deltemp;
%     for l=1:nl
%         deltemp1(:, l, :, :) = deltemp_allin .* squeeze(deltemp(:, l, :, :)./sum(deltemp, 2));
%     end
    %deltemp = deltemp1;
%%

    all_data_vars_matrix = cumsum(squeeze(sum(deltemp, 4)), 3);
 
    pred_new_cases = squeeze(sum(deltemp(:, :, thisday+1:end, :), 2));
    new_infec_ag_0(simnum, :, :, :) = pred_new_cases;
    normalizer = sum(c3d1(:, thisday, :), 3)./un(:, thisday, :);
    pred_new_cases = pred_new_cases .* normalizer;
    net_infec_0(simnum, :, :) = cumsum(sum(pred_new_cases, 3), 2);


    rel_lineage_rates = ones(nl, 1);

    %%
    % Hosp
    P = 1 - (rel_lineage_rates'./max(rel_lineage_rates)).*((1-P_hosp)./(1-ag_wan_lb));

    T_full = thisday;
    base_hosp = 0;

    hk = 1; hjp = 1; hwin = floor([20*7/bin_sz; 7*7/bin_sz]); halpha = 0.98^bin_sz; hlags = 0;

    [hosp_rate, ci_h, fC_h] = get_death_rates_escape(deltemp(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates, P, ...
        hosp_cumu_ag(:, 1:thisday, :),  halpha, hk, hjp, hwin, 0.95, popu>-1, hlags);

    comp_h{simnum} = fC_h;
    temp_res = zeros(num_dh_rates_sample, ns, horizon);
    temp_res_ag = zeros(num_dh_rates_sample, ns, horizon, ag);
    for rr = 1:num_dh_rates_sample
        this_rate = hosp_rate;

        if rr ~= (num_dh_rates_sample + 1)/2
            for cid=1:ns
                for g=1:ag
                    this_rate{cid, g} = ci_h{cid, g}(:, 1) + (ci_h{cid, g}(:, 2) - ci_h{cid, g}(:, 1))*(rr-1)/(num_dh_rates_sample-1);
                end
            end
        end

        [~, pred_new_hosps_ag] = simulate_deaths_escape(deltemp, immune_infec, rel_lineage_rates, P, this_rate, hk, hjp, ...
            horizon, base_hosp, T_full-1);
        
        pred_hosps = cumsum(sum(pred_new_hosps_ag, 3), 2); 
        
        base_hosp(:) = 0;
        
        h_start = thisday-T_full+1;
        temp_res(rr, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
        temp_res_ag(rr, :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
        %        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
        %        new_hosp_ag_0(simnum+(jj-1)*size(scen_list, 1), :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
    end
    net_h_cell{simnum} = temp_res;
    net_h_ag_cell{simnum} = temp_res_ag;


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
    %%%%%%%% From infections
    hosp_preds_lins = deltemp;
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%
    P = 1 - (rel_lineage_rates'./max(rel_lineage_rates)).*((1-P_death)./(1-ag_wan_lb));
    temp_res = zeros(num_dh_rates_sample, ns, horizon);
    temp_res_ag = zeros(num_dh_rates_sample, ns, horizon, ag);

    T_full = thisday;
    base_deaths = deaths(:, T_full);

    %dk = 7; djp = 7; dwin = 75; dalpha = 0.95; dlags = 3;
    rel_lineage_rates1 = repmat(rel_lineage_rates(:)', [ns 1]); rel_lineage_rates1(:) = 1; % high severity already captured
    dalpha = 0.99^(bin_sz);
    [X, Y, Z, A, A1] = ndgrid([1:4], 1, floor([25*7/bin_sz]), [0:2], [1]);
    param_list = [X(:), Y(:), Z(:), A(:), A1(:)];
    val_idx = (param_list(:, 1).*param_list(:, 2) <=49) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))>2 & (param_list(:, 1) - param_list(:, 4))<5;
    param_list = param_list(val_idx, :);
    [best_death_hyperparam] = dh_age_hyper(hosp_preds_lins, immune_infec, rel_lineage_rates1, P_death, deaths_ag(:, 1:thisday, :), thisday, 0, param_list, dalpha);
    dk = best_death_hyperparam(:, 1); djp = best_death_hyperparam(:, 2);
    dwin = best_death_hyperparam(:, 3); dlags = best_death_hyperparam(:, 4); rel_lineage_rates1(:, wildcard_idx>0) = repmat(best_death_hyperparam(:, 5), [1 sum(wildcard_idx)]);

    [death_rate, ci_d, fC_d] = get_death_rates_escape(hosp_preds_lins(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates, P, ...
        deaths_ag(:, 1:thisday, :),  dalpha, dk, djp, dwin, 0.95, popu>-1, dlags);
    %%

    comp_d{simnum} = fC_d;

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
    net_d_ag_cell{simnum} = temp_res_ag;

    fprintf('.');
end

%%
for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
    net_death_0(idx, :, :) = net_d_cell{simnum};
    new_death_ag_0(idx, :, :, :) = net_d_ag_cell{simnum};
    net_hosp_0(idx, :, :) = net_h_cell{simnum};
    new_hosp_ag_0(idx, :, :, :) = net_h_ag_cell{simnum};
end
clear net_*_cell
fprintf('\n');

