
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


nl = length(lineages);
vacc_effi1 = 0.35; vacc_effi2 = 1 - vacc_effi1;
booster_delay = 210;
omic_idx=  find(contains(lineages, 'micron') | startsWith(lineages, 'BA'));
esc_param = 0.5;
rel_vacc_effi = ones(nl, 1); rel_vacc_effi(omic_idx) = esc_param;
rel_booster_effi = ones(nl, 1); rel_vacc_effi(omic_idx) = (1+esc_param)/2;
cross_protect = ones(length(lineages), length(lineages));
cross_protect(omic_idx, :) = esc_param ;
cross_protect(omic_idx, omic_idx) = 1;

rel_lineage_rates = ones(nl, 1);
rel_lineage_rates(omic_idx) = 1;

all_deltemps = cell(size(scen_list, 1), 1);
all_immune_infecs = cell(size(scen_list, 1), 1);

Rt_all = zeros(size(scen_list, 1), ns, nl);

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

    [all_betas, all_cont, fC,immune_infec, ALL_STATS] = multivar_beta_escape(all_data_vars, 0, popu, k_l, case_alpha, ...
        jp_l, un_fact, vacc_ag, ag_case_frac, ag_popu_frac, waned_impact, booster_effect, booster_delay, ...
        rel_vacc_effi, rel_booster_effi, cross_protect, rlag);
    rate_change = ones(length(popu), horizon);

    this_Rt = calc_Rt_all(all_betas, all_cont, ag_popu_frac, k_l, jp_l);
    Rt_all(simnum, :, :) = this_Rt;
    
    %%
    base_infec = data_4;

    [infec, deltemp, immune_infec, ALL_STATS_new] = multivar_pred_escape(all_data_vars, 0, ...
        all_betas, popu, k_l, horizon, jp_l, un_fact, base_infec, vacc_ag, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, all_cont, 0, ...
        booster_effect, booster_delay, rel_vacc_effi, rel_booster_effi, cross_protect, ALL_STATS);

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

    immune_infec = movmean(immune_infec, 7, 3);
    new_infec_ag_0(simnum, :, :, :) = pred_new_cases;
    bad_idx = (deltemp - immune_infec) < 0;
    immune_infec(bad_idx) = deltemp(bad_idx);

    all_deltemps{simnum} = deltemp;
    all_immune_infecs{simnum} = immune_infec;
    
    %%
    % Deaths
    P = 1 - (1-P_death)./(1-ag_wan_lb);
    temp_res = zeros(num_dh_rates_sample, length(countries), horizon);
    
    T_full = size(data_4, 2);
    base_deaths = deaths(:, T_full);
    rel_lineage_rates1 = repmat(rel_lineage_rates(:)', [ns 1]);
    

    [best_death_hyperparam] = dh_age_hyper(deltemp, immune_infec, rel_lineage_rates1, P_death, deaths_ag(:, 1:thisday, :), thisday, 0, param_list, dalpha);
    dk = best_death_hyperparam(:, 1); djp = best_death_hyperparam(:, 2);
    dwin = best_death_hyperparam(:, 3); dlags = best_death_hyperparam(:, 4); rel_lineage_rates1(:, omic_idx) = repmat(best_death_hyperparam(:, 5), [1 length(omic_idx)]);

%    dk = 5; djp = 7; dwin = 100; dlags = 1;

    [death_rate, ci_d, fC_d, ~] = get_death_rates_escape(deltemp(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates1, P, ...
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
        
        [pred_deaths, pred_new_deaths_ag] = simulate_deaths_escape(deltemp, immune_infec, rel_lineage_rates1, P, this_rate, dk, djp, ...
            horizon, base_deaths, T_full-1);

        temp_res(rr, :, :) = pred_deaths(:, 1:horizon);
    end
    net_d_cell{simnum} = temp_res;
    fprintf('.');
end

for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
    net_death_0(idx, :, :) = net_d_cell{simnum};
end