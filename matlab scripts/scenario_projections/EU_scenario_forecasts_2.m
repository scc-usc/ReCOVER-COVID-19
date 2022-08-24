%%% Scenario forecasts
clear;
warning off;
write_data = 1;
addpath('../../scripts/');
addpath('../utils/')
%%
warning off;
load latest_global_data.mat;

eu_names_table =  readtable('locations_eu.csv');
eu_names = cell(length(countries), 1);
eu_present = zeros(length(countries), 1);
for jj = 1:length(eu_names_table.location)
%     if strcmpi(eu_names_table.location_name(jj), 'Czechia')==1
%         idx = find(strcmpi(countries, 'Czech Republic'));
%     else
        idx = find(strcmpi(countries, eu_names_table.location_name(jj)));
%     end
    if ~isempty(idx)
        eu_present(idx(1)) = 1;
        eu_names(idx(1)) = eu_names_table.location(jj);
    else
        disp([eu_names_table.location_name(jj) ' Not Found']);
    end
end


%% Load baselines


%%%% Date correction if the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% is to be done on a previous date %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
now_date = datetime(2022, 7, 24);
thisday = floor(days((now_date) - datetime(2020, 1, 23)));
orig_thisday = thisday;
ns = size(data_4(eu_present>0, :), 1);
data_4 = data_4(eu_present>0, 1:thisday);
deaths = deaths(eu_present>0, 1:thisday);
countries = countries(eu_present>0);
popu = popu(eu_present > 0);
%%
horizon = 53*7;

rate_smooth = 7; % The death and hospitalizations will change slowly over these days


%% Prepare vaccine data
xx = load('vacc_data.mat');
%nidx = isnan(latest_vac); latest_vac(nidx) = popu(nidx).*(mean(latest_vac(~nidx))/mean(popu(~nidx)));
vacc_num_age_est = xx.g_vacc_full(eu_present>0, :);
extra_dose_age_est = xx.g_booster(eu_present>0, :);
vacc_num_age_est = fillmissing(vacc_num_age_est, 'previous', 2);
vacc_num_age_est(isnan(vacc_num_age_est)) = 0;
extra_dose_age_est = fillmissing(extra_dose_age_est, 'previous', 2);
extra_dose_age_est(isnan(extra_dose_age_est)) = 0;
%% Load EU 60+ booster proportion
xx = readtable('https://raw.githubusercontent.com/covid19-forecast-hub-europe/covid19-scenario-hub-europe/main/data-truth/data/vaccination-60plus-booster1.csv');

iso2 = eu_names(eu_present>0);
[~, bb] = ismember(xx.location, iso2);
boost_prop60 = nan(length(countries), 1);
boost_prop60(bb) = xx.booster1_sixty_plus_pp;
boost_prop60(isnan(boost_prop60)) = nanmean(boost_prop60);
%% Booster data preparation
all_boosters_ts = cell(5, 1);
all_boosters_ts{2} = sum(get_vacc_preds(vacc_num_age_est, popu, horizon+14), 3);
fd_given_by_age = nan(size(all_boosters_ts{2}));
fd_given_by_age(:, 1:end-21, :) = all_boosters_ts{2}(:, 22:end, :);
fd_given_by_age = fillmissing(fd_given_by_age, 'previous', 2);
all_boosters_ts{1} = fd_given_by_age;

all_boosters_ts{3} = sum(get_booster_preds(extra_dose_age_est, all_boosters_ts{2}, popu, 1, 180, 0), 3);
%% booster scenarios
boost_all = sum(get_booster_preds([extra_dose_age_est.*0 zeros(ns, 30)], all_boosters_ts{3}, popu, 0.5, 120, 1, -1), 3);
boost_60 = boost_prop60.*boost_all; 
%% Smoothing and heperparams

smooth_factor = 14;
num_dh_rates_sample = 5; % Must be an odd number

data_4_s = smooth_epidata(data_4, smooth_factor/2, 1, 1);
deaths_s = smooth_epidata(deaths, 1, 1, 1);

k_l = 2; jp_l = 7; alpha = 0.9;

dalpha = 1; dhorizon = horizon+28;

