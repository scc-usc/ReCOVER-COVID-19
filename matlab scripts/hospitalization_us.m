addpath('./utils/');
addpath('./scenario_projections/');
% Get from 
% https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state-timeseries
%sel_url = 'https://healthdata.gov/sites/default/files/reported_hospital_utilization_timeseries_20210306_1105.csv';
sel_url = 'https://healthdata.gov/api/views/g62h-syeh/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
hosp_tab = readtable('dummy.csv');
%% Load case data
prefix = 'us';

%%%%%%%% Choose a date or selcect current date
%now_date = datetime(2021, 1, 3);
now_date = datetime((now),'ConvertFrom','datenum'); % 'TimeZone', 'America/Los_Angeles');
%%%%%%%%%%%%%%%%%%%%%%%%%

daynum = floor(days((now_date) - datetime(2020, 1, 23)));

path = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [path dirname];      
xx = readtable([fullpath '/' prefix '_data.csv']); data_4 = table2array(xx(2:end, 3:end));
lcorrection = daynum - size(data_4, 2); data_4 = [zeros(size(data_4, 1), lcorrection) data_4];

%% Convert hospital data to ReCOVER format
abvs = readcell('us_states_abbr_list.txt');
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
fips = cell(size(data_4, 1), 1);
hosp_dat = nan(size(data_4, 1), size(data_4, 2));
hosp_dat_p = nan(size(data_4, 1), size(data_4, 2));
hosp_dat_a = nan(size(data_4, 1), size(data_4, 2));

for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end

for idx = 1:size(hosp_tab, 1)
    
    cid = find(strcmp(abvs, hosp_tab.state(idx)));
    if isempty(cid)
        disp(['Error at ' num2str(idx)]);
    end
    date_idx = days(datetime(hosp_tab.date(idx), 'InputFormat', 'yyyy/MM/dd') - datetime(2020, 1, 23));
    
    if date_idx < 1
        continue;
    end
    
    hosp_dat_a(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx);
    hosp_dat_p(cid, date_idx) = hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
    hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_adult_covid_confirmed(idx) + hosp_tab.previous_day_admission_pediatric_covid_confirmed(idx);
end

%% Learn hospitalization rate like death forecasts
T_full = max(find(any(~isnan(hosp_dat), 1)));
maxt = size(data_4, 2);
%load us_hyperparam_latest.mat;
hosp_cumu = cumsum(nan2zero(hosp_dat), 2);
hosp_data_limit = T_full;
%% Load case forecasts
% dirname = datestr(datetime(2020, 1, 23)+caldays(maxt), 'yyyy-mm-dd');
% fullpath = [path dirname];      
% 
% xx = readtable([fullpath '/' prefix '_forecasts_cases.csv']); pred_cases = table2array(xx(2:end, 4:end));
%placenames = xx{2:end, 2};
popu = load('us_states_population_data.txt');
placenames = readcell('us_states_list.txt');
%% 
% CDC_sero;
% un = un_array(:, 2);

%%
smooth_factor = 14;
%data_4_s = smooth_epidata(data_4(:, :), smooth_factor/2, 0, 1);
hosp_cumu_s = smooth_epidata(hosp_cumu(:, 1:T_full), 1, 0, 1);


%% Save data

%un_list = [1 2 3];

save us_hospitalization hosp_cumu hosp_cumu_s hosp_data_limit fips;
 %%
load us_results.mat;
xx = load('variants.mat', 'lineages*');
omic_idx = find(contains(xx.lineages_f, 'BA'));
nl = length(xx.lineages_f);
%%

num_dh_rates_sample = 3;
num_wan = [1:2];
ag_wan_lb_list = repmat([0.5], [2 1]);
P_hosp = repmat([repmat([0.87], [2 1])], [1 1 nl]); P_hosp(:) = 0;
rel_lineage_rates = ones(nl, 1);
%rel_lineage_rates(omic_idx) = 0.3;
thisday = T_full;
horizon = 100;
ns = size(hosp_cumu_s, 1);

ag = 2;
hosp_cumu_ag = zeros(ns, thisday, 2);
hosp_cumu_ag(:, :, 1) = hosp_cumu_s;

%%
tic;
net_infec_A = net_infec_0;
net_hosp_A = zeros(size(net_infec_A, 1)*num_dh_rates_sample, size(data_4, 1), horizon);

if ~isempty(gcp('nocreate'))
    pctRunOnAll warning('off', 'all')
else
    parpool;
    pctRunOnAll warning('off', 'all')
end

