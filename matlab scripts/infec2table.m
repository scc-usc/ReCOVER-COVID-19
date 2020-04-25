function tt = infec2table(infec, countries)
% function to create tables in the correct output format
    datecols = datestr(datetime(floor(now),'ConvertFrom','datenum')+caldays(0:size(infec, 2)-1), 'yyyy-mm-dd');
    datecols = cellstr(datecols);
    allcols = [{'id'; 'Country'}; datecols];
    vectorarray  = num2cell(infec,1);
    tt = table((0:length(countries)-1)', countries, vectorarray{:}, 'VariableNames',allcols);
end