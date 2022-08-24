sel_url = 'https://raw.githubusercontent.com/biobotanalytics/covid19-wastewater-data/master/wastewater_by_county.csv';
urlwrite(sel_url, 'dummy.csv');
ww_data = readtable('dummy.csv');
abvs = readcell('us_states_abbr_list.txt');
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
load latest_us_data.mat
%%
fips_tab.location(strcmpi(fips_tab.location, 'US')) = {'0'};
[aa, fips_idx] = ismember(ww_data.fipscode, cellfun(@(x)(str2double(x)), fips_tab.location));

xx = ww_data.sampling_week;
whichday = zeros(length(xx), 1);

for ii = 1:length(xx)
    whichday(ii) = days(xx(ii) - datetime(2020, 1, 23));
end
ww_ts = zeros(size(data_4));
ww_pres = zeros(size(data_4));
[aa, abvs_idx] = ismember(ww_data.state, abvs);

for ii=1:length(xx)
    if whichday(ii) < 1 || fips_idx(ii) < 1
        continue;
    end
    ww_pres(abvs_idx(ii), whichday(ii)) = 1;
    ww_ts(abvs_idx(ii), whichday(ii)) = ww_ts(abvs_idx(ii), whichday(ii)) ...
        + ww_data.effective_concentration_rolling_average(ii)*fips_tab.population(fips_idx(ii))/popu(abvs_idx(ii));
end
ww_ts(ww_pres < 1) = nan; ww_ts(ww_ts <= 0) = nan;
%%
ww_ts1 = fillmissing(ww_ts, 'linear', 2, 'EndValues','none');
ww_tsm = movmean(ww_ts1, 14, 2);
data_4_s = smooth_epidata(data_4, 14, 0, 1);
data_diff = [zeros(length(popu), 1) diff(data_4_s, 1, 2)];
%%
ww_tsw = [zeros(length(popu), 1) ww_ts(:, 6:7:end)];
weekly_dat = [zeros(length(popu), 1) diff(data_4_s(:, 3:7:end), 1, 2)];

%%
wlag = 7; ww_tsm(ww_ts==0) = nan;
f = nan(size(ww_ts));
f(:, 1+wlag:end) = ww_ts(:, 1:end-wlag)./data_diff(:, 1+wlag:end); f(:, 1:200) = nan;
f1 = f;
% f = fillmissing(f, "linear", 2, 'EndValues','none');
% f = filloutliers(f, "linear", 2);
% f = fillmissing(f, "nearest", 2);
for jj = 1:size(ww_ts, 1)
    xx = find(~isnan(f1(jj, :))); yy = f1(jj, xx);
    if length(xx) > 5 && sum(xx > 200 & xx < 600) > 2
        f(jj, 200:end) = csaps(xx, yy, 0.0001, 200:size(f, 2));
    end
    f(jj, :) = fillmissing(f(jj, :), "linear", 1, 'EndValues','none');
    %f(jj, :) = filloutliers(f(jj, :), "linear");
    f(jj, :) = fillmissing(f(jj, :), "nearest");
end
f(f<0) = 0; f = movmean(f, 7, 2);
ww_adj = movmean(data_diff.*f, 14, 2);
%%
CDC_sero;
%%

true_new_infec{1} = (true_new_infec{1}+abs(true_new_infec{1}))/2;
true_new_infec{2} = (true_new_infec{2}+abs(true_new_infec{2}))/2;
true_new_infec{3} = (true_new_infec{3}+abs(true_new_infec{3}))/2;

eq_range = 200:600;
nz_idx =  ww_adj(:, eq_range)>0.5; % To deal with missing data early

ww_year1 = sum(ww_adj(:, eq_range).*nz_idx, 2);

sero_year1 = sum(true_new_infec{2}(:, eq_range).*nz_idx, 2);
true_new_infec_ww{1} = [(sero_year1./ww_year1).*ww_adj];
true_new_infec_ww{1} = movmean(max(true_new_infec_ww{1}, max(true_new_infec{1},un_array(:, 1).*data_diff)), 14, 2);

sero_year2 = sum(true_new_infec{2}(:, eq_range).*nz_idx, 2);
true_new_infec_ww{2} = [(sero_year2./ww_year1).*ww_adj];
true_new_infec_ww{2} = movmean(max(true_new_infec_ww{2}, max(true_new_infec{2},un_array(:, 2).*data_diff)), 14, 2);

sero_year3 = sum(true_new_infec{3}(:, eq_range).*nz_idx, 2);
true_new_infec_ww{3} = [(sero_year3./ww_year1).*ww_adj];
true_new_infec_ww{3} = movmean(max(true_new_infec_ww{3}, max(true_new_infec{3},un_array(:, 3).*data_diff)), 14, 2);

bad_states = (sum(~isnan(ww_ts), 2)<1) & (sum(~isnan(true_new_infec{2}), 2)>1);
true_new_infec_ww{1}(bad_states, :) = true_new_infec{1}(bad_states, :); true_new_infec_ww{2}(bad_states, :) = true_new_infec{2}(bad_states, :); true_new_infec_ww{3}(bad_states, :) = true_new_infec{3}(bad_states, :);

bad_states = (sum(~isnan(ww_ts), 2)<1) & (sum(~isnan(true_new_infec{2}), 2)<1);
true_new_infec_ww{1}(bad_states, :) = data_diff(bad_states, :); true_new_infec_ww{2}(bad_states, :) = data_diff(bad_states, :); true_new_infec_ww{3}(bad_states, :) = data_diff(bad_states, :);
%%
save ww_prevalence_us.mat true_new_infec_ww true_new_infec;