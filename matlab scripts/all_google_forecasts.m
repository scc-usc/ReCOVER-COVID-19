% Generate forecasts for all the regions available from Google opendata
tic;

pop_dat = readtable('demographicsG.csv');
index_dat = readtable('indexG.csv', 'Format','%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
sel_url = 'https://storage.googleapis.com/covid19-open-data/v2/epidemiology.csv';
urlwrite(sel_url, 'dummy.csv');
all_tab = readtable('dummy.csv');
delete dummy.csv;
disp('Finished loading data');
toc
%% Extract valid indices, and create name and population arrays
tic;
all_keys = (pop_dat.key(~isnan(pop_dat.population)));
popu =  (pop_dat.population(~isnan(pop_dat.population)));
temp_tab = table(all_keys, popu);
temp_tab = sortrows(temp_tab, 'all_keys');
all_keys = temp_tab.all_keys;
popu = temp_tab.popu;
[~, idx] = ismember(all_keys, index_dat.key);
delim = repmat('|', [length(all_keys) 1]);
countries = strcat(index_dat.country_name(idx), delim, index_dat.subregion1_name(idx), delim, index_dat.subregion2_name(idx), delim, index_dat.locality_name(idx));
countries_hier = [index_dat.country_name(idx),index_dat.subregion1_name(idx), index_dat.subregion2_name(idx), index_dat.locality_name(idx)];

%% 
 % It looks like that the rows are already sorted, but if not we want to sort them
 % to accelerate the processing
if ~issorted(all_tab.key)
    all_tab = sortrows(all_tab, 'key');
end
% Get the first and last occurrence of each key
[~, fo] = ismember(all_keys, all_tab.key);
[~, lo] = ismember(all_keys, flip(all_tab.key));
lo = length(all_tab.key)+1 - lo;

%%
date_list = days(all_tab.date - datetime(2020, 1, 23));
maxt = days(datetime(floor(now),'ConvertFrom','datenum') - datetime(2020, 1, 23));
good_dates =  date_list> 0 & date_list < maxt; % Only consider the dates after this

data_4 = nan(length(all_keys), maxt-1);
deaths = nan(length(all_keys), maxt-1);
ridx = zeros(length(all_tab.key), 1);
for j= 1:length(all_keys)
     if fo(j) == 0
         continue;
     end
     ridx(fo(j):lo(j)) = j;
end
val_idx = (ridx>0) & good_dates;

data_4(sub2ind(size(data_4), ridx(val_idx), date_list(val_idx))) = all_tab.total_confirmed(val_idx);
deaths(sub2ind(size(data_4), ridx(val_idx), date_list(val_idx))) = all_tab.total_deceased(val_idx);

disp('Finished pre-processing data ');
toc

%% Vaccine data download
sel_url = 'https://storage.googleapis.com/covid19-open-data/v2/vaccinations.csv';
urlwrite(sel_url, 'dummy.csv');
vacc_tab = readtable('dummy.csv');

%% Vaccine data prep
if ~issorted(vacc_tab.key)
    vacc_tab = sortrows(vacc_tab, 'key');
end
% Get the first and last occurrence of each key
[~, fo] = ismember(all_keys, vacc_tab.key);
[~, lo] = ismember(all_keys, flip(vacc_tab.key));
lo = length(vacc_tab.key)+1 - lo;

%% Vaccine data matrix creation
date_list = days(vacc_tab.date - datetime(2020, 1, 23));
maxt = days(datetime(floor(now),'ConvertFrom','datenum') - datetime(2020, 1, 23));
good_dates =  date_list> 0 & date_list < maxt; % Only consider the dates after this

vacc = nan(length(all_keys), maxt-1);
vacc_full = nan(length(all_keys), maxt-1);
vacc_person = nan(length(all_keys), maxt-1);

ridx = zeros(length(vacc_tab.key), 1);
for j= 1:length(all_keys)
     if fo(j) == 0
         continue;
     end
     ridx(fo(j):lo(j)) = j;
end
val_idx = (ridx>0) & good_dates;

vacc(sub2ind(size(vacc), ridx(val_idx), date_list(val_idx))) = vacc_tab.new_vaccine_doses_administered(val_idx);
vacc_full(sub2ind(size(vacc_full), ridx(val_idx), date_list(val_idx))) = vacc_tab.new_persons_fully_vaccinated(val_idx);
vacc_person(sub2ind(size(vacc_person), ridx(val_idx), date_list(val_idx))) = vacc_tab.new_persons_vaccinated(val_idx);

%% Write vaccine data

gt_offset = 344; % Only need to show starting from Jan 1
T_full = size(vacc, 2);

bad_idx = all(isnan(vacc), 2);
bad_idx_full = all(isnan(vacc_full), 2);
bad_idx_person = all(isnan(vacc_person), 2);

vacc = cumsum(vacc, 2, 'omitnan');
vacc_full = cumsum(vacc_full, 2, 'omitnan');
vacc_person = cumsum(vacc_person, 2, 'omitnan');

vacc = fillmissing(vacc(:, gt_offset:T_full), "previous",2);
vacc_full = fillmissing(vacc_full(:, gt_offset:T_full), "previous",2);
vacc_person = fillmissing(vacc_person(:, gt_offset:T_full), "previous",2);

vacc_full(isnan(vacc_full)) = 0;
vacc(isnan(vacc)) = 0;

T2r = infec2table(vacc, countries, bad_idx, datetime(2020, 1, 23)+gt_offset, 1, 1);
T2r.population = popu(~bad_idx);
T2r_full = infec2table(vacc_full, countries, bad_idx_full, datetime(2020, 1, 23)+gt_offset,1 , 1);
T2r_full.population = popu(~bad_idx_full);
T2r_person = infec2table(vacc_person, countries, bad_idx_person, datetime(2020, 1, 23)+gt_offset, 1, 1);
T2r_person.population = popu(~bad_idx_person);
%%
data_4 = fillmissing(data_4, 'previous', 2);
writetable(infec2table(data_4(:, gt_offset:T_full), countries, bad_idx & bad_idx_full & bad_idx_person , datetime(2020, 1, 23)+gt_offset,1 , 1), '../results/forecasts/G_recent_cases.csv');
writetable(T2r, '../results/forecasts/G_vacc_num.csv');
writetable(T2r_full, '../results/forecasts/G_vacc_full.csv');
writetable(T2r_person, '../results/forecasts/G_vacc_person.csv');
disp('Finished writing vaccine data ');

%% Smoothing for prediction
tic;

%data_4 = fillmissing(data_4, 'previous', 2);
deaths = fillmissing(deaths, 'previous', 2);

data_4(isnan(data_4)) = 0;
deaths(isnan(deaths)) = 0;

smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

%%
un = 1.5*ones(size(data_4, 1), 1); % Select the ratio of true cases to reported cases. 1 for default.
no_un_idx = un.*data_4(:, end)./popu > 0.2;
un(no_un_idx) = 1; % These places have enough prevelance that un =1 is sufficient


T_full = size(data_4, 2); % Consider all data for predictions
horizon = 80; dhorizon = horizon;
passengerFlow = 0; 
base_infec = data_4(:, T_full);
last_empty = base_infec < 1;
base_infec(last_empty) = max(data_4(last_empty, :), [], 2);

compute_region = data_4_s(:, end)> 1;

dalpha=1; dk = 4; lags = 2; djp = 7; dwin = 50*ones(size(data_4, 1), 1); % Change to learn in the future
lowinc = data_4(439, end-lags*dk) - data_4(439, end-2*dwin) < 20; dwin(lowinc) = 100;

best_param_list = [2 7 8 ]; % Change to learn in the future
%beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, compute_region);

