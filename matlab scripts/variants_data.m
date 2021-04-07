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
u_tot_o = nan(length(u_countries), maxt);
u_sgtf_o = nan(length(u_countries), maxt);

for ii = 1:size(u_var_tab, 1)
    if cidx(ii)>0
        u_tot_o(cidx(ii), d_idx(ii)) = u_var_tab.positive(ii);
        u_sgtf_o(cidx(ii), d_idx(ii)) = u_var_tab.all_SGTF(ii);
    end
end
%%
u_tot = fillmissing(u_tot_o, 'previous', 2);
u_sgtf = fillmissing(u_sgtf_o, 'previous', 2);
u_tot_s = movmean(u_tot, 7, 2);
u_sgtf_s = movmean(u_sgtf, 7, 2);

%% Calculate prevelance range
xx = u_sgtf_s(:, end-3:end)./u_tot_s(:, end-3:end);
yy = u_tot_s(:, end-3:end);
xx = xx(:); yy = yy(:); idx = isnan(xx)| yy <10; xx(idx) = []; yy(idx) = [];

y = randsample(xx, 1000, true, yy);
var_prev_q = quantile(y, [0.05 0.5 0.95]);

%%
u_tot_s = movmean(u_tot_o, 14, 2);
u_sgtf_s = movmean(u_sgtf_o, 14, 2);
xx = cumsum(u_tot_o, 2, 'omitnan');
u_tot_w = diff(xx(:, 31:7:end)')';
xx = cumsum(u_sgtf_o, 2, 'omitnan');
u_sgtf_w = diff(xx(:, 31:7:end)')';

% Ratio data
rat_data = u_sgtf_o./(u_tot_o - u_sgtf_o); % Original
rat_data_s = u_sgtf_o./(u_tot_s - u_sgtf_s); % Smoothed
rat_data_w = u_sgtf_w./(u_tot_w - u_sgtf_w); % Weekly

%%
[~, ~, ~, s_val_s_lin, s_conf_s_lin, fC_s_lin, mdl, mdl_lin] = growth_rate(rat_data_s);
sel_idx_bool = (~cellfun(@(x)(any(isnan(x))), s_val_s_lin)); sel_idx = find(sel_idx_bool);
% for jj=1:length(sel_idx)
%     cid = sel_idx(jj);
%     [yy1, yy2] = predict(mdl_lin{cid}, [thisday:(thisday+horizon-1)]');
%     yy1 = 1./(1+1./exp(yy1)); yy2 = 1./(1+1./exp(yy2));
%     variant_rt_change_list(1, cid, :) = yy2(:, 1);
%     variant_rt_change_list(3, cid, :) = yy2(:, 2);
%     variant_rt_change_list(2, cid, :) = yy1(:, 1);
% end
sel_idx = find(~cellfun(@(x)(any(isnan(x))), s_val_s_lin));
Xmat = []; Ymat = [];
for jj=1:length(sel_idx)
    cid = sel_idx(jj);
    yy = rat_data_s(cid, :);
    nnanidx = intersect(find(~isnan(yy)), find(yy>0.00)); nnanidx(nnanidx<385) = [];
    thisX = zeros(length(nnanidx), length(sel_idx)+1);
    thisX(:, 1) = nnanidx'; thisX(:, 1+jj) = 1;
    thisY = log(yy(nnanidx)');
    Xmat = [Xmat; thisX]; Ymat = [Ymat; thisY];
end
MM = fitlm(Xmat, Ymat, 'Intercept', false);