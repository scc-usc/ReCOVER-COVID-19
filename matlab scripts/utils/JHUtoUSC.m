%%% Must run the appropriate data loading script first
%% Setup
%daynums = 100:1:size(data_4, 2);
daynums = 100:1:250;
path = 'C:\Users\User\research\matlab_extra\';

%% Compute for all days
for day_idx = 1:length(daynums)
%for day_idx = 1:length(daynums)
    thisday = daynums(day_idx);
    forecast_date = datetime(2020, 1, 23)+caldays(thisday);
    dirname_w = datestr(forecast_date, 'yyyy-mm-dd');
    dirname_r = datestr(forecast_date+caldays(1), 'yyyy-mm-dd'); % Adjusting for incorrect groundtruth timestamp
    fullpath_r = [path dirname_r];
    fullpath_w = [path dirname_w];
    if ~exist(fullpath_r, 'dir') || ~exist(fullpath_w, 'dir')
        continue;
    end
    
    % Read US data
    countries = readcell('us_states_list.txt', 'Delimiter','');
    state_ab = readcell('us_states_abbr_list.txt', 'Delimiter','');
    
    tableConfirmed = readtable([fullpath_r '\time_series_covid19_confirmed_US.csv']);
    tableDeaths = readtable([fullpath_r '\time_series_covid19_deaths_US.csv']);
    
    % Extract US cases from JHU data
    vals = table2array(tableConfirmed(2:end, 13:end)); % Day-wise values
    clist = tableConfirmed.Var7(2:end);
    if all(isnan(vals(:, end)))
        vals(:, end) = [];
    end
    data_4 = zeros(length(countries), size(vals, 2));
    for cidx = 1:length(countries)
        idx = strcmpi(clist, countries{cidx});
        if(isempty(idx))
            disp([countries{cidx} 'not found']);
        end
        data_4(cidx, :) = sum(vals(idx, :), 1);
        idx = find(idx);
    end
    
    % Extract US deaths from JHU data
    vals = table2array(tableDeaths(2:end, 14:end)); % Day-wise values
    clist = tableDeaths.Var7(2:end);
    if all(isnan(vals(:, end)))
        vals(:, end) = [];
    end
    deaths = zeros(length(countries), size(vals, 2));
    for cidx = 1:length(countries)
        idx = strcmpi(clist, countries{cidx});
        if(isempty(idx))
            disp([countries{cidx} 'not found']);
        end
        deaths(cidx, :) = sum(vals(idx, :), 1);
    end
    writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23), 1), [fullpath_w '/us_data.csv']);
    writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23), 1), [fullpath_w '/us_deaths.csv']);
    
    % Read global tables
    countries = readcell('countries_list.txt', 'Delimiter','');
    tableConfirmed = readtable([fullpath_r '\time_series_covid19_confirmed_global.csv']);
    tableDeaths = readtable([fullpath_r '\time_series_covid19_deaths_global.csv']);
    
    % Extract global confirmed cases
    vals = table2array(tableConfirmed(2:end, 6:end)); % Day-wise values
    clist = tableConfirmed.Var2(2:end);
    if all(isnan(vals(:, end)))
        vals(:, end) = [];
    end
    data_4 = zeros(length(countries), size(vals, 2));
    for cidx = 1:length(countries)
        idx = strcmpi(countries{cidx}, clist);
        if(sum(idx)<1)
            disp([countries{cidx} ' not found']);
            continue;
        end
        data_4(cidx, :) = sum(vals(idx, :), 1);
        idx = find(idx);
    end
    
    % Extract deaths
    
    vals = table2array(tableDeaths(2:end, 6:end)); % Day-wise values
    clist = tableDeaths.Var2(2:end);
    if all(isnan(vals(:, end)))
        vals(:, end) = [];
    end
    deaths = zeros(length(countries), size(vals, 2));
    for cidx = 1:length(countries)
        idx = strcmpi(countries{cidx}, clist);
        if(isempty(idx))
            disp([countries{cidx} 'not found']);
        end
        deaths(cidx, :) = sum(vals(idx, :), 1);
    end
    
    writetable(infec2table(data_4, countries, zeros(length(countries), 1), datetime(2020, 1, 23), 1), [fullpath_w '/global_data.csv']);
    writetable(infec2table(deaths, countries, zeros(length(countries), 1), datetime(2020, 1, 23), 1), [fullpath_w '/global_deaths.csv']);
    
    delete([fullpath_r '/time*']);
    
    disp(['Finished for day' dirname_r]);
end

