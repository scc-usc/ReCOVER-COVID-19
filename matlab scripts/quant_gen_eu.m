%prefix = 'us'; cidx = (1:56); num_ens_weeks = 15; week_len = 1;
prefix = 'global'; cidx = 1:184; num_ens_weeks = 3;

quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
quant_cases = quant_deaths;

load_data_global;
T_corr = 0;
now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
%load global_hyperparam_latest.mat;

% %% Load ground truth and today's prediction
 
% path = '../results/historical_forecasts/';
% dirname = datestr(now_date, 'yyyy-mm-dd');
% fullpath = [path dirname];
% 
% xx = readtable([fullpath '/' prefix '_data.csv']); data_4 = table2array(xx(2:end, 3:end));
% xx = readtable([fullpath '/' prefix '_deaths.csv']); deaths = table2array(xx(2:end, 3:end));
% 
% xx = readtable([fullpath '/' prefix '_forecasts_cases.csv']); pred_cases = table2array(xx(2:end, 3:end));
% xx = readtable([fullpath '/' prefix '_forecasts_deaths.csv']); pred_deaths = table2array(xx(2:end, 3:end));
% placenames = xx{2:end, 2};

%% Rename places
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



load global_results.mat;
smooth_factor = 14;
T_full = size(data_4, 2);
data_4_s = smooth_epidata(data_4, smooth_factor/2, 0);
deaths_s = smooth_epidata(deaths, smooth_factor/2);



%% Generate quantiles
num_ahead = 56;

quant_preds_deaths = zeros(length(popu), floor((num_ahead-1)/7), length(quant_deaths));
mean_preds_deaths = squeeze(nanmean(diff(net_death_0(:, :, 1:7:num_ahead), 1, 3), 1));
quant_preds_cases = zeros(length(popu), floor((num_ahead-1)/7), length(quant_cases));
mean_preds_cases = squeeze(nanmean(diff(net_infec_0(:, :, 1:7:num_ahead), 1, 3), 1));
med_idx_d  = find(abs(quant_deaths-0.5)<0.001);
med_idx_c  = find(abs(quant_cases-0.5)<0.001);


