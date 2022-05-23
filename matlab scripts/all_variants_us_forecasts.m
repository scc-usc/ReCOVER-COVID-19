
clear; warning off;
load_data_us;
addpath('./utils/');
addpath('./scenario_projections/');
prevalence_ww;
%load ww_prevalence_us.mat
%%
smooth_factor = 14;
data_4(:, 669:669+13) = nan; deaths(:, 669:669+13) = nan;
data_4_s = smooth_epidata(data_4, smooth_factor, 0, 1);
deaths_s = smooth_epidata(deaths, 1);
horizon = 100;
ns = size(data_4, 1); maxt = size(data_4, 2);
%% Vaccine data

vacc_download_age_state;
%%
[vacc_given_by_age] = get_vacc_preds(vacc_num_age_est, pop_by_age, horizon);
all_boosters_ts = cell(3, 1);
booster_by_age_orig = get_booster_preds(extra_dose_age_est, vacc_given_by_age, pop_by_age, 1, 180, 0);
all_boosters_ts{2} = sum(booster_by_age_orig, 3);
pred_adopts = squeeze(booster_by_age_orig(:, end, :)./(vacc_given_by_age(:, end, :) + 1e-10)); pred_adopts(pred_adopts>1) = 1;
curr_adopts = squeeze(booster_by_age_orig(:, end-horizon, :)./(vacc_given_by_age(:, end, :) + 1e-10)); curr_adopts(curr_adopts>1) = 1;

lb = curr_adopts + (pred_adopts - curr_adopts)*(1 - 0.1);
ub = pred_adopts + (1 - pred_adopts)*(0.3);
all_boosters_ts{1} = sum(get_booster_preds(extra_dose_age_est, vacc_given_by_age, pop_by_age, ub, 180, 1), 3);
all_boosters_ts{3} = sum(get_booster_preds(extra_dose_age_est, vacc_given_by_age, pop_by_age, lb, 180, 1), 3);
boost_cov = [1 2 3];
vacc_given_by_age = sum(vacc_given_by_age, 3);

%% hyperparameters
best_param_list_v = zeros(ns, 3);
best_param_list_v(:, 1) = 2; best_param_list_v(:, 2) = 7; case_alpha = 0.95;
k_l = best_param_list_v(:, 1); jp_l = best_param_list_v(:, 2);
T_full = size(data_4, 2);
thisday = T_full;

%% Adjust variants prevalences
xx = load('variants.mat', "var_frac_all*","lineages_voc", 'valid_lins_voc', "all_var_data*");
var_frac_all = xx.var_frac_all_voc(:, :, 1:thisday);
var_frac_all_low = xx.var_frac_all_low_voc(:, :, 1:thisday); 
var_frac_all_high = xx.var_frac_all_high_voc(:, :, 1:thisday); 
lineages = xx.lineages_voc;
valid_lins = xx.valid_lins_voc;

% xx = load('variants.mat', "var_frac_all*","lineages", 'valid_lins', "all_var_data");
% var_frac_all = xx.var_frac_all(:, :, 1:thisday);
% var_frac_all_low = xx.var_frac_all_low(:, :, 1:thisday); 
% var_frac_all_high = xx.var_frac_all_high(:, :, 1:thisday); 
% lineages = xx.lineages;
% valid_lins = xx.valid_lins;

%% Adjust bounds to focus on omicron
var_frac_all_low(var_frac_all_low < 0) = 0;
var_frac_all_high(var_frac_all_high > 1) = 1;
var_frac_all_low = var_frac_all_low./(1e-20 + nansum(var_frac_all_low, 2));
var_frac_all_high = var_frac_all_high./(1e-20 + nansum(var_frac_all_high, 2));

% omic_idx = find(contains(lineages, 'Omicron')); omic_idx = omic_idx(1);
% other_idx = find(contains(lineages, 'other')); other_idx = other_idx(1);

% omic_refs = valid_lins(:, omic_idx)> 0;
% if sum(omic_refs)>0
%     temp = var_frac_all(omic_refs, omic_idx, :);
%     [~, idx] = min(abs(sum(temp(:, end-7:end), 3) - median(sum(temp(:, end-7:end), 3))));
%     omic_fill = temp(idx(1), :);
% 
%     omic_fill_low = omic_fill/2; % Necessary to have some prevelance
% 
%     temp = var_frac_all_high(omic_refs, omic_idx, :);
%     [~, idx] = min(abs(sum(temp(:, end-7:end), 3) - median(sum(temp(:, end-7:end), 3))));
%     omic_fill_high = temp(idx(1), :);
% end

nl = length(lineages);

var_frac_all(isnan(var_frac_all)) = 0;
var_frac_all_low(isnan(var_frac_all_low)) = 0;
var_frac_all_high(isnan(var_frac_all_high)) = 0;
var_frac_range{1} = var_frac_all_low;
var_frac_range{2} = var_frac_all;
var_frac_range{3} = var_frac_all_high;

%%
rate_smooth = 14;
rlag_list = [0 1]; rlag_idx = (1:length(rlag_list));
lag_list = [0];
un_array = true_new_infec_ww;

