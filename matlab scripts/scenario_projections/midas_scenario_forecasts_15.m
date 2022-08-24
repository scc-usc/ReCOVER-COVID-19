%%% Scenario forecasts
clear;
warning off;
write_data = 1;
addpath('../../scripts/');
addpath('../utils/')
%% Load data and set last date
warning off;
load latest_us_data.mat
load us_hyperparam_latest.mat
load us_hospitalization.mat
load ww_prevalence_us.mat

%%%% Date correction if the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% is to be done on a previous date %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
now_date = datetime(2022, 7, 31); % Use data up to this date
% This round's data cutoff is on June 5, 2022
% T_corr = week of now_date - data cutoff date
T_corr = 0; % these many previous weeks will be appended to projections to keep the dates consistent

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

thisday = floor(days((now_date) - datetime(2020, 1, 23)));
orig_thisday = thisday;
ns = size(data_4, 1);
data_4 = data_4(:, 1:thisday);
deaths = deaths(:, 1:thisday);
hosp_data_limit = min([hosp_data_limit, thisday]);
hosp_cumu = hosp_cumu(:, 1:min([thisday size(hosp_cumu, 2)]));
hosp_cumu_s = hosp_cumu_s(:, 1:min([thisday size(hosp_cumu_s, 2)]));

%% Thanksgiving patch
data_4(:, 669:669+13) = nan; deaths(:, 669:669+13) = nan;
data_4 = fillmissing(data_4, 'linear', 2);
deaths = fillmissing(deaths, 'linear', 2);
%%
horizon = 53*7;
rate_smooth = 7; % The death and hospitalizations will change slowly over these days
hc_num = 18000000; % Number of health care workers ahead of age-groups


%% Age-specific data
vacc_download_age_state;

%% First and Second dose modeling

[fd_given_by_age] = get_vacc_preds(first_dose_age_est, pop_by_age, horizon);
vacc_given_by_age = get_booster_preds(vacc_num_age_est, fd_given_by_age, pop_by_age, 1, 14, 0);

ag = size(vacc_given_by_age, 3);
vacc_ag = vacc_given_by_age;


%% Smoothing and Severe rate sampling
smooth_factor = 14;
num_dh_rates_sample = 5; % Must be an odd number

data_4_s = smooth_epidata(data_4, smooth_factor/2, 1, 1);
deaths_s = smooth_epidata(deaths, 1, 1, 1);

k_l = 2; jp_l = 7; alpha = 0.9;

dalpha = 1; dhorizon = horizon+28;

halpha = 1; hhorizon = horizon + 28;

%%
%% age-group management

ag_case_frac = c_3d1;
ag_popu_frac = pop_by_age./sum(pop_by_age, 2);
pop_by_age = popu.*pop_by_age./sum(pop_by_age, 2);

data_4_ag = cumsum([zeros(ns, 1) diff(data_4_s, 1, 2)].*c_3d1, 2);
deaths_ag = cumsum([zeros(ns, 1) diff(deaths_s, 1, 2)].*d_3d1, 2);
hosp_cumu_ag = cumsum([zeros(ns, 1) diff(hosp_cumu_s, 1, 2)].*h_3d1, 2);

ag = size(c_3d1, 3);

%% Booster modeling (all vaccines are boosters!!)
all_boosters_ts = cell(5, 1);
all_boosters_ts{2} = vacc_ag;
all_boosters_ts{3} = get_booster_preds(extra_dose_age_est, vacc_ag, pop_by_age, 1, 150, 0);
fd_given_by_age = nan(size(vacc_ag));
fd_given_by_age(:, 1:end-21, :) = vacc_ag(:, 22:end, :);
fd_given_by_age = fillmissing(fd_given_by_age, 'previous', 2);
all_boosters_ts{1} = fd_given_by_age;

