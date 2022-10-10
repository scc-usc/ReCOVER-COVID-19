M_0 = repmat(M0,1,size(data_4,3));
dh_sims = size(scen_list, 1)*num_dh_rates_sample;
% net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(dh_sims, size(data_4, 1), horizon);
net_hosp_0 = zeros(dh_sims, size(data_4, 1), horizon);
% new_infec_ag_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon, size(vacc_ag, 3));
new_death_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_cov, 3));
new_hosp_ag_0 = zeros(dh_sims, size(data_4, 1), horizon, size(vacc_cov, 3));

net_d_cell = cell(size(scen_list*num_dh_rates_sample, 1), 1);
net_d_ag_cell = cell(size(scen_list*num_dh_rates_sample, 1), 1);
net_h_cell = cell(size(scen_list*num_dh_rates_sample, 1), 1);
net_h_ag_cell = cell(size(scen_list*num_dh_rates_sample, 1), 1);

parfor simnum = 1:size(scen_list, 1)
%for simnum = 1:1
    rlag = rlags(scen_list(simnum, 2));
    un = un_array(:, scen_list(simnum, 1));
    un = repmat(un,1,size(data_4,3));
    season = scen_list(simnum, 3);
    shift = scen_list(simnum, 4);

    %Select which season's data to get prior betas from
    if season == 0
        old_data = reshape(diff(hosp_cumu_s,1,2),size(diff(hosp_cumu_s,1,2),1),1,size(diff(hosp_cumu_s,1,2),2),size(diff(hosp_cumu_s,1,2),3));   
        hosp_cumu_s_old = hosp_cumu_s;
    else
        hosp_cumu_s_old = select_old(hosp_dat_old,thisday,season); %Selects & smoothes the old data
        old_data = reshape(diff(hosp_cumu_s_old,1,2),size(diff(hosp_cumu_s_old,1,2),1),1,size(diff(hosp_cumu_s_old,1,2),2),size(diff(hosp_cumu_s_old,1,2),3));   
    end
%   halpha = scen_list(simnum, 3);
%%
    vac_effect_all = zeros(size(hosp_cumu_s));
    vac_effect_pred = vacc_ag;
    pad_time = 1+size(hosp_cumu,2 ) - size(vacc_ag, 2);
    for v = 1:size(vacc_cov, 3) % Past vax_effect is the mean of opti and pessi
        vac_effect_all(:, pad_time:end, v) = 0.01*popu_ag(:, v).*(0.5*(vacc_A_B(:, :, v) + vacc_C_D(:, :, v))*(high_VE(v)+low_VE(v))*0.5);
    end
    vac_effect_all(isnan(vac_effect_all)) = 0;
    for v = 1:size(vacc_ag, 3)
        vac_effect_pred(:, :, v) = 0.01*popu_ag(:, v).*vacc_ag(:, :, v)*vacc_effi(v);
    end

    % Fit variants transmission rates
    T_full = size(data_4, 2);
    ns = length(popu);
    var_frac_all = ones(size(data_4));
    
    all_data_vars0 = cell(length(1), 1);
%%
    all_data_vars_noisy = reshape(diff(hosp_cumu,1,2),size(diff(hosp_cumu,1,2),1),1,size(diff(hosp_cumu,1,2),2),size(diff(hosp_cumu,1,2),3));%hosp_cumu_s;
    all_data_vars = reshape(diff(hosp_cumu_s,1,2),size(diff(hosp_cumu_s,1,2),1),1,size(diff(hosp_cumu_s,1,2),2),size(diff(hosp_cumu_s,1,2),3));%hosp_cumu_s;
    eps = 10^-3;
    
    M0_old = M_0; M0_old(:) = (0.33+0.165)/2;
    %Find beta
    hosp_cumu_rec = hosp_cumu;
    for g=1:length(age_groups)
        hosp_cumu_rec(:, :, g) = hosp_cumu(:, :, g) - hosp_cumu(:, end-2*window_size-1, g);
    end
    %For previous year, we only need recent immunity and recent data 
    [all_betas2, ci, fC, ~, all_M] = get_betas_age_AoN(all_data_vars, zeros(size(all_data_vars)), 1, 0, hosp_cumu_rec, 1, hk, hjp, 2*window_size, 0.5, ones(ns,1), 0, M_0, vac_effect_all*0, un, popu_ag);
    %%%% Estimate prior betas and their rate change. Betas start from day1 (august14th)
    [all_betas, rate_change_ag] = get_prior_betas(old_data(:, :, 1:thisday-rlag-1,:),hosp_cumu_s_old(:, 1:thisday-rlag,:),vac_effect_all,1, hk, hjp, window_size, 0, M0_old, un, popu_ag, season);
    %%%%%
    
    %%
    temp_res = zeros(num_dh_rates_sample, ns, horizon);
    temp_res_ag = zeros(num_dh_rates_sample, ns, horizon, length(age_groups));
