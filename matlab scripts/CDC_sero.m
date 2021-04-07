%% Load sero data from CDC
sel_url = 'https://data.cdc.gov/api/views/d2tw-32xv/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
sero_data = readtable('dummy.csv');

%%
abvs = readcell('us_states_abbr_list.txt');
%%
state_map = containers.Map(abvs, (1:length(abvs)));
xx = cellfun(@(x)(x(:, end-11:end)), sero_data.DateRangeOfSpecimenCollection, 'UniformOutput', false);
whichday = zeros(length(xx), 1);
dt = cell(length(xx), 1);
for ii = 1:length(xx)
    %thisstr = strsplit(xx{ii}, {' ',','});
    dt{ii} = datetime(xx{ii});
    whichday(ii) = days(dt{ii} - datetime(2020, 1, 23));
end
un_ts = nan(size(data_4));
un_lts = nan(size(data_4));
un_uts = nan(size(data_4));

for ii = 1:length(whichday)
    cidx = state_map(sero_data.Site{ii});
    un_ts(cidx, whichday(ii)) = sero_data.EstimatedCumulativeInfectionsCount(ii)/data_4(cidx, whichday(ii)); 
    un_lts(cidx, whichday(ii)) = sero_data.EstimatedCumulativeInfectionsLowerCI7(ii)/data_4(cidx, whichday(ii)); 
    un_uts(cidx, whichday(ii)) = sero_data.EstimatedCumulativeInfectionsUpperCI7(ii)/data_4(cidx, whichday(ii)); 
end
%%
thisday = size(data_4, 2);
un_ts_s = fillmissing(un_ts(:, 1:thisday), 'previous', 2); un_ts_s(un_ts<1) = 1;
un_lts_s = fillmissing(un_lts(:, 1:thisday), 'previous', 2); un_lts_s(un_lts<1) = 1;
un_uts_s = fillmissing(un_uts(:, 1:thisday), 'previous', 2);