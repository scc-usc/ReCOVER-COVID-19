%%
net_hosp_0 = zeros(num_sims, ns, horizon, ag);
err = zeros(num_sims, ns, nl);
% Create pseudo vaccines that do not change immunity only severity
pseudo_vax = cell(1,1);
pseudo_vax{1} = zeros(ns, T + horizon, ag);
%%
deltemp_all = cell(num_sims, 1);
dtw_med_error = nan(num_sims, 1);

if reuse_betas == 0
    saved_rates = cell(num_sims, 1);
end


parfor simnum = 1:num_sims
%for simnum = 1:1
    this_un = un_list{scen_list(simnum, 1)};
    this_alpha = scen_list(simnum, 2);
    nl = 2; urep = 1./this_un;
    ag_popu_frac = pop_by_age./sum(pop_by_age, 2);

    compute_region = popu > -1;
    var_frac_all = zeros(ns, 2, T);
    var_frac_all(:, 1, :) = 1;

    nw = ceil((T+horizon)/1)+1;
    waned_impact = zeros(nl, nw, nw, ag);
    tdiff_matrix = (0:1:(nw-1))' - (0:1:(nw-1));
    tdiff_matrix(tdiff_matrix <= 0) = -Inf;

    ag_wan_lb = scen_list(simnum, 3)*ones(ag, 1);
    ag_wan_param = scen_list(simnum, 4)*ones(ag, 1);
    vacc_effi_60 = 0.99*ones(ag, 1);
    week_at_effi = scen_list(simnum, 5)*ag_wan_param(1);

    for idx = 1:ag
        for ll=1:nl
            [k, theta] = gamma_param_med(ag_wan_param(idx), ag_wan_lb(idx), vacc_effi_60(idx), week_at_effi);
            waned_impact(ll, :, :, idx) = (1-ag_wan_lb(idx)).*gamcdf(tdiff_matrix, k, theta);
        end
    end
    waned_impact(isinf(waned_impact)) = 0;
    waned_impact(isnan(waned_impact)) = 0;

    un_ag = ones(ag, 1);
    un_3d = prod_2w3(urep, hosps_3D_s(:, 1:T, :));
    vac_factor = 1 - prod_2w3(1./pop_by_age, all_boosters_ts{1}(:, 1:T, :));
    un_3d = un_3d./vac_factor;

    un = squeeze(sum(un_3d, 3));
    ag_case_frac = un_3d./(1e-30 + sum(un_3d, 3));
    age_transit = 1./(52*(age_groups_r - age_groups_l));

    all_data_vars0 = cell(nl, 1);
    all_data_vars = zeros(ns, nl, thisday);
    k = 2; jp = 1;
    dd = un;
    un_fact = 1;

    for l=1:nl
        variant_fact = squeeze(var_frac_all(:, l, :));
        data_var_s = cumsum(dd.*(variant_fact), 2);
        all_data_vars0{l} = data_var_s;
        all_data_vars(:, l, :) =  data_var_s;
    end

    [all_betas, all_cont, fC,immune_infec, ALL_STATS, ~, rel_booster_effi] = Sp_multivar_beta_escape(all_data_vars, 0, popu, k, this_alpha, ...
        jp, 1, ag_case_frac, ag_popu_frac, waned_impact, pseudo_vax, [], ...
        zeros(nl, 1), [], [], 1, 1, [], [], age_transit);
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

    

    if reuse_betas == 0 % If we want to reuse the rates learned here for other scenarios
        these_res = struct;
        these_res.all_betas = all_betas;
        these_res.all_cont = all_cont;
        saved_rates{simnum}  = these_res;
    else                % % If we need to reuse previous rates
        these_res = saved_rates{simnum};
        all_betas = these_res.all_betas;
        all_cont = these_res.all_cont;
    end

    
    err(simnum, :, :) = this_err;

    rate_change = ones(ns, horizon);
    base_infec = zeros(ns, T);

    [infec, deltemp, immune_infec1, ALL_STATS_new, protected_popu_frac] = Sp_multivar_pred_escape(all_data_vars, 0, ...
        all_betas, popu, k, horizon, jp, 1, base_infec, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, all_cont, 0, ...
        pseudo_vax, [], zeros(nl, 1), [], ALL_STATS, 1, 1, [], [], age_transit);

    deltemp_all{simnum} = deltemp;
    vac_factor = 1 - prod_2w3(1./pop_by_age, all_boosters_ts{1}(:, T+1 : T+horizon, :));

    net_hosp_0(simnum, :, :, :) = prod_2w3(1./urep, squeeze(deltemp(:, 1, T+1 : T+horizon, :))) .* vac_factor;

    fprintf('.');
end

