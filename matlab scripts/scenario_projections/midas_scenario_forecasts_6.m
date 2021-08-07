%%% Scenario forecasts
clear;
write_data = 0;
addpath('../../scripts/');
%% Load baselines
warning off;
load latest_us_data.mat
load us_hyperparam_latest.mat
load us_hospitalization.mat
CDC_sero;

%%%% Date correction if the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% is to be done on a previous date %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
now_date = datetime(2021, 05, 29);
thisday = floor(days((now_date) - datetime(2020, 1, 23)));
data_4 = data_4(:, 1:thisday);
deaths = deaths(:, 1:thisday);
hosp_data_limit = min([hosp_data_limit, thisday]);
hosp_cumu = hosp_cumu(:, 1:min([thisday size(hosp_cumu, 2)]));
hosp_cumu_s = hosp_cumu_s(:, 1:min([thisday size(hosp_cumu_s, 2)]));
un_ts = fillmissing(un_ts(:, 1:thisday), 'previous', 2); un_ts(un_ts<1) = 1;
un_lts = fillmissing(un_lts(:, 1:thisday), 'previous', 2); un_lts(un_lts<1) = 1;
un_uts = fillmissing(un_uts(:, 1:thisday), 'previous', 2);
un_array = [un_lts(:, end), un_ts(:, end), un_uts(:, end)];
un_array(isnan(un_array)) = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find death and hospitalization behavior among age groups
popu_age = readtable('population_by_age_by_state.csv');
popu_by_age = popu_age{:, 2:end};
popu_ratio = nansum(popu_by_age, 1)./sum(nansum(popu_by_age, 1));
idx = any(isnan(popu_by_age), 2);
popu_by_age(idx, :) = popu(idx)*popu_ratio;
cum_popu = cumsum(popu_by_age, 2);
target_age_medians = [6, 13.5, 16.5, 21, 32, 45, 57, 69.5, 85];
temp = interp1([2, 9.5, 19.5, 29.5, 39.5, 49.5, 60, 69.5, 79.5, 85], cum_popu', target_age_medians);
popu_for_vacc = diff([zeros(1, 56); temp]);

death_age = readtable('death_by_age_by_state.csv');
dr_by_age = interp1([2, 9.5, 19.5, 29.5, 39.5, 49.5, 60, 69.5, 79.5, 85], death_age{:, 2:end}', target_age_medians)';

% hospitalization age groups: interpolated from CDC data 9 age groups-->10
hosp_int_age = interp1([2, 11, 23.5, 34.5, 44.5, 57, 69.5, 79.5, 85], [1/4 1/9 1 2 3 4 5 8 13], target_age_medians);
hr_by_age = repmat(hosp_int_age, [size(data_4, 1) 1]);

%%

vacc_ad_dist_lags = [0]; % Where to pull admistered/distributed

%un_list = 1.1:0.1:1.5;
un_list = [1 2 3];
lags_list = 0:7:7;

rate_smooth = 14; % The death and hospitalizations will change slowly over these days

hc_num = 18000000; % Number of health care workers ahead of age-groups

xx = load('vacc_data.mat');
u_vacc = xx.u_vacc;
u_vacc_shipped = xx.u_vacc_shipped;

vacc_lag_rate = ones(length(popu), 14);
vacc_all = xx.u_vacc(:, 1:thisday); vacc_full = xx.u_vacc_full(:, 1:thisday);
vacc_all = fillmissing(vacc_all, 'previous', 2); vacc_all(isnan(vacc_all)) = 0;
vacc_full = fillmissing(vacc_full, 'previous', 2); vacc_full(isnan(vacc_full)) = 0;

vacc_fd = vacc_all - vacc_full;
vacc_fd = [zeros(size(data_4, 1), size(data_4, 2)-size(vacc_fd, 2)), vacc_fd];
latest_vac = vacc_fd(:, end);
%% Vaccine hesitancy modeling
vacc_analysis;
vacc_perc = vacc_perc(:, 1:thisday);
%% hesitancy data is for [*, *, < 18, 18-29, 30-39, 40-49, 50-64, 65-74, 75+]
thisday = size(data_4, 2);
cum_popu = cumsum(popu_by_age, 2);
temp = interp1([2, 9.5, 19.5, 29.5, 39.5, 49.5, 60, 69.5, 79.5, 85], cum_popu', target_age_medians);
popu_for_vacc = diff([zeros(1, 56); temp]);
[vacc_given_by_age_low] = get_vacc_admin(vacc_perc, 0.75, final_cov1, 12, popu_for_vacc, vacc_fd, 200); % For ~75%
[vacc_given_by_age_high] = get_vacc_admin(vacc_perc, 0.86, final_cov2, 12, popu_for_vacc, vacc_fd, 200); % For ~86%
%%
horizon = 200;
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);
dk = best_death_hyperparam(:, 1);
djp = best_death_hyperparam(:, 2);
dwin = best_death_hyperparam(:, 3);
lags = best_death_hyperparam(:, 4);
dalpha = 1; dhorizon = horizon+28;

hk = best_hosp_hyperparam(:, 1);
hjp = best_hosp_hyperparam(:, 2);
hwin = best_hosp_hyperparam(:, 3);
hlags = best_hosp_hyperparam(:, 4);
halpha = 1; hhorizon = horizon + 28;

for j=1:length(lags_list)
    [death_rates] = var_ind_deaths(data_4_s(:, 1:end-lags_list(j)), deaths_s(:, 1:end-lags_list(j)), dalpha, dk, djp, dwin, 0, popu>-1, lags);
    death_rates_list{j} = death_rates;
    T_full = hosp_data_limit;
    [hosp_rates] = var_ind_deaths(data_4_s(:, 1:T_full - lags_list(j)), hosp_cumu_s(:, 1:T_full - lags_list(j)), halpha, hk, hjp, hwin, 0, popu > -1, hlags);
    hosp_rates_list{j} = hosp_rates;
    
    %     for uid = 1:length(un_list)
    %         un = un_array(:, uid);
    %         beta_after = var_ind_beta_un(data_4_s(:, 1:end-lags_list(j)), 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, popu>-1);
    %         infec_rates_list{j}{uid} = beta_after;
    %     end
end
best_param_list(:, 1) = 1; best_param_list(:, 2) = 7; best_param_list(:, 3) = 0.9;

%%
% Reference Rt values for NPI
phase1_len = ones(size(data_4, 1), 1)*0;
base_infec = data_4_s(:, 1:end);
best_param_list_v = best_param_list;
best_param_list_nv = best_param_list;

mob_data = readtable('cuebiq_mobility.csv');
[aa, bb] = ismember(mob_data.place_, countries);
cic = nan(length(popu), 1);
cic(bb) = mob_data.Openness;
cic(isnan(cic)) = median(cic(~isnan(cic)));

ns = length(popu); nr = 4; Rt_conf_all = zeros(nr, ns, 3);

for jj=52:7:(52+(nr-1)*7)
[betas, ~,  betas_ci] = var_ind_beta_un(data_4_s(:, 1:jj), 0, best_param_list_v(:, 3)*0.1, best_param_list_v(:, 1), 2, popu, best_param_list_v(:, 2), 1, popu>-1);
[Rt, Rt_conf] = calc_Rt(betas, best_param_list_v(:, 1), best_param_list_v(:, 2), ones(ns, 1), betas_ci);
Rt_conf_all((jj-52)/7 + 1, :, 1) = Rt_conf(:, 1);
Rt_conf_all((jj-52)/7 + 1, :, 3) = Rt_conf(:, 2);
Rt_conf_all((jj-52)/7 + 1, :, 2) = Rt;
end
Rt_conf_all = movmean(squeeze(Rt_conf_all(:, :, 2)),  3, 2)';
Rt_before = min(3, Rt_conf_all(:, 1));

[betas] = var_ind_beta_un(data_4_s(:, 1:end), 0, best_param_list_v(:, 3)*0.1, best_param_list_v(:, 1), 2, popu, best_param_list_v(:, 2), 0, popu>-1);
Rt_now = calc_Rt(betas, best_param_list_v(:, 1), best_param_list_v(:, 2), ones(ns, 1));

%Target_Rt = [min(1, (Rt_now./Rt_before)*[1/1.3 1/1.5]) cic];  % openness
Target_Rt = [cic];  % openness

Rt_final_scens = [1:size(Target_Rt, 2)];
Feb_Rt = ones(length(popu), 1); 

Rt_init_scens = [1 2];
scenario_forecasts = 1;
var_prev_q = 1;
lags_list = [0];

%% Scenario A. High Vaccination, Low transmission advantage
tic;
disp('Executing Scenario A');

vacc_effi1 = 0.5; vacc_effi2 = 0.9 - vacc_effi1;
trans_adv = 1.2;

vacc_given_by_age = vacc_given_by_age_high;
vacc_coverage_list = [1];

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, lags_list, vacc_ad_dist_lags, var_prev_q, Rt_init_scens, Rt_final_scens, vacc_coverage_list);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:), X7(:)];

