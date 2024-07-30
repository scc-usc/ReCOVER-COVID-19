addpath('../../../shapelets/');
addpath('../../../shapelets/shapelet_space_matlab/');
load underreporting_facts.mat


T = maxt; T = 104;
thisday = T;

%%
horizon = 52;
un_list{1} = un_lb; un_list{2} = un_mid; un_list{3} = un_ub;
un_list_idx = [1 2 3];
alpha_list = [0.8 0.85 0.9 0.95];
wan_lb_list = [0 0.4 0.6];
wan_med_list = [30, 60, 90];
wan_eff_frac_list = [0.2, 0.5]; %if x, then x*wan_med is the effi_week of 0.99
[X1, X2, X3, X4, X5] = ndgrid(un_list_idx, alpha_list, wan_lb_list, wan_med_list, wan_eff_frac_list);
scen_list = [X1(:) X2(:), X3(:), X4(:), X5(:)];
num_sims = size(scen_list, 1);
%%
dtw_error_all = cell(num_sims, 1);
deltemp_all = cell(num_sims, 1);
dtw_med_error = nan(num_sims, 1);

parfor simnum = 1:num_sims
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
        jp, 1, ag_case_frac, ag_popu_frac, waned_impact, [], [], ...
        [], [], [], 1, 1, [], [], age_transit);

    rate_change = ones(ns, horizon);
    base_infec = zeros(ns, T);

    [infec, deltemp, immune_infec1, ALL_STATS_new, protected_popu_frac] = Sp_multivar_pred_escape(all_data_vars, 0, ...
        all_betas, popu, k, horizon, jp, 1, base_infec, rate_change, ...
        ag_case_frac, ag_popu_frac, waned_impact, all_cont, 0, ...
        [], [], [], [], ALL_STATS, 1, 1, [], [], age_transit);

    deltemp_all{simnum} = deltemp;

    dtw_norm_err = zeros(ns, ag);
    for gg=1:ag
        for cid = 1:ns
            preds = prod_2w3(1./urep(cid, gg), squeeze(deltemp(cid, 1, :, gg)));
            gt = squeeze(hosps_3D_s(cid, :, gg));
            T_end = min(length(preds), length(gt));
            t1 = gt(T:T_end); t1 = t1(:)';
            t2 = preds(T:T_end); t2 = t2(:)';
            dtw_norm_err(cid, gg) = dtw_cons_md(t1, t2, 4)/max(gt(T:T_end))^2;
        end
    end
    dtw_error_all{simnum} = dtw_norm_err;
    dtw_med_error(simnum) = median(median(dtw_norm_err));

    fprintf('.');
end

%%
save retro_results -v7