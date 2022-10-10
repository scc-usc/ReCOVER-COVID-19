vac_tab = readtable('https://opendata.ecdc.europa.eu/covid19/vaccine_tracker/csv/data.csv');
%% 
all_idx = contains(vac_tab.TargetGroup, 'ALL');
vac_tab = vac_tab(all_idx, :);
%%
week_nums = cellfun(@(xx)(str2double(xx(end-1:end))), vac_tab.YearWeekISO);
year_nums = cellfun(@(xx)(str2double(xx(1:4))), vac_tab.YearWeekISO);
%%
t = datetime(year_nums, 1, 1, 'Format', 'dd-MMMM-yyyy');  % First day of the year
t = t - days(weekday(t)-1) + days((week_nums-1).*7);
dd = days(t - datetime(2020, 1, 23));
%%
warning off;
load latest_global_data.mat;

eu_names_table =  readtable('locations_eu.csv');
eu_names = cell(length(countries), 1);
eu_present = zeros(length(countries), 1);
for jj = 1:length(eu_names_table.location)
%     if strcmpi(eu_names_table.location_name(jj), 'Czechia')==1
%         idx = find(strcmpi(countries, 'Czech Republic'));
%     else
        idx = find(strcmpi(countries, eu_names_table.location_name(jj)));
%     end
    if ~isempty(idx)
        eu_present(idx(1)) = 1;
        eu_names(idx(1)) = eu_names_table.location(jj);
    else
        disp([eu_names_table.location_name(jj) ' Not Found']);
    end
end
iso2 = eu_names(eu_present>0);
iso2_new = iso2; iso2_new{find(strcmp(iso2, 'GR'))} = 'EL';
[aa, bb] = ismember(vac_tab.ReportingCountry, iso2_new);
%%
all_boosters_data = cell(4, 1);
maxt = floor(days(datetime(now,'ConvertFrom','datenum') - datetime(2020, 1, 23)));

for j=1:length(all_boosters_data)
    all_boosters_data{j} = zeros(length(iso2), maxt);
end
%%
for j=1:length(dd)
    if bb(j) == 0
        continue;
    end
    all_boosters_data{1}(bb(j), dd(j)) = vac_tab.FirstDose(j);
    all_boosters_data{2}(bb(j), dd(j)) = vac_tab.SecondDose(j);
    all_boosters_data{3}(bb(j), dd(j)) = vac_tab.DoseAdditional1(j);
    all_boosters_data{4}(bb(j), dd(j)) = vac_tab.DoseAdditional2(j);
end
%%
for j=1:length(all_boosters_data)
    all_boosters_data{j} = smooth_epidata(cumsum(all_boosters_data{j}, 2),'c');
end
%%
save EU_vax_data.mat all_boosters_data
