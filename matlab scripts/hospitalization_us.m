addpath('./utils/');
% Get from 
% https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state-timeseries
%sel_url = 'https://healthdata.gov/sites/default/files/reported_hospital_utilization_timeseries_20210306_1105.csv';
sel_url = 'https://healthdata.gov/api/views/g62h-syeh/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
hosp_tab = readtable('dummy.csv');
%% Load case data
prefix = 'us';

%%%%%%%% Choose a date or selcect current date
%now_date = datetime(2021, 1, 3);
now_date = datetime((now),'ConvertFrom','datenum'); % 'TimeZone', 'America/Los_Angeles');
%%%%%%%%%%%%%%%%%%%%%%%%%

daynum = floor(days((now_date) - datetime(2020, 1, 23)));

path = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [path dirname];      
xx = readtable([fullpath '/' prefix '_data.csv']); data_4 = table2array(xx(2:end, 3:end));
lcorrection = daynum - size(data_4, 2); data_4 = [zeros(size(data_4, 1), lcorrection) data_4];

%% Convert hospital data to ReCOVER format
abvs = readcell('us_states_abbr_list.txt');
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
fips = cell(size(data_4, 1), 1);
hosp_dat = nan(size(data_4, 1), size(data_4, 2));
hosp_dat_p = nan(size(data_4, 1), size(data_4, 2));
hosp_dat_a = nan(size(data_4, 1), size(data_4, 2));

for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end

for idx = 1:size(hosp_tab, 1)
    
    cid = find(strcmp(abvs, hosp_tab.state(idx)));
    if isempty(cid)
        disp(['Error at ' num2str(idx)]);
    end
    date_idx = days(datetime(hosp_tab.date(idx), 'InputFormat', 'yyyy/MM/dd') - datetime(2020, 1, 23));
    
    if date_idx < 1
        continue;
    end
    
    hosp_dat_a(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx);
    hosp_dat_p(cid, date_idx) = hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
    hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx) + hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
end

%% Learn hospitalization rate like death forecasts
T_full = max(find(any(~isnan(hosp_dat), 1)));
maxt = size(data_4, 2);
load us_hyperparam_latest.mat;
hosp_cumu = cumsum(nan2zero(hosp_dat), 2);

%% Load case forecasts
dirname = datestr(datetime(2020, 1, 23)+caldays(maxt), 'yyyy-mm-dd');
fullpath = [path dirname];      

xx = readtable([fullpath '/' prefix '_forecasts_cases.csv']); pred_cases = table2array(xx(2:end, 4:end));
placenames = xx{2:end, 2};
popu = load('us_states_population_data.txt');

%% 
% CDC_sero;
% un = un_array(:, 2);

%%
smooth_factor = 14;
data_4_s = smooth_epidata(data_4(:, :), smooth_factor/2);
hosp_cumu_s = smooth_epidata(hosp_cumu(:, 1:T_full), smooth_factor/2);

% Redefine hyper-parameter ranges, no need to enforce lag
dkrange = (1:2); djprange = 7; dwin = [50 100]; lag_range = (0:1);
[X, Y, Z, A] = ndgrid(dkrange, djprange, dwin, lag_range);
param_list = [X(:), Y(:), Z(:), A(:)];
idx = (param_list(:, 1).*param_list(:, 2) <=28) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))> 0;
param_list = param_list(idx, :);
[best_hosp_hyperparam] = death_hyperparams(hosp_cumu(:, 1:T_full), data_4_s(:, 1:T_full), hosp_cumu_s(:, 1:T_full), T_full, 7, popu, 0, best_param_list, 1, param_list);
hosp_data_limit = T_full;
% dk = best_hosp_hyperparam(:, 1);
% djp = best_hosp_hyperparam(:, 2);
% dwin = best_hosp_hyperparam(:, 3);
% dlags = best_hosp_hyperparam(:, 4);
% dalpha = 0.8;
% dhorizon = 100;