% 2nd booster started March 28
second_start_day = days(datetime(2022, 3, 28) - datetime(2020, 1, 20));
% all_boosters_ts{4} = get_booster_preds(extra_dose_age2, all_boosters_ts{3}, pop_by_age, 0.9, 60, 1);
% all_boosters_ts{5} = get_booster_preds(0*extra_dose_age_est, all_boosters_ts{4}, pop_by_age, 0.85/0.9, 120, 1);
%% 3rd_booster_flu_inspired
xx = readtable('https://raw.githubusercontent.com/midas-network/covid19-scenario-modeling-hub/master/round14_resources/Adult_Coverage_RD14_Sc_C_D.csv');
%%
flu_booster = all_boosters_ts{3}*nan;
[~, cc] = ismember(xx.location_name, countries);
dd = days(xx.Week_Ending_Sat - datetime(2020, 1, 23));
for ii = 1:size(dd)
    if cc(ii)<1
        continue;
    end
    if startsWith(xx.Age{ii}, '18') % Storing here temporarily
        flu_booster(cc(ii), dd(ii), 3) = xx.Boost_coverage_rd14_sc_C_D(ii)*xx.Population(ii)/100;
    elseif startsWith(xx.Age{ii}, '50')
        flu_booster(cc(ii), dd(ii), 4) = xx.Boost_coverage_rd14_sc_C_D(ii)*xx.Population(ii)/100;
    else
        flu_booster(cc(ii), dd(ii), 5) = xx.Boost_coverage_rd14_sc_C_D(ii)*xx.Population(ii)/100;
    end
end
flu_booster(:, :, 4) = flu_booster(:, :, 4) + flu_booster(:, :, 3);
flu_booster(:, :, 3) = 0;
flu_booster = fillmissing(flu_booster, 'linear', 2);
%flu_booster(:, 1:1228, :) = all_boosters_ts{5};
flu_booster = fillmissing(flu_booster, 'previous',2);
flu_booster(isnan(flu_booster)) = 0;

% xx = load('flu_booster_r14.mat', 'flu_booster');
% flu_booster = xx.flu_booster;
%% Create 5th booster based on the flu vaccine coverage
flu_cov = zeros(ns, ag);
for gg = 1:ag
    for cid = 1:ns
        flu_cov(cid, gg) = 0.9*flu_booster(cid, end, gg)./all_boosters_ts{3}(cid, end, gg);
    end
end
flu_cov(flu_cov > 1) = 1;

all_boosters_ts{4} = get_booster_preds(extra_dose_age_est2, all_boosters_ts{3}, pop_by_age, flu_cov, 60, 1);
all_boosters_ts{5} = get_booster_preds(0*extra_dose_age_est2, all_boosters_ts{4}, pop_by_age, 1, 120, 1);

 %% variants data
 
 % Load and pad with an extra variant "wildcard"
xx = load('variants.mat', "var_frac_all*","lineages*", 'valid_lins*');
var_frac_all = xx.var_frac_all_f(:, :, 1:thisday);
var_frac_all_low = xx.var_frac_all_low_f(:, :, 1:thisday); 
var_frac_all_high = xx.var_frac_all_high_f(:, :, 1:thisday); 
lineages = xx.lineages_f;
%% Add wildcard
var_frac_all = padarray(var_frac_all(:, :, 1:thisday), [0 1 0], 'post');
var_frac_all_low = padarray(var_frac_all_low(:, :, 1:thisday), [0 1 0], 'post'); 
var_frac_all_low(var_frac_all_low < 0) = 0;
var_frac_all_high = padarray(var_frac_all_high(:, :, 1:thisday), [0 1 0], 'post');
lineages = [lineages; {'wildcard'}];

%% Adjust bounds to focus on ba.5
var_frac_all_low(var_frac_all_low < 0) = 0;
var_frac_all_high(var_frac_all_high > 1) = 1;
% var_frac_all_low = var_frac_all_low./(1e-20 + nansum(var_frac_all_low, 2));
% var_frac_all_high = var_frac_all_high./(1e-20 + nansum(var_frac_all_high, 2));


foc_idx = find(contains(lineages, 'ba.5', 'IgnoreCase', true)); foc_idx = foc_idx(1);
% Readjust bounds to focus on uncertainty in delta
xx = var_frac_all_low(:, foc_idx, :);
var_frac_all_low = var_frac_all.*(1 - xx)./(1 - var_frac_all(:, foc_idx, :));
var_frac_all_low(:, foc_idx, :) = xx;

xx = var_frac_all_high(:, foc_idx, :);
var_frac_all_high = var_frac_all.*(1 - xx)./(1 - var_frac_all(:, foc_idx, :));
var_frac_all_high(:, foc_idx, :) = xx;


foc_present = any(var_frac_all(:, foc_idx, :)>0, 3);
foc_missing = ~foc_present;

