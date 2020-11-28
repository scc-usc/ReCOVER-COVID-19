sel_url = 'https://healthdata.gov/sites/default/files/reported_hospital_utilization_timeseries_20201122_2140.csv';
urlwrite(sel_url, 'dummy.csv');
hosp_tab = readtable('dummy.csv');
%% Load case data
prefix = 'us';
now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
path = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [path dirname];      
daynum = days(date - datetime(2020, 1, 23))-1;

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
    date_idx = days(hosp_tab.date(idx) - datetime(2020, 1, 23));
    
    if date_idx < 1
        continue;
    end
    
    hosp_dat_a(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx);
    hosp_dat_p(cid, date_idx) = hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
    hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx) + hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
end

%% Learn hospitalization rate like death forecasts
T_full = size(data_4, 2);
load us_hyperparam_latest.mat;
hosp_cumu = cumsum(nan2zero(hosp_dat), 2);

%% Load case forecasts
dirname = datestr(datetime(2020, 1, 23)+caldays(T_full), 'yyyy-mm-dd');
fullpath = [path dirname];      
daynum = T_full;
xx = readtable([fullpath '/' prefix '_forecasts_cases.csv']); pred_cases = table2array(xx(2:end, 3:end));

placenames = xx{2:end, 2};
popu = load('us_states_population_data.txt');

%% 
smooth_factor = 14;
data_4_s = smooth_epidata(data_4(:, 1:end), smooth_factor);
hosp_cumu_s = smooth_epidata(hosp_cumu(:, 1:T_full), smooth_factor);

% Redefine hyper-parameter ranges, no need to enforce lag
dkrange = (1:4); djprange = 7; dwin = [25 50 100]; lag_range = (0:3);
[X, Y, Z, A] = ndgrid(dkrange, djprange, dwin, lag_range);
param_list = [X(:), Y(:), Z(:), A(:)];
idx = (param_list(:, 1).*param_list(:, 2) <=21) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))>0;
param_list = param_list(idx, :);
[best_hosp_hyperparam] = death_hyperparams(hosp_cumu(:, 1:T_full), data_4_s(:, 1:T_full), hosp_cumu_s(:, 1:T_full), T_full, 7, popu, 0, best_param_list, 1, param_list);
dk = best_hosp_hyperparam(:, 1);
djp = best_hosp_hyperparam(:, 2);
dwin = best_hosp_hyperparam(:, 3);
lags = best_hosp_hyperparam(:, 4);
dalpha = 1;
dhorizon = 100;

%% Perform prediction
infec_data = [data_4_s(:, 1:T_full) pred_cases];
base_hosp = hosp_cumu(:, T_full);

[hosp_rates] = var_ind_deaths(data_4_s(:, 1:T_full), hosp_cumu_s, dalpha, dk, djp, dwin, 0, popu > -1, lags);
disp('trained hospitalizations');
[pred_hosps] = var_simulate_deaths(infec_data, hosp_rates, dk, djp, dhorizon, base_hosp, T_full-1);

