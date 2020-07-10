countries = readcell('countries_list.txt', 'Delimiter','');
passengerFlow = load('global_travel_data.txt');
passengerFlow = passengerFlow - diag(diag(passengerFlow));
popu = load('global_population_data.txt');
[tableConfirmed, tableDeaths] = getDataCOVID();
%% Extract reported cases
vals = table2array(tableConfirmed(:, 6:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end
data_4 = zeros(length(countries), size(vals, 2));
for cidx = 1:length(countries)
    idx = strcmpi(countries{cidx}, tableConfirmed.CountryRegion);
    if(sum(idx)<1)
        disp([countries{cidx} ' not found']);
    end
    data_4(cidx, :) = sum(vals(idx, :), 1);
end

writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/global_data.csv');

%% Extract deaths

vals = table2array(tableDeaths(:, 6:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end
deaths = zeros(length(countries), size(vals, 2));
for cidx = 1:length(countries)
    idx = strcmpi(tableConfirmed.CountryRegion, countries{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
    end
    deaths(cidx, :) = sum(vals(idx, :), 1);
end

writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/global_deaths.csv');

%%
prefix = 'global'; % This ensures that the files to load and saved are named properly