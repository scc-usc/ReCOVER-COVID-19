prefix = 'other'; num_ens_weeks = 14; week_len = 1;
%prefix = 'global'; cidx = 1:184; num_ens_weeks = 3;

num_ahead = 4;
quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
quant_cases = [0.025, 0.100, 0.250, 0.500, 0.750, 0.900, 0.975];
quant_cases = quant_deaths;
%% Load ground truth and today's prediction
now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
path = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [path dirname];

xx = readcell([fullpath '/' prefix '_data.csv']); data_4 = cell2mat(xx(2:end, 3:end));
xx = readcell([fullpath '/' prefix '_deaths.csv']); deaths = cell2mat(xx(2:end, 3:end));
gt_dates = (xx(1, 3:end));

xx = readcell([fullpath '/' prefix '_forecasts_cases.csv']); pred_cases = cell2mat(xx(2:end, 3:end));
xx = readcell([fullpath '/' prefix '_forecasts_deaths.csv']); pred_deaths = cell2mat(xx(2:end, 3:end));
pred_dates = (xx(1, 3:end));


placenames = xx(2:end, 2);
cidx = (1:length(placenames));
%% Prepare data for training
Xdata = cell(num_ahead, 1); Ydata = cell(num_ahead, 1);
Xdeaths = cell(num_ahead, 1); Ydeaths = cell(num_ahead, 1);
Mdl = cell(num_ahead, 1); Mdl_d = cell(num_ahead, 1);
for tt = 1:(num_ens_weeks + num_ahead*(7/week_len))
    forecast_date = now_date - week_len*tt;
    dirname = datestr(forecast_date, 'yyyy-mm-dd');
    fullpath = [path dirname];
    
    try
        xx = readcell([fullpath '/' prefix '_forecasts_cases.csv']);
        xxd = readcell([fullpath '/' prefix '_forecasts_deaths.csv']);
    catch
        continue;
    end
    preds = cell2mat(xx(2:end, 3:end));
    preds = diff(preds(cidx, 1:7:end)')';
    
    preds_d = cell2mat(xxd(2:end, 3:end));
    preds_d = diff(preds_d(cidx, 1:7:end)')';
    
    for jj=1:num_ahead
        if (week_len*tt - 7*jj) < 0
            continue;
        end
        
        this_inc = data_4(cidx, end - week_len*tt) - data_4(cidx, end - week_len*tt-7);
        prev_inc = data_4(cidx, end - week_len*tt-7) - data_4(cidx, end - week_len*tt-14);
        extern_dat = [data_4(cidx, end - week_len*tt), this_inc , prev_inc, jj*ones(length(this_inc), 1)];
        %extern_dat = [];
        thisx = [preds(:, jj) extern_dat];
        
        thisy = data_4(cidx, end - week_len*tt + 7*jj) - data_4(cidx, end - week_len*tt + 7*jj - 7);
        Xdata{jj} = [Xdata{jj}; thisx];
        Ydata{jj} = [Ydata{jj}; thisy];
        
        this_inc1 = deaths(cidx, end - week_len*tt) - deaths(cidx, end - week_len*tt-7);
        prev_inc1 = deaths(cidx, end - week_len*tt-7) - deaths(cidx, end - week_len*tt-14);
        extern_dat = [deaths(cidx, end - week_len*tt), this_inc , prev_inc, this_inc1, prev_inc1, jj*ones(length(this_inc), 1)];
        %extern_dat = [];
        thisx = [preds_d(:, jj) extern_dat];
        
        thisy = deaths(cidx, end - week_len*tt + 7*jj) - deaths(cidx, end - week_len*tt + 7*jj - 7);
        Xdeaths{jj} = [Xdeaths{jj}; thisx];
        Ydeaths{jj} = [Ydeaths{jj}; thisy];
    end
end

%% Single dataset for single model
AllXdata = []; AllYdata = [];
AllXdeaths = []; AllYdeaths = [];
for jj=1:num_ahead
    AllXdata = [AllXdata; [Xdata{jj}]]; AllYdata = [AllYdata; Ydata{jj}];
    AllXdeaths = [AllXdeaths; [Xdeaths{jj}]]; AllYdeaths = [AllYdeaths; Ydeaths{jj}];
end
All_Mdl = TreeBagger(100, AllXdata, (AllYdata-AllXdata(:, 1)), 'Method','regression', 'CategoricalPredictors', [size(AllXdata, 2)]);
All_Mdl_d = TreeBagger(100, AllXdeaths, (AllYdeaths-AllXdeaths(:, 1)), 'Method','regression', 'CategoricalPredictors', [size(AllXdeaths, 2)]);

%% Identify predictions based on dates

pl_row_idx = startsWith(placenames, 'PL');
gr_row_idx = startsWith(placenames, 'GM');
pl_pred_idx = find(cellfun(@(x)(weekday(x)==6), pred_dates));
gr_pred_idx = find(cellfun(@(x)(weekday(x)==7), pred_dates));
pl_gt_idx = find(cellfun(@(x)(weekday(x)==6), gt_dates));
gr_gt_idx = find(cellfun(@(x)(weekday(x)==7), gt_dates));

%% Create data with desired days
if pred_dates{gr_pred_idx(1)} == gt_dates{gr_gt_idx(end)}
    gr_pred_idx(1) = [];
end
if pred_dates{pl_pred_idx(1)} == gt_dates{pl_gt_idx(end)}
    pl_pred_idx(1) = [];
end
pl_pred_idx = pl_pred_idx(1:10); gr_gt_idx = gr_gt_idx(:, end-10:end);
gr_pred_idx = gr_pred_idx(1:10); pl_gt_idx = pl_gt_idx(:, end-10:end);

case_gt = [data_4(gr_row_idx, gr_gt_idx); data_4(pl_row_idx, pl_gt_idx)];
death_gt = [deaths(gr_row_idx, gr_gt_idx); deaths(pl_row_idx, pl_gt_idx)];

cum_pred_cases = [pred_cases(gr_row_idx, gr_pred_idx); pred_cases(pl_row_idx, pl_pred_idx)];
cum_pred_deaths = [pred_deaths(gr_row_idx, gr_pred_idx); pred_deaths(pl_row_idx, pl_pred_idx)];

preds = diff([case_gt(:, end) cum_pred_cases]')';
preds_d = diff([death_gt(:, end) cum_pred_deaths]')';


%% Generate quantiles

quant_preds_cases = zeros(length(cidx), num_ahead, length(quant_cases));
mean_preds_cases = zeros(length(cidx), num_ahead);
quant_preds_deaths = zeros(length(cidx), num_ahead, length(quant_deaths));
mean_preds_deaths = zeros(length(cidx), num_ahead);
for jj=1:num_ahead
    this_inc = case_gt(:, end) - case_gt(:, end-1);
    prev_inc = case_gt(:, end-1) - case_gt(:, end-2);
    extern_dat = [case_gt(:, end), this_inc , prev_inc, jj*ones(length(this_inc), 1)];
    %extern_dat = [];
    errs = preds(:, jj) + quantilePredict(All_Mdl,[preds(:, jj) extern_dat],'Quantile',quant_cases);
    errs = errs - errs(:, abs(quant_cases-0.5) < 1e-5);
    quant_preds_cases(:, jj, :) = preds(:, jj) + errs;
    mean_preds_cases(:, jj) = preds(:, jj);% + predict(Mdl{jj}, [preds(:, jj) extern_dat]);
    
    this_inc1 = death_gt(:, end) - death_gt(:, end-1);
    prev_inc1 = death_gt(:, end-1) - death_gt(:, end-2);
    extern_dat = [death_gt(:, end), this_inc , prev_inc, this_inc1, prev_inc1, jj*ones(length(this_inc), 1)];
    %extern_dat = [];
    errs = quantilePredict(All_Mdl_d, [preds_d(:, jj) extern_dat],'Quantile',quant_deaths);
    errs = errs - errs(:, abs(quant_deaths-0.5) < 1e-5);
    quant_preds_deaths(:, jj, :) = preds_d(:, jj) + errs;
    mean_preds_deaths(:, jj) = preds_d(:, jj);% + predict(Mdl_d{jj}, [preds_d(:, jj) extern_dat]);
end

quant_preds_cases = round((quant_preds_cases + abs(quant_preds_cases))/2);
quant_preds_deaths = round((quant_preds_deaths + abs(quant_preds_deaths))/2);

%% Plot
% sel_idx = 30;
% thisquant = squeeze(quant_preds_deaths(sel_idx, :, :));
% gt_len = 6;
% point_forecast = num2cell([(gt_len+1:gt_len+4)' mean_preds_deaths(sel_idx, :)']);
% historical = num2cell([(1:gt_len)' diff(death_gt(sel_idx, end-gt_len:end))']);
% forecast = num2cell([(gt_len+1:gt_len+4)' thisquant]);
% fanplot([historical; point_forecast], forecast)
% title([placenames{sel_idx} 'Deaths']);
% 
% thisquant = squeeze(quant_preds_cases(sel_idx, :, :));
% point_forecast = num2cell([(gt_len+1:gt_len+4)' mean_preds_cases(sel_idx, :)']);
% historical = num2cell([(1:gt_len)' diff(case_gt(sel_idx, end-gt_len:end))']);
% forecast = num2cell([(gt_len+1:gt_len+4)' thisquant]);
% fanplot([historical; point_forecast], forecast)
% title([placenames{sel_idx} 'Cases']);
%% Convert to the format
forecast_date = pred_dates{1}+1;
forecast_date = datestr(forecast_date, 'yyyy-mm-dd');
num_ahead = 4;
placenames = [placenames(gr_row_idx); placenames(pl_row_idx)];
placenames_full = placenames;
placenames_full{strcmp(placenames, 'GM')} = 'Germany';
placenames_full{strcmp(placenames, 'PL')} = 'Poland';

death_vals = cell(2*(1+length(quant_deaths))*(length(cidx))*num_ahead, 8);
case_vals = cell(2*(1+length(quant_cases))*(length(cidx))*num_ahead, 8);

kk = 1;
for ii = 1:length(cidx)
    for jj = 1:num_ahead
        target_date = datestr(pred_dates{gr_pred_idx(1)} + 7*(jj-1), 'yyyy-mm-dd');
        
        thisentry = [{forecast_date} {[num2str(jj) ' wk ahead inc death']} {target_date} placenames{cidx(ii)} placenames_full{cidx(ii)} {'point'} {'NA'} {preds_d(cidx(ii), jj)}];
        death_vals(kk, :) = thisentry;
        
        death_vals(kk+1:kk+length(quant_deaths), 1) = mat2cell(repmat(forecast_date, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 2) = mat2cell(repmat([num2str(jj) ' wk ahead inc death'], [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 3) = mat2cell(repmat(target_date, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 4) = mat2cell(repmat(placenames{cidx(ii)}, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 5) = mat2cell(repmat(placenames_full{cidx(ii)}, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 6) = mat2cell(repmat('quantile', [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 7) = mat2cell(quant_deaths(:), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 8) = mat2cell(squeeze(quant_preds_deaths(cidx(ii), jj, :)), ones(length(quant_deaths), 1));
        
        kk = kk+length(quant_deaths)+1;
        
        cc = cum_pred_deaths(cidx(ii), jj) - preds_d(cidx(ii), jj) + squeeze(quant_preds_deaths(cidx(ii), jj, :));
        thisentry = [{forecast_date} {[num2str(jj) ' wk ahead cum death']} {target_date} placenames{cidx(ii)} placenames_full{cidx(ii)} {'point'} {'NA'} {cum_pred_deaths(cidx(ii), jj)}];
        death_vals(kk, :) = thisentry;
        
        death_vals(kk+1:kk+length(quant_deaths), 1) = mat2cell(repmat(forecast_date, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 2) = mat2cell(repmat([num2str(jj) ' wk ahead cum death'], [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 3) = mat2cell(repmat(target_date, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 4) = mat2cell(repmat(placenames{cidx(ii)}, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 5) = mat2cell(repmat(placenames_full{cidx(ii)}, [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 6) = mat2cell(repmat('quantile', [length(quant_deaths) 1]), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 7) = mat2cell(quant_deaths(:), ones(length(quant_deaths), 1));
        death_vals(kk+1:kk+length(quant_deaths), 8) = mat2cell(cc, ones(length(quant_deaths), 1));
        
        kk = kk+length(quant_deaths)+1;
    end
    fprintf('.');
end
kk = 1;
for ii = 1:length(cidx)
    for jj = 1:num_ahead
        target_date = datestr(pred_dates{gr_pred_idx(1)} + 7*(jj-1), 'yyyy-mm-dd');
        thisentry = [{forecast_date} {[num2str(jj) ' wk ahead inc case']} {target_date} placenames{cidx(ii)} placenames_full{cidx(ii)} {'point'} {'NA'} {preds(cidx(ii), jj)}];
        case_vals(kk, :) = thisentry;
        
        case_vals(kk+1:kk+length(quant_cases), 1) = mat2cell(repmat(forecast_date, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 2) = mat2cell(repmat([num2str(jj) ' wk ahead inc case'], [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 3) = mat2cell(repmat(target_date, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 4) = mat2cell(repmat(placenames{cidx(ii)}, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 5) = mat2cell(repmat(placenames_full{cidx(ii)}, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 6) = mat2cell(repmat('quantile', [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 7) = mat2cell(quant_cases(:), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 8) = mat2cell(squeeze(quant_preds_cases(cidx(ii), jj, :)), ones(length(quant_cases), 1));
        
        kk = kk+length(quant_cases)+1;
        
        cc = cum_pred_cases(cidx(ii), jj) - preds(cidx(ii), jj) + squeeze(quant_preds_cases(cidx(ii), jj, :));
        thisentry = [{forecast_date} {[num2str(jj) ' wk ahead cum case']} {target_date} placenames{cidx(ii)} placenames_full{cidx(ii)} {'point'} {'NA'} {cum_pred_cases(cidx(ii), jj)}];
        case_vals(kk, :) = thisentry;
        
        case_vals(kk+1:kk+length(quant_cases), 1) = mat2cell(repmat(forecast_date, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 2) = mat2cell(repmat([num2str(jj) ' wk ahead cum case'], [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 3) = mat2cell(repmat(target_date, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 4) = mat2cell(repmat(placenames{cidx(ii)}, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 5) = mat2cell(repmat(placenames_full{cidx(ii)}, [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 6) = mat2cell(repmat('quantile', [length(quant_cases) 1]), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 7) = mat2cell(quant_cases(:), ones(length(quant_cases), 1));
        case_vals(kk+1:kk+length(quant_cases), 8) = mat2cell(cc, ones(length(quant_cases), 1));
        
        kk = kk+length(quant_cases)+1;
    end
    fprintf('.');
end
fprintf('\n');
%% Write file
pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

all_heads = {'forecast_date', 'target', 'target_end_date', 'location', 'location_name', 'type', 'quantile', 'value'};

idx = startsWith(case_vals(:, 4), 'GM');
writecell([all_heads; case_vals(idx, :)], [fullpath '/' datestr(forecast_date, 'yyyy-mm-dd') '-Germany-USC-SIkJalpha-case.csv']);
writecell([all_heads; case_vals(~idx, :)], [fullpath '/' datestr(forecast_date, 'yyyy-mm-dd') '-Poland-USC-SIkJalpha-case.csv']);

idx = startsWith(death_vals(:, 4), 'GM');
writecell([all_heads; death_vals(idx, :)], [fullpath '/' datestr(forecast_date, 'yyyy-mm-dd') '-Germany-USC-SIkJalpha.csv']);
writecell([all_heads; death_vals(~idx, :)], [fullpath '/' datestr(forecast_date, 'yyyy-mm-dd') '-Poland-USC-SIkJalpha.csv']);