pred_new_hosps = diff(pred_hosps')';
disp('predicted hospitalizations');

%% Temporary quick way of finding quantiles - Training
num_ahead = 56;
cidx = find(~isnan(hosp_dat(:, end)));
lookback = 14;
base_hosp = hosp_cumu(:, T_full-lookback);
[xx] = var_simulate_deaths(infec_data, hosp_rates, dk, djp, dhorizon, base_hosp, T_full-1-lookback);
xx = diff([base_hosp xx]')';
xx1 = repmat((1:lookback), [length(cidx) 1]); 
extern_dat = xx1(:);
extern_dat = [];
xx2 = xx(cidx, 1:lookback); AllXdata = [xx2(:) extern_dat];
AllYdata = hosp_dat(cidx, end-lookback+1:end); AllYdata = AllYdata(:);
All_Mdl = TreeBagger(100, AllXdata, (AllYdata-AllXdata(:, 1)), 'Method','regression');
%%  Temporary quick way of finding quantiles - generation
quant_hosp = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
preds = pred_new_hosps;
quant_preds_hosp = zeros(size(data_4, 1), num_ahead, length(quant_hosp));
mean_preds_hosp = zeros(size(data_4, 1), num_ahead);

for jj=1:num_ahead
    tt = 0;
%     this_inc = data_4(cidx, end - 7*tt) - data_4(cidx, end - 7*tt-7);
%     prev_inc = data_4(cidx, end - 7*tt-7) - data_4(cidx, end - 7*tt-14);
%     extern_dat = [data_4(cidx, end - 7*tt), this_inc , prev_inc, jj*ones(length(this_inc), 1)];
    extern_dat = [jj*ones(size(data_4, 1), 1)];
    extern_dat = [];
    errs = preds(:, jj) + quantilePredict(All_Mdl,[preds(:, jj) extern_dat], 'Quantile', quant_hosp);
    errs = errs - errs(:, abs(quant_hosp-0.5) < 1e-5);
    quant_preds_hosp(:, jj, :) = preds(:, jj) + ((num_ahead/2+2*jj)/num_ahead)*errs;
    mean_preds_hosp(:, jj) = preds(:, jj);% + predict(Mdl{jj}, [preds(:, jj) extern_dat]);
end

quant_preds_hosp = (quant_preds_hosp + abs(quant_preds_hosp))/2;

%% Plot
cid = 1;
sel_idx = cid;
% plot((1:size(data_4, 2)), hosp_dat(cid, :)); hold on;
% plot((T_full+1:T_full+size(pred_new_hosps, 2)), pred_new_hosps(cid, :)); hold off;

dt = hosp_dat;
thisquant = squeeze(quant_preds_hosp(sel_idx, :, :));
gt_len = 40;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len+1:1:gt_lidx);
gt = dt(sel_idx, gt_idx);
point_forecast = num2cell([(gt_len+1:gt_len+num_ahead)' mean_preds_hosp(sel_idx, 1:num_ahead)']);
historical = num2cell([(1:gt_len)' gt']);
forecast = num2cell([(gt_len+1:gt_len+num_ahead)' thisquant]);
fanplot([historical; point_forecast], forecast)

%%
hosp_vals = cell((1+length(quant_hosp))*(1+length(cidx))*num_ahead, 7);
kk = 1;
forecast_date = datestr(datetime(2020, 1, 23)+caldays(T_full), 'yyyy-mm-dd');

for ii = 1:length(cidx)
    for jj = 1:num_ahead
        target_date = datestr(datetime(2020, 1, 23)+caldays(T_full+jj), 'yyyy-mm-dd');
        thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc hosp']} {target_date} fips{cidx(ii)} {'point'} {'NA'} {pred_new_hosps(cidx(ii), jj)}];
        hosp_vals(kk, :) = thisentry;
        
        hosp_vals(kk+1:kk+length(quant_hosp), 1) = mat2cell(repmat(forecast_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc hosp'], [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 3) = mat2cell(repmat(target_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 4) = mat2cell(repmat(fips{cidx(ii)}, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 5) = mat2cell(repmat('quantile', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 6) = mat2cell(quant_hosp(:), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 7) = mat2cell(squeeze(quant_preds_hosp(cidx(ii), jj, :)), ones(length(quant_hosp), 1));
        kk = kk+length(quant_hosp)+1;
    end
    fprintf('.');
end
%%
% Add US forecasts by combining states
for jj = 1:num_ahead
    target_date = datestr(datetime(2020, 1, 23)+caldays(T_full+jj), 'yyyy-mm-dd');
    thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc hosp']} {target_date} {'US'} {'point'} {'NA'} {sum(pred_new_hosps(cidx, jj))}];
    hosp_vals(kk, :) = thisentry;
    
    hosp_vals(kk+1:kk+length(quant_hosp), 1) = mat2cell(repmat(forecast_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc hosp'], [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 3) = mat2cell(repmat(target_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 4) = mat2cell(repmat('US', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 5) = mat2cell(repmat('quantile', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 6) = mat2cell(quant_hosp(:), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 7) = mat2cell(sum(squeeze(quant_preds_hosp(cidx, jj, :)), 1)', ones(length(quant_hosp), 1));
    kk = kk+length(quant_hosp)+1;
end

%% Write file

pathname = '../results/to_reich/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

writecell(hosp_vals, [fullpath '/' prefix '_hosp_quants.csv']);