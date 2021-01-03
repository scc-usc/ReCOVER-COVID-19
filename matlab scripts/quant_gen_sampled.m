prefix = 'global'; cidx = (1:184); 

num_ahead = 95;
lookback = 14;
quant_deaths = [0.025, 0.5, 0.975];
quant_cases = [0.025, 0.5, 0.975];

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

nn = size(data_4, 1);
%% Prepare data for training

all_cidx = [];
horizon = num_ahead;
all_dat = nan(nn, lookback, horizon);
all_dat_d = nan(nn, lookback, horizon);

for tt = 1:lookback
    forecast_date = now_date - tt + 1;
    dirname = datestr(forecast_date, 'yyyy-mm-dd');
    fullpath = [path dirname];
    try
    xx = readtable([fullpath '/' prefix '_forecasts_cases.csv']); 
    xxd = readtable([fullpath '/' prefix '_forecasts_deaths.csv']); 
    catch
        continue;
    end
    
    preds_cum = table2array(xx(2:end, (3+tt-1):end));
    preds = diff(preds_cum')';
    
    preds_d_cum = table2array(xxd(2:end, (3+tt-1):end));
    preds_d = diff(preds_d_cum')';
    
    maxt = min([horizon, size(preds, 2)]); all_dat(:, tt, 1:maxt) = preds(:, 1:maxt);
    maxt = min([size(preds_d, 2), horizon]); all_dat_d(:, tt, 1:maxt) = preds_d(:, 1:maxt);
    
end

%% Generate quantiles of errors
preds = diff(pred_cases(cidx, 1:end)')';
preds_d = diff(pred_deaths(cidx, 1:end)')';
quant_preds_cases = zeros(length(cidx), num_ahead, length(quant_cases));
mean_preds_cases = zeros(length(cidx), num_ahead);
quant_preds_deaths = zeros(length(cidx), num_ahead, length(quant_deaths));
mean_preds_deaths = zeros(length(cidx), num_ahead);
for cid = 1:nn
    thisdata = squeeze(all_dat(cid, :, :));
    thisdata(all(isnan(thisdata), 2), :) = [];
    thisdata =  fillmissing(thisdata, "linear", 2);
    quant_preds_cases(cid, :, :) = quantile(thisdata(:, 1:num_ahead), quant_cases)';
    mean_preds_cases(cid, :) = preds(cid, 1:horizon);
    med_idx = find(abs(quant_cases-0.5)< 1e-5);
    quant_preds_cases(cid, :, :) = squeeze(quant_preds_cases(cid, :, :)) - quant_preds_cases(cid, :, med_idx)' + mean_preds_cases(cid, :)';
    
    thisdata = squeeze(all_dat_d(cid, :, :));
    thisdata(all(isnan(thisdata), 2), :) = [];
    thisdata =  fillmissing(thisdata, "linear", 2);
    quant_preds_deaths(cid, :, :) = quantile(thisdata(:, 1:num_ahead), quant_deaths)';
    mean_preds_deaths(cid, :) = preds_d(cid, 1:horizon);
    med_idx = find(abs(quant_deaths-0.5)< 1e-5);
    quant_preds_deaths(cid, :, :) = squeeze(quant_preds_deaths(cid, :, :)) - quant_preds_deaths(cid, :, med_idx)' + mean_preds_deaths(cid, :)';
end
quant_preds_cases = (quant_preds_cases + abs(quant_preds_cases))/2;
quant_preds_deaths = (quant_preds_deaths + abs(quant_preds_deaths))/2;
%% Extract lower and upper bounds

case_lb_preds = cumsum([pred_cases(:, 1) squeeze(quant_preds_cases(:, :, 1))], 2);
case_ub_preds = cumsum([pred_cases(:, 1) squeeze(quant_preds_cases(:, :, end))], 2);

death_lb_preds = cumsum([pred_deaths(:, 1) squeeze(quant_preds_deaths(:, :, 1))], 2);
death_ub_preds = cumsum([pred_deaths(:, 1) squeeze(quant_preds_deaths(:, :, end))], 2);

%% Plot
% sel_idx = 143;
% dt = diff(deaths(sel_idx, :));
% thisquant = diff([death_lb_preds(sel_idx, :)' death_ub_preds(sel_idx, :)']);
% gt_len = length(dt);
% figure;
% plot(datetime(2020, 1, 22)+(1:gt_len), dt'); hold on;
% plot(datetime(2020, 1, 22)+(gt_len+1:gt_len+num_ahead), mean_preds_deaths(sel_idx, 1:num_ahead)'); hold on;
% plot(datetime(2020, 1, 22)+(gt_len+1:gt_len+num_ahead), thisquant(1:num_ahead, :)); hold off;
% title([placenames{sel_idx} 'Deaths']);
% 
% figure;
% dt = diff(data_4(sel_idx, :));
% thisquant = diff([case_lb_preds(sel_idx, :)' case_ub_preds(sel_idx, :)']);
% gt_len = length(dt);
% plot(datetime(2020, 1, 22)+(1:gt_len), dt'); hold on;
% plot(datetime(2020, 1, 22)+(gt_len+1:gt_len+num_ahead), mean_preds_cases(sel_idx, 1:num_ahead)'); hold on;
% plot(datetime(2020, 1, 22)+(gt_len+1:gt_len+num_ahead), thisquant(1:num_ahead, :)); hold off;
% title([placenames{sel_idx} 'Cases']);
%% Write to file
% countries = placenames;
% case_vals = cell((length(quant_cases))*(length(cidx))*num_ahead, 7);
% kk = 1;
% 
% forecast_date = datestr(now_date, 'yyyy-mm-dd');
% 
% for ii = 1:length(cidx)
%     for jj = 1:num_ahead
%         target_date = datestr(now_date+caldays(jj), 'yyyy-mm-dd');
%         thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc case']} {target_date} countries{cidx(ii)} {'point'} {'NA'} {mean_preds_cases(cidx(ii), jj)}];
%         case_vals(kk, :) = thisentry;
%         
%         case_vals(kk+1:kk+length(quant_cases), 1) = mat2cell(repmat(forecast_date, [length(quant_cases) 1]), ones(length(quant_cases), 1));
%         case_vals(kk+1:kk+length(quant_cases), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc case'], [length(quant_cases) 1]), ones(length(quant_cases), 1));
%         case_vals(kk+1:kk+length(quant_cases), 3) = mat2cell(repmat(target_date, [length(quant_cases) 1]), ones(length(quant_cases), 1));
%         case_vals(kk+1:kk+length(quant_cases), 4) = mat2cell(repmat(countries{cidx(ii)}, [length(quant_cases) 1]), ones(length(quant_cases), 1));
%         case_vals(kk+1:kk+length(quant_cases), 5) = mat2cell(repmat('quantile', [length(quant_cases) 1]), ones(length(quant_cases), 1));
%         case_vals(kk+1:kk+length(quant_cases), 6) = mat2cell(quant_cases(:), ones(length(quant_cases), 1));
%         case_vals(kk+1:kk+length(quant_cases), 7) = mat2cell(squeeze(quant_preds_cases(cidx(ii), jj, :)), ones(length(quant_cases), 1));
%         kk = kk+length(quant_cases)+1;   
%     end
%     if mod(ii, 10)==0
%         fprintf('.');
%     end
% end
% 
% death_vals = cell((length(quant_deaths))*(length(cidx))*num_ahead, 7);
% kk = 1;
% forecast_date = datestr(datetime(2020, 1, 23)+caldays(maxt), 'yyyy-mm-dd');
% 
% for ii = 1:length(cidx)
%     for jj = 1:num_ahead
%         target_date = datestr(now_date+caldays(jj), 'yyyy-mm-dd');
%         thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc death']} {target_date} countries{cidx(ii)} {'point'} {'NA'} {mean_preds_deaths(cidx(ii), jj)}];
%         death_vals(kk, :) = thisentry;
%         
%         death_vals(kk+1:kk+length(quant_deaths), 1) = mat2cell(repmat(forecast_date, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
%         death_vals(kk+1:kk+length(quant_deaths), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc death'], [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
%         death_vals(kk+1:kk+length(quant_deaths), 3) = mat2cell(repmat(target_date, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
%         death_vals(kk+1:kk+length(quant_deaths), 4) = mat2cell(repmat(countries{cidx(ii)}, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
%         death_vals(kk+1:kk+length(quant_deaths), 5) = mat2cell(repmat('quantile', [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
%         death_vals(kk+1:kk+length(quant_deaths), 6) = mat2cell(quant_deaths(:), ones(length(quant_deaths), 1));
%         death_vals(kk+1:kk+length(quant_deaths), 7) = mat2cell(squeeze(quant_preds_deaths(cidx(ii), jj, :)), ones(length(quant_deaths), 1));
%         kk = kk+length(quant_deaths)+1;
%         
%         
%     end
%     if mod(ii, 10)==0
%         fprintf('.');
%     end
% end

%% Write file
pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end
countries = placenames;
lowidx = zeros(length(countries), 1);

writetable(infec2table(case_lb_preds, countries, lowidx, now_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases_lb.csv']);
writetable(infec2table(case_ub_preds, countries, lowidx, now_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases_ub.csv']);

writetable(infec2table(death_lb_preds, countries, lowidx, now_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths_lb.csv']);
writetable(infec2table(death_ub_preds, countries, lowidx, now_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths_ub.csv']);

