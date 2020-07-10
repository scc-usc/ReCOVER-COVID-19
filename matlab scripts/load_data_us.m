%[tableConfirmed,tableDeaths,tableRecovered,time] = getDataCOVID_US();
countries = readcell('us_states_list.txt', 'Delimiter','');
passengerFlow = load('us_states_travel_data.txt');
passengerFlow = passengerFlow - diag(diag(passengerFlow));
popu = load('us_states_population_data.txt');
state_ab = readcell('us_states_abbr_list.txt', 'Delimiter','');
%% Load using JHU data
[tableConfirmed, tableDeaths] = getDataCOVID_US();
%% Extract confirmed cases from JHU data
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

%% Extract deaths from JHU data
vals = table2array(tableDeaths(:, 14:end)); % Day-wise values
if all(isnan(vals(:, end)))
    vals(:, end) = [];
end
deaths = zeros(length(countries), size(vals, 2));
for cidx = 1:length(countries)
    idx = strcmpi(tableDeaths.Province_State, countries{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
    end
    deaths(cidx, :) = sum(vals(idx, :), 1);
end
data_4_JHU = data_4; deaths_JHU = deaths;
clear tableConfirmed tableDeaths;

%% Load from NY Times
fsource = 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv';
urlwrite(fsource,'dummy.csv');
nytimestable = readtable('dummy.csv');
%% Extract confirmed cases and deaths from NY Times
maxt = days(nytimestable.date(end) - datetime(2020, 1, 22)); % numbering consistent with JHU data
data_4_NYT = zeros(length(countries), maxt);
deaths_NYT = zeros(length(countries), maxt);
for cidx = 1:length(countries)
    idx = strcmpi(nytimestable.state, countries{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
        continue;
    end
    tempt = nytimestable(idx, :);
    for ii=1:height(tempt)
        tt = days(tempt.date(ii) - datetime(2020, 1, 22));
        if tt>0
            data_4_NYT(cidx, tt) = tempt.cases(ii);
            deaths_NYT(cidx, tt) = tempt.deaths(ii);
        end
    end
end
clear nytimestable;
%% Load from USA Facts
fsource = 'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_confirmed_usafacts.csv';
urlwrite(fsource,'dummy.csv');
USAfacts_confirmed = readtable('dummy.csv');
fsource = 'https://usafactsstatic.blob.core.windows.net/public/data/covid-19/covid_deaths_usafacts.csv';
urlwrite(fsource,'dummy.csv');
USAfacts_deaths = readtable('dummy.csv');
%% Extract Confirmed and Deaths from US Facts
cvals = USAfacts_confirmed{1:end, 6:end};
dvals = USAfacts_deaths{1:end, 6:end};
maxt = size(cvals, 2);
data_4_USF = zeros(length(countries), maxt);
deaths_USF = zeros(length(countries), maxt);
for cidx = 1:length(countries)
    idx = strcmpi(USAfacts_confirmed.Var3, state_ab{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
        continue;
    end
    data_4_USF(cidx, :) = sum(cvals(idx, :), 1);
    
    idx = strcmpi(USAfacts_deaths.Var3, state_ab{cidx});
    if(isempty(idx))
        disp([countries{cidx} 'not found']);
        continue;
    end
    deaths_USF(cidx, :) =  sum(dvals(idx, :), 1);
end
clear USAfacts_deaths USAfacts_confirmed;
%% Change the following to pick which data to use
data_4 = data_4_JHU; deaths = deaths_JHU;
writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/us_data.csv');
writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23)), '../results/forecasts/us_deaths.csv');


prefix = 'us'; % This ensures that the files to load and saved are named properly