npi_red = 0.8;
variant_rt_change = nan(length(popu), horizon);
midas_scenario_simulator6;

net_infec_A = net_infec_0;
net_death_A = net_death_0;
net_hosp_A = net_hosp_0;
net_var_A = net_var_0;
toc;
%% Scenario B: High Vaccination, High transmission advantage

disp('Executing Scenario B');


vacc_effi1 = 0.5; vacc_effi2 = 0.9 - vacc_effi1;
trans_adv = 1.6;

vacc_given_by_age = vacc_given_by_age_high;
vacc_coverage_list = [1];

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, lags_list, vacc_ad_dist_lags, var_prev_q, Rt_init_scens, Rt_final_scens, vacc_coverage_list);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:), X7(:)];

npi_red = 0.8;
variant_rt_change = nan(length(popu), horizon);

midas_scenario_simulator6;

net_infec_B = net_infec_0;
net_death_B = net_death_0;
net_hosp_B = net_hosp_0;
net_var_B = net_var_0;

%% Scenario C: Low Vaccination, Low transmission advantage

disp('Executing Scenario C');


vacc_effi1 = 0.5; vacc_effi2 = 0.9 - vacc_effi1;
trans_adv = 1.2;

vacc_given_by_age = vacc_given_by_age_low;
vacc_coverage_list = [1];

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, lags_list, vacc_ad_dist_lags, var_prev_q, Rt_init_scens, Rt_final_scens, vacc_coverage_list);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:), X7(:)];


