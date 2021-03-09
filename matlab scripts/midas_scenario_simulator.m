net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(size(scen_list, 1)*length(lags_list), size(data_4, 1), horizon);
net_hosp_0 = zeros(size(scen_list, 1)*length(lags_list), size(data_4, 1), horizon);

for simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1));
    lags = scen_list(simnum, 2);
    %beta_after = var_ind_beta_un(data_4_s(:, 1:end-lags), 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, popu>-1);
    j = find(lags_list==lags); uid = find(un_list==scen_list(simnum, 1));
    beta_after = infec_rates_list{j(1)}{uid(1)};
    
    vacc_coverage = scen_list(simnum, 7);
    
    vac_distributed_ts = (1./vacc_coverage)*(popu./sum(popu))*ones(1, 200)*vacc_monthly/31;
    vac_effi = equiv_vacc_effi*vacc_coverage;
    vrate = vacc_ad_dist(:, end-scen_list(simnum, 3));
    vac_available = [latest_vac, vrate.*vac_distributed_ts];
    vac_effect = cumsum(vac_available*vac_effi, 2);
    vac_given = cumsum(vac_available, 2) - repmat(hc_num.*popu/sum(popu), [1 size(vac_available, 2)]); vac_given = 0.5*(vac_given+abs(vac_given));
    
    dh_rate_change = get_rate_change_vac(dr_by_age, popu_by_age, vac_effi, vac_given);
    h_rate_change = get_rate_change_vac(hr_by_age, popu_by_age, vac_effi, vac_given);
    Rt_init = Rt_mat(:, end);
    Rt_final = Feb_Rt(:, scen_list(simnum, 5)) + max(zeros(size(Feb_Rt, 1), 1), npi_red*(Target_Rt(:, scen_list(simnum, 6)) - Feb_Rt(:, scen_list(simnum, 5))));
    rate_change = intermed_betas([], [], [], [], horizon, Rt_init, Rt_final);
    
    current_prev = scen_list(simnum, 4);
    variant_rt_change(:, 1) = 1;
    variant_rt_change(:, tt1) = (0.5*1.5+0.5*1)/(current_prev*1.5+(1-current_prev));
    variant_rt_change(:, tt2) = (1*1.5+0*1)/(current_prev*1.5+(1-current_prev));
    variant_rt_change = fillmissing(variant_rt_change, 'linear', 2);
    variant_rt_change(:, tt2:end) = repmat(variant_rt_change(:, tt2), [1, size(variant_rt_change, 2)-tt2+1]);
    rate_change = rate_change.*variant_rt_change(:, 1:size(rate_change, 2));
    
    %%% Cases
%     %%% Iterative
%     for cid = 1:size(data_4, 1)
%         
%         base_infec = data_4(cid, end);
%         un = un_array(cid, scen_list(simnum, 1));
% %         infec_un1 = var_simulate_pred_vac(data_4_s(cid, 1:end), 0, beta_after(cid), popu(cid), best_param_list(cid, 1), phase1_len(cid), best_param_list(cid, 2), un, base_infec, [0*vacc_lag_rate(cid, :), vac_effect(cid, 1:phase1_len(cid))]);
%         infec_un1 = [];
%         infec_dat = [data_4_s(cid, 1:end), infec_un1-base_infec+data_4_s(cid, end)];
%         base_infec = infec_un1(end);        
%         
%         infec_un2 = var_simulate_pred_vac(infec_dat, 0, beta_after(cid), popu(cid), best_param_list(cid, 1), horizon - phase1_len(cid), best_param_list(cid, 2), un, base_infec, vac_effect(cid, max([1, phase1_len(cid)-size(vacc_lag_rate, 2)]):end), rate_change(cid, :));
%         net_infec_0(simnum, cid, :) = [infec_un1 infec_un2];
%     end
        %%%% Full matrix version (faster)
        base_infec = data_4(:, end);
        un = un_array(:, scen_list(simnum, 1));
        infec_un2 = var_simulate_pred_vac(data_4_s, 0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec, vac_effect, rate_change);
        net_infec_0(simnum, :, :) = [infec_un2];

        
    % Deaths
    for jj = 1:length(death_rates_list)
        death_rates = death_rates_list{1};
        this_rate_change = intermed_betas(death_rates, best_death_hyperparam, death_rates_list{jj}, best_death_hyperparam, rate_smooth);
        this_rate_change = [this_rate_change, repmat(this_rate_change(:, end), [1 2*size(dh_rate_change, 2)-size(this_rate_change, 2)])];
        dh_rate_change1 = dh_rate_change;
        dh_rate_change1 = [vacc_lag_rate, dh_rate_change1./dh_rate_change1(:, 1)].*this_rate_change(:, 1:(size(dh_rate_change1, 2)+size(vacc_lag_rate, 2)));
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        [pred_deaths] = var_simulate_deaths_vac(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1, dh_rate_change1);
        net_death_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_deaths(:, 1:horizon);
    end
    % Hosp
    for jj = 1:length(death_rates_list)
        hosp_rates = hosp_rates_list{1};
        this_rate_change = intermed_betas(hosp_rates, best_hosp_hyperparam, hosp_rates_list{jj}, best_hosp_hyperparam, rate_smooth);
        this_rate_change = [this_rate_change, repmat(this_rate_change(:, end), [1 2*size(dh_rate_change, 2)-size(this_rate_change, 2)])];
        dh_rate_change1 = h_rate_change;
        dh_rate_change1 = [vacc_lag_rate, dh_rate_change1./dh_rate_change1(:, 1)].*this_rate_change(:, 1:(size(dh_rate_change1, 2)+size(vacc_lag_rate, 2)));
        T_full = hosp_data_limit;
        infec_data = [data_4_s squeeze(net_infec_0(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        base_hosp = hosp_cumu(:, T_full);
        pred_hosps = var_simulate_deaths_vac(infec_data, hosp_rates, hk, hjp, hhorizon, base_hosp, T_full-1, dh_rate_change1);
        h_start = size(data_4, 2)-T_full+1;
        net_hosp_0(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_hosps(:, h_start:h_start+horizon-1);
    end
    fprintf('.');
end
fprintf('\n');