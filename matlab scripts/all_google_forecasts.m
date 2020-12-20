% Generate forecasts for all the regions available from Google opendata
tic;

pop_dat = readtable('demographicsG.csv');
index_dat = readtable('indexG.csv', 'Format','%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
sel_url = 'https://storage.googleapis.com/covid19-open-data/v2/epidemiology.csv';
urlwrite(sel_url, 'dummy.csv');
all_tab = readtable('dummy.csv');
delete dummy.csv

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
delim = repmat('-', [length(all_keys) 1]);
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

date_list = days(all_tab.date - datetime(2020, 1, 23));
maxt = max(date_list);
good_dates =  date_list> 0 & date_list < maxt; % Only consider the dates after this

data_4 = zeros(length(all_keys), maxt-1);
deaths = zeros(length(all_keys), maxt-1);
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

data_4(isnan(data_4)) = 0;
deaths(isnan(deaths)) = 0;

disp('Finished pre-processing data ');
toc
%%
tic;
smooth_factor = 14;
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);

%%
un = 2*ones(size(data_4, 1), 1); % Select the ratio of true cases to reported cases. 1 for default.
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

beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2), 0, compute_region);
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

prefix = 'google'; file_prefix =  ['../results/forecasts/' prefix];
bad_idx = ~compute_region;
bad_idx_d = ~compute_region_d;

startdate = datetime(2020, 1, 23) + caldays(T_full);
file_suffix = '0'; 

writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/google_data.csv');
writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/google_deaths.csv');

writetable(infec2table(infec_un, countries, bad_idx, startdate), [file_prefix '_forecasts_current_' file_suffix '.csv']);
writetable(infec2table(pred_deaths, countries, bad_idx_d, startdate), [file_prefix '_deaths_current_' file_suffix '.csv']);

disp('Finished wrting data and forecasts ');
toc
