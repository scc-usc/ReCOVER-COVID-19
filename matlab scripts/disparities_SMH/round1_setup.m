load disparity_data.mat
addpath('..');
addpath('../scenario_projections/');
addpath('../utils/');
%%
zero_date = datetime(2020, 1, 2);
sel_regions = [3 16]; % This exercise only projects for CA and NC
bin_sz = 1;
%%
d3d = bin_ts(deaths_3D_phase2_daily, 2, 2, bin_sz, 1);
c3d = bin_ts(cases_3D_imputated_daily, 2, 2, bin_sz, 1);
h3d = bin_ts(hosps_3D_daily, 2, 2, bin_sz, 1);

c3d_gt = bin_ts(cases_3D_phase2_daily, 2, 2, bin_sz, 1);

thisday = floor(days(datetime(2020, 11, 14) - (zero_date + 2))/bin_sz);

ag = size(d3d, 3); ns = size(d3d, 1); T = thisday;

c3d1 = c3d(:, 1:thisday, :);
for gg = 1:ag
    c3d1(:, :, gg) = smooth_epidata(cumsum(c3d(:, 1:thisday, gg), 2), 3, 0, 0);
end
%%
c3d1 = padarray(diff(c3d1, 1, 2), [0 1 0], 0, 'pre');

%%
hosp_cumu_ag = cumsum(h3d, 2);
deaths_ag = cumsum(d3d, 2);
deaths = sum(deaths_ag, 3);
data_4 = sum(cumsum(c3d, 2), 3);
%% vaccine data
all_boosters_ts = cell(2, 1);
all_boosters_ts{1} = padarray(bin_ts(vax_partial_3D_daily, 2, 2, bin_sz), [0 floor(30*7/bin_sz) 0], nan, 'post');
all_boosters_ts{1} = fillmissing(all_boosters_ts{1}, "previous", 2);
all_boosters_ts{2} = padarray(bin_ts(vax_full_3D_daily, 2, 2, bin_sz), [0 floor(30*7/bin_sz) 0], nan, 'post');
all_boosters_ts{2} = fillmissing(all_boosters_ts{2}, "previous", 2);

fd_effi = 0.35; % First dose only provides 35% of the two dose efficacy

horizon = floor(28*7/bin_sz);
%% contacts
% This data is starting from Feb 2.
xx = load('Rt_num_time.mat');
conts_zero_date = datetime(2020, 2, 2);
conts = xx.Rt_unique; 
conts(32, :) = nan; % Vermont has bad data
% 3 and 16 are the required regions
%conts = movmean(conts, 14, 2);

dura = xx.Rt_duration;
%dura = movmean(dura, 14, 2);

conts = bin_ts(conts, 2, 1, bin_sz, 1, 1);
dura = bin_ts(dura, 2, 1, bin_sz, 1, 1);

if bin_sz < 4
%     conts = filloutliers(conts, "linear", "movmedian", 3, 2, "ThresholdFactor", 1.1);
%     dura = filloutliers(dura, "linear", "movmedian", 3, 2, "ThresholdFactor", 1.1);
    conts = csaps(1:size(conts, 2), conts, 0.1, 1:size(conts, 2));
    dura = csaps(1:size(conts, 2), dura, 0.1, 1:size(conts, 2));
end

%%%% infection multiplier = conts .* (1 - exp(-p .* dura))
%%%% p = (-1/ dura(0)) * ln(1 - 1/conts(0))
init_day = thisday - floor(days( conts_zero_date - zero_date)/bin_sz); 
pvals = real((-1./dura(:, init_day)) .* log(1 - 1./conts(:, init_day)));

inf_multiplier = conts .* (1 - exp( - pvals .* dura))  ;

% This data is starting from Feb 2. After 140 days (20 weeks) we have
% stable contact (June 21)
% indices
% we are going to attach time-series to extend the mobility by detrending


first_contact = floor(20*7/bin_sz); % 20 weeks since Feb 2 is approx June 21

rt_winter_effect = inf_multiplier(:, first_contact:end);

inf_multiplier2 = conts./conts(:, init_day);
rt_winter_effect2 = conts(:, first_contact:end)./conts(:, init_day);


% Match the first and last points
ts_slope = (rt_winter_effect(:, end) - rt_winter_effect(:, 1))./(size(rt_winter_effect, 2) - 1);
rt_winter_effect = rt_winter_effect - (ts_slope.*(1:size(rt_winter_effect, 2)));

% Match the first and last points
ts_slope = (rt_winter_effect2(:, end) - rt_winter_effect2(:, 1))./(size(rt_winter_effect2, 2) - 1);
rt_winter_effect2 = rt_winter_effect2 - (ts_slope.*(1:size(rt_winter_effect2, 2)));