halpha = 1; hhorizon = horizon + 28;


 %% variants data
 
 % Load and pad with an extra variant "wildcard"
xx = load('variants_global.mat', "var_frac_all*","lineages*", 'valid_lins*');
var_frac_all = xx.var_frac_all_f(eu_present > 0, :, 1:thisday);
var_frac_all_low = xx.var_frac_all_low_f(eu_present > 0, :, 1:thisday); 
var_frac_all_high = xx.var_frac_all_high_f(eu_present > 0, :, 1:thisday); 
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
% var_frac_all_low = var_frac_all_low./(1e-20 + sum(var_frac_all_low, 2));
% var_frac_all_high = var_frac_all_high./(1e-20 + sum(var_frac_all_high, 2));


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
var_frac_all_low(foc_missing, foc_idx, :) = repmat(temp(1, :)*0, [sum(foc_missing) 1]);
var_frac_all(foc_missing, foc_idx, :) = repmat(temp(1, :)*0.5, [sum(foc_missing) 1]);
var_frac_all_high(foc_missing, foc_idx, :) = repmat(temp(1, :), [sum(foc_missing) 1]);


nl = length(lineages);

var_prev_q = [1 2 3];
var_frac_all(isnan(var_frac_all)) = 0;
var_frac_all_low(isnan(var_frac_all_low)) = 0;
var_frac_all_high(isnan(var_frac_all_high)) = 0;

var_frac_all_high(var_frac_all_high > 1) = 1;
var_frac_all_low = var_frac_all_low./(1e-20 + sum(var_frac_all_low, 2));
var_frac_all_high = var_frac_all_high./(1e-20 + sum(var_frac_all_high, 2));

var_frac_range{1} = var_frac_all_low;
var_frac_range{2} = var_frac_all;
var_frac_range{3} = var_frac_all_high;

pre_omic_idx = startsWith(lineages, 'pre');
wildcard_idx = startsWith(lineages, 'wild');
omic_idx2 =  (contains(lineages, 'ba.4', 'IgnoreCase', true)| contains(lineages, 'ba.5', 'IgnoreCase', true));
omic_idx =  ~(pre_omic_idx | wildcard_idx | omic_idx2);

%% Vaccine efficacy

booster_delay = {0; 14; 210; 180; 150};
esc_param2_list = [0.6 0.4]; % For BA.4 and BA.5 over BA.1
booster_imm_list = [0.25 0.5];  % (x + (1-x)*<2nd dose effi>)

esc_param2_idxs = [1:length(esc_param2_list)];
booster_imm_idxs = [1:length(booster_imm_list)];
%% Mobility
% Reference Rt values for NPI
cic = ones(ns, 1);

Target_Rt = [cic]; %, cic+(1-cic)/4];  % openness
current_Rt = cic; 

Rt_final_scens = [1:size(Target_Rt, 2)];
Rt_init_scens = [1:size(current_Rt, 2)];


mobility_effect = ones(1, horizon);
mobility_scenarios = [1:size(mobility_effect, 1)];

%%
scenario_forecasts = 1;
rlag_list = [0 7];

%% age-group management

ns = size(data_4, 1);
T = size(data_4, 2);
ag = 2;

temp = zeros(ns, T+horizon, ag);
temp(:, :, 1) = boost_60(:, 1:T+horizon, 1);
boost_60 = temp;

temp = zeros(ns, T+horizon, ag);
temp(:, :, 1) = boost_all(:, 1:T+horizon, 1);
boost_all = temp;


for ii=1:size(all_boosters_ts)
    if size(all_boosters_ts{ii}, 3)==1
        booster_given_by_age = zeros(ns, T+horizon, 2);
        if ~isempty(all_boosters_ts{ii})
            booster_given_by_age(:, :, 1) = all_boosters_ts{ii}(:, 1:T+horizon, 1);
        end
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