parfor simnum = 1:size(net_infec_A, 1)
    deltemp = all_deltemps{simnum};
    immune_infec = all_immune_infecs{simnum};

    P = 1 - (1 - P_hosp)./(1 - 0.5);
    temp_res = zeros(num_dh_rates_sample, ns, horizon);

    T_full = hosp_data_limit;
    base_hosp = hosp_cumu(:, T_full);

    halpha = 0.95;
    rel_lineage_rates1 = repmat(rel_lineage_rates(:)', [ns 1]);
    
    [X, Y, Z, A, A1] = ndgrid([2:3], [1:3], [50], [0:2], [1]);
    param_list = [X(:), Y(:), Z(:), A(:), A1(:)];
    val_idx = (param_list(:, 1).*param_list(:, 2) <=28) & (param_list(:, 3) > param_list(:, 1).*param_list(:, 2)) & (param_list(:, 1) - param_list(:, 4))>0;
    param_list = param_list(val_idx, :);

    [best_death_hyperparam] = dh_age_hyper(deltemp, immune_infec, rel_lineage_rates1, P_hosp, hosp_cumu_ag(:, 1:thisday, :), thisday, 0, param_list, halpha);
    hk = best_death_hyperparam(:, 1); hjp = best_death_hyperparam(:, 2);
    hwin = best_death_hyperparam(:, 3); hlags = best_death_hyperparam(:, 4); rel_lineage_rates1(:, omic_idx) = repmat(best_death_hyperparam(:, 5), [1 length(omic_idx)]);
    
%    hk = 3; hjp = 1; hwin = 100; hlags = 0;
 
    
    [hosp_rate, ci_h, fC_h] = get_death_rates_escape(deltemp(:, :, 1:thisday, :), immune_infec(:, :, 1:thisday, :), rel_lineage_rates1, P, ...
        hosp_cumu_ag(:, 1:thisday, :),  halpha, hk, hjp, hwin, 0.95, popu>-1, hlags);

    for rr = 1:num_dh_rates_sample
        this_rate = hosp_rate;

        if rr ~= (num_dh_rates_sample + 1)/2
            for cid=1:ns
                for g=1:ag
                    this_rate{cid, g} = ci_h{cid, g}(:, 1) + (ci_h{cid, g}(:, 2) - ci_h{cid, g}(:, 1))*(rr-1)/(num_dh_rates_sample-1);
                end
            end
        end

        [pred_hosps, pred_new_hosps_ag] = simulate_deaths_escape(deltemp, immune_infec, rel_lineage_rates1, P, this_rate, hk, hjp, ...
            horizon, base_hosp, T_full-1);

        h_start = size(data_4, 2)-T_full+1;
        temp_res(rr, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
    end
    net_h_cell{simnum} = temp_res;
    fprintf('.');
end

for simnum = 1:size(net_infec_A, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(net_infec_A, 1);
    net_hosp_A(idx, :, :) = net_h_cell{simnum};
end
clear net_*_cell
fprintf('\n');
fprintf('\n');
toc

%% Clean bad simulations
for cid=1:length(popu)
    thisdata = net_hosp_A(:, cid, :);
    approx_target = interp1([1 2], [hosp_cumu_s(cid, end-1)-hosp_cumu_s(cid, end-2), hosp_cumu_s(cid, end) - hosp_cumu_s(cid, end-1)], 3, 'linear', 'extrap');
    bad_idx = abs(thisdata(:, 1)-0) < 0.3*approx_target;
    net_hosp_A(bad_idx, cid, :) = nan;
    bad_idx = abs(thisdata(:, 1)-0) > 2*approx_target;
    net_hosp_A(bad_idx, cid, :) = nan;

end

%% Generate quantiles
num_ahead = 99;
quant_hosp = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
quant_preds_hosp = zeros(length(popu), num_ahead, length(quant_hosp));
%mean_preds_hosp = zeros(length(popu), num_ahead);
%mean_preds_hosp = pred_new_hosps(:, 1:num_ahead);
mean_preds_hosp = squeeze(nanmean(diff(net_hosp_A(:, :, 1:num_ahead+1), 1, 3), 1));
med_idx  = find(abs(quant_hosp-0.5)<0.001);

T_corr = 0;

for cid = 1:length(popu)
    thisdata = squeeze(net_hosp_A(:, cid, 1:num_ahead-T_corr+1));
    thisdata = [repmat(hosp_dat(cid, end-T_corr+1:end), [size(net_hosp_A, 1) 1]), diff(thisdata, 1, 2)];
    thisdata(all(thisdata==0, 2), :) = [];
    dt = hosp_dat; gt_lidx = size(dt, 2); 
    
    extern_dat = (dt(cid, gt_lidx-14:gt_lidx))';
    extern_dat(isnan(extern_dat)) = [];
    extern_dat = extern_dat - mean(extern_dat) + mean_preds_hosp(cid, :);
    %thisdata = thisdata - mean(thisdata, 1);
    thisdata = [thisdata; extern_dat];
    
    quant_preds_hosp(cid, :, :) = quantile(thisdata(:, 1:num_ahead), quant_hosp)';

end
quant_preds_hosp = (quant_preds_hosp+abs(quant_preds_hosp))/2;
%% Plot
% plot((1:size(data_4, 2)), hosp_dat(cid, :)); hold on;
% plot((T_full+1:T_full+size(pred_new_hosps, 2)), pred_new_hosps(cid, :)); hold off;
dt = hosp_dat;
dt_s = [zeros(length(popu), 2) diff(hosp_cumu_s, 1, 2)];
sel_idx = 3; %sel_idx = contains(placenames, 'California');
thisquant = squeeze(nansum(quant_preds_hosp(sel_idx, :, [1 7 17 23]), 1));
mpred = (nansum(mean_preds_hosp(sel_idx, :), 1))';
gt_len = 400;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len:1:gt_lidx);
gt = nansum(dt(sel_idx, gt_idx), 1);
%gt_s = sum(dt_s(sel_idx, gt_idx), 1);
TT = datetime(2020, 1, 23) + T_full - gt_len + (1:1000);
plot(TT(1:length(gt)), [gt']); hold on; plot(TT(gt_len+1:gt_len+size(thisquant, 1)), [mpred thisquant]); hold off;
title(['Hospitalization ' placenames{sel_idx} ]);

%%
cidx = find(popu>-1);
hosp_vals = cell((1+length(quant_hosp))*(1+length(cidx))*num_ahead, 7);
kk = 1;
forecast_date = datestr(datetime(2020, 1, 23)+caldays(maxt), 'yyyy-mm-dd');

for ii = 1:length(cidx)
    for jj = 1:num_ahead
        target_date = datestr(datetime(2020, 1, 23)+caldays(maxt+jj), 'yyyy-mm-dd');
        thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc hosp']} {target_date} fips{cidx(ii)} {'point'} {'NA'} compose('%.1f', mean_preds_hosp(cidx(ii), jj))];
        hosp_vals(kk, :) = thisentry;
        
        hosp_vals(kk+1:kk+length(quant_hosp), 1) = mat2cell(repmat(forecast_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc hosp'], [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 3) = mat2cell(repmat(target_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 4) = mat2cell(repmat(fips{cidx(ii)}, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 5) = mat2cell(repmat('quantile', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 6) = compose('%g', quant_hosp(:));
        %hosp_vals(kk+1:kk+length(quant_hosp), 7) = mat2cell(squeeze(quant_preds_hosp(cidx(ii), jj, :)), ones(length(quant_hosp), 1));
        hosp_vals(kk+1:kk+length(quant_hosp), 7) = compose('%.1f', squeeze(quant_preds_hosp(cidx(ii), jj, :)));
        kk = kk+length(quant_hosp)+1;
    end
    fprintf('.');
end
%%
% Add US forecasts by combining states
for jj = 1:num_ahead
    target_date = datestr(datetime(2020, 1, 23)+caldays(maxt+jj), 'yyyy-mm-dd');
    thisentry = [{forecast_date} {[num2str(jj) ' day ahead inc hosp']} {target_date} {'US'} {'point'} {'NA'} compose('%.1f',nansum(mean_preds_hosp(cidx, jj)))];
    hosp_vals(kk, :) = thisentry;
    
    hosp_vals(kk+1:kk+length(quant_hosp), 1) = mat2cell(repmat(forecast_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 2) = mat2cell(repmat([num2str(jj) ' day ahead inc hosp'], [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 3) = mat2cell(repmat(target_date, [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 4) = mat2cell(repmat('US', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 5) = mat2cell(repmat('quantile', [length(quant_hosp) 1]), ones(length(quant_hosp), 1));
    hosp_vals(kk+1:kk+length(quant_hosp), 6) = compose('%g', quant_hosp(:));
    hosp_vals(kk+1:kk+length(quant_hosp), 7) = compose('%.1f', nansum(squeeze(quant_preds_hosp(cidx, jj, :)), 1)');
    kk = kk+length(quant_hosp)+1;
end

%% Write file

pathname = '../results/historical_forecasts/';
dirname = datestr(now_date, 'yyyy-mm-dd');
fullpath = [pathname dirname];
if ~exist(fullpath, 'dir')
    mkdir(fullpath);
end

hosp_vals((strcmpi(hosp_vals(:, 7), 'nan')), :) = [];
writecell(hosp_vals, [fullpath '/' prefix '_hosp_quants.csv']);