%%
    %Find future Initial Conditions and occurence based on the past 
    [IC,t_prime] = future_IC(old_data,age_groups,abvs,hk,now_date);
    all_data_vars(:, :, 1:end-2*window_size, :) = 0;
    %For each sampled Betas, get a projection
    for s=1:num_dh_rates_sample
        for j=1:ns
            for g = 1:length(age_groups)
                all_betas2{j, g} = ci{j, g}(:, 1) + (ci{j, g}(:, 2) - ci{j, g}(:, 1))*s/(num_dh_rates_sample-1+ eps);
            end
        end
        xx = cellfun(@(x)(sum(x)), all_betas2);
        yy = (1-all_M).*xx*7;
        for g=1:length(age_groups)
            bad_idx = yy(:, g) < 0.1/7 | xx(:, g) > 2/7 ; % R0 < 0.1!!
            med_idx = find(abs(xx(:, g) - median(xx(~bad_idx, g))) < 0.02); % close to median
            all_betas2(bad_idx, g) = all_betas2(med_idx(1), g);
%             bad_idx = find(yy(:, g) > 1.5);
%             for idx=1:length(bad_idx)
%                 all_betas2{bad_idx(idx), g} = 1.5*all_betas2{bad_idx(idx), g}./yy(bad_idx(idx), g) ;
%             end
        end

        rate_change_ag_sel = repmat((trimmean(rate_change_ag(:, :, :), 0.5, 1)), [ns 1 1]);
        
        %Apply shift
        rate_change_ag_sel = circshift(rate_change_ag_sel,[0,shift]);
        t_prime = t_prime + shift;
        t_prime(t_prime<0) = t_prime(t_prime<0)+size(old_data,3);
    
        %rate_change_ag_sel(:) = 1; 
        %IC(:) = 0;
        [pred_hosps, pred_new_hosps_ag] = simulate_pred_age_AoN(all_data_vars, zeros(size(all_data_vars)), ...
            1, 0, all_betas2, hk, hjp, horizon, zeros(ns,horizon), T_full-1, rate_change_ag_sel(:,1:horizon,:), M_0, vac_effect_pred, un, popu_ag,IC,t_prime);
        
        h_start = size(data_4, 2)-T_full+1;
        temp_res(s, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - zeros(ns,horizon);
        temp_res_ag(s, :, :, :) = pred_new_hosps_ag(:, 1:horizon, :);
   
    end
    net_h_cell{simnum} = temp_res;
    net_h_ag_cell{simnum} = temp_res_ag;
    %Assuming a 0 lag 
    net_d_cell{simnum} = temp_res.*mean(multiplier_T);
    net_d_ag_cell{simnum} = temp_res_ag.*permute(multiplier, [4 3 1 2]);
    fprintf('.');
end

%% Is this needed?
for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
    net_hosp_0(idx, :, :) = net_h_cell{simnum};
    new_hosp_ag_0(idx, :, :, :) = net_h_ag_cell{simnum};

    net_death_0(idx, :, :) = net_d_cell{simnum};
    new_death_ag_0(idx, :, :, :) = net_d_ag_cell{simnum};

end
%clear net_*_cell
fprintf('\n');