%% Waning possibilities as described in the scenarios
% 2nd dimension represents scenarios. 
% 1st dimension is # of age gorups
% 3rd dimension is # of lineages
num_wan = [1:2];
ag_wan_lb_list = repmat([0.4 0.4], [ag 1]);
ag_wan_param_list = repmat([30*8 30*3], [ag 1]);
P_death_list_orig = repmat([repmat([0.91 0.91], [ag-1 1]);0.93 0.93], [1 1 nl]);
P_hosp_list_orig = repmat([repmat([0.8 0.80], [ag-1 1]);0.87 0.87], [1 1 nl]);
P_death_list_orig(:) = 0;
P_hosp_list_orig(:) = 0;
%% Underreporting
un_mat = popu*0 + [2 2.5 3 3.5];
un_list = [1 2 3 4];
un_array = cell(length(un_list), 1);
for uu = 1:length(un_array)
    un_array{uu} = un_mat(:, uu);
end
%% Add more sub-scenarios in under-reporting interval
% gaps = 0;
% temp = nan(ns, 2*gaps + 3); 
% temp(:, 1) = un_array(:, 1);
% temp(:, 2*gaps+3) = un_array(:, 3);
% temp(:, 2+gaps) = un_array(:, 2);
% temp = fillmissing(temp, 'linear', 2);
% un_list = [1:(2*gaps + 3)];
% un_array = temp;


%% Start parallel processing

parpool(24 )
pctRunOnAll warning('off', 'all')
%% Common Specifications

vacc_effi1 = 0.35; vacc_effi2 = 1 - vacc_effi1;

%omic_ad = 1.66;

fd_effi = 0.4;

rel_lineage_rates = ones(nl, 1);

% severity = 0.3;
% rel_lineage_rates(omic_idx|wildcard_idx) = severity;
% P_death_list = P_death_list_orig;
% P_hosp_list = P_hosp_list_orig;
% P_hosp_list(:, :, omic_idx|wildcard_idx) =  repmat(1 - severity*(1-P_hosp_list(:, :, pre_omic_idx)), [1,1,sum(omic_idx|wildcard_idx)]);
% P_death_list(:, :, omic_idx|wildcard_idx) = repmat(1 - severity*(1-P_death_list(:, :, pre_omic_idx)), [1,1,sum(omic_idx|wildcard_idx)]);

%% Scenario A. Optimistic vaccine effectiveness, Age 60+ booster campaign
tic;
T = thisday;
disp('Executing Scenario A');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list, num_wan(1:2), mobility_scenarios(1), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

reform_b_effi = 1;
all_boosters_ts{4} = boost_60;


external_infec_perc = zeros(ns, length(lineages), horizon, ag);
wildcard_day = days(datetime(2022, 5, 1) - datetime(2020, 1, 23)) - thisday;

EU_scenario_simulator2;

net_infec_A = net_infec_0;
net_death_A = net_death_0;
%net_hosp_A = net_hosp_0;

err_A = err;

toc;
%% Scenario B. Optimistic vaccine effectiveness, Age 18+ booster campaign

disp('Executing Scenario B');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list, num_wan(1:2), mobility_scenarios(1), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

all_boosters_ts{4} = boost_all;
reform_b_effi = 1;

external_infec_perc = zeros(ns, length(lineages), horizon, ag);
wildcard_day = days(datetime(2022, 5, 1) - datetime(2020, 1, 23)) - thisday;

EU_scenario_simulator2;

net_infec_B = net_infec_0;
net_death_B = net_death_0;
%net_hosp_B = net_hosp_0;

err_B = err;

% new_infec_ag_B = new_infec_ag_0;
% new_death_ag_B = new_death_ag_0;
%new_hosp_ag_B = new_hosp_ag_0;

%% Scenario C: pessWan_noVar

disp('Executing Scenario C');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list, num_wan(1:2), mobility_scenarios(1), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

all_boosters_ts{4} = boost_60;
reform_b_effi = -1;

external_infec_perc = zeros(ns, length(lineages), horizon, ag);
wildcard_day = days(datetime(2022, 5, 1) - datetime(2020, 1, 23)) - thisday;

EU_scenario_simulator2;

err_C = err;

net_infec_C = net_infec_0;
net_death_C = net_death_0;
%net_hosp_C = net_hosp_0;