% %% Perform prediction
% 
% [hosp_rates] = var_ind_deaths(data_4_s(:, 1:T_full), hosp_cumu_s, dalpha, dk, djp, dwin, 0, popu > -1, dlags);
% disp('trained hospitalizations');
% 
% infec_data = cumsum([zeros(length(placenames), 1) diff(data_4_s, 1, 2) diff(pred_cases, 1, 2)], 2);
% base_hosp = hosp_cumu(:, maxt);
% [pred_hosps] = var_simulate_deaths(infec_data, hosp_rates, dk, djp, dhorizon, base_hosp, T_full-1);
% pred_base_hosp = pred_hosps(:, maxt-T_full+1);
% pred_new_hosps = diff([base_hosp pred_hosps]')';
% pred_new_hosps(:,  1:(maxt-T_full)) = [];   % Adjust based on the day of prediction
% disp('predicted hospitalizations');

%% We generate multiple sub-scenarios and sample to get quantiles

%un_list = [1 2 3];
lags_list = [0 3 7 10 14];

hk = best_hosp_hyperparam(:, 1);
hjp = best_hosp_hyperparam(:, 2);
hwin = best_hosp_hyperparam(:, 3);
hlags = best_hosp_hyperparam(:, 4);
halpha = 0.9; hhorizon = 110; horizon = 100;

for j=1:length(lags_list)
    T_full = hosp_data_limit;
    [hosp_rates] = var_ind_deaths(data_4_s(:, 1:T_full - lags_list(j)), hosp_cumu_s(:, 1:T_full - lags_list(j)), halpha, hk, hjp, hwin, 0, popu > -1, hlags);
    hosp_rates_list{j} = hosp_rates;
end
save us_hospitalization hosp_cumu hosp_cumu_s best_hosp_hyperparam hosp_rates hosp_data_limit fips;
%%
load us_results.mat;
net_infec_A = net_infec_0;
net_hosp_A = zeros(size(net_infec_A, 1)*length(lags_list), size(data_4, 1), horizon);


for simnum = 1:size(net_infec_A, 1)
    % Hosp
    for jj = 1:length(hosp_rates_list)
        hosp_rates = hosp_rates_list{1};
        rate_change = intermed_betas(hosp_rates, best_hosp_hyperparam, hosp_rates_list{jj}, best_hosp_hyperparam, 7);
        T_full = hosp_data_limit;
        infec_data = [data_4_s squeeze(net_infec_A(simnum, :, :))-data_4(:, end)+data_4_s(:, end)];
        base_hosp = hosp_cumu(:, T_full);
        pred_hosps1 = var_simulate_deaths_vac(infec_data, hosp_rates, hk, hjp, hhorizon, base_hosp, T_full-1, rate_change);
        h_start = size(data_4, 2)-T_full+1;
        net_hosp_A(simnum+(jj-1)*size(net_infec_A, 1), :, :) = [pred_hosps1(:, h_start:h_start+horizon-1)];
    end
    fprintf('.');
    
end
fprintf('\n');

%% Generate quantiles
num_ahead = 99;
quant_hosp = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
quant_preds_hosp = zeros(length(popu), num_ahead, length(quant_hosp));
%mean_preds_hosp = zeros(length(popu), num_ahead);
%mean_preds_hosp = pred_new_hosps(:, 1:num_ahead);
mean_preds_hosp = squeeze(nanmean(diff(net_hosp_A(:, :, 1:num_ahead+1), 1, 3), 1));
med_idx  = find(abs(quant_hosp-0.5)<0.001);
for cid = 1:length(popu)
    thisdata = squeeze(net_hosp_A(:, cid, 1:num_ahead+1));
    thisdata(all(thisdata==0, 2), :) = [];
    
    %thisdata = diff([repmat(pred_base_hosp(cid, 1),[size(thisdata, 1), 1]) thisdata]')';
    thisdata = diff(thisdata, 1, 2);
    dt = hosp_dat; gt_lidx = size(dt, 2); extern_dat = (dt(cid, gt_lidx-14:gt_lidx))';
    extern_dat(isnan(extern_dat)) = [];
    extern_dat = extern_dat - mean(extern_dat) + mean_preds_hosp(cid, :);
    %thisdata = thisdata - mean(thisdata, 1);
    thisdata = [thisdata; extern_dat];
    
    quant_preds_hosp(cid, :, :) = quantile(thisdata(:, 1:num_ahead), quant_hosp)';
%     adjust_quants = (squeeze(quant_preds_hosp(cid, :, med_idx)) - mean_preds_hosp(cid, :));
%     quant_preds_hosp(cid, :, :) = quant_preds_hosp(cid, :, :) - adjust_quants;
    %mean_preds_hosp(cid, :) = mean(thisdata(:, 1:num_ahead), 1);
end
quant_preds_hosp = (quant_preds_hosp+abs(quant_preds_hosp))/2;
%% Plot
% plot((1:size(data_4, 2)), hosp_dat(cid, :)); hold on;
% plot((T_full+1:T_full+size(pred_new_hosps, 2)), pred_new_hosps(cid, :)); hold off;
dt = hosp_dat;
dt_s = [zeros(length(popu), 2) diff(hosp_cumu_s, 1, 2)];
sel_idx = 3;% sel_idx = contains(placenames, 'Nebraska');
thisquant = squeeze(nansum(quant_preds_hosp(sel_idx, :, [1 7 17 23]), 1));
mpred = (nansum(mean_preds_hosp(sel_idx, :), 1))';
gt_len = 400;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len:1:gt_lidx);
gt = dt(sel_idx, gt_idx);
gt_s = dt_s(sel_idx, gt_idx);
TT = datetime(2020, 1, 23) + T_full - gt_len + (1:1000);
plot(TT(1:length(gt)), [gt' gt_s']); hold on; plot(TT(gt_len+1:gt_len+size(thisquant, 1)), [mpred thisquant]); hold off;
title(['Hospitalization ' placenames{sel_idx} ]);

%%
cidx = find(popu>-1);
hosp_vals = cell((1+length(quant_hosp))*(1+length(cidx))*num_ahead, 7);
kk = 1;
forecast_date = datestr(datetime(2020, 1, 23)+caldays(maxt), 'yyyy-mm-dd');

for ii = 1:length(cidx)
    for jj = 1:num_ahead
        target_date = datestr(datetime(2020, 1, 23)+caldays(maxt+jj), 'yyyy-mm-dd');
        thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc hosp']} {target_date} fips{cidx(ii)} {'point'} {'NA'} compose('%.1f', mean_preds_hosp(cidx(ii), jj))];
        hosp_vals(kk, :) = thisentry;
        
        hosp_vals(kk+1:kk+length(quant_hosp), 1) = mat2cell(repmat(forecast_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc hosp'], [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 3) = mat2cell(repmat(target_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 4) = mat2cell(repmat(fips{cidx(ii)}, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 5) = mat2cell(repmat('quantile', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 6) = compose('%g', quant_hosp(:));
        %hosp_vals(kk+1:kk+length(quant_hosp), 7) = mat2cell(squeeze(quant_preds_hosp(cidx(ii), jj, :)), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 7) = compose('%.1f', squeeze(quant_preds_hosp(cidx(ii), jj, :)));
        kk = kk+length(quant_hosp)+1;
    end
    fprintf('.');
end
%%
% Add US forecasts by combining states
for jj = 1:num_ahead
    target_date = datestr(datetime(2020, 1, 23)+caldays(maxt+jj), 'yyyy-mm-dd');
    thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc hosp']} {target_date} {'US'} {'point'} {'NA'} compose('%.1f',nansum(mean_preds_hosp(cidx, jj)))];
    hosp_vals(kk, :) = thisentry;
    
    hosp_vals(kk+1:kk+length(quant_hosp), 1) = mat2cell(repmat(forecast_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc hosp'], [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 3) = mat2cell(repmat(target_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 4) = mat2cell(repmat('US', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 5) = mat2cell(repmat('quantile', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 6) = compose('%g', quant_hosp(:));
    hosp_vals(kk+1:kk+length(quant_hosp), 7) = compose('%.1f', nansum(squeeze(quant_preds_hosp(cidx, jj, :)), 1)');
    kk = kk+length(quant_hosp)+1;
end

%% Write file

pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

hosp_vals((strcmpi(hosp_vals(:, 7), 'nan')), :) = [];
writecell(hosp_vals, [fullpath '/' prefix '_hosp_quants.csv']);