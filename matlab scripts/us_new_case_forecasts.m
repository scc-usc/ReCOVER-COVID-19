
clear; warning off;
load latest_us_data.mat
load us_hyperparam_latest.mat
horizon = 200;
best_param_list(:, 1) = 2; best_param_list(:, 2) = 7; best_param_list(:, 3) = 8;
%% Prepare seroprevalence
CDC_sero;

un_ts = fillmissing(un_ts(:, 1:thisday), 'previous', 2); un_ts(un_ts<1) = 1;
un_lts = fillmissing(un_lts(:, 1:thisday), 'previous', 2); un_lts(un_lts<1) = 1;
un_uts = fillmissing(un_uts(:, 1:thisday), 'previous', 2);
un_array = [un_lts(:, end), un_ts(:, end), un_uts(:, end)];
un_array(isnan(un_array)) = 1; un_array(isnan(un_array)) = 1;
un = un_array(:, 2);


%% Learn variant prevelance
variants_data;
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

variant_fact = data_4;
sel_idx_bool = zeros(length(countries), 1); sel_idx_bool(sel_idx) = 1;
for jj=1:length(sel_idx)
    cid = sel_idx(jj);
    target_days = [1:size(data_4, 2)];
    thisX = zeros(length(target_days), length(sel_idx)+1);
    thisX(:, 1) = target_days'; thisX(:, 1+jj) = 1;
    [yy1, yy2] = predict(MM, thisX);
    yy1 = 1./(1+1./exp(yy1)); yy2 = 1./(1+1./exp(yy2));
    variant_fact(cid, :) = yy1';
end

variant_fact(~sel_idx_bool, :) = repmat(nanmedian(variant_fact(cid, :), 1), [sum(~sel_idx_bool), 1]);

%% Prepare vaccine data
xx = load('vacc_data.mat');
latest_vac = xx.u_vacc(:, end) - xx.u_vacc_full(:, end);
nidx = isnan(latest_vac); latest_vac(nidx) = popu(nidx).*(mean(latest_vac(~nidx))/mean(popu(~nidx)));
vacc_lag_rate = ones(length(popu), 14);
vacc_ad_dist(:) = 1; % This round specifies administration, rather than distribution. No need to model distribution rates
u_vacc_fd = xx.u_vacc(:, 1:end) - xx.u_vacc_full(:, 1:end); 
u_vacc_fd = fillmissing(u_vacc_fd, 'linear'); u_vacc_fd(isnan(u_vacc_fd)) = 0;
u_vacc_fd = [zeros(size(data_4, 1), size(data_4, 1)-size(u_vacc_fd, 1)), u_vacc_fd];
latest_vac = xx.u_vacc(:, end) - xx.u_vacc_full(:, end);
%% Assume future vaccination rates
vacc_monthly = 55000000;
vac_administered =(popu./sum(popu))*ones(1, horizon)*vacc_monthly/30.5 ;
equiv_vacc_effi = 0.5*(0.5+0.95);
vac_available = [vac_administered];
vac_effect = cumsum([latest_vac vac_available]*equiv_vacc_effi, 2);
vacc_pre_immunity = equiv_vacc_effi*((1 - un.*data_4./popu).*u_vacc_fd);

%% Run projections
scenario_forecasts = 0;
smooth_factor = 14; rate_change = ones(length(popu), horizon);
data_4_s = smooth_epidata(data_4, smooth_factor);
deaths_s = smooth_epidata(deaths, smooth_factor);
variant_projections;
pred_cases = infec_var + infec_nvar;

save us_forecasts_with_var;

%% Death Forecasts
dk = best_death_hyperparam(:, 1);
djp = best_death_hyperparam(:, 2);
dwin = best_death_hyperparam(:, 3);
lags = best_death_hyperparam(:, 4);
dalpha = 1;
dhorizon = 100;
T_full = size(data_4, 2);
base_deaths = deaths(:, T_full);
infec_data = [data_4_s pred_cases];
[death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin, 0, compute_region, lags);
[pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);

%%
infec_un_0 = pred_cases - data_4_s(:, end) + data_4(:, end);
deaths_un_0 = pred_deaths;
file_suffix = '0';
prefix = 'us';
file_prefix =  ['../results/forecasts/' prefix];
writetable(infec2table(pred_cases(:, 1:100), countries), [file_prefix '_forecasts_current_' file_suffix '.csv']);
writetable(infec2table(pred_deaths, countries), [file_prefix '_deaths_current_' file_suffix '.csv']);

add_to_history;
disp('Files Written');