un_list = [1 2 3];
var_prev_q = [1 2 3];

booster_cov_list = [1 2 3];

%% Waning possibilities
% 2nd dimension represents scenarios. 
% 1st dimension is # of age gorups
% 3rd dimension is # of lineages
num_wan = [1:2];
ag_wan_lb_list = repmat([0.3 0.5], [2 1]);
ag_wan_param_list = repmat([30*6 30*4], [2 1]);
P_death_list_orig = repmat([repmat([0.93 0.93], [2 1])], [1 1 nl]);
P_hosp_list_orig = repmat([repmat([0.87 0.87], [2 1])], [1 1 nl]);

%%
[X1, X2, X3, X4, X5, X6] = ndgrid(un_list, lag_list, var_prev_q(2), rlag_idx, booster_cov_list(2), num_wan);
scen_list = [X1(:), X2(:), X3(:) X4(:) X5(:) X6(:)];
num_dh_rates_sample = 5;

dalpha = 0.98;
[X, Y, Z, A, A1] = ndgrid([3:8], 7, [75 100], [1:6], [1]);
param_list = [X(:), Y(:), Z(:), A(:), A1(:)];
val_idx = (param_list(:, 1).*param_list(:, 2) <=49) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))>2 & (param_list(:, 1) - param_list(:, 4))<4;
param_list = param_list(val_idx, :);

%%
tic;
net_infec_0 = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_0 = zeros(size(scen_list, 1)*num_dh_rates_sample, size(data_4, 1), horizon);

P_death_list = P_death_list_orig;
P_hosp_list = P_hosp_list_orig;
forecast_simulator;
toc
%%
net_infec_0(isnan(net_infec_0)) = 0;
%%
infec_un_0 = squeeze(trimmean(net_infec_0, 0.9, 1));
deaths_un_0 = squeeze(trimmean(net_death_0, 0.9, 1));

infec_un_lb = squeeze(min(net_infec_0, [], 1));
deaths_un_lb = squeeze(min(net_death_0, [], 1));

infec_un_ub = squeeze(max(net_infec_0, [], 1));
deaths_un_ub = squeeze(max(net_death_0, [], 1));


%% Plot test
cid = 26; maxt = size(data_4, 2); horizon = size(net_death_0, 3);
tiledlayout(2, 1);
nexttile;
plot(diff(sum(data_4(cid, :), 1))); hold on;
plot(diff(sum(data_4_s(cid, :), 1))); hold on;
plot(maxt:maxt+horizon-2, squeeze(diff(sum(net_infec_0(:, cid, :), 2), 1, 3))); 
%plot(maxt:maxt+horizon-2, diff(sum(infec_un_0(cid, :), 1)), 'o'); hold on;

nexttile;
plot(diff(sum(deaths(cid, :), 1))); hold on;
plot(diff(sum(deaths_s(cid, :), 1))); hold on;
plot(maxt:maxt+horizon-2, squeeze(diff(sum(net_death_0(:, cid, :), 2), 1, 3))); hold off;
hold off;
%%
% figure; cid = 3; ss = 6;
% plot(maxt:maxt+horizon-2, squeeze(diff(sum(net_infec_0(scen_list(:, ss)==1, cid, :), 2), 1, 3)), 'r'); hold on;
% plot(maxt:maxt+horizon-2, squeeze(diff(sum(net_infec_0(scen_list(:, ss)==2, cid, :), 2), 1, 3)), 'g'); hold on;
% plot(maxt:maxt+horizon-2, squeeze(diff(sum(net_infec_0(scen_list(:, ss)==3, cid, :), 2), 1, 3)), 'b'); 

%%
save us_results.mat all_deltemps all_immune_infecs net_death_0 net_infec_0 data_4 deaths deaths_s data_4_s popu countries best_param_list* un_array;
%%
file_suffix = '0';
prefix = 'us';
file_prefix =  ['../results/forecasts/' prefix];
writetable(infec2table(infec_un_0, countries), [file_prefix '_forecasts_current_' file_suffix '.csv']);
writetable(infec2table(deaths_un_0, countries), [file_prefix '_deaths_current_' file_suffix '.csv']);

add_to_history;
disp('Files Written');

%% Write lower and upper bounds

now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end
lowidx = zeros(length(countries), 1);

writetable(infec2table(infec_un_lb, countries), [file_prefix '_forecasts_current_' file_suffix '_lb.csv']);
writetable(infec2table(deaths_un_lb, countries), [file_prefix '_deaths_current_' file_suffix '_lb.csv']);

writetable(infec2table(infec_un_ub, countries), [file_prefix '_forecasts_current_' file_suffix '_ub.csv']);
writetable(infec2table(deaths_un_ub, countries), [file_prefix '_deaths_current_' file_suffix '_ub.csv']);


writetable(infec2table([base_infec infec_un_lb], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases_lb.csv']);
writetable(infec2table([base_deaths deaths_un_lb], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths_lb.csv']);

writetable(infec2table([base_infec infec_un_ub], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases_ub.csv']);
writetable(infec2table([base_deaths deaths_un_ub], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths_ub.csv']);