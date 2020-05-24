function tt = infec2table(infec, countries, lowidx, start_date)
% function to create tables in the correct output format

    if nargin <3
        lowidx = zeros(length(countries), 1);
    end
    if nargin < 4
        start_date = datetime(floor(now),'ConvertFrom','datenum');
    end
    datecols = datestr(start_date +caldays(0:size(infec, 2)-1), 'yyyy-mm-dd');
    datecols = cellstr(datecols);
    allcols = [{'id'; 'Country'}; datecols];
    badidx = any(infec<0 | isnan(infec), 2);
    goodidx = ~(badidx | lowidx);
    
    vectorarray  = num2cell(infec(goodidx, :),1);
    cidx = (0:length(countries)-1)';
    
    countries = countries(goodidx);
    cidx = cidx(goodidx);
    
    tt = table(cidx, countries, vectorarray{:}, 'VariableNames',allcols);
end