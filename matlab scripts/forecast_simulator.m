num_boosters = length(all_boosters_ts);

ns = size(data_4, 1);
T = size(data_4, 2);
ag = 2;

vacc_ag = zeros(ns, T+horizon, ag);
vacc_ag(:, :, 1) = vacc_given_by_age(:, 1:T+horizon, 1);
for ii=1:size(all_boosters_ts)
    if size(all_boosters_ts{ii}, 3)==1
        booster_given_by_age = zeros(ns, T+horizon, 2);
        booster_given_by_age(:, :, 1) = all_boosters_ts{ii}(:, 1:T+horizon, 1);
        all_boosters_ts{ii} = booster_given_by_age;
    end
end

ag_case_frac = zeros(ns, T, 2);
ag_case_frac(:, :, 1) = 1;
ag_popu_frac = 1e-20*ones(ns, ag); ag_popu_frac(:, 1) = 1;

data_4_ag = zeros(ns, T, 2); deaths_ag = zeros(ns, T, 2);
data_4_ag(:, :, 1) = data_4_s;
deaths_ag(:, :, 1) = deaths_s;
hosp_cumu_ag = zeros(ns, T, 2);

if hosp_available > 0
    hosp_cumu_ag(:, :, 1) = hosp_cumu;
else
    hosp_cumu = 0;
end


nl = length(lineages);
vacc_effi1 = 0.35; vacc_effi2 = 1 - vacc_effi1;
booster_delay = repmat({150}, [length(all_boosters_ts) 1]);
booster_delay(1:4) = {0; 14; 210; 180};

fd_effi = 0.35; b_effi = 0.1;
esc_param = 0.5; esc_param2 = 0.5; esc_param_w = 0.5;

pre_omic_idx = startsWith(lineages, 'pre');
wildcard_idx = startsWith(lineages, 'wild');
omic_idx2 =  contains(lineages, {'ba.4', 'ba.5', 'ba.2.75', 'other'}, 'IgnoreCase', true);
omic_idx =  ~(pre_omic_idx | wildcard_idx | omic_idx2);

rel_vacc_effi = ones(nl, 1);
rel_vacc_effi(omic_idx) = esc_param;
rel_vacc_effi(omic_idx2) = esc_param2*esc_param;
rel_vacc_effi(wildcard_idx) = esc_param_w*esc_param;

cross_protect = ones(length(lineages), length(lineages));
cross_protect(omic_idx, pre_omic_idx) = esc_param ;
cross_protect(omic_idx, omic_idx) = 1;

esc_param2 = 0.5; % For ba4 and ba5 over omicron
cross_protect(omic_idx2, :) = esc_param2*esc_param;
cross_protect(omic_idx2, omic_idx2|wildcard_idx) = 1;
cross_protect(wildcard_idx, :) = esc_param_w;
cross_protect(wildcard_idx, wildcard_idx) = 1;

rel_booster_effi = cell(num_boosters, 1);
rel_booster_effi{1} = rel_vacc_effi*fd_effi;
rel_booster_effi{2} = rel_vacc_effi;
for bb=3:num_boosters
    rel_booster_effi{bb} = ones(nl, T+horizon);
    rel_booster_effi{bb}(omic_idx2, :) = b_effi + esc_param2*esc_param*(1-b_effi);
    rel_booster_effi{bb}(omic_idx, :) = b_effi + esc_param*(1-b_effi);
    rel_booster_effi{bb}(wildcard_idx, :) = b_effi +esc_param_w*(1-b_effi);
    if reform_boost_day > 0
        rel_booster_effi{bb}(:, reform_boost_day:end) = 1;
        rel_booster_effi{bb}(wildcard_idx, reform_boost_day:end) = esc_param_w;
    end
end

rel_lineage_rates = ones(nl, 1);
rel_lineage_rates(omic_idx) = 1;

all_deltemps = cell(size(scen_list, 1), 1);
all_immune_infecs = cell(size(scen_list, 1), 1);

Rt_all = zeros(size(scen_list, 1), ns, nl);
err = zeros(size(scen_list, 1), ns, nl);

if ~isempty(gcp('nocreate'))
    pctRunOnAll warning('off', 'all')
else
    parpool;
    pctRunOnAll warning('off', 'all')
