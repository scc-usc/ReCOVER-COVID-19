countries = readcell('countries_list.txt', 'Delimiter','');
passengerFlow = load('global_travel_data.txt');
popu = load('global_population_data.txt');
[tableConfirmed] = getDataCOVID();
%%
vals = table2array(tableConfirmed(:, 12:end)); % Day-wise values
data_4 = zeros(length(countries), size(vals, 2));
for cidx = 1:length(countries)
    idx = strcmpi(countries{cidx}, tableConfirmed.CountryRegion);
    if(sum(idx)<1)
        disp([countries{cidx} ' not found']);
    end
    data_4(cidx, :) = sum(vals(idx, :), 1);
end