npi_red = 0.8;
variant_rt_change = nan(length(popu), horizon);

midas_scenario_simulator6;

net_infec_C = net_infec_0;
net_death_C = net_death_0;
net_hosp_C = net_hosp_0;
net_var_C = net_var_0;

%% Scenario D: Low Vaccination & High transmission advantage

disp('Executing Scenario D');

vacc_effi1 = 0.5; vacc_effi2 = 0.9 - vacc_effi1;
trans_adv = 1.6;

vacc_given_by_age = vacc_given_by_age_low;
vacc_coverage_list = [1];

[X1, X2, X3, X4, X5, X6, X7] = ndgrid(un_list, lags_list, vacc_ad_dist_lags, var_prev_q, Rt_init_scens, Rt_final_scens, vacc_coverage_list);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:), X7(:)];

npi_red = 0.8;
variant_rt_change = nan(length(popu), horizon);

midas_scenario_simulator6;

net_infec_D = net_infec_0;
net_death_D = net_death_0;
net_hosp_D = net_hosp_0;
net_var_D = net_var_0;

%%
% cid = 1:56;
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
quants = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
scen_ids = {'A'; 'B'; 'C'; 'D'};
dat_type = {'infec'; 'death'; 'hosp'};
scen_names = {'highVac_lowVar'; 'highVac_highVar'; 'lowVac_lowVar'; 'lowVac_highVar'};
all_quant_vals = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), horizon);
all_mean_vals = zeros(length(scen_ids), length(dat_type), length(popu), horizon);
for ss = 1:length(scen_ids)
    for dt = 1:length(dat_type)
        net_dat = eval(['net_' dat_type{dt} '_' scen_ids{ss}]);
        for cid = 1:length(popu)
            thisdata = squeeze(net_dat(:, cid, :));
            all_quant_vals(ss, dt, cid, :, :) = cumsum([quantile(thisdata(:, 1), quants), quantile(diff(thisdata')', quants)], 2);
            all_mean_vals(ss, dt, cid, :) = mean(thisdata, 1);
        end
    end
end
% all_quant_vals(isnan(all_quant_vals)) = 0;
% all_mean_vals(isnan(all_mean_vals)) = 0;
%% Create week ahead values based on what's observed on Sunday
thisday = size(data_4, 2);
a_sunday = 52;
today_day = mod(size(data_4, 2)-a_sunday, 7); % 0 for Sunday
first_day_pred = 7-today_day;

if today_day < 2
    infec0 = data_4(:, end-today_day);
    deaths0 = deaths(:, end-today_day);
    hosp0 = max([hosp_cumu_s(:, end-today_day)'; hosp_cumu(:, end-today_day)'])';
    
    all_quant_cum = all_quant_vals(:, :, :, :, first_day_pred:7:end);
    all_mean_cum = all_mean_vals(:, :, :, first_day_pred:7:end);
    all_quant_diff1 = diff(all_quant_vals(:, :, :, :, first_day_pred:7:end), 1, 5);
    all_mean_diff1 = diff(all_mean_vals(:, :, :, first_day_pred:7:end), 1, 4);
    
    all_quant_diff = zeros(size(all_quant_diff1) + [0 0 0 0 1]);
    all_mean_diff = zeros(size(all_mean_diff1) + [0 0 0 1]);
    all_quant_diff(:, :, :, :, 2:end) = all_quant_diff1;
    all_mean_diff(:, :, :, 2:end) = all_mean_diff1;
    
    for ss = 1:length(scen_ids)
        for qq = 1:length(quants)
            all_quant_diff(ss, 1, :, qq, 1) = squeeze(all_quant_cum(ss, 1, :, qq, 1)) - infec0;
            all_quant_diff(ss, 2, :, qq, 1) = squeeze(all_quant_cum(ss, 2, :, qq, 1)) - deaths0;
            all_quant_diff(ss, 3, :, qq, 1) = squeeze(all_quant_cum(ss, 3, :, qq, 1)) - hosp0;
            
            all_mean_diff(ss, 1, :, 1) = squeeze(all_mean_cum(ss, 1, :, 1)) - infec0;
            all_mean_diff(ss, 2, :, 1) = squeeze(all_mean_cum(ss, 2, :, 1)) - deaths0;
            all_mean_diff(ss, 3, :, 1) = squeeze(all_mean_cum(ss, 3, :, 1)) - hosp0;
        end
    end
    
    
else
    all_quant_cum = all_quant_vals(:, :, :, :, first_day_pred+7:7:end);
    all_mean_cum = all_mean_vals(:, :, :, first_day_pred+7:7:end);
    all_quant_diff = diff(all_quant_vals(:, :, :, :, first_day_pred:7:end), 1, 5);
    all_mean_diff = diff(all_mean_vals(:, :, :, first_day_pred:7:end), 1, 4);
    
    first_day_pred = first_day_pred+7;
end

%% Quant plots
%cid = popu>-1;
cid = 1:56;
quant_show = [7 12 17];
xvals = size(data_4(cid, 52:7:end), 2):size(data_4(cid, 52:7:end), 2)+size(all_quant_diff, 5)-1;
tiledlayout(4, 3, 'TileSpacing','compact');

for ss=1:4
    nexttile; plot(diff(nansum(data_4(cid, 52:7:end), 1))); hold on; plot(xvals, squeeze(nansum(all_quant_diff(ss, 1, cid, quant_show, :), 3))'); hold off
    nexttile; plot(diff(nansum(deaths(cid, 52:7:end), 1))); hold on; plot(xvals, squeeze(nansum(all_quant_diff(ss, 2, cid, quant_show, :), 3))'); hold off
    nexttile; plot(diff(nansum(hosp_cumu(cid, 52:7:end), 1))); hold on; plot(xvals, squeeze(nansum(all_quant_diff(ss, 3, cid, quant_show, :), 3))'); hold off
end


%% Create tables from the matrices
if write_data == 1
    disp('creating inc quant table for states');
    T = table;
    scen_date = '2021-06-08';
    dt_name = {' case'; ' death'; ' hosp'};
    thesevals = all_quant_diff(:);
    [ss, dt, cid, qq, wh] = ind2sub(size(all_quant_diff), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T.scenario_name = scen_names(ss);
    T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    T.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
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
    Tm.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
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
    us_T.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
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
    us_Tm.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
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
    full_T(contains(full_T.target, '27 wk'), :) = [];
    full_T(contains(full_T.target, '28 wk'), :) = [];
    nanidx = (strcmpi(full_T.value, 'NaN'));
    full_T(nanidx, :) = [];
    
    % Write files on disk
    disp('Writing File');
    tic;
    writetable(full_T, ['../../results/to_reich/' datestr(now_date, 'YYYY-mm-DD') '-USC-SIkJalpha.csv']);
    toc
    
end