addpath('./utils/');
addpath('./scenario_projections/');
load us_hospitalization;
 %%
load us_results.mat;

%% Generate quantiles
num_ahead = 99;
quant_hosp = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
quant_preds_hosp = zeros(length(popu), num_ahead, length(quant_hosp));
%mean_preds_hosp = zeros(length(popu), num_ahead);
%mean_preds_hosp = pred_new_hosps(:, 1:num_ahead);
mean_preds_hosp = squeeze(nanmean(diff(net_hosp_0(:, :, 1:num_ahead+1), 1, 3), 1));
med_idx  = find(abs(quant_hosp-0.5)<0.001);

hosp_dat = hosp_cumu; hosp_dat(:, 2:end) = diff(hosp_cumu, 1, 2);
T_corr = 0;

for cid = 1:length(popu)
    thisdata = squeeze(net_hosp_0(:, cid, 1:num_ahead-T_corr+1));
    thisdata = [repmat(hosp_dat(cid, end-T_corr+1:end), [size(net_hosp_0, 1) 1]), diff(thisdata, 1, 2)];
    thisdata(all(thisdata==0, 2), :) = [];
    dt = hosp_dat; gt_lidx = size(dt, 2); 
    
    extern_dat = (dt(cid, gt_lidx-14:gt_lidx))';
    extern_dat(isnan(extern_dat)) = [];
    extern_dat = extern_dat - mean(extern_dat) + mean_preds_hosp(cid, :);
    %thisdata = thisdata - mean(thisdata, 1);
    thisdata = [thisdata; extern_dat];
    
    quant_preds_hosp(cid, :, :) = quantile(thisdata(:, 1:num_ahead), quant_hosp)';

end
quant_preds_hosp = (quant_preds_hosp+abs(quant_preds_hosp))/2;
%% Plot
% plot((1:size(data_4, 2)), hosp_dat(cid, :)); hold on;
% plot((T_full+1:T_full+size(pred_new_hosps, 2)), pred_new_hosps(cid, :)); hold off;
T_full = size(hosp_dat, 2);
dt = hosp_dat;
dt_s = [zeros(length(popu), 2) diff(hosp_cumu_s, 1, 2)];
sel_idx = 1; %sel_idx = contains(placenames, 'California');
thisquant = squeeze(nansum(quant_preds_hosp(sel_idx, :, [1 7 17 23]), 1));
mpred = (nansum(mean_preds_hosp(sel_idx, :), 1))';
gt_len = 400;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len:1:gt_lidx);
gt = nansum(dt(sel_idx, gt_idx), 1);
%gt_s = sum(dt_s(sel_idx, gt_idx), 1);
TT = datetime(2020, 1, 23) + T_full - gt_len + (1:1000);
plot(TT(1:length(gt)), [gt']); hold on; plot(TT(gt_len+1:gt_len+size(thisquant, 1)), [mpred thisquant]); hold off;
title(['Hospitalization ' countries{sel_idx} ]);

%%
cidx = find(popu>-1);
maxt = size(data_4, 2);
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
now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
prefix = 'us';
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

hosp_vals((strcmpi(hosp_vals(:, 7), 'nan')), :) = [];
writecell(hosp_vals, [fullpath '/' prefix '_hosp_quants.csv']);