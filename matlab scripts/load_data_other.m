%% Load germany data
temp = readtable('state_codes_germany.csv');
countries = temp.state_code;
popu = temp.population;

%% Load german infection and death data
fsource = 'https://raw.githubusercontent.com/KITmetricslab/covid19-forecast-hub-de/master/data-truth/RKI/truth_RKI-Cumulative%20Cases_Germany.csv';
urlwrite(fsource,'dummy.csv');
germanycasetable = readtable('dummy.csv');

fsource = 'https://raw.githubusercontent.com/KITmetricslab/covid19-forecast-hub-de/master/data-truth/RKI/truth_RKI-Cumulative%20Deaths_Germany.csv';
urlwrite(fsource,'dummy.csv');
germanydeathtable = readtable('dummy.csv');
%% Prepare data
maxt = days(max(germanycasetable.date) - datetime(2020, 1, 22));
nn = length(popu);
data_4 = zeros(nn, maxt);
for ll = 1:length(germanycasetable.date)
    tt = days(germanycasetable.date(ll) - datetime(2020, 1, 22));
    cc = find(strcmpi(countries, germanycasetable.location(ll)));
    if length(cc)==1
        data_4(cc, tt) = germanycasetable.value(ll);
    else
        fprintf('ERROR on %d\n', cc);
    end
end

maxt = days(max(germanydeathtable.date) - datetime(2020, 1, 22));
nn = length(popu);
deaths = zeros(nn, maxt);
for ll = 1:length(germanydeathtable.date)
    tt = days(germanydeathtable.date(ll) - datetime(2020, 1, 22));
    cc = find(strcmpi(countries, germanydeathtable.location(ll)));
    if length(cc)==1
        deaths(cc, tt) = germanydeathtable.value(ll);
    else
        fprintf('ERROR on %d\n', cc);
    end
end

prefix = 'other';