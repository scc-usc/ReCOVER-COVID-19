% Source: https://github.com/myhelix/helix-covid19db/blob/master/counts_by_state.csv
u_countries = readcell('us_states_list.txt');
u_ab = readcell('us_states_abbr_list.txt');
u_popu = load('us_states_population_data.txt');
sel_url = 'https://raw.githubusercontent.com/myhelix/helix-covid19db/master/counts_by_state.csv';
urlwrite(sel_url, 'dummy.csv');
u_var_tab = readtable('dummy.csv');
%%
d_idx = days(u_var_tab.collection_date - datetime(2020, 1, 23));
[~, cidx] = ismember(u_var_tab.state, u_ab);
now_date_actual = datetime((now),'ConvertFrom','datenum');
maxt = floor(days((now_date_actual) - datetime(2020, 1, 23)));
u_tot = nan(length(u_countries), maxt);
u_sgtf = nan(length(u_countries), maxt);

for ii = 1:size(u_var_tab, 1)
    if cidx(ii)>0
        u_tot(cidx(ii), d_idx(ii)) = u_var_tab.positive(ii);
        u_sgtf(cidx(ii), d_idx(ii)) = u_var_tab.all_SGTF(ii);
    end
end
%%
u_tot = fillmissing(u_tot, 'previous', 2);
u_sgtf = fillmissing(u_sgtf, 'previous', 2);
u_tot_s = movmean(u_tot, 7, 2);
u_sgtf_s = movmean(u_sgtf, 7, 2);

%% Calculate prevelance range
xx = u_sgtf_s(:, end-3:end)./u_tot_s(:, end-3:end);
yy = u_tot_s(:, end-3:end);
xx = xx(:); yy = yy(:); idx = isnan(xx)| yy <10; xx(idx) = []; yy(idx) = [];

y = randsample(xx, 1000, true, yy);
var_prev_q = quantile(y, [0.05 0.5 0.95]);