%temp = quantile(squeeze(var_frac_all(foc_present, foc_idx, :)), [0.05 0.5 0.95]);
temp = min(squeeze(var_frac_all(foc_present, foc_idx, :)));
%temp = squeeze(mean(var_frac_all_low(~foc_missing, foc_idx, :), 1)); temp = temp(:)';
var_frac_all_low(foc_missing, foc_idx, :) = repmat(temp(1, :)*0, [sum(foc_missing) 1]);
var_frac_all(foc_missing, foc_idx, :) = repmat(temp(1, :)/2, [sum(foc_missing) 1]);
var_frac_all_high(foc_missing, foc_idx, :) = repmat(temp(1, :), [sum(foc_missing) 1]);


nl = length(lineages);

var_prev_q = [1 2 3];
var_frac_all(isnan(var_frac_all)) = 0;
var_frac_all_low(isnan(var_frac_all_low)) = 0;
var_frac_all_high(isnan(var_frac_all_high)) = 0;

var_frac_all_high(var_frac_all_high > 1) = 1;
var_frac_all_low = var_frac_all_low./(1e-20 + nansum(var_frac_all_low, 2));
var_frac_all_high = var_frac_all_high./(1e-20 + nansum(var_frac_all_high, 2));

var_frac_range{1} = var_frac_all_low;
var_frac_range{2} = var_frac_all;
var_frac_range{3} = var_frac_all_high;

pre_omic_idx = startsWith(lineages, 'pre');
wildcard_idx = startsWith(lineages, 'wild');
omic_idx2 =  (contains(lineages, 'ba.4', 'IgnoreCase', true)| contains(lineages, 'ba.5', 'IgnoreCase', true)) | contains(lineages, 'other');
omic_idx =  ~(pre_omic_idx | wildcard_idx | omic_idx2);
%other_idx = contains(lineages, 'other');
%% Vaccine and escape parmaeters

booster_delay = {0; 14; 210; 180; 150};
esc_param2_list = [0.6 0.4]; % For BA.4 and BA.5 over BA.1
booster_imm_list = [0.25 0.5];  % (x + (1-x)*<esc_param>)

esc_param2_idxs = [1:length(esc_param2_list)];
booster_imm_idxs = [1:length(booster_imm_list)];
%% Reference Rt values for NPI
cic = ones(ns, 1);

Target_Rt = [cic]; %, cic+(1-cic)/4];  % openness
current_Rt = cic; 

Rt_final_scens = [1:size(Target_Rt, 2)];
Rt_init_scens = [1:size(current_Rt, 2)];

xx = load('Rt_num_time.mat');
conts = xx.Rt_unique; 
conts(32, :) = nan; % Vermont has bad data

% This data is starting from Feb 2. After 170 days we have stable contact
% indices
first_contact = 170;

rt_winter_effect = conts(:, first_contact:end);
for ii=1:ns
    [xx, yy] = trenddecomp(rt_winter_effect(ii, :));
    try
       % rt_winter_effect(ii, :) = 1 + yy'- yy(1);
       rt_winter_effect(ii, :) = rt_winter_effect(ii, :) - yy';
       rt_winter_effect(ii, :) = rt_winter_effect(ii, :)/mean(rt_winter_effect(ii, :));
    catch
        display(['skipping ' countries{ii}]);
    end
end

paddays = first_contact + 31 - mod(thisday + 23, 365);
conts = rt_winter_effect;
conts = movmean(conts, 7, 2);
rt_winter_effect = quantile(conts, [0.25 0.5 0.75]);
mobility_effect = movmean([ones(3, 7) rt_winter_effect], 7, 2); % Introduce 7 day delay reporting
mobility_effect = [nan(3, paddays) mobility_effect repmat(mobility_effect(:, end), [1, horizon-size(mobility_effect, 2)])];
mobility_effect = fillmissing(mobility_effect, 'nearest', 2);

mobility_effect(:) = 1;

mobility_scenarios = [1:size(mobility_effect, 1)];

%%
scenario_forecasts = 1;
rlag_list = [0 7];


