%% Load global vacc data
% Source: https://github.com/owid/covid-19-data/tree/master/public/data/vaccinations
g_countries = readcell('countries_list.txt', 'Delimiter','');
g_countries_ihme = readcell('ihme_global.txt');
g_popu = load('global_population_data.txt');
sel_url = 'https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv';
urlwrite(sel_url, 'dummy.csv');
g_vacc_tab = readtable('dummy.csv');
%% generate data matrices
d_idx = days(g_vacc_tab.date - datetime(2020, 1, 23));
[~, cidx] = ismember(g_vacc_tab.location, g_countries);
[~, cidx_ihme] = ismember(g_vacc_tab.location(cidx==0), g_countries_ihme);
cidx(cidx==0) = cidx_ihme;
T = days(today('datetime') - datetime(2020, 1, 23));
g_vacc = nan(length(g_countries), T);
g_vacc_full = nan(length(g_countries), T);
g_booster = nan(length(g_countries), max(d_idx));

for ii = 1:size(g_vacc_tab, 1)
    if cidx(ii)>0
        g_vacc(cidx(ii), d_idx(ii)) = g_vacc_tab.people_vaccinated(ii)+g_vacc_tab.people_fully_vaccinated(ii);
        g_vacc_full(cidx(ii), d_idx(ii)) = g_vacc_tab.people_fully_vaccinated(ii);
        g_booster(cidx(ii), d_idx(ii)) = g_vacc_tab.total_boosters(ii);
    end
end
g_vacc = fillmissing(g_vacc, 'previous', 2);
g_vacc_full = fillmissing(g_vacc_full, 'previous', 2);
%g_booster = fillmissing(g_booster, 'previous', 2);
%%
for cid=1:length(g_countries)
    xx = g_booster(cid, :);
    idx = find(~isnan(xx)); 
    if isempty(idx)
        continue;
    end
    idx = idx(1);
    if idx > 700   % force this to be the start date of booster
        g_booster(cid, 1) = 0;
        g_booster(cid, 700) = 1;
        g_booster(cid, :) = fillmissing(g_booster(cid, :), 'linear');
    end
end
g_booster = fillmissing(g_booster, 'previous', 2);
%% Load US data
% Source: https://github.com/govex/COVID-19/blob/master/data_tables/vaccine_data/raw_data/vaccine_data_us_state_timeline.csv
u_countries = readcell('us_states_list.txt');
u_ab = readcell('us_states_abbr_list.txt');
u_popu = load('us_states_population_data.txt');
sel_url = 'https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/us_state_vaccinations.csv';
urlwrite(sel_url, 'dummy.csv');
u_vacc_tab = readtable('dummy.csv');
%%
d_idx = days(u_vacc_tab.date - datetime(2020, 1, 23));
u_countries{strcmpi(u_countries, 'New York')} = 'New York State';
[~, cidx] = ismember(u_vacc_tab.location, u_countries);
T = days(today('datetime') - datetime(2020, 1, 23));
u_vacc = nan(length(u_countries), T);
u_vacc_full = nan(length(u_countries), T);

for ii = 1:size(u_vacc_tab, 1)
    if cidx(ii)>0
        u_vacc(cidx(ii), d_idx(ii)) = u_vacc_tab.people_vaccinated(ii)+u_vacc_tab.people_fully_vaccinated(ii);
        u_vacc_full(cidx(ii), d_idx(ii)) = u_vacc_tab.people_fully_vaccinated(ii);
    end
end
u_vacc_full = filloutliers(u_vacc_full, 'linear', 2);
u_vacc = filloutliers(u_vacc, 'linear', 2);
u_vacc = fillmissing(u_vacc, 'previous', 2);
u_vacc_full = fillmissing(u_vacc_full, 'previous', 2);
%% Write data
tic;
gt_offset = 344; % Only need to show starting from Jan 1
T_full = min([size(u_vacc, 2) size(g_vacc, 2)]);

gu_vacc = [u_vacc(:, gt_offset:T_full); g_vacc(:, gt_offset:T_full)];
gu_vacc_full = [u_vacc_full(:, gt_offset:T_full); g_vacc_full(:, gt_offset:T_full)];

gu_vacc = fillmissing(gu_vacc, "previous",2);
gu_vacc_full = fillmissing(gu_vacc_full, "previous",2);

bad_idx = all(isnan(gu_vacc), 2);
bad_idx_full = all(isnan(gu_vacc_full), 2);

popu = [u_popu; g_popu];
countries = [strcat({'US | '}, u_countries); g_countries];

gu_vacc_full(isnan(gu_vacc_full)) = 0;
gu_vacc(isnan(gu_vacc)) = 0;

T2r = infec2table(gu_vacc, countries, bad_idx, datetime(2020, 1, 23)+gt_offset, 1, 1);
T2r.population = popu(~bad_idx);
T2r_full = infec2table(gu_vacc_full, countries, bad_idx_full, datetime(2020, 1, 23)+gt_offset,1 , 1);
T2r_full.population = popu(~bad_idx_full);


save vacc_data.mat
%% Write recent cases file to be used for immunity analysis
got_data = 0;
tt = 1;
now_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
path = '../results/historical_forecasts/';

while got_data==0
    forecast_date = now_date - tt + 1;
    dirname = datestr(forecast_date, 'yyyy-mm-dd');
    fullpath = [path dirname];
    try
    xx = readtable([fullpath '/us_data.csv']); us_cases = table2array(xx(2:end, 3:end));
    xx = readtable([fullpath '/global_data.csv']); global_cases = table2array(xx(2:end, 3:end));
    if size(us_cases, 2) == size(global_cases, 2)
        got_data = 1;
        break;
    end
    tt = tt+1;
    catch
        got_data = 0;
        tt = tt+1;
        continue;
    end
end
daynum = floor(days(datetime((now),'ConvertFrom','datenum') - datetime(2020, 1, 23)))-tt+1;
all_cases = [us_cases; global_cases];
lcorrection = daynum - size(all_cases, 2); 
all_cases = [zeros(size(all_cases, 1), lcorrection) all_cases];

writetable(infec2table(all_cases(:, gt_offset:daynum), countries, zeros(length(countries), 1), datetime(2020, 1, 23)+gt_offset,1 , 1), '../results/forecasts/recent_cases.csv');
writetable(T2r, '../results/forecasts/vacc_num.csv');
writetable(T2r_full, '../results/forecasts/vacc_full.csv');