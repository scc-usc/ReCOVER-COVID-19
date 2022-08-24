 %% Scenario X: test scenario
tic;
T = thisday;
[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list(2), var_prev_q(2), rlag_list(1), num_wan(1), mobility_scenarios(2), esc_param2_idxs(1), booster_imm_idxs(1));
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

disp(['Executing Scenario X with ' num2str(size(scen_list, 1)) ' sub-scenarios']);

external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
wildcard_day = days(datetime(2022, 9, 4) - datetime(2020, 1, 23)) - thisday;
% for gg=1:ag
%     external_infec_perc(:, length(lineages), wildcard_day:wildcard_day+16*7, gg) = repmat(-ag_popu_frac(:, gg)*(50/7).*(popu./sum(popu)), [1 1 113]);
% end
reform_boost_day = days(datetime(2022, 9, 11) - datetime(2020, 1, 23));

midas_scenario_simulator15;

toc;
%%
net_infec_X = net_infec_0;
net_death_X = net_death_0;
%err = err_0;
%net_hosp_X = net_hosp_A;



%% Test plots
cid = 1:56; %cid = find(contains(countries, 'United Kingdom'));
tiledlayout(3, 1);
nexttile;
plot(sum(diff(data_4_s(cid, :),1 , 2), 1)); hold on; plot(thisday:thisday+horizon-2, squeeze(sum(diff(net_infec_X(:, cid, :), 1, 3), 2))'); hold off;

 nexttile;
 plot(sum(diff(hosp_cumu_s(cid, :), 1, 2), 1)); hold on; plot(thisday:thisday+horizon-2, squeeze(sum(diff(net_hosp_X(:, cid, 1:end), 1, 3), 2))'); hold off;

nexttile
plot(sum(diff(deaths_s(cid, :), 1, 2), 1)); hold on; plot(thisday:thisday+horizon-2, squeeze(sum(diff(net_death_X(:, cid, 1:end), 1, 3), 2))'); hold off;

%%
maxt = thisday;
mean_err = mean(err, 3);
cid = 33; ss = 4;
good_ones = mean_err(:, cid) < median(mean_err(:, cid));
ps = sort(unique(scen_list(:, ss)), 'descend');
cc = ['r' 'g' 'b', 'c'];
tiledlayout(2, 1);
nexttile;
plot(datetime(2020, 1, 23) + (1:maxt-1), diff(sum(data_4_s(cid, :), 1), 1, 2), '--'); hold on
for ii=1:length(ps)
    if sum(scen_list(:, ss)==ps(ii) & good_ones) > 0
        plot(datetime(2020, 1, 23) + (maxt:maxt+horizon-2), squeeze(diff(sum(net_infec_0(scen_list(:, ss)==ps(ii) & good_ones, cid, :), 2), 1, 3)), cc(ii)); hold on;
    end
    if sum(scen_list(:, ss)==ps(ii) & ~good_ones) > 0
        plot(datetime(2020, 1, 23) + (maxt:maxt+horizon-2), squeeze(diff(sum(net_infec_0(scen_list(:, ss)==ps(ii) & ~good_ones, cid, :), 2), 1, 3)),  "LineStyle","-.", "Color",cc(ii)); hold on;
    end
end
hold off;
xlabel('Date'); ylabel('Reported Cases');

nexttile;
plot(datetime(2020, 1, 23) + (1:maxt-1), diff(sum(deaths_s(cid, :), 1), 1, 2), '--'); hold on
for ii=1:length(ps)
    idx = find((scen_list(:, ss)==ps(ii))) + [0:num_dh_rates_sample-1]*size(scen_list, 1);
    plot(datetime(2020, 1, 23) + (maxt:maxt+horizon-2), squeeze(diff(sum(net_death_0(idx(:), cid, :), 2), 1, 3)), cc(ii)); hold on;
end
hold off;

xlabel('Future Days'); ylabel('Reported Deaths');
if length(cid)==1
    title([countries{cid} ': Scenario A'])
else
    title('US: Scenario A')
end
hold off;

%% Debug plots: All states at the end
cid = 7;
TT = datetime(2020, 1, 19) + caldays(7*(1:size(ALL_STATS_new(cid).I1, 2)));
deltemp_w = cumsum(deltemp, 3);
deltemp_w = diff(deltemp_w(:, :, 3:7:end, :), 1, 3);
plot(TT, sum(sum(ALL_STATS_new(cid).I1, 3), 1), 'LineWidth', 2)
hold on;
plot(TT, sum(sum(ALL_STATS_new(cid).I2, 3), 1), 'LineWidth', 2)
plot(TT, sum(sum(ALL_STATS_new(cid).If, 3), 1), 'LineWidth', 2)
plot(TT, sum(sum(ALL_STATS_new(cid).Iv, 3), 1), 'LineWidth', 2)
plot(TT, sum(sum(ALL_STATS_new(cid).Ib, 3), 1), 'LineWidth', 2)

plot(TT, sum(sum(ALL_STATS_new(cid).Fi, 3), 1), 'LineWidth', 1)
plot(TT, sum(sum(ALL_STATS_new(cid).VnBi, 3), 1), 'LineWidth', 1)
plot(TT, sum(sum(ALL_STATS_new(cid).Bi, 3), 1), 'LineWidth', 1)

plot(TT, sum(sum(ALL_STATS_new(cid).F(1, :, :), 3), 1), 'LineWidth', 1, 'LineStyle', '--');
plot(TT, sum(sum(ALL_STATS_new(cid).VnB(1, :, :), 3), 1), 'LineWidth', 1,  'LineStyle', '--');
plot(TT, sum(sum(ALL_STATS_new(cid).B(1, :, :), 3), 1), 'LineWidth', 1,  'LineStyle', '--');

xx = ALL_STATS_new(cid).I1 + ALL_STATS_new(cid).I2 + ALL_STATS_new(cid).Iv + ALL_STATS_new(cid).Ib + ALL_STATS_new(cid).VnBi + ALL_STATS_new(cid).Bi + ALL_STATS_new(cid).Fi + ALL_STATS_new(cid).If;
yy = ALL_STATS_new(cid).I1 + ALL_STATS_new(cid).I2 + ALL_STATS_new(cid).Iv + ALL_STATS_new(cid).Ib + ALL_STATS_new(cid).If;

plot(TT, sum(sum(xx, 3), 1), 'LineWidth', 2, 'LineStyle', '--'); hold on
plot(TT(2:end), un(cid)*squeeze(sum(deltemp_w(cid, :, 1:end, :), [2 4]))', 'o');
plot(TT, sum(sum(yy, 3), 1), 'LineWidth', 2, 'LineStyle', ':'); hold on

legend({'I1', 'I2+', 'If', 'Iv', 'Ib', 'Fi', 'VnBi', 'Bi', 'F', 'VnB', 'B', 'total infected', 'actual', 'sum-infected'});

%%
cid = 3;
if isvector(un)
    f = un;
else
    f = 1;
end
dd = size(ALL_STATS_new(cid).immune_infec_temp, 2);
TT = datetime(2020, 1, 19) + caldays(7*(1:size(ALL_STATS_new(cid).I1, 2)));
deltemp_w = cumsum(deltemp, 3);
deltemp_w = diff(deltemp_w(:, :, 3:7:end, :), 1, 3);
h1 = plot(TT(1:dd-1), squeeze((sum(ALL_STATS_new(cid).immune_infec_temp(:, 1:dd-1, :), 3))), 'LineWidth', 2, 'LineStyle', '--'); hold on
h2 = plot(TT(2:dd), f*squeeze((sum(deltemp_w(cid, :, 1:dd-1, :), 4))), 'LineWidth', 2);
set(h1, {'color'}, num2cell(hsv(length(h1)),2));
set(h2, {'color'}, num2cell(hsv(length(h1)),2));

% figure;
% plot(TT(1:dd-1), un(cid)*squeeze(sum(deltemp_w(cid, :, 1:dd-1, :), 2)) ...
%     -  squeeze(sum(ALL_STATS_new(cid).immune_infec_temp(:, 1:dd-1, :))), ...
%       'LineWidth', 2); hold on
%%
cid = 4;
TT = datetime(2020, 1, 19) + caldays(7*(1:size(ALL_STATS_new(cid).I1, 2)));
%plot(TT, sum(ALL_STATS_new(cid).M, 3));
gg = 1; plot(TT, sum(ALL_STATS_new(cid).M(:, :, gg), 3)./ag_popu_frac(cid, gg));

%%
cid = 4;
TT = datetime(2020, 1, 19) + caldays(7*(1:size(ALL_STATS(cid).I1, 2)));
%plot(TT, sum(ALL_STATS_new(cid).M, 3));
gg = 1; plot(TT, sum(ALL_STATS(cid).M(:, :, gg), 3)./ag_popu_frac(cid, gg));
%%
plot(TT, sum(ALL_STATS_new(cid).B{3}(:, :, gg), 3)); hold on
plot(TT, sum(ALL_STATS_new(cid).Bi{3}(:, :, gg), 3)); 
plot(TT, sum(ALL_STATS_new(cid).Ib{3}(:, :, gg), 3)); 

plot(TT, sum(ALL_STATS_new(cid).B{2}(:, :, gg), 3), '--'); hold on
plot(TT, sum(ALL_STATS_new(cid).Bi{2}(:, :, gg), 3), '--'); 
plot(TT, sum(ALL_STATS_new(cid).Ib{2}(:, :, gg), 3), '--'); 