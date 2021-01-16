function tt = infec2table(infec, countries, lowidx, start_date, skip_days, first_day)
% function to create tables in the correct output format

    if nargin <3
        lowidx = zeros(length(countries), 1);
    end
    if nargin < 4
        start_date = datetime((now),'ConvertFrom','datenum', 'TimeZone', 'America/Los_Angeles');
    end
    if nargin < 5
        skip_days = 7;
    end
    if nargin < 6   % Default first day is the first Saturday
        xx = weekday(start_date);
        first_day = 8-xx; % Index for the first Saturday
    end
    
    infec = round(infec(:, first_day:skip_days:end));
    last_day = first_day-1 + skip_days*(size(infec, 2)-1);
    datecols = datestr(start_date + caldays(first_day-1:skip_days:last_day), 'yyyy-mm-dd');
    datecols = cellstr(datecols);
    allcols = [{'id'; 'Country'}; datecols];
    %badidx = any(infec<0 | isnan(infec), 2);
    %goodidx = ~(badidx | lowidx);
    goodidx = ~(lowidx);
    vectorarray  = num2cell(infec(goodidx, :),1);
    cidx = (0:length(countries)-1)';
    
    countries = countries(goodidx);
    cidx = cidx(goodidx);
    
    tt = table(cidx, countries, vectorarray{:}, 'VariableNames',allcols);
end