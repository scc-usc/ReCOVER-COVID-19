%% Load sero data from CDC
sel_url = 'https://data.cdc.gov/api/views/mtc3-kq6r/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
sero_data = readtable('dummy.csv');

%%
abvs = readcell('us_states_abbr_list.txt');
%%
state_map = containers.Map(abvs, (1:length(abvs)));
xx = sero_data.MedianDonationDate;
whichday = zeros(length(xx), 1);

for ii = 1:length(xx)
    whichday(ii) = days(xx(ii) - datetime(2020, 1, 23));
end
un_ts = nan(size(data_4));
un_lts = nan(size(data_4));
un_uts = nan(size(data_4));
un_idx = cell(size(data_4));

%Note down where parts of different states occur in the table
for ii = 1:length(whichday)
    if ~isKey(state_map, sero_data.RegionAbbreviation{ii}(1:2))
        continue;
    end
    cidx = state_map(sero_data.RegionAbbreviation{ii}(1:2));
    un_idx{cidx, whichday(ii)} = [un_idx{cidx, whichday(ii)}; ii];
end
%% Take the weighted average prevalence over sub-regions to estimate for each state
for cidx = 1:size(data_4, 1)
    for ii = 1:size(data_4, 2)
        if isempty(un_idx{cidx, ii})
            continue;
        end
        valid_idx = un_idx{cidx, ii};
        x1 = sero_data.LowerCI__TotalPrevalence_(valid_idx).*sero_data.n_TotalPrevalence_(valid_idx)./sum(sero_data.n_TotalPrevalence_(valid_idx));
        x2 = sero_data.Rate__TotalPrevalence_(valid_idx).*sero_data.n_TotalPrevalence_(valid_idx)./sum(sero_data.n_TotalPrevalence_(valid_idx));
        x3 = sero_data.UpperCI__TotalPrevalence_(valid_idx).*sero_data.n_TotalPrevalence_(valid_idx)./sum(sero_data.n_TotalPrevalence_(valid_idx));
        un_lts(cidx, (ii)) = 0.01*sum(x1)*popu(cidx)./data_4(cidx, ii);
        un_ts(cidx, (ii)) = 0.01*sum(x2)*popu(cidx)./data_4(cidx, ii);
        un_uts(cidx, (ii)) = 0.01*sum(x3)*popu(cidx)./data_4(cidx, ii);
    end
end
%%
thisday = size(data_4, 2);
un_ts(un_ts<1) = nan; un_ts_s = fillmissing(un_ts(:, 1:thisday), 'linear', 2); un_ts_s = fillmissing(un_ts(:, 1:thisday), 'nearest', 2);
un_lts(un_lts<1) = nan; un_lts_s = fillmissing(un_lts(:, 1:thisday), 'linear', 2); un_lts_s = fillmissing(un_lts(:, 1:thisday), 'nearest', 2);
un_uts(un_lts<1) = nan; un_uts_s = fillmissing(un_uts(:, 1:thisday), 'linear', 2); un_uts_s = fillmissing(un_uts(:, 1:thisday), 'nearest', 2); 
un_ts_s = fillmissing(un_ts_s, "constant",1);
un_lts_s = fillmissing(un_lts_s, "constant",1);
un_uts_s = fillmissing(un_uts_s, "constant",1);
%%
dd_s = smooth_epidata(data_4, 14);
ddata = [0*popu diff(dd_s')'];

true_new_infec = cell(3, 1);
true_new_infec{1} = movmean(un_lts_s(:, 1:thisday).*ddata, 28, 2);
true_new_infec{2} = movmean(un_ts_s(:, 1:thisday).*ddata, 28, 2);
true_new_infec{3} = movmean(un_uts_s(:, 1:thisday).*ddata, 28, 2);


un_array = [sum(un_lts_s.*ddata, 2)./dd_s(:, end), ...
    sum(un_ts_s.*ddata, 2)./dd_s(:, end), sum(un_uts_s.*ddata, 2)./dd_s(:, end)];
un_array(isnan(un_array)) = 1;