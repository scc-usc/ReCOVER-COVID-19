%% Load germany data
temp = readtable('state_codes_germany.csv');
countries = temp.state_code;
popu = temp.population;

temp = readtable('state_codes_poland.csv');
countries = [countries; temp.state_code];
popu = [popu; temp.population];

%% Load german infection and death data
fsource = 'https://raw.githubusercontent.com/KITmetricslab/covid19-forecast-hub-de/master/data-truth/RKI/truth_RKI-Cumulative%20Cases_Germany.csv';
urlwrite(fsource,'dummy.csv');
germanycasetable = readtable('dummy.csv');

fsource = 'https://raw.githubusercontent.com/KITmetricslab/covid19-forecast-hub-de/master/data-truth/RKI/truth_RKI-Cumulative%20Deaths_Germany.csv';
urlwrite(fsource,'dummy.csv');
germanydeathtable = readtable('dummy.csv');

fsource = 'https://raw.githubusercontent.com/KITmetricslab/covid19-forecast-hub-de/master/data-truth/MZ/truth_MZ-Cumulative%20Cases_Poland.csv';
urlwrite(fsource,'dummy.csv');
polandcasetable = readtable('dummy.csv');

fsource = 'https://raw.githubusercontent.com/KITmetricslab/covid19-forecast-hub-de/master/data-truth/MZ/truth_MZ-Cumulative%20Deaths_Poland.csv';
urlwrite(fsource,'dummy.csv');
polanddeathtable = readtable('dummy.csv');

germanycasetable = [germanycasetable; polandcasetable];
germanydeathtable = [germanydeathtable; polanddeathtable];

%% Prepare data
maxt = days(max(germanycasetable.date) - datetime(2020, 1, 23));
nn = length(popu);
data_4 = zeros(nn, maxt); data_4(:, end-7:end) = -1; %-1 indicates data not available
for ll = 1:length(germanycasetable.date)
    tt = days(germanycasetable.date(ll) - datetime(2020, 1, 23));
    cc = find(strcmpi(countries, germanycasetable.location(ll)));
    if length(cc)==1
        data_4(cc, tt) = germanycasetable.value(ll);
    else
        fprintf('ERROR on %d\n', cc);
    end
end

maxt = days(max(germanydeathtable.date) - datetime(2020, 1, 23));
nn = length(popu);
deaths = zeros(nn, maxt); deaths(:, end-7:end) = -1; %-1 indicates data not available
for ll = 1:length(germanydeathtable.date)
    tt = days(germanydeathtable.date(ll) - datetime(2020, 1, 23));
    cc = find(strcmpi(countries, germanydeathtable.location(ll)));
    if length(cc)==1
        deaths(cc, tt) = germanydeathtable.value(ll);
    else
        fprintf('ERROR on %d\n', cc);
    end
end

%% Fix missing data problem
for cc = 1:size(data_4, 1)
    idx = find(data_4(cc, :)>-1);
    miss_len = size(data_4, 2) - idx(end);
    data_4(cc, :) = [zeros(1, miss_len) data_4(cc, 1:idx(end))];
    
    idx = find(deaths(cc, :)>-1);
    miss_len = size(deaths, 2) - idx(end);
    deaths(cc, :) = [zeros(1, miss_len) deaths(cc, 1:idx(end))];
end

prefix = 'other';
clear *table;