cid = 1:56; gg = 1:5;
plot(sum(diff(hosp_cumu_s(cid, :, gg), 1, 2), [1 3])); hold on
plot(397:(396+horizon), squeeze(sum(temp_res_ag(:, cid, :, gg), [2 4])))
%%
cid = 6; gg = 1:5;
plot(sum(diff(hosp_cumu_s(cid, :, gg), 1, 2), [1 3])); hold on
%plot(347:(346+horizon), squeeze(sum(new_hosp_ag_A(:, cid, :, gg), [2 4])))
plot(347:(346+horizon), squeeze((sum(new_hosp_ag_D(:, cid, :, gg), [2 4]))))
%%
qq = [0.05 0.25 0.5 0.75 0.95];
cid = 6; gg = 1:5;
plot(sum(diff(hosp_cumu(cid, :, gg), 1, 2), [1 3])); hold on
plot(347:(346+horizon), quantile(squeeze(sum(new_hosp_ag_D(:, cid, :, gg), [2 4])), qq))
%%
maxt = thisday;
cid = 3; ss = 1;
zero_date = datetime(2021, 9, 1);
ps = sort(unique(scen_list(:, ss)), 'descend');
%cc = ['y' 'g' 'b', 'c', 'r'];
cc = ['r' 'r' 'r' 'r' 'r'];
tiledlayout(1, 1);
nexttile;
plot(zero_date + (1:maxt-1), diff(sum(hosp_cumu_s(cid, :, :), [1 3]), 1, 2), '--'); hold on
max_peaks = squeeze(max(sum(new_hosp_ag_D(:, cid, :, :), [2 4]), [], 3));
prev_peaks = max(diff(sum(hosp_cumu_s(cid, :, :), [1 3]), 1, 2), [], 2);
bad_sims = max_peaks > 30*prev_peaks | max_peaks < prev_peaks/4;
%bad_sims(:) = 0;
for ii=1:length(ps)    
    idx = zeros(size(new_hosp_ag_0, 1), 1);
    scen_picks = scen_list(:, ss)==ps(ii);
    for dd=1:num_dh_rates_sample
        idx(dd:num_dh_rates_sample:end) = scen_picks;
    end
    plot(zero_date + (maxt:maxt+horizon-1), squeeze((sum(new_hosp_ag_D(idx & ~bad_sims, cid, :, :), [2 4]))), cc(ii)); hold on;
    
end
hold off;
xlabel('Date'); ylabel('Reported Hospitalizations');
%%
