%% Hospitalization data download
sel_url = 'https://storage.googleapis.com/covid19-open-data/v2/hospitalizations.csv';
urlwrite(sel_url, 'dummy.csv');
hosp_dat = readtable('dummy.csv');

%% Static data
pop_dat = readtable('demographicsG.csv');
index_dat = readtable('indexG.csv', 'Format','%s%s%s%s%s%s%s%s%s%s%s%s%s%s');
econ_dat = readtable('G_economy.csv');
health_dat = readtable('G_health.csv');
Gll = readtable('G_lats_longs_processed.csv');
disp('Finished loading data')
%%
tic;
all_keys = (pop_dat.key(~isnan(pop_dat.population)));
popu =  (pop_dat.population(~isnan(pop_dat.population)));
temp_tab = pop_dat(~isnan(pop_dat.population), :);
temp_tab = sortrows(temp_tab, 'key');
all_keys = temp_tab.key;
popu = temp_tab.population;
nn = length(all_keys);
[~, idx] = ismember(all_keys, index_dat.key);
delim = repmat('|', [nn 1]);
countries = strcat(index_dat.country_name(idx), delim, index_dat.subregion1_name(idx), delim, index_dat.subregion2_name(idx), delim, index_dat.locality_name(idx));
temp_tab.aggregation_level = index_dat.aggregation_level(idx);
temp_tab.lats = Gll.lats; temp_tab.longs = Gll.longs;
temp_tab.hosp_capacity = nan(nn, 1);
[~, idx] = ismember(all_keys, health_dat.key);
temp_tab.hosp_capacity((idx>0)) = health_dat.hospital_beds(idx(idx>0));
temp_tab.diabetes_prevalence((idx>0)) = health_dat.diabetes_prevalence(idx(idx>0));
[~, idx] = ismember(all_keys, econ_dat.key);
temp_tab.gdp_per(idx>0) = econ_dat.gdp_per_capita(idx(idx>0));
temp_tab.gdp_per(temp_tab.gdp_per ==0) = NaN;
%%
xx = readtable('../results/forecasts/google_forecasts_current_0.csv');
valid_idx = 1+xx{2:end, 1};
%%
idx  = zeros(length(all_keys), 1);
idx(valid_idx) = 1;
pos_mat = [1,1,850,400];
figure;
cidx = idx & strcmp(temp_tab.aggregation_level, '0'); sum(cidx)
set(gcf,'position',pos_mat);
gb = geobubble(temp_tab.lats(cidx), temp_tab.longs(cidx));
gb.Title = 'Admin0 Covered';
geolimits([-60 75], [-180 180]);

figure;
set(gcf,'position',pos_mat);
cidx = idx & strcmp(temp_tab.aggregation_level, '1'); sum(cidx)
gb = geobubble(temp_tab.lats(cidx), temp_tab.longs(cidx));
gb.Title = 'Admin1 Covered';
geolimits([-60 75], [-180 180]);

figure;
set(gcf,'position',pos_mat);
cidx = idx & strcmp(temp_tab.aggregation_level, '2'); sum(cidx)
gb = geobubble(temp_tab.lats(cidx), temp_tab.longs(cidx));
gb.Title = 'Admin2 Covered';
geolimits([-60 75], [-180 180]);
%% Coverage per data type
idx  = (prod(~isnan(temp_tab{:, [11:18, 20:21]}), 2))>0;
x1 = sum(idx & strcmp(temp_tab.aggregation_level, '0'));
x2 = sum(idx & strcmp(temp_tab.aggregation_level, '1'));
x3 = sum(idx & strcmp(temp_tab.aggregation_level, '2'));
disp([x1 x2 x3]);

%%
hosp_keys = unique(hosp_dat.key);

xx = cell(length(hosp_keys), 1);
for jj=1:size(xx, 1)
yy = strsplit(hosp_keys{jj}, '_');
for ii = 1:min([length(yy), 3])
xx{jj, ii} = strjoin(yy(1:ii));
end
for ii=min([length(yy), 3])+1:3
xx{jj, ii} = '-';
end
end
%%
[~, hosp_idx] = ismember(all_keys, unique(xx(:, 1)));
countries(strcmp(temp_tab.aggregation_level, '0') & hosp_idx);