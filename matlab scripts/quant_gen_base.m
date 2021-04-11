prefix = 'us'; cidx = (1:56); num_ens_weeks = 15; week_len = 1;
%prefix = 'global'; cidx = 1:184; num_ens_weeks = 3;

num_ahead = 4;
quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
quant_cases = [0.025, 0.100, 0.250, 0.500, 0.750, 0.900, 0.975];

load latest_us_data.mat
load us_hyperparam_latest.mat

%% Load ground truth and today's prediction
now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
path = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [path dirname];      

xx = readtable([fullpath '/' prefix '_data.csv']); data_4 = table2array(xx(2:end, 3:end));
xx = readtable([fullpath '/' prefix '_deaths.csv']); deaths = table2array(xx(2:end, 3:end));

xx = readtable([fullpath '/' prefix '_forecasts_cases.csv']); pred_cases = table2array(xx(2:end, 3:end));
xx = readtable([fullpath '/' prefix '_forecasts_deaths.csv']); pred_deaths = table2array(xx(2:end, 3:end));
placenames = xx{2:end, 2};

%%
CDC_sero;

un_ts = fillmissing(un_ts(:, 1:thisday), 'previous', 2); un_ts(un_ts<1) = 1;
un_lts = fillmissing(un_lts(:, 1:thisday), 'previous', 2); un_lts(un_lts<1) = 1;
un_uts = fillmissing(un_uts(:, 1:thisday), 'previous', 2);
un_array = [un_lts(:, end), un_ts(:, end), un_uts(:, end)];
un_array(isnan(un_array)) = 1; un_array(isnan(un_array)) = 1;
un = un_array(:, 2);

%% Generate various samples
smooth_factor = 14;
T_full = size(data_4, 2);
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);
rate_smooth = 1;
un_list = [1 2 3];
lags_list = 0:7:7;
horizon = 100;
dk = best_death_hyperparam(:, 1);
djp = best_death_hyperparam(:, 2);
dwin = best_death_hyperparam(:, 3);
lags = best_death_hyperparam(:, 4);
dalpha = 1; dhorizon = horizon+28;

for j=1:length(lags_list)
    [death_rates] = var_ind_deaths(data_4_s(:, 1:end-lags_list(j)), deaths_s(:, 1:end-lags_list(j)), dalpha, dk, djp, dwin, 0, popu>-1, lags);
    death_rates_list{j} = death_rates;
end

[X, Y] = ndgrid(un_list, lags_list);
scen_list = [X(:), Y(:)];

net_infec_A = zeros(size(scen_list, 1), size(data_4, 1), horizon);
net_death_A = zeros(size(scen_list, 1)*length(lags_list), size(data_4, 1), horizon);


for simnum = 1:size(scen_list, 1)
    un = un_array(:, scen_list(simnum, 1));
    lags = scen_list(simnum, 2);
    beta_after = var_ind_beta_un(data_4_s(:, 1:end-lags), 0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, popu>-1);
    
    % Cases
    base_infec = data_4(:, end-lags);
    infec_un1 = var_simulate_pred_un(data_4_s(:, 1:end-lags), 0, beta_after, popu, best_param_list(:, 1), horizon+lags, best_param_list(:, 2), un, base_infec);
    infec_dat = [data_4_s(:, 1:end-lags), infec_un1-base_infec+data_4_s(:, end-lags)];
    net_infec_A(simnum, :, :) = infec_un1(:, 1+lags:end);

   % Deaths
    for jj = 1:length(death_rates_list)
        death_rates = death_rates_list{1};
        this_rate_change = intermed_betas(death_rates, best_death_hyperparam, death_rates_list{jj}, best_death_hyperparam, rate_smooth);
        %this_rate_change = [this_rate_change, repmat(this_rate_change(:, end), [1 size(dh_rate_change, 2)-size(this_rate_change, 2)])];
        dh_rate_change1 = this_rate_change;
        
        infec_data = [data_4_s squeeze(net_infec_A(simnum, :, :))-data_4(:, T_full)+data_4_s(:, T_full)];
        T_full = size(data_4, 2);
        base_deaths = deaths(:, T_full);
        [pred_deaths1] = var_simulate_deaths_vac(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1, dh_rate_change1);
        net_death_A(simnum+(jj-1)*size(scen_list, 1), :, :) = pred_deaths1(:, 1:horizon);
    end
    fprintf('.');
    
end
fprintf('\n');
%% Data correction (for delayed forecasting)
T_corr = 1;
if T_corr > 0
    pred_cases_orig = pred_cases; pred_deaths_orig = pred_deaths;
    data_orig = data_4; deaths_orig = deaths;
    deaths = deaths_orig(:, 1:end-T_corr); data_4 = data_orig(:, 1:end-T_corr);
    pred_cases = [data_4(:, end-T_corr+1: end) pred_cases_orig];
    pred_deaths = [deaths(:, end-T_corr+1: end) pred_deaths_orig];
end

%% Generate quantiles
num_ahead = 56;

