clear; warning off;
addpath('./hyper_params');

%% For US
load_data_us;
smooth_factor = 14;
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', smooth_factor, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', smooth_factor, 2), 2)];
load us_hyperparam_ref_64.mat
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dhyperparams;
write_unreported;
save us_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;

disp('Finished updating US forecasts');
%% For Global
clear;
load_data_global;
smooth_factor = 14;
data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', smooth_factor, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', smooth_factor, 2), 2)];
load global_hyperparam_ref_64.mat
[best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, 0, 20, size(data_4, 2));
dhyperparams;
write_unreported;
save global_hyperparam_latest.mat best_param_list MAPEtable_s best_death_hyperparam one_hyperparam;

disp('Finished updating Global forecasts');

%% Add the entry to historical forecasts
path = '../results/historical_forecasts/';
thisday = size(data_4, 2);
forecast_date = datetime(2020, 1, 23)+caldays(thisday);
dirname = datestr(forecast_date, 'yyyy-mm-dd');

fullpath = [path dirname];

if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

copyfile('../results/forecasts/us_forecasts_quarantine_20.csv', [fullpath '/us_forecasts_cases.csv']);
copyfile('../results/forecasts/us_deaths_quarantine_20.csv', [fullpath '/us_forecasts_deaths.csv']);
copyfile('../results/forecasts/global_forecasts_quarantine_20.csv', [fullpath '/global_forecasts_cases.csv']);
copyfile('../results/forecasts/global_deaths_quarantine_20.csv', [fullpath '/global_forecasts_deaths.csv']);