%% Waning possibilities as described in the scenarios
% 2nd dimension represents scenarios. 
% 1st dimension is # of age gorups
% 3rd dimension is # of lineages
num_wan = [1:2];
ag_wan_lb_list = repmat([0.4 0.6], [5 1]);
ag_wan_param_list = repmat([30*3 30*5], [5 1]); % In days
P_death_list_orig = repmat([repmat([0.91 0.91], [4 1]);0.93 0.93], [1 1 nl]);
P_hosp_list_orig = repmat([repmat([0.8 0.80], [4 1]);0.87 0.87], [1 1 nl]);
% No one is naive anymore!
P_death_list_orig(:) = 0;
P_hosp_list_orig(:) = 0;
%% True infecitons
un_array{1} = true_new_infec_ww{1}(:, 1:thisday);
un_array{2} = true_new_infec_ww{2}(:, 1:thisday);
un_array{3} = true_new_infec_ww{3}(:, 1:thisday);
% un_array{1} = true_new_infec{1}(:, 1:thisday);
% un_array{3} = true_new_infec{2}(:, 1:thisday);
% un_array{2} = 0.5*(true_new_infec_ww{2}(:, 1:thisday) + true_new_infec{2}(:, 1:thisday));
un_list = [1:length(un_array)];
%% Start parallel processing

parpool(16)
pctRunOnAll warning('off', 'all')
%% Lineage severity
fd_effi = 0.35;
rel_lineage_rates = ones(nl, 1);
severity = 1.2;
rel_lineage_rates(wildcard_idx) = severity;
P_death_list = P_death_list_orig;
P_hosp_list = P_hosp_list_orig;
% P_hosp_list(:, :, wildcard_idx) =  repmat(1 - severity*(1-P_hosp_list(:, :, omic_idx)), [1,1,sum(wildcard_idx)]);
% P_death_list(:, :, wildcard_idx) = repmat(1 - severity*(1-P_death_list(:, :, omic_idx)), [1,1,sum(wildcard_idx)]);

%% Scenario A: earlyBoo_noVar
tic;
T = thisday;
disp('Executing Scenario A');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list(1), num_wan, mobility_scenarios(2), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
wildcard_day = days(datetime(2022, 9, 4) - datetime(2020, 1, 23)) - thisday;
% for gg=1:ag
%     external_infec_perc(:, length(lineages), wildcard_day:wildcard_day+16*7, gg) = repmat(-ag_popu_frac(:, gg)*(50/7).*(popu./sum(popu)), [1 1 113]);
% end
reform_boost_day = days(datetime(2022, 9, 11) - datetime(2020, 1, 23));

midas_scenario_simulator15;

net_infec_A = net_infec_0;
net_death_A = net_death_0;
net_hosp_A = net_hosp_0;
err_A = err;flu_booster = fillmissing(flu_booster, 'previous',2);
flu_booster(isnan(flu_booster)) = 0;
var_x_A = var_x_0;
% new_infec_ag_A = new_infec_ag_0;
% new_death_ag_A = new_death_ag_0;
% new_hosp_ag_A = new_hosp_ag_0;
toc;
%% Scenario B: earlyBoo_Var

disp('Executing Scenario B');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list(1), num_wan, mobility_scenarios(2), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
wildcard_day = days(datetime(2022, 9, 4) - datetime(2020, 1, 23)) - thisday;
for gg=1:ag
    external_infec_perc(:, wildcard_idx, wildcard_day:wildcard_day+16*7, gg) = repmat(-ag_popu_frac(:, gg)*(50/7).*(popu./sum(popu)), [1 1 113]);
end
reform_boost_day = days(datetime(2022, 9, 11) - datetime(2020, 1, 23));

midas_scenario_simulator15;

net_infec_B = net_infec_0;
net_death_B = net_death_0;
net_hosp_B = net_hosp_0;
err_B = err;
var_x_B = var_x_0;
% new_infec_ag_B = new_infec_ag_0;
% new_death_ag_B = new_death_ag_0;
% new_hosp_ag_B = new_hosp_ag_0;

%% Scenario C: lateBoo_noVar

disp('Executing Scenario C');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list(1), num_wan, mobility_scenarios(2), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
wildcard_day = days(datetime(2022, 9, 4) - datetime(2020, 1, 23)) - thisday;
% for gg=1:ag
%     external_infec_perc(:, length(lineages), wildcard_day:wildcard_day+16*7, gg) = repmat(-ag_popu_frac(:, gg)*(50/7).*(popu./sum(popu)), [1 1 113]);
% end
reform_boost_day = days(datetime(2022, 11, 13) - datetime(2020, 1, 23));

midas_scenario_simulator15;