%
temp = nan(size(conts, 1), ceil(365/bin_sz)); % yearly pattern starting on June 21
temp(:, 1:size(rt_winter_effect, 2)) = rt_winter_effect;
regular_conts = repmat(temp, [1 6]);
regular_conts= fillmissing(regular_conts , 'linear', 2);

temp(:, 1:size(rt_winter_effect, 2)) = rt_winter_effect2;
regular_conts2 = repmat(temp, [1 6]);
regular_conts2 = fillmissing(regular_conts2 , 'linear', 2);

% Now we take the end point of conts and stitch it to regular_conts
%last_conts_date = 7*size(inf_multiplier, 2) + conts_zero_date;
first_regular_index = size(inf_multiplier, 2) -  first_contact + 1;
concat_multipliers = [inf_multiplier regular_conts(:, first_regular_index:end)];
concat_multipliers2 = [inf_multiplier2 regular_conts2(:, first_regular_index:end)];

%concat_conts = movmean(concat_conts, 1, 2);
% Extract the future contacts
st =  1 + round( (bin_sz*thisday - days(conts_zero_date - zero_date) ) /bin_sz); % Find the first entry based
concat_multipliers = concat_multipliers(:, st:st+horizon);
%mobility_effect = quantile(concat_multipliers, [0.25 0.5 0.75]);
mobility_effect = concat_multipliers([3 16], :);

concat_multipliers2 = concat_multipliers2(:, st:st+horizon);
%mobility_effect2 = quantile(concat_multipliers2, [0.25 0.5 0.75]);
mobility_effect2 = concat_multipliers2([3 16], :);

mobility_effect = [mobility_effect; mobility_effect2];
mobility_effect = mobility_effect./mobility_effect(:, 1);
mobility_effect = [mobility_effect; ones(1, size(mobility_effect, 2))];

mobility_scenarios = [1:size(mobility_effect, 1)];

%% Variants
xx = load('retro_variants.mat');
map_list = readtable('coarse_levels.txt', 'Delimiter', ', ');

%% aggregate variants as desried
[lin6, v6, vl6, vh6] = group_vars(map_list, xx.lineages_voc, xx.var_frac_all_voc, xx.var_frac_all_low_voc, xx.var_frac_all_high_voc, xx.rel_adv_voc, 'alpha');

% for i=1:3
%     var_frac_range{i}  = zeros(ns, 5, thisday);
%     var_frac_range{i}(:, 1, :) = 1;
% end
% v6 = zeros(56, 5, 2*thisday);
v6 = bin_ts(v6, 3, 2, bin_sz);
vl6 = bin_ts(vl6, 3, 2, bin_sz);
vh6 = bin_ts(vh6, 3, 2, bin_sz);

var_frac_range{1} = vl6(sel_regions, :, 1:thisday);
var_frac_range{2} = v6(sel_regions, :, 1:thisday);
var_frac_range{3} = vh6(sel_regions, :, 1:thisday);

var_prev_q = [1:length(var_frac_range)];
nl = length(lin6);
cross_protect = ones(nl, nl);
wildcard_idx = zeros(nl, 1); wildcard_idx(end) = 1;

%% Make alpha wildcard
external_infec_perc = zeros(ns, nl, horizon, ag);
external_infec_perc(:, nl, :, :) = repmat(v6(sel_regions, 2, thisday+1:thisday+horizon), [1 1 1 ag]);
external_infec_perc(external_infec_perc(:) > 0.01) = 0.01;
%% true_infection
%serop = bin_ts(sero_3D_daily, 2, 2, bin_sz);
% un_array{1} = 2*sum(c3d1, 3);
% un_array{2} = 2.5*sum(c3d1, 3);
% un_array{3} = 3*sum(c3d1, 3);
% un_list = [1:length(un_array)]; 

ag_case_frac = c3d1./sum(c3d1, 3);
ag_popu_frac = popu./sum(popu, 2);
pop_by_age = popu;
total_population = sum(popu, 2);

%
% Using sero_3D which is weekly
sero_data = bin_ts(sero_3D_daily, 2, 2, bin_sz, 1, 1);
sel_days = floor([200:330]./bin_sz);
temp = sero_data(:, sel_days, :)./c3d_gt(:, sel_days, :);
temp(temp<1) = 1;
temp_s = temp;
for cid = 1:ns
    for gg = 1:ag
        try
        temp_s(cid, :, gg) = csaps(1:length(sel_days), temp(ns, :, gg), 0.00001, (1:length(sel_days)));
        catch
            %fprintf('skipping for %d, %d', cid, gg);
            temp_s(cid, :, gg) = 3;
        end
    end
