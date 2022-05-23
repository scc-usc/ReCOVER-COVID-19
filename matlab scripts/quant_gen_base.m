prefix = 'us'; cidx = (1:56); num_ens_weeks = 15; week_len = 1;
%prefix = 'global'; cidx = 1:184; num_ens_weeks = 3;

num_ahead = 4;
quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
quant_cases = [0.025, 0.100, 0.250, 0.500, 0.750, 0.900, 0.975];

load latest_us_data.mat
%load us_hyperparam_latest.mat

now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');

%%
load us_results;
num_ahead = 56;
smooth_factor = 14;
Tcd_full = size(data_4, 2);
data_4_s = smooth_epidata(data_4, smooth_factor/2, 0);
deaths_s = smooth_epidata(deaths, smooth_factor);
placenames = countries;
%%
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
    dt = data_4; gt_lidx = size(dt, 2); extern_dat = diff(dt(cid, gt_lidx-14:7:gt_lidx))';
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
cidx = 1:56;
sel_idx = 11; %sel_idx = contains(countries, 'Washington');
dt = deaths(cidx, :);
dts = deaths_s(cidx, :);
thisquant = squeeze(nansum(quant_preds_deaths(sel_idx, :, [1 7 12 17 23]), 1));
thismean = (nansum(mean_preds_deaths(sel_idx, :), 1));
gt_len = 50;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
gt = nansum(diff(dt(sel_idx, gt_idx), 1, 2), 1)';
gts = nansum(diff(dts(sel_idx, gt_idx), 1, 2), 1)';

tiledlayout(2, 1); nexttile;

plot([gt gts]); hold on; plot((gt_len+1:gt_len+size(thisquant, 1)), [thisquant]); 
plot((gt_len+1:gt_len+size(thisquant, 1)), [thismean'], 'o'); 
title(['Deaths']);

nexttile;
dt = data_4(cidx, :);
dts = data_4_s(cidx, :);
thisquant = squeeze(nansum(quant_preds_cases(sel_idx, :, [1 4 7]), 1));
thismean = (nansum(mean_preds_cases(sel_idx, :), 1));
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
gt = nansum(diff(dt(sel_idx, gt_idx)'), 2);
gts = diff(nansum(dts(sel_idx, gt_idx), 1))';

plot([gt gts]); hold on; plot((gt_len+1:gt_len+size(thisquant, 1)), [thisquant]); 
plot((gt_len+1:gt_len+size(thisquant, 1)), [thismean'], 'o'); 
hold off;
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

%%
pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

writecell(case_vals, [fullpath '/' prefix '_cases_quants.csv']);
writecell(death_vals, [fullpath '/' prefix '_deaths_quants.csv']);