net_infec_C = net_infec_0;
net_death_C = net_death_0;
net_hosp_C = net_hosp_0;
err_C = err;
var_x_C = var_x_0;
% new_infec_ag_C = new_infec_ag_0;
% new_death_ag_C = new_death_ag_0;
% new_hosp_ag_C = new_hosp_ag_0;
%% Scenario D: lateBoo_Var

disp('Executing Scenario D');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list(1), num_wan, mobility_scenarios(2), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
wildcard_day = days(datetime(2022, 9, 4) - datetime(2020, 1, 23)) - thisday;
for gg=1:ag
    external_infec_perc(:, length(lineages), wildcard_day:wildcard_day+16*7, gg) = repmat(-ag_popu_frac(:, gg)*(50/7).*(popu./sum(popu)), [1 1 113]);
end
reform_boost_day = days(datetime(2022, 11, 13) - datetime(2020, 1, 23));

midas_scenario_simulator15;

net_infec_D = net_infec_0;
net_death_D = net_death_0;
net_hosp_D = net_hosp_0;
err_D = err;
var_x_D = var_x_0;
% new_infec_ag_D = new_infec_ag_0;
% new_death_ag_D = new_death_ag_0;
% new_hosp_ag_D = new_hosp_ag_0;

%%
% cid = 1;
% tiledlayout(4, 3, 'TileSpacing','compact');
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_A(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_A(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_A(:, cid, :), 2))')); hold off
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_B(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_B(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_B(:, cid, :), 2))')); hold off
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_C(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_C(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_C(:, cid, :), 2))')); hold off
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_D(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_D(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_D(:, cid, :), 2))')); hold off


%% Prepare quantiles
quants = [0, 0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99, 1]';
num_wk_ahead = 52;
scen_ids = {'A'; 'B'; 'C'; 'D'};
dat_type = {'infec'; 'death'; 'hosp'};
scen_names = {'earlyBoo_noVar'; 'earlyBoo_Var'; 'lateBoo_noVar'; 'lateBoo_Var'};
all_quant_diff = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), num_wk_ahead);
all_mean_diff = zeros(length(scen_ids), length(dat_type), length(popu), num_wk_ahead);
all_quant_cum = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), num_wk_ahead);
all_mean_cum = zeros(length(scen_ids), length(dat_type), length(popu), num_wk_ahead);

num_wk_ahead = num_wk_ahead - T_corr;   
thisday = orig_thisday;

%%%%%%%%%%% Create duplicates for weighted sampling
%%% Here we want to replicate based on rates
infec_weights = ones(size(scen_list, 1), 1);
% infec_weights(scen_list(:, 5)==0) = 4;
% infec_weights(scen_list(:, 5)==7) = 1;
% infec_weights(scen_list(:, 5)==14) = 0;

dh_weights = ones(size(scen_list, 1)*num_dh_rates_sample, 1);
% idx = find((scen_list(:, 5)==0)) + [0:num_dh_rates_sample-1]*size(scen_list, 1);
% dh_weights(idx) = 4;
% idx = find((scen_list(:, 5)==7)) + [0:num_dh_rates_sample-1]*size(scen_list, 1);
% dh_weights(idx) = 1;
% idx = find((scen_list(:, 5)==14)) + [0:num_dh_rates_sample-1]*size(scen_list, 1);
% dh_weights(idx) = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for ss = 1:length(scen_ids)
    for dt = 1:length(dat_type)
        net_dat = eval(['net_' dat_type{dt} '_' scen_ids{ss}]);
        for cid = 1:length(popu)
            thisdata = squeeze(net_dat(:, cid, :));
            
            if dt == 1
                base_val = data_4(cid, thisday-7*T_corr);
                fw = data_4(cid, thisday-7*T_corr+1 : thisday);
                ww = infec_weights;
            elseif dt == 2  
                base_val = deaths(cid, thisday-7*T_corr);
                fw = deaths(cid, thisday-7*T_corr+1 : thisday);
                ww = dh_weights;
            else
                base_val = hosp_cumu(cid, thisday-7*T_corr);
                fw = hosp_cumu(cid, thisday-7*T_corr+1 : thisday) - base_val;
                thisdata = thisdata + hosp_cumu(cid, thisday) - base_val;
                base_val = 0;
                ww = dh_weights;
            end
            
            thisdata = [repmat(fw, [size(thisdata, 1) 1]) thisdata];
            thisdata = thisdata(:, 7:7:(num_wk_ahead+T_corr)*7);
