%[tableConfirmed,tableDeaths,tableRecovered,time] = getDataCOVID_US();
countries = readcell('us_states_list.txt', 'Delimiter','');
passengerFlow = load('us_states_travel_data.txt');
passengerFlow = passengerFlow - diag(diag(passengerFlow));
popu = load('us_states_population_data.txt');
[tableConfirmed, tableDeaths] = getDataCOVID_US();
%% Extract confirmed cases
vals = table2array(tableConfirmed(:, 13:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end
data_4 = zeros(length(countries), size(vals, 2));
for cidx = 1:length(countries)
    idx = strcmpi(tableConfirmed.Province_State, countries{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
    end
    data_4(cidx, :) = sum(vals(idx, :), 1);
end

writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/us_data.csv');

%% Extract deaths

vals = table2array(tableDeaths(:, 14:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end
deaths = zeros(length(countries), size(vals, 2));
for cidx = 1:length(countries)
    idx = strcmpi(tableConfirmed.Province_State, countries{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
    end
    deaths(cidx, :) = sum(vals(idx, :), 1);
end

writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/us_deaths.csv');