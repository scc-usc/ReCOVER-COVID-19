path = '../results/historical_forecasts/';

thisday = size(data_4, 2);
forecast_date = datetime(2020, 1, 23)+caldays(thisday);
dirname = datestr(forecast_date, 'yyyy-mm-dd');

fullpath = [path dirname];

if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

ihme_countries = readcell(['ihme_' prefix '.txt']);
lowidx = popu < 1; % No lowidx
base_infec = data_4(:, T_full); base_deaths = deaths(:, T_full);
writetable(infec2table([base_infec infec_un_20], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases.csv']);
writetable(infec2table([base_deaths deaths_un_20], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths.csv']);