quant_preds_deaths = zeros(length(popu), floor((num_ahead-1)/7), length(quant_deaths));
mean_preds_deaths = diff(pred_deaths(:, 1:7:num_ahead)')';
quant_preds_cases = zeros(length(popu), floor((num_ahead-1)/7), length(quant_cases));
mean_preds_cases = diff(pred_cases(:, 1:7:num_ahead)')';
med_idx_d  = find(abs(quant_deaths-0.5)<0.001);
med_idx_c  = find(abs(quant_cases-0.5)<0.001);

for cid = 1:length(popu)
    thisdata = squeeze(net_infec_A(:, cid, :));
    thisdata(all(thisdata==0, 2), :) = [];
    thisdata = diff(thisdata(:, 1:7:num_ahead)')';
    dt = data_4; gt_lidx = size(dt, 2); extern_dat = diff(dt(cid, gt_lidx-7:7:gt_lidx))';
    thisdata = [thisdata; repmat(extern_dat, [1 size(thisdata, 2)])];
    thisdata = repmat(thisdata, [5 1]);
    quant_preds_cases(cid, :, :) = movmean(quantile(thisdata, quant_cases)', 5, 1);
    adjust_quants = (squeeze(quant_preds_cases(cid, :, med_idx_c)) - mean_preds_cases(cid, :));
    quant_preds_cases(cid, :, :) = quant_preds_cases(cid, :, :) - adjust_quants;
    
    thisdata = squeeze(net_death_A(:, cid, :));
    thisdata(all(thisdata==0, 2), :) = [];
    thisdata = diff(thisdata(:, 1:7:num_ahead)')';
    dt = deaths; gt_lidx = size(dt, 2); extern_dat = diff(dt(cid, gt_lidx-7:7:gt_lidx))';
    thisdata = [thisdata; repmat(extern_dat, [1 size(thisdata, 2)])];
    thisdata = repmat(thisdata, [5 1]);
    quant_preds_deaths(cid, :, :) = movmean(quantile(thisdata, quant_deaths)', 5, 1);
    adjust_quants = (squeeze(quant_preds_deaths(cid, :, med_idx_d)) - mean_preds_deaths(cid, :));
    quant_preds_deaths(cid, :, :) = quant_preds_deaths(cid, :, :) - adjust_quants;
end
 
quant_preds_cases = (quant_preds_cases + abs(quant_preds_cases))/2;
quant_preds_deaths = (quant_preds_deaths + abs(quant_preds_deaths))/2;

%% Plot
cidx = 1:56;
sel_idx = 38; %sel_idx = contains(countries, 'Washington');
dt = deaths(cidx, :);
dts = deaths_s(cidx, :);
thisquant = squeeze(nansum(quant_preds_deaths(sel_idx, :, [1 12 23]), 1));
gt_len = 50;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
gt = diff(nansum(dt(sel_idx, gt_idx), 1))';
gts = diff(nansum(dts(sel_idx, gt_idx), 1))';
point_forecast = num2cell([(gt_len+1:gt_len+size(thisquant, 1))' mean_preds_deaths(sel_idx, :)']);
historical = num2cell([(1:gt_len)' gt]);
forecast = num2cell([(gt_len+1:gt_len+size(thisquant, 1))' thisquant]);
%fanplot([historical; point_forecast], forecast);
plot([gt gts]); hold on; plot((gt_len+1:gt_len+size(thisquant, 1)), thisquant); hold off;
title(['Deaths']);

figure;
dt = data_4(cidx, :);
thisquant = squeeze(nansum(quant_preds_cases(sel_idx, :, [1 4 7]), 1));
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
gt = nansum(diff(dt(sel_idx, gt_idx)'), 2);
point_forecast = num2cell([(gt_len+1:gt_len+size(thisquant, 1))' mean_preds_cases(sel_idx, :)']);
historical = num2cell([(1:gt_len)' gt]);
forecast = num2cell([(gt_len+1:gt_len+size(thisquant, 1))' thisquant]);
%fanplot([historical; point_forecast], forecast)
plot(gt); hold on; plot((gt_len+1:gt_len+size(thisquant, 1)), thisquant); hold off;
title(['Cases']);
%% Write to file
max_week_ahead = size(quant_preds_deaths, 2);
case_vals = {'place' , 'week_ahead', 'quantile', 'value'};
death_vals = {'place' , 'week_ahead', 'quantile', 'value'};
placenames = placenames(cidx);
for ii = 1:length(cidx)
    for jj = 1:max_week_ahead
        thisentry = [placenames{ii} {jj} {'point'} {mean_preds_cases(ii, jj)}];
        case_vals = [case_vals; thisentry];
        for qq = 1:length(quant_cases)
            thisentry = [{placenames{ii}} {jj} {quant_cases(qq)} {quant_preds_cases(ii, jj, qq)}];
            case_vals = [case_vals; thisentry];
        end
        thisentry = [{placenames{ii}} {jj} {'point'} {mean_preds_deaths(ii, jj)}];
        death_vals = [death_vals; thisentry];
        for qq = 1:length(quant_deaths)
            thisentry = [{placenames{ii}} {jj} {quant_deaths(qq)} {quant_preds_deaths(ii, jj, qq)}];
            death_vals = [death_vals; thisentry];
        end
    end
end

% Add US forecasts by combining states
for jj = 1:max_week_ahead
    thisentry = [{'US'} {jj} {'point'} {nansum(mean_preds_cases(:, jj), 1)}];
    case_vals = [case_vals; thisentry];
    for qq = 1:length(quant_cases)
        thisentry = [{'US'} {jj} {quant_cases(qq)} {nansum(quant_preds_cases(:, jj, qq), 1)}];
        case_vals = [case_vals; thisentry];
    end
    thisentry = [{'US'} {jj} {'point'} {nansum(mean_preds_deaths(:, jj), 1)}];
    death_vals = [death_vals; thisentry];
    for qq = 1:length(quant_deaths)
        thisentry = [{'US'} {jj} {quant_deaths(qq)} {nansum(quant_preds_deaths(:, jj, qq), 1)}];
        death_vals = [death_vals; thisentry];
    end
end
pathname = '../results/to_reich/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

writecell(case_vals, [fullpath '/' prefix '_cases_quants.csv']);
writecell(death_vals, [fullpath '/' prefix '_deaths_quants.csv']);