for cid = 1:length(popu)
    thisdata = squeeze(net_infec_0(:, cid, :));
    thisdata(all(thisdata==0, 2), :) = [];
    thisdata = diff(thisdata(:, 1:7:num_ahead)')';
    dt = data_4; gt_lidx = size(dt, 2); extern_dat = diff(dt(cid, gt_lidx-21:7:gt_lidx))';
    extern_dat = extern_dat - mean(extern_dat) + mean_preds_cases(cid, :);
    thisdata = [thisdata; repmat(extern_dat, [3 1])];    
    quant_preds_cases(cid, :, :) = movmean(quantile(thisdata, quant_cases)', 1, 1);
    
    thisdata = squeeze(net_death_0(:, cid, :));
    thisdata(all(thisdata==0, 2), :) = [];
    thisdata = diff(thisdata(:, 1:7:num_ahead)')';
     dt = deaths; gt_lidx = size(dt, 2); 
    %extern_dat = diff(dt(cid, gt_lidx-35:7:gt_lidx))';
    extern_dat = diff(deaths(cid, gt_lidx-35:7:gt_lidx)') - diff(deaths_s(cid, gt_lidx-35:7:gt_lidx)');
    % [~, midx] = max(extern_dat); extern_dat(midx) = [];
     extern_dat = extern_dat - mean(extern_dat) + mean_preds_deaths(cid, :);
    thisdata = [thisdata; repmat(extern_dat, [3 1])];    
    quant_preds_deaths(cid, :, :) = movmean(quantile(thisdata, quant_deaths)', 1, 1);
end
quant_preds_deaths = 0.5*(quant_preds_deaths+abs(quant_preds_deaths));
quant_preds_cases = 0.5*(quant_preds_cases+abs(quant_preds_cases));

%% Plot
plot_check = 1;

if plot_check > 0
    tiledlayout(2, 1); nexttile;
    sel_idx = 37; sel_idx = contains(countries, 'Germany');
    dt = deaths;
    dts = deaths_s;
    thisquant = squeeze(nansum(quant_preds_deaths(sel_idx, :, :), 1));
    gt_len = 20;
    gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
    gt = diff(nansum(dt(sel_idx, gt_idx), 1))';
    gts = diff(nansum(dts(sel_idx, gt_idx), 1))';
    plot([gt gts]); hold on; plot((gt_len+1:gt_len+size(thisquant, 1)), thisquant); hold off;
    title(['Deaths']);
    
    nexttile;
    dt = data_4;
    thisquant = squeeze(nansum(quant_preds_cases(sel_idx, :, :), 1));
    gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
    gt = nansum(diff(dt(sel_idx, gt_idx)'), 2);
    plot(gt); hold on; plot((gt_len+1:gt_len+size(thisquant, 1)), thisquant); hold off;
    title(['Cases']);
end
%% Write to file
max_weeks = 5; 
eu_names_short = eu_names(eu_present>0);
T = table;
quant_matrix = quant_preds_cases(eu_present>0, 1:max_weeks, :);
thesevals = quant_matrix(:);
[cc, wh, qq] = ind2sub(size(quant_matrix), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
T.forecast_date = repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
T.target = strcat(wh_string(wh), ' wk ahead inc case');
T.target_end_date = datestr(now_date - T_corr -1 + 7*wh, 'YYYY-mm-DD');
T.location = eu_names_short(cc);
T.type = repmat({'quantile'}, [length(thesevals) 1]);
T.quantile = compose('%.3f', (quant_cases(qq)'));
T.value = compose('%g', round(thesevals, 0));

T1 = table;
quant_matrix = quant_preds_deaths(eu_present>0, 1:max_weeks, :);
thesevals = quant_matrix(:);
[cc, wh, qq] = ind2sub(size(quant_matrix), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
T1.forecast_date = repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
T1.target = strcat(wh_string(wh), ' wk ahead inc death');
T1.target_end_date = datestr(now_date - T_corr - 1 + 7*wh, 'YYYY-mm-DD');
T1.location = eu_names_short(cc);
T1.type = repmat({'quantile'}, [length(thesevals) 1]);
T1.quantile = compose('%.3f', (quant_deaths(qq)'));
T1.value = compose('%g', round(thesevals, 0));

T2 = table;
mean_matrix = mean_preds_cases(eu_present>0, 1:max_weeks);
thesevals = mean_matrix(:);
[cc, wh] = ind2sub(size(mean_matrix), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
T2.forecast_date = repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
T2.target = strcat(wh_string(wh), ' wk ahead inc case');
T2.target_end_date = datestr(now_date - T_corr - 1 + 7*wh, 'YYYY-mm-DD');
T2.location = eu_names_short(cc);
T2.type = repmat({'point'}, [length(thesevals) 1]);
T2.quantile = repmat({'NA'}, [length(thesevals) 1]);
T2.value = compose('%g', round(thesevals, 0));

T3 = table;
mean_matrix = mean_preds_deaths(eu_present>0, 1:max_weeks);
thesevals = mean_matrix(:);
[cc, wh] = ind2sub(size(mean_matrix), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
T3.forecast_date = repmat({datestr(now_date - T_corr, 'YYYY-mm-DD')}, [length(thesevals) 1]);
T3.target = strcat(wh_string(wh), ' wk ahead inc death');
T3.target_end_date = datestr(now_date - T_corr - 1 + 7*wh, 'YYYY-mm-DD');
T3.location = eu_names_short(cc);
T3.type = repmat({'point'}, [length(thesevals) 1]);
T3.quantile = repmat({'NA'}, [length(thesevals) 1]);
T3.value = compose('%g', round(thesevals, 0));

T_all = [T; T1; T2; T3];
%%
bad_idx = strcmp(T_all.value, 'NaN');
disp('Following countries have NaNs');
disp(unique(T_all.location(bad_idx)));
T_all(bad_idx, :) = [];
%%
disp('Writing File');
tic;
pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

writetable(T_all, [fullpath '/' datestr(now_date-T_corr, 'YYYY-mm-DD') '-USC-SIkJalpha_EU.csv']);
toc