%             fw = fw + 0*thisdata(:, 1);
%             fw = (fw+abs(fw))/2;
% 
%             if T_corr > 0
%                 thisdata = [fw, thisdata];
%             end

            diffdata = diff([repmat(base_val, [size(thisdata, 1) 1]), thisdata], 1, 2);
            
            diffdata(diffdata < 0) = nan;
            diffdata = fillmissing(diffdata, 'linear',2);

            [~, diffdata] = weighted_quantile(diffdata, 0.5, ww);
            [~, thisdata] = weighted_quantile(thisdata, 0.5, ww);

            all_quant_diff(ss, dt, cid, :, :) = quantile(diffdata, quants);
            all_quant_cum(ss, dt, cid, :, :) = quantile(thisdata, quants);
            all_mean_diff(ss, dt, cid, :) = trimmean(diffdata, 0.95, 1);
            all_mean_cum(ss, dt, cid, :) = trimmean(thisdata, 0.95, 1);
        end
    end
end
% all_quant_vals(isnan(all_quant_vals)) = 0;
% all_mean_vals(isnan(all_mean_vals)) = 0;
thisday = orig_thisday - 7*T_corr;

%%


%% Quant plots
%cid = popu>-1;
cid = 3; cid = contains(countries, "Vermont");
quant_show = [1 8 13 18 23];
tvals = size(data_4(cid, 52:7:thisday), 2);
xvals = (size(data_4(cid, 52:7:thisday), 2):size(data_4(cid, 52:7:thisday), 2)+size(all_quant_diff, 5)-1);
tiledlayout(4, 3, 'TileSpacing','compact');
TT = datetime(2020, 1, 23) + 52 + 7*(1 : tvals-1); TT2 = datetime(2020, 1, 23) + 52 + 7*(xvals);
for ss=1:4                
    nexttile; plot(TT, diff(nansum(data_4(cid, 52:7:thisday), 1))); hold on;
    plot(TT2, squeeze(nansum(all_quant_diff(ss, 1, cid, quant_show, :), 3))'); hold on;
    plot(TT2, squeeze(nansum(all_mean_diff(ss, 1, cid, :), 3))', 'o'); hold off;
    xlim([datetime(2021, 11, 1), datetime(2021, 11, 30)+inf])
        
    nexttile; plot(TT, diff(nansum(deaths(cid, 52:7:thisday), 1))); hold on;
    plot(TT2, squeeze(nansum(all_quant_diff(ss, 2, cid, quant_show, :), 3))'); hold on;
    plot(TT2, squeeze(nansum(all_mean_diff(ss, 2, cid, :), 3))', 'o'); hold off;
    xlim([datetime(2021, 11, 1), datetime(2021, 11, 30)+inf])
    
    nexttile; plot(TT, diff(nansum(hosp_cumu(cid, 52:7:thisday), 1))); hold on;
    plot(TT2, squeeze(nansum(all_quant_diff(ss, 3, cid, quant_show, :), 3))'); hold on;
    plot(TT2, squeeze(nansum(all_mean_diff(ss, 3, cid, :), 3))', 'o'); hold off;
    xlim([datetime(2021, 11, 1), datetime(2021, 11, 30)+inf])
end
%%
save ../../../../../code/data_dumps/round_15_large.mat

%% Create prop_X table
first_day_pred = 7;
prop_X_matrix = zeros(2, ns, 52);
varB_mean = squeeze(mean(var_x_B(:, :, 7:7:end), 1)); varB_mean(isnan(varB_mean)) = 0;
varD_mean = squeeze(mean(var_x_D(:, :, 7:7:end), 1));
scen_date = '2022-07-19';
thesevals = varB_mean(:);
[cid, wh] = ind2sub(size(varB_mean), (1:length(thesevals))');
ss = 2*ones(length(thesevals), 1);
Tp1 = table;
wh_string = sprintfc('%d', [1:max(wh)]');
Tp1.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
Tp1.scenario_name = scen_names(ss);
Tp1.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
Tp1.target = strcat(wh_string(wh), ' wk ahead prop X');
Tp1.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
Tp1.location = fips(cid);
Tp1.type = repmat({'point'}, [length(thesevals) 1]);
Tp1.quantile = repmat({'NA'}, [length(thesevals) 1]);
Tp1.value = compose('%0.3f', thesevals);

thesevals = varD_mean(:);
[cid, wh] = ind2sub(size(varD_mean), (1:length(thesevals))');
ss = 4*ones(length(thesevals), 1);
Tp2 = table;
wh_string = sprintfc('%d', [1:max(wh)]');
Tp2.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
Tp2.scenario_name = scen_names(ss);
Tp2.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
Tp2.target = strcat(wh_string(wh), ' wk ahead prop X');
Tp2.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
Tp2.location = fips(cid);
Tp2.type = repmat({'point'}, [length(thesevals) 1]);
Tp2.quantile = repmat({'NA'}, [length(thesevals) 1]);
Tp2.value = compose('%0.3f', thesevals);
%% Create tables from the matrices

if write_data == 1
    disp('creating inc quant table for states');
    T = table;
    scen_date = '2022-07-19';
    dt_name = {' case'; ' death'; ' hosp'};
    thesevals = all_quant_diff(:);
    [ss, dt, cid, qq, wh] = ind2sub(size(all_quant_diff), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T.scenario_name = scen_names(ss);
    T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    T.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    T.location = fips(cid);
    T.type = repmat({'quantile'}, [length(thesevals) 1]);
    T.quantile = num2cell(quants(qq));
    T.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum quant table for states');
    
    thesevals = all_quant_cum(:);
    Tc = T;
    Tc.value = compose('%g', round(thesevals, 1));
    Tc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));
    
    disp('creating inc mean table for states');
    
    Tm = table;
    thesevals = all_mean_diff(:);
    [ss, dt, cid, wh] = ind2sub(size(all_mean_diff), (1:length(thesevals))');
    Tm.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tm.scenario_name = scen_names(ss);
    Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    Tm.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Tm.location = fips(cid);
    Tm.type = repmat({'point'}, [length(thesevals) 1]);
    Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Tm.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum mean table for states');
    
    thesevals = all_mean_cum(:);
    Tmc = Tm;
    Tmc.value = compose('%g', round(thesevals, 1));
    Tmc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));
    
    % Repeat for US
    
    disp('creating inc quant table for US');
    
    us_all_quant_diff = squeeze(nansum(all_quant_diff, 3));
    us_all_mean_diff = squeeze(nansum(all_mean_diff, 3));
    us_all_quant_cum = squeeze(nansum(all_quant_cum, 3));
    us_all_mean_cum = squeeze(nansum(all_mean_cum, 3));
    
    us_T = table;
    dt_name = {' case'; ' death'; ' hosp'};
    wh_string = sprintfc('%d', [1:max(wh)]');
    thesevals = us_all_quant_diff(:);
    [ss, dt, qq, wh] = ind2sub(size(us_all_quant_diff), (1:length(thesevals))');
    us_T.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_T.scenario_name = scen_names(ss);
    us_T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_T.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_T.location = repmat({'US'}, [length(thesevals) 1]);
    us_T.type = repmat({'quantile'}, [length(thesevals) 1]);
    us_T.quantile = num2cell(quants(qq));
    us_T.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum quant table for US');
    
    thesevals = us_all_quant_cum(:);
    us_Tc = us_T;
    us_Tc.value = compose('%g', round(thesevals, 1));
    us_Tc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));
    
    disp('creating inc mean table for US');
    
    us_Tm = table;
    thesevals = us_all_mean_diff(:);
    [ss, dt, wh] = ind2sub(size(us_all_mean_diff), (1:length(thesevals))');
    us_Tm.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Tm.scenario_name = scen_names(ss);
    us_Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_Tm.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Tm.location = repmat({'US'}, [length(thesevals) 1]);
    us_Tm.type = repmat({'point'}, [length(thesevals) 1]);
    us_Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    us_Tm.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum mean table for US');
    
    thesevals = us_all_mean_cum(:);
    us_Tmc = us_Tm;
    us_Tmc.value = compose('%g', round(thesevals, 1));
    us_Tmc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));
    
    disp('Creating combined table');
    
    full_T = [T; Tc; Tm; Tmc; us_T; us_Tc; us_Tm; us_Tmc];
    bad_idx = contains(full_T.target, compose('%g wk ', [41:60])) | contains(full_T.location, '50');
    nanidx = (strcmpi(full_T.value, 'NaN'));
    full_T(bad_idx|nanidx, :) = [];
    
    % Write files on disk
    disp('Writing File');
    tic;
    writetable(full_T, ['../../../../data_dumps/' datestr(now_date, 'YYYY-mm-DD') '-USC-SIkJalpha.csv']);
    toc
    
end