best_param_list = [3 7 10]; % For holidays!
beta_after  = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, compute_region, 50);

infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec);
infec_un_re = infec_un - repmat(base_infec - data_4_s(:, T_full), [1, size(infec_un, 2)]);
infec_data = [data_4_s(:, 1:T_full), infec_un_re];

base_deaths = deaths(:, T_full);
last_empty = base_deaths < 1;
base_deaths(last_empty) = max(deaths(last_empty, :), [], 2);

compute_region_d = data_4_s(:, end)> 1;

[death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin, 0, compute_region_d, lags);
[deaths_un_20] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
infec_un_20 = infec_un;
pred_deaths = deaths_un_20;

disp('Finished all forecasts ');
toc

%% Write files
tic;
gt_offset = T_full - 200; % Only need to show last 200/7 weeks

prefix = 'google'; file_prefix =  ['../results/forecasts/' prefix];
bad_idx = ~compute_region;
bad_idx_d = ~compute_region_d;

startdate = datetime(2020, 1, 23) + caldays(T_full+1);
file_suffix = '0'; 

writetable(infec2table(data_4(:, gt_offset:end), countries, zeros(length(countries), 1), datetime(2020, 1, 23)+gt_offset), '../results/forecasts/google_data.csv');
writetable(infec2table(deaths(:, gt_offset:end), countries, zeros(length(countries), 1), datetime(2020, 1, 23)+gt_offset), '../results/forecasts/google_deaths.csv');

writetable(infec2table(infec_un, countries, bad_idx, startdate), [file_prefix '_forecasts_current_' file_suffix '.csv']);
writetable(infec2table(pred_deaths, countries, bad_idx_d, startdate), [file_prefix '_deaths_current_' file_suffix '.csv']);

disp('Finished wrting data and forecasts ');
toc