end
parfor simnum = 1:size(scen_list, 1)
    wan_idx = scen_list(simnum, 6);
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


    un = un_array{scen_list(simnum, 1)}; % Under-reporting
    if isvector(un)
        bad_un = un.*data_4(:, end).*(1-vacc_ag(:, end)./popu) + vacc_ag(:, end) > 0.9*popu;
        un(bad_un) = 1;
    end

    dom_idx = scen_list(simnum, 3); % uncertainty in the dominant variant/VOC

    rlag = rlag_list(scen_list(simnum, 4));
    booster_cov_idx = scen_list(simnum, 5);

    ns = length(popu);
    vac_effect_all = vacc_ag;

    booster_given_by_age = all_boosters_ts{booster_cov_idx};
    booster_effect = booster_given_by_age;

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

    rate_change = ones(length(popu), horizon);

    this_Rt = calc_Rt_all(all_betas, all_cont, ag_popu_frac, k_l, jp_l);
    Rt_all(simnum, :, :) = this_Rt;

    this_err = calc_error_fC(fC);
    err(simnum, :, :) = this_err;

    %%
    base_infec = data_4;

    [infec, deltemp, immune_infec1, ALL_STATS_new, protected_popu_frac] = Sp_multivar_pred_escape(all_data_vars, 0, ...
        all_betas, popu, k_l, horizon, jp_l, un_fact, base_infec, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, all_cont, 0, ...
        booster_effect, booster_delay, rel_booster_effi, cross_protect, ALL_STATS);

    if ~isvector(un) % If un was true infections, readjust to caliberate with recent reporting
        infec = base_infec(:, end) + (infec - base_infec(:, end)).*(data_4_s(:, end) - data_4_s(:, end-14))./sum(un(:, end-13:end),2);
    end

    T_full = size(data_4, 2);
    all_data_vars_matrix = cumsum(squeeze(sum(deltemp, 4)), 3);
    pred_new_cases = squeeze(sum(deltemp, 2));
    pred_new_cases = pred_new_cases(:, thisday+1 : thisday+horizon, :);
    %     infec_data = squeeze(sum(all_data_vars_matrix, 2));
    %     infec_net = infec_data(:, T_full+1:end) - infec_data(:, T_full) + data_4(:, end);
    %     infec_net = cumsum([infec_net(:, 1) movmean(diff(infec_net, 1, 2), 7, 2)], 2);
    net_infec_0(simnum, :, :) = infec;

    immune_infec = movmean(immune_infec1, 7, 3);
    new_infec_ag_0(simnum, :, :, :) = pred_new_cases;
    bad_idx = (deltemp - immune_infec) < 0;
    immune_infec(bad_idx) = deltemp(bad_idx);

    all_deltemps{simnum} = deltemp;
    all_immune_infecs{simnum} = immune_infec;
    death_source = deltemp; % Which time-series leads to death?
        %%
    % Hosp
    if hosp_available > 0
        P = 1 - (1-P_hosp)./(1-ag_wan_lb);
        %T_full = hosp_data_limit;
        base_hosp = hosp_cumu(:, end);
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
        hk = 3; hjp = 2; hwin = 100; halpha = 0.95; hlags = 0;

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
            temp_res = zeros(num_dh_rates_sample, ns, horizon);
            temp_res_ag = zeros(num_dh_rates_sample, ns, horizon, ag);
            temp_res(rr, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
            temp_res_ag(rr, :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
            %        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
            %        new_hosp_ag_0(simnum+(jj-1)*size(scen_list, 1), :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
        end
        net_h_cell{simnum} = temp_res;
        %net_h_ag_cell{simnum} = temp_res_ag;

        %%%%% Deaths from hospitalizations?
        mid_idx = (num_dh_rates_sample + 1)/2;
        hosp_preds_lins = zeros(ns, nl, T+horizon, ag);
        for l=1:nl
            for gg=1:ag
                hosp_preds_lins(:, l, :, gg) = rel_lineage_rates(l)*squeeze(deltemp(:, l, :, gg)./sum(deltemp(:, :, :, gg), 2)).*[diff([ zeros(ns, 1) squeeze(hosp_cumu_ag(:, 1:thisday, gg))], 1, 2) ...
                    squeeze(temp_res_ag(mid_idx, :, 1:horizon, gg))];
            end
        end
        hosp_preds_lins(isnan(hosp_preds_lins)) = 0;
        death_source = hosp_preds_lins; 
        %%%%%%%%%%%%%%%%
    end
    %%
    % Deaths
    P = 1 - (1-P_death)./(1-ag_wan_lb);
    temp_res = zeros(num_dh_rates_sample, length(countries), horizon);

    T_full = size(data_4, 2);
    base_deaths = deaths(:, T_full);
    rel_lineage_rates1 = repmat(rel_lineage_rates(:)', [ns 1]);


    [best_death_hyperparam] = dh_age_hyper(death_source, immune_infec, rel_lineage_rates1, P_death, deaths_ag(:, 1:thisday, :), thisday, 0, param_list, dalpha);
    dk = best_death_hyperparam(:, 1); djp = best_death_hyperparam(:, 2);
    dwin = best_death_hyperparam(:, 3); dlags = best_death_hyperparam(:, 4); rel_lineage_rates1(:, foc_idx) = repmat(best_death_hyperparam(:, 5), [1 length(foc_idx)]);

    %    dk = 5; djp = 7; dwin = 100; dlags = 1;

    [death_rate, ci_d, fC_d, ~] = get_death_rates_escape(death_source(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates1, P, ...
        deaths_ag(:, 1:thisday, :),  dalpha, dk, djp, dwin, 0.99, popu>-1, dlags);

    %[death_rate, ci_d, fC_d, ~, rel_lineage_rates1] = get_death_rel_rates_escape(deltemp(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates1, P, deaths_ag(:, 1:thisday, :),  dalpha, dk, djp, dwin, 0.95, popu>-1, dlags);
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

        [pred_deaths, pred_new_deaths_ag] = simulate_deaths_escape(death_source, immune_infec, rel_lineage_rates1, P, this_rate, dk, djp, ...
            horizon, base_deaths, T_full-1);

        temp_res(rr, :, :) = pred_deaths(:, 1:horizon);
    end
    net_d_cell{simnum} = temp_res;
    fprintf('.');
end
%% Prune the samples to get rid of bad fits
bad_sims = zeros(ns, size(scen_list, 1));
for cid = 1:ns
    this_er = squeeze(sum(err(:, cid, :), 3));
    [~, err_idx] = sort(this_er, 'descend', 'MissingPlacement','first');
    bad_sims(cid, err_idx(1:floor(size(bad_sims, 2)/2))) = 1;
    net_infec_0(bad_sims(cid, :)>0, cid, :) = net_infec_0(bad_sims(cid, :)< 1, cid, :);
end

%%

for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
    xx = net_d_cell{simnum};
    xx(:, bad_sims(:, simnum)>0, :) = nan;
    net_death_0(idx, :, :) = xx;

    if hosp_available > 0
        xx = net_h_cell{simnum};
        xx(:, bad_sims(:, simnum)>0, :) = nan;
        net_hosp_0(idx, :, :) = xx;
    end
end

for cid = 1:ns
    xx = net_death_0(:, cid, :);
    bad_idx = any(isnan(xx), 3);
    net_death_0(bad_idx, cid, :) = net_death_0(~bad_idx, cid, :);
    if hosp_available > 0 
        xx = net_hosp_0(:, cid, :);
        bad_idx = any(isnan(xx), 3);
        net_hosp_0(bad_idx, cid, :) = net_hosp_0(~bad_idx, cid, :);
    end
end
%% Remove unusual simulations
for cid=1:length(popu)
    thisdata = net_infec_0(:, cid, :);
    approx_target = interp1([1 2], [data_4_s(cid, end-1)-data_4_s(cid, end-2), data_4_s(cid, end) - data_4_s(cid, end-1)], 3, 'linear', 'extrap');
    bad_idx = abs(thisdata(:, 1)-data_4(cid, end)) < 0.3*approx_target;
    net_infec_0(bad_idx, cid, :) = nan;
    thisdata = net_death_0(:, cid, :);
    approx_target = interp1([1 2], [deaths_s(cid, end-1)-deaths_s(cid, end-2), deaths_s(cid, end) - deaths_s(cid, end-1)], 3, 'linear', 'extrap');
    bad_idx = abs(thisdata(:, 1)-deaths(cid, end)) < 0.3*approx_target;
    net_death_0(bad_idx, cid, :) = nan;
    bad_idx = abs(thisdata(:, 1)-deaths(cid, end)) > 2*approx_target;
    net_death_0(bad_idx, cid, :) = nan;

    if hosp_available > 0
        thisdata = net_hosp_0(:, cid, :);
        approx_target = interp1([1 2], [hosp_cumu_s(cid, end-1)-hosp_cumu_s(cid, end-2), hosp_cumu_s(cid, end) - hosp_cumu_s(cid, end-1)], 3, 'linear', 'extrap');
        bad_idx = abs(thisdata(:, 1)) < 0.3*approx_target;
        net_hosp_0(bad_idx, cid, :) = nan;
        bad_idx = abs(thisdata(:, 1)) > 2*approx_target;
        net_hosp_0(bad_idx, cid, :) = nan;
    end

end