% new_infec_ag_C = new_infec_ag_0;
% new_death_ag_C = new_death_ag_0;
%new_hosp_ag_C = new_hosp_ag_0;
%% Scenario D: pessWan_var

disp('Executing Scenario D');

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, var_prev_q, rlag_list, num_wan(1:2), mobility_scenarios(1), esc_param2_idxs, booster_imm_idxs);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:) X7(:)];

all_boosters_ts{4} = boost_all;
reform_b_effi = -1;

external_infec_perc = zeros(ns, length(lineages), horizon, ag);
wildcard_day = days(datetime(2022, 5, 1) - datetime(2020, 1, 23)) - thisday;

EU_scenario_simulator2;

net_infec_D = net_infec_0;
net_death_D = net_death_0;
%net_hosp_D = net_hosp_0;

err_D = err;

%new_infec_ag_D = new_infec_ag_0;
%new_death_ag_D = new_death_ag_0;
%new_hosp_ag_D = new_hosp_ag_0;

%%
% cid = 25;
% tiledlayout(4, 2, 'TileSpacing','compact');
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_infec_A(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_death_A(:, cid, :), 2))')); hold off
% %nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_A(:, cid, :), 2))')); hold off
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_infec_B(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_death_B(:, cid, :), 2))')); hold off
% %nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_B(:, cid, :), 2))')); hold off
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_infec_C(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_death_C(:, cid, :), 2))')); hold off
% %nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_C(:, cid, :), 2))')); hold off
% 
% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_infec_D(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(sum(net_death_D(:, cid, :), 2))')); hold off
% %nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_D(:, cid, :), 2))')); hold off


%% Prepare quantiles
drop_by_error = 1;
num_samps = 96;
num_wk_ahead = 52;
scen_ids = {'A'; 'B'; 'C'; 'D'};
dat_type = {'infec'; 'death'};
all_quant_diff = zeros(length(scen_ids), length(dat_type), length(popu), num_samps, num_wk_ahead);

T_corr = 0; % append previous week to projections
num_wk_ahead = num_wk_ahead - T_corr;   
thisday = orig_thisday;

%%%%%%%%%%% Create duplicates for weighted sampling
%%% Here we want to replicate based on rates
infec_weights = ones(size(scen_list, 1), 1);
% infec_weights(scen_list(:, 5)==0) = 4;
% infec_weights(scen_list(:, 5)==7) = 0;
% infec_weights(scen_list(:, 5)==14) = 0;

dh_weights = ones(size(scen_list, 1)*num_dh_rates_sample, 1);
idx = find((scen_list(:, 5)==0)) + [0:num_dh_rates_sample-1]*size(scen_list, 1);
dh_weights(idx) = 4;
idx = find((scen_list(:, 5)==7)) + [0:num_dh_rates_sample-1]*size(scen_list, 1);
dh_weights(idx) = 0;
% idx = find((scen_list(:, 5)==14)) + [0:num_dh_rates_sample-1]*size(scen_list, 1);
% dh_weights(idx) = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for ss = 1:length(scen_ids)
    err_mat = eval(['err_' scen_ids{ss}]);
    for cid = 1:length(popu)
        for dt = 1:length(dat_type)
            net_dat = eval(['net_' dat_type{dt} '_' scen_ids{ss}]);
            thisdata = squeeze(net_dat(:, cid, :));

            if dt == 1
                base_val = data_4(cid, thisday-7*T_corr);
                fw = data_4(cid, thisday);
                ww = infec_weights;
            elseif dt == 2
                base_val = deaths(cid, thisday-7*T_corr);
                fw = deaths(cid, thisday);
                ww = dh_weights;
            end

            thisdata = thisdata(:, 7:7:num_wk_ahead*7);
            fw = fw + 0*thisdata(:, 1);
            fw = (fw+abs(fw))/2;

            if T_corr > 0
                thisdata = [fw, thisdata];
            end

            diffdata = diff([repmat(base_val, [size(thisdata, 1) 1]), thisdata], 1, 2);
            bad_diff = diffdata(:, 1)==0;

            if drop_by_error == 1
                if dt==1
                    [~, idx] = sort(mean(err_mat(:, cid, :), 3), 'ascend');
                    good_idx = idx(1:length(idx)/2);
                    all_quant_diff(ss, dt, cid, :, :) = diffdata(good_idx, :);
                else
                    all_quant_diff(ss, dt, cid, :, :) = diffdata(3+num_dh_rates_sample*(good_idx-1), :);
                end
            else
                if dt==1
                    all_quant_diff(ss, dt, cid, :, :) = diffdata(2:2:end, :);
                else
                    all_quant_diff(ss, dt, cid, :, :) = diffdata(3:10:end, :);
                end
            end
        end
    end
