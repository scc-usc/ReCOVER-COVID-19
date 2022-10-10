addpath('./utils/');
addpath('./scenario_projections/');
% Get from 
% https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state-timeseries
%sel_url = 'https://healthdata.gov/sites/default/files/reported_hospital_utilization_timeseries_20210306_1105.csv';
sel_url = 'https://healthdata.gov/api/views/g62h-syeh/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
hosp_tab = readtable('dummy.csv');
%% Load case data
prefix = 'us';

%%%%%%%% Choose a date or selcect current date
%now_date = datetime(2021, 1, 3);
now_date = datetime((now),'ConvertFrom','datenum'); % 'TimeZone', 'America/Los_Angeles');
%%%%%%%%%%%%%%%%%%%%%%%%%

daynum = floor(days((now_date) - datetime(2020, 1, 23)));

path = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [path dirname];      
xx = readtable([fullpath '/' prefix '_data.csv']); data_4 = table2array(xx(2:end, 3:end));
lcorrection = daynum - size(data_4, 2); data_4 = [zeros(size(data_4, 1), lcorrection) data_4];

%% Convert hospital data to ReCOVER format
abvs = readcell('us_states_abbr_list.txt');
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
fips = cell(size(data_4, 1), 1);
hosp_dat = nan(size(data_4, 1), size(data_4, 2));
hosp_dat_p = nan(size(data_4, 1), size(data_4, 2));
hosp_dat_a = nan(size(data_4, 1), size(data_4, 2));

for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end

for idx = 1:size(hosp_tab, 1)
    
    cid = find(strcmp(abvs, hosp_tab.state(idx)));
    if isempty(cid)
        disp(['Error at ' num2str(idx)]);
    end
    date_idx = days(datetime(hosp_tab.date(idx), 'InputFormat', 'yyyy/MM/dd') - datetime(2020, 1, 23));
    
    if date_idx < 1
        continue;
    end
    
    hosp_dat_a(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx);
    hosp_dat_p(cid, date_idx) = hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
    hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx) + hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
end

%% Learn hospitalization rate like death forecasts
T_full = max(find(any(~isnan(hosp_dat), 1)));
maxt = size(data_4, 2);
%load us_hyperparam_latest.mat;
hosp_cumu = cumsum(nan2zero(hosp_dat), 2);
hosp_data_limit = T_full;

%%
smooth_factor = 14;
%data_4_s = smooth_epidata(data_4(:, :), smooth_factor/2, 0, 1);
hosp_cumu_s = smooth_epidata(hosp_cumu(:, 1:T_full), 1, 0, 1);


%% Save data

%un_list = [1 2 3];

save us_hospitalization hosp_cumu hosp_cumu_s hosp_data_limit fips;