end

temp_s(temp_s<1.1) = 1.1; temp_s = movmean(temp_s, 3, 2);
un_fact_mean = mean(temp_s, 2);

un_array{1} = sum(un_fact_mean.*c3d1, 3)/1.2;
un_array{2} = sum(un_fact_mean.*c3d1, 3);
un_array{3} = sum(un_fact_mean.*c3d1, 3)/0.8;
ag_case_frac = un_fact_mean.*c3d1./un_array{2};
un_list = [1:length(un_array)];
%% sub-scenarios
num_dh_rates_sample = 5;
booster_delay = {0; 14/bin_sz};
ag_wan_lb_list = repmat([0.1 0.1], [ag 1]);
ag_wan_param_list = repmat(30*[6 10]/bin_sz, [ag 1]); % In weeks
num_wan = [1:size(ag_wan_lb_list, 2)];
k_l = 2; jp_l = max(1, floor(7/bin_sz)); %rlag = 0;
P_death_list = 0.9*ones(ag, length(num_wan), nl);
P_hosp_list = 0.8*ones(ag, length(num_wan), nl);

%%
alpha_adv_scenarios = [1.15 1.2 1.4];
vacc_effi_scenarios = [0.9];
rlag_scenarios = [0 1 2];
alpha_scenarios = [0.9 0.93 0.96 0.99].^bin_sz;
%%
parpool;
pctRunOnAll warning('off', 'all')

%%
[X1, X2, X3, X4, X5, X6, X7, X8] = ndgrid(un_list, var_prev_q(2), num_wan, mobility_scenarios, alpha_adv_scenarios, vacc_effi_scenarios, rlag_scenarios, alpha_scenarios);
scen_list = array2table([X1(:) X2(:) X3(:) X4(:) X5(:) X6(:) X7(:) X8(:)]);
scen_list.Properties.VariableNames = {'un_list', 'var_prev_q', 'num_wan', 'mobility_scenarios', 'wild_advantage', 'vacc_effi', 'rlag', 'alpha'};

%%

disp(['Executing Scenario X with ' num2str(size(scen_list, 1)) ' sub-scenarios']);
tic;
scenario_simulator;
toc;

%%
save ../../../../data_dumps/disparities_1.mat

%%
[sidx, errs] = validate_traj(diff(net_infec_0, 1, 3), diff(data_4(:, thisday+1:thisday+60), 1, 2));
[sidx_d, errs_d] = validate_traj(diff(net_death_0, 1, 3), diff(deaths(:, thisday+1:thisday+60), 1, 2));
[sidx_h, errs_h] = validate_traj(diff(net_hosp_0, 1, 3), diff(hosp_cumu_s(:, thisday+1:thisday+60), 1, 2));

sel_infec_traj = new_infec_ag_0(sidx(1:200), :, :, :);
sel_hosp_traj = new_hosp_ag_0(sidx_h(1:200), :, :, :);
sel_death_traj = new_death_ag_0(sidx_d(1:200), :, :, :);
%%
cid = 1; gg = 14;
tiledlayout(3, 1); hosp_cumu_s = sum(hosp_cumu_ag, 3);
maxt = thisday;
dd = zero_date + (bin_sz:bin_sz:bin_sz*(maxt-1));
ff = zero_date +bin_sz + (bin_sz*maxt:bin_sz:bin_sz*(maxt+horizon-2));
df = zero_date + (bin_sz:bin_sz:bin_sz*(size(hosp_cumu_s, 2)-2));
nexttile;
plot(df, sum(diff(data_4(cid, 1:length(df)+1),1 , 2), 1)); hold on; plot(ff, squeeze(sum(diff(net_infec_X(:, cid, 1:length(ff)+1), 1, 3), 2))'); hold off;
 ylabel('Reported Cases');
 nexttile;
 plot(df, sum(diff(hosp_cumu_s(cid, 1:length(df)+1), 1, 2), 1)); hold on; plot(ff, squeeze(nansum((diff(net_hosp_X(:, cid, 1:length(ff)+1), 1, 3)), 2))'); hold off;
ylabel('Hospitalizations');
nexttile;
plot(df, sum(diff(deaths_ag(cid, 1:length(df)+1, gg), 1, 2), 1)); hold on; plot(ff, squeeze(nansum(sel_death_traj(:, cid, 1:length(ff), gg), [2 4]))'); hold off;
ylabel('Deaths');

%%
save ../../../../data_dumps/disparities_1_targets.mat sel_*traj*