end
% all_quant_vals(isnan(all_quant_vals)) = 0;
% all_mean_vals(isnan(all_mean_vals)) = 0;
thisday = orig_thisday - 7*T_corr;
 %% Remove bad countries
bad_cc = 4;
all_quant_diff(:, :, bad_cc, :) = nan;
%% Quant plots
%cid = popu>-1;
cid = 9; %cid = find(contains(countries, 'United Kingdom'));
quant_show = 1:num_samps        ;
tvals = size(data_4(cid, 52:7:end), 2);
xvals = (size(data_4(cid, 52:7:end), 2):size(data_4(cid, 52:7:end), 2)+size(all_quant_diff, 5)-1);
tiledlayout(4, 2, 'TileSpacing','compact');

for ss=1:4                
    nexttile; plot(diff(sum(data_4(cid, 52:7:thisday), 1))); hold on;
    plot(xvals, squeeze(sum(all_quant_diff(ss, 1, cid, quant_show, :), 3))');
        
    nexttile; plot(diff(sum(deaths(cid, 52:7:thisday), 1))); hold on;
    plot(xvals, squeeze(sum(all_quant_diff(ss, 2, cid, quant_show, :), 3))');
    
%     nexttile; plot(diff(nansum(hosp_cumu(cid, 52:7:thisday), 1))); hold on;
%     plot(xvals, squeeze(nansum(all_quant_diff(ss, 3, cid, quant_show, :), 3))'); hold on;
%     plot(xvals, squeeze(nansum(all_mean_diff(ss, 3, cid, :), 3))', 'o'); hold off;
end
%%
save ../../../../../code/data_dumps/EU_round_2_large.mat

%% Create tables from the matrices

first_day_pred = 7;
iso2 = eu_names(eu_present>0);

if write_data == 1
    disp('creating inc quant table for EU countries');
    T = table;
    scen_date = '2022-07-24';
    dt_name = {' case'; ' death'}; %' hosp'};
    thesevals = all_quant_diff(:);
    [ss, dt, cid, qq, wh] = ind2sub(size(all_quant_diff), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T.origin_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    T.target_variable =strcat(['inc '], dt_name(dt));
    T.horizon = strcat(wh_string(wh), [' wk']);
    T.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    T.location = iso2(cid);
    %T.type = repmat({'quantile'}, [length(thesevals) 1]);
    T.sample = num2cell((qq));
    T.value = compose('%g', round(thesevals, 0));
    
%     bad_quants = cellfun(@(x)(x==0 || x==1), T.quantile);
%     T(bad_quants, :) = [];
    
%     disp('creating inc mean table for EU countries');
%     
%     Tm = table;
%     thesevals = all_mean_diff(:);
%     [ss, dt, cid, wh] = ind2sub(size(all_mean_diff), (1:length(thesevals))');
%     Tm.origin_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
%     Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
%     Tm.target_variable =strcat(['inc '], dt_name(dt));
%     Tm.horizon = strcat(wh_string(wh), [' wk ahead ']);
%     Tm.target_end_date = datestr(thisday+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
%     Tm.location = iso2(cid);
%     Tm.type = repmat({'point'}, [length(thesevals) 1]);
%     Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
%     Tm.value = compose('%g', round(thesevals, 0));
    
    %full_T = [T];
    nanidx = (strcmpi(T.value, 'NaN'));
    T(nanidx, :) = [];
    % Write files on disk
    disp('Writing File');
    tic;
    writetable(T, ['../../../../data_dumps/' datestr(now_date, 'YYYY-mm-DD') '-USC-SIkJalpha_EU.csv']);
    toc
    
end