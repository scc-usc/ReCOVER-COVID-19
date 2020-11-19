prefix = 'us'; cidx = (1:56); num_ens_weeks = 5; week_len = 7;
%prefix = 'global'; cidx = 1:184; num_ens_weeks = 3;

num_ahead = 4;
quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99];
quant_cases = [0.025, 0.100, 0.250, 0.500, 0.750, 0.900, 0.975];

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

%% Prepare data for training
Xdata = cell(num_ahead, 1); Ydata = cell(num_ahead, 1);
Xdeaths = cell(num_ahead, 1); Ydeaths = cell(num_ahead, 1);
Mdl = cell(num_ahead, 1); Mdl_d = cell(num_ahead, 1);
for tt = 1:(num_ens_weeks + num_ahead*(7/week_len))
    forecast_date = now_date - week_len*tt;
    dirname = datestr(forecast_date, 'yyyy-mm-dd');
    xx = readtable([fullpath '/' prefix '_forecasts_cases.csv']); 
    xxd = readtable([fullpath '/' prefix '_forecasts_deaths.csv']); 
    
    preds = table2array(xx(2:end, 3:end));
    preds = diff(preds(cidx, 1:7:end)')';
    
    preds_d = table2array(xxd(2:end, 3:end));
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
%% Train separate ensembles
% for jj=1:num_ahead
%     %thismdl = TreeBagger(100, Xdata{jj}, Ydata{jj}, 'Method','regression');
%     %thismdl = fitlm(Xdata{jj}, (Ydata{jj}-Xdata{jj}(:, 1)));
%     thismdl = TreeBagger(100, Xdata{jj}, (Ydata{jj}-Xdata{jj}(:, 1)), 'Method','regression');
%     Mdl{jj} = thismdl;
%     %thismdl = TreeBagger(100, Xdeaths{jj}, Ydeaths{jj}, 'Method','regression');
%     %thismdl = fitlm(Xdeaths{jj}, (Ydeaths{jj}-Xdeaths{jj}(:, 1)));
%     thismdl = TreeBagger(100, Xdeaths{jj}, (Ydeaths{jj}-Xdeaths{jj}(:, 1)), 'Method','regression');
%     Mdl_d{jj} = thismdl;
%     fprintf('.');
% end
%% Generate quantiles
preds = diff(pred_cases(cidx, 1:7:end)')';
preds_d = diff(pred_deaths(cidx, 1:7:end)')';
quant_preds_cases = zeros(length(cidx), num_ahead, length(quant_cases));
mean_preds_cases = zeros(length(cidx), num_ahead);
quant_preds_deaths = zeros(length(cidx), num_ahead, length(quant_deaths));
mean_preds_deaths = zeros(length(cidx), num_ahead);
for jj=1:num_ahead
    tt = 0;
    this_inc = data_4(cidx, end - 7*tt) - data_4(cidx, end - 7*tt-7);
    prev_inc = data_4(cidx, end - 7*tt-7) - data_4(cidx, end - 7*tt-14);
    extern_dat = [data_4(cidx, end - 7*tt), this_inc , prev_inc, jj*ones(length(this_inc), 1)];
    %extern_dat = [];
    errs = preds(:, jj) + quantilePredict(All_Mdl,[preds(:, jj) extern_dat],'Quantile',quant_cases);
    errs = errs - errs(:, abs(quant_cases-0.5) < 1e-5);
    quant_preds_cases(:, jj, :) = preds(:, jj) + errs;
    mean_preds_cases(:, jj) = preds(:, jj);% + predict(Mdl{jj}, [preds(:, jj) extern_dat]);
    
    this_inc1 = deaths(cidx, end - 7*tt) - deaths(cidx, end - 7*tt-7);
    prev_inc1 = deaths(cidx, end - 7*tt-7) - deaths(cidx, end - 7*tt-14);
    extern_dat = [deaths(cidx, end - 7*tt), this_inc , prev_inc, this_inc1, prev_inc1, jj*ones(length(this_inc), 1)];
    %extern_dat = [];
    errs = quantilePredict(All_Mdl_d, [preds_d(:, jj) extern_dat],'Quantile',quant_deaths);
    errs = errs - errs(:, abs(quant_deaths-0.5) < 1e-5);
    quant_preds_deaths(:, jj, :) = preds_d(:, jj) + errs;
    mean_preds_deaths(:, jj) = preds_d(:, jj);% + predict(Mdl_d{jj}, [preds_d(:, jj) extern_dat]);
end

quant_preds_cases = (quant_preds_cases + abs(quant_preds_cases))/2;
quant_preds_deaths = (quant_preds_deaths + abs(quant_preds_deaths))/2;
%% Plot
sel_idx = 1;
dt = deaths(cidx, :);
thisquant = squeeze(quant_preds_deaths(sel_idx, :, :));
gt_len = 4;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
gt = diff(dt(sel_idx, gt_idx)');
point_forecast = num2cell([(gt_len+1:gt_len+4)' mean_preds_deaths(sel_idx, :)']);
historical = num2cell([(1:gt_len)' gt]);
forecast = num2cell([(gt_len+1:gt_len+4)' thisquant]);
fanplot([historical; point_forecast], forecast)
title([placenames{sel_idx} 'Deaths']);

dt = data_4(cidx, :);
thisquant = squeeze(quant_preds_cases(sel_idx, :, :));
gt_len = 4;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
gt = diff(dt(sel_idx, gt_idx)');
point_forecast = num2cell([(gt_len+1:gt_len+4)' mean_preds_cases(sel_idx, :)']);
historical = num2cell([(1:gt_len)' gt]);
forecast = num2cell([(gt_len+1:gt_len+4)' thisquant]);
fanplot([historical; point_forecast], forecast)
title([placenames{sel_idx} 'Cases']);
%% Write to file

case_vals = {'place' , 'week_ahead', 'quantile', 'value'};
death_vals = {'place' , 'week_ahead', 'quantile', 'value'};
placenames = placenames(cidx);
for ii = 1:length(cidx)
    for jj = 1:num_ahead
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
for jj = 1:num_ahead
    thisentry = [{'US'} {jj} {'point'} {sum(mean_preds_cases(:, jj), 1)}];
    case_vals = [case_vals; thisentry];
    for qq = 1:length(quant_cases)
        thisentry = [{'US'} {jj} {quant_cases(qq)} {sum(quant_preds_cases(:, jj, qq), 1)}];
        case_vals = [case_vals; thisentry];
    end
    thisentry = [{'US'} {jj} {'point'} {sum(mean_preds_deaths(:, jj), 1)}];
    death_vals = [death_vals; thisentry];
    for qq = 1:length(quant_deaths)
        thisentry = [{'US'} {jj} {quant_deaths(qq)} {sum(quant_preds_deaths(:, jj, qq), 1)}];
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