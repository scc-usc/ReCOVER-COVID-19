%% Get hosp rates

hosp_trends_A = get_rates(net_hosp_A, net_infec_A, (1:56));
hosp_trends_B = get_rates(net_hosp_B, net_infec_B, (1:56));
hosp_trends_C = get_rates(net_hosp_C, net_infec_C, (1:56));
hosp_trends_D = get_rates(net_hosp_D, net_infec_D, (1:56));
%%
TT = datetime(2020, 1, 23) + (1:1000);
tiledlayout('flow');
nexttile; plot(TT(2:T_full), diff(nansum(hosp_cumu_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(hosp_trends_A, [0.025 0.5 0.975])'); hold off;
ylabel('inc. hosp/inc. cases');
title('High Vac, Low Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, Inf]);

nexttile; plot(TT(2:T_full), diff(nansum(hosp_cumu_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(hosp_trends_B, [0.025 0.5 0.975])'); hold off;
ylabel('inc. hosp/inc. cases');
title('High Vac, High Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, Inf]);

nexttile; plot(TT(2:T_full), diff(nansum(hosp_cumu_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(hosp_trends_C, [0.025 0.5 0.975])'); hold off;
ylabel('inc. hosp/inc. cases');
title('Low Vac, Low Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, Inf]);

nexttile; plot(TT(2:T_full), diff(nansum(hosp_cumu_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(hosp_trends_D, [0.025 0.5 0.975])'); hold off;
ylabel('inc. hosp/inc. cases');
title('Low Vac, High Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, Inf]);

%% Get deaths rates

death_trends_A = get_rates(net_death_A, net_infec_A, (1:56));
death_trends_B = get_rates(net_death_B, net_infec_B, (1:56));
death_trends_C = get_rates(net_death_C, net_infec_C, (1:56));
death_trends_D = get_rates(net_death_D, net_infec_D, (1:56));
%%
TT = datetime(2020, 1, 23) + (1:1000);
tiledlayout('flow');
nexttile; plot(TT(2:T_full), diff(nansum(deaths_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(death_trends_A, [0.025 0.5 0.975])'); hold off;
ylabel('inc. deaths/inc. cases');
title('High Vac, Low Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, 0.05]);

nexttile; plot(TT(2:T_full), diff(nansum(deaths_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(death_trends_B, [0.025 0.5 0.975])'); hold off;
ylabel('inc. deaths/inc. cases');
title('High Vac, High Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, 0.05]);

nexttile; plot(TT(2:T_full), diff(nansum(deaths_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(death_trends_C, [0.025 0.5 0.975])'); hold off;
ylabel('inc. deaths/inc. cases');
title('Low Vac, Low Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, 0.05]);

nexttile; plot(TT(2:T_full), diff(nansum(deaths_s, 1))./diff(nansum(data_4_s, 1))); hold on;
plot(TT(T_full+1:T_full+horizon-1), quantile(death_trends_D, [0.025 0.5 0.975])'); hold off;
ylabel('inc. deaths/inc. cases');
title('Low Vac, High Var');
xlim([TT(200), TT(T_full+horizon)]); ylim([0, 0.05]);

%% Underreporting
boxplot(un_array);
boxplot(un_array, {'lower', 'mean', 'upper'});
ylabel('True infections/reported');
title('Ratio over all states');

%% Estimates rates of the past
ll = [0:7:7*60];
for j=1:length(ll)
    [death_rates, death_rates_ci] = var_ind_deaths(data_4_s(:, 1:end-ll(j)), deaths_s(:, 1:end-ll(j)), 1, dk, djp, dwin, 1, popu>-1, lags);
    dr_list{j} = death_rates; dr_list_ci{j} = death_rates_ci;
    T_full = hosp_data_limit;
    [hosp_rates, hosp_rates_ci] = var_ind_deaths(data_4_s(:, 1:T_full - ll(j)), hosp_cumu_s(:, 1:T_full - ll(j)), 1, hk, hjp, hwin, 1, popu > -1, hlags);
    hr_list{j} = hosp_rates; hr_list_ci{j} = hosp_rates_ci;
    fprintf('.');
end

%%
[all_H, all_H_l, all_H_h] = get_all_R(hr_list, best_hosp_hyperparam, hr_list_ci);
[all_D, all_D_l, all_D_h] = get_all_R(dr_list, best_death_hyperparam, dr_list_ci);
%%
cid = 11;
t = tiledlayout(3, 1);
TT = datetime(2021, 7, 3) - 7*40 + (7:7:7*40) ;
nexttile; plot(TT, all_H(cid, end-39:end), 'o'); ylabel('model-based rate'); title('Hosp rates');
nexttile; plot(TT, all_D(cid, end-39:end), 'o'); ylabel('model-based rate'); title('Death rates');
nexttile; plot(TT, diff(data_4_s(cid, end-40*7:7:end)), 'o'); ylabel('cases'); title('Cases');
title(t, countries{cid});


%% Variants
plot(squeeze(var_frac_all(1, :, :))');
var_data = squeeze(all_data_vars_matrix(1, :, :))./sum(squeeze(all_data_vars_matrix(1, :, :)), 1);
hold on; 
plot(var_data, 'o');
%%
sz = 10*(0.01+log(popu)-min(log(popu))).^1.5;
sel_idx = 1:56; sel_idx([51 52 53 55 56]) = [];
t = tiledlayout(2, 2);
nexttile;
new_cum_infec = squeeze(net_death_A(:, :, end) - net_death_A(:, :, 1));
new_cum_infec_un = [un_array(:, 1)'.*(new_cum_infec);...
    un_array(:, 2)'.*(new_cum_infec); un_array(:, 3)'.*(new_cum_infec)];
ee = quantile(new_cum_infec, [0.025 0.5 0.975])'./popu;
errorbar(vacc_full(:, end)./popu, ee(:, 2), ee(:, 2) - ee(:, 1), ee(:, 3)-ee(:, 2), 'o', 'Color', 'blue', 'LineWidth', 1); hold on;
scatter(vacc_full(:, end)./popu, ee(:, 2), 'filled', 'b', 'SizeData', sz);
set(gca, 'XScale','log', 'YScale','log')
xlabel(t, '% Fully Vaccinated');
ylabel(t, 'Total new estimated deaths/population');
title('High Vacc, Low Var');
ylim([10^-6, Inf]);

nexttile;
new_cum_infec = squeeze(net_death_B(:, :, end) - net_death_B(:, :, 1));
new_cum_infec_un = [un_array(:, 1)'.*(new_cum_infec);...
    un_array(:, 2)'.*(new_cum_infec); un_array(:, 3)'.*(new_cum_infec)];
ee = quantile(new_cum_infec, [0.025 0.5 0.975])'./popu;
errorbar(vacc_full(:, end)./popu, ee(:, 2), ee(:, 2) - ee(:, 1), ee(:, 3)-ee(:, 2), 'o', 'Color', 'blue', 'LineWidth', 1); hold on;
scatter(vacc_full(:, end)./popu, ee(:, 2), 'filled', 'b', 'SizeData', sz);
set(gca, 'XScale','log', 'YScale','log')
%xlabel('% Fully Vaccinated');
%ylabel('Total new estimated deaths/population');
ylim([10^-6, Inf]);
title('High Vacc, High Var');

nexttile;
new_cum_infec = squeeze(net_death_C(:, :, end) - net_death_C(:, :, 1));
new_cum_infec_un = [un_array(:, 1)'.*(new_cum_infec);...
    un_array(:, 2)'.*(new_cum_infec); un_array(:, 3)'.*(new_cum_infec)];
ee = quantile(new_cum_infec, [0.025 0.5 0.975])'./popu;
errorbar(vacc_full(:, end)./popu, ee(:, 2), ee(:, 2) - ee(:, 1), ee(:, 3)-ee(:, 2), 'o', 'Color', 'blue', 'LineWidth', 1); hold on;
scatter(vacc_full(:, end)./popu, ee(:, 2), 'filled', 'b', 'SizeData', sz);
set(gca, 'XScale','log', 'YScale','log')
%xlabel('% Fully Vaccinated');
%ylabel('Total new estimated deaths/population');
ylim([10^-6, Inf]);
title('Low Vacc, Low Var');

nexttile;
new_cum_infec = squeeze(net_death_D(:, :, end) - net_death_D(:, :, 1));
new_cum_infec_un = [un_array(:, 1)'.*(new_cum_infec);...
    un_array(:, 2)'.*(new_cum_infec); un_array(:, 3)'.*(new_cum_infec)];
ee = quantile(new_cum_infec, [0.025 0.5 0.975])'./popu;
errorbar(vacc_full(:, end)./popu, ee(:, 2), ee(:, 2) - ee(:, 1), ee(:, 3)-ee(:, 2), 'o', 'Color', 'blue', 'LineWidth', 1); hold on;
scatter(vacc_full(:, end)./popu, ee(:, 2), 'filled', 'b', 'SizeData', sz);
set(gca, 'XScale','log', 'YScale','log')
%xlabel('% Fully Vaccinated');
%ylabel('Total new estimated deaths/population');
ylim([10^-6, Inf]);
title('Low Vacc, High Var');

%%
TT = datetime(2020, 1, 23)+(1:1000);
tiledlayout('flow');
nexttile;
plot(TT(T_full-200:T_full), sum(vacc_full(:, end-200:end))./sum(popu)); 
hold on; plot(sum(vacc_fd(:, end-200:end))./sum(popu)); 
ylabel('% of Population'); xlabel('Date');
legend({'Full', 'First Dose'}, 'Location', 'northwest');
hold off;

nexttile;
xx = sum(vacc_full, 1); yy = sum(vacc_fd, 1); zz = xx;
for j=1:length(xx)
    idx = find(yy > xx(j)); idx = idx(1);
    zz(j) = abs(idx(1) - j);
end
plot(xx./sum(popu), zz); xlim([0.05, Inf]);
title('Days for Partially Vaccinated to Catch up With Fully Vaccinated');
xlabel('% of Population'); ylabel('Days');
hold off;


%% Helper functions
function [all_R, all_R_l, all_R_h] = get_all_R(rates, best_hyper, rates_ci)
ns = length(rates{1}); nw = length(rates);
all_R_l = zeros(ns, nw);
all_R_h = zeros(ns, nw);
all_R = zeros(ns, nw);
for ii = 1:length(rates)
    [yy, xx] = calc_Rt(rates{ii}, best_hyper(:, 1), best_hyper(:, 2), ...
        ones(ns, 1), rates_ci{ii});
    all_R_l(:, nw-(ii-1)) = xx(:, 1);
    all_R_h(:, nw-(ii-1)) = xx(:, 2);
    all_R(:, nw-(ii-1)) = yy;
end
all_R = movmean(all_R', 10)';
all_R_l = movmean(all_R_l', 10)';
all_R_h = movmean(all_R_h', 10)';
end

function hosp_trends = get_rates(net_hosp_0, net_infec_0, cid)
nr = size(net_infec_0, 1);
hosp_trends = diff(nansum(net_hosp_0(:, cid, :), 2), 1, 3);
new_infec = diff(nansum(net_infec_0(:, cid, :), 2), 1, 3);
for j=1:size(hosp_trends, 1)
    i_idx = 1+mod(j-1, nr);
    hosp_trends(j, :, :) = hosp_trends(j, :, :)./new_infec(i_idx, :, :);
end

hosp_trends = squeeze(hosp_trends);
end