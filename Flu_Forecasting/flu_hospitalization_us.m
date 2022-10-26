addpath('../utils/');
addpath('..');
warning off
% Get from 
% https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state-timeseries
%sel_url = 'https://healthdata.gov/sites/default/files/reported_hospital_utilization_timeseries_20210306_1105.csv';
sel_url = 'https://healthdata.gov/api/views/g62h-syeh/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
hosp_tab = readtable('dummy.csv');


%% Convert hospital data to ReCOVER format
abvs = readcell('us_states_abbr_list.txt');
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
zero_date = datetime(2021, 9, 1);
all_days = days(datetime(hosp_tab.date, 'InputFormat', 'yyyy/MM/dd') - zero_date);
bad_idx = all_days <= 0;
hosp_tab(bad_idx, :) = [];
all_days = all_days(~bad_idx);

ns = length(abvs);
maxt = max(all_days);
fips = cell(ns, 1);
hosp_dat = nan(ns, maxt);
hosp_cov = nan(ns, maxt);

for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end
%%
for idx = 1:size(hosp_tab, 1)
    
    cid = find(strcmp(abvs, hosp_tab.state(idx)));
    if isempty(cid)
        disp(['Error at ' num2str(idx)]);
    end

    date_idx = all_days(idx);
    
    hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_influenza_confirmed(idx);
    hosp_cov(cid, date_idx) = hosp_tab.previous_day_admission_influenza_confirmed_coverage(idx);
end

%% Cumulative hospitalizations
T_full = max(find(any(~isnan(hosp_dat), 1)));
hosp_cumu = cumsum(nan2zero(hosp_dat), 2);
hosp_data_limit = T_full;
%% Load population data
popu = load('us_states_population_data.txt');

%%
smooth_factor = 1;
hosp_cumu_s = smooth_epidata(cumsum(hosp_dat(:, 1:T_full).*hosp_cov(:, T_full)./(hosp_cov(:,1:T_full)+ 1e-10), 2, 'omitnan'), smooth_factor, 0, 1);

%% Save data


save flu_hospitalization hosp_cumu hosp_cumu_s hosp_data_limit fips;

%%
num_dh_rates_sample = 3;
thisday = T_full;
horizon = 100;
ns = size(hosp_cumu_s, 1);

%%
num_dh_rates_sample = 5;
rlags = [0];
rlag_list = 1:length(rlags);
hk = 2; hjp = 7; halpha = 0.95;
un_array = popu*0 + [50 100 150];
un_list = size(un_array, 2);

[X1, X2] = ndgrid(un_list, rlag_list);
scen_list = [X1(:), X2(:)];
%%
tic;
net_hosp_A = zeros(size(scen_list,1)*num_dh_rates_sample, ns, horizon);
net_h_cell = cell(size(scen_list,1), 1);

base_hosp = hosp_cumu(:, T_full);
% if ~isempty(gcp('nocreate'))
%     pctRunOnAll warning('off', 'all')
% else
%     parpool;
%     pctRunOnAll warning('off', 'all')
% end

for simnum = 1:size(scen_list, 1)
    rrl = rlags(scen_list(simnum, 2));
    un = un_array(:, scen_list(simnum, 1));
    
    [hosp_rate, fC, ci_h] = var_ind_beta_un(hosp_cumu_s(:, 1:end-rrl), 0, halpha, hk, un, popu, hjp, 0.95);
    temp_res = zeros(num_dh_rates_sample, ns, horizon);
    for rr = 1:num_dh_rates_sample
        this_rate = hosp_rate;
        
        if rr ~= (num_dh_rates_sample + 1)/2
            for cid=1:ns
                
                this_rate{cid} = ci_h{cid}(:, 1) + (ci_h{cid}(:, 2) - ci_h{cid}(:, 1))*(rr-1)/(num_dh_rates_sample-1);
                
            end
        end

        [pred_hosps] = var_simulate_pred_un(hosp_cumu_s, 0, this_rate, popu, hk, horizon, hjp, un, base_hosp);

        h_start = maxt-T_full+1;
        temp_res(rr, :, :) = pred_hosps(:, h_start:h_start+horizon-1) - base_hosp;
    end
    net_h_cell{simnum} = temp_res;
    fprintf('.');
end

for simnum = 1:size(scen_list, 1)
    idx = simnum+[0:num_dh_rates_sample-1]*size(scen_list, 1);
    net_hosp_A(idx, :, :) = net_h_cell{simnum};
end
clear net_*_cell
fprintf('\n');
fprintf('\n');
toc

%% Generate quantiles
num_ahead = 35;

quant_deaths = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
quant_preds_deaths = zeros(length(popu), floor((num_ahead-1)/7), length(quant_deaths));
mean_preds_deaths = squeeze(trimmean(diff(net_hosp_A(:, :, 1:7:num_ahead), 1, 3), 0.95, 1));

med_idx_d  = find(abs(quant_deaths-0.5)<0.001);


for cid = 1:length(popu)
    
    thisdata = squeeze(net_hosp_A(:, cid, :));
    thisdata(all(thisdata==0, 2), :) = [];
    thisdata = diff(thisdata(:, 1:7:num_ahead)')';
     dt = hosp_cumu; gt_lidx = size(dt, 2); 
    %extern_dat = diff(dt(cid, gt_lidx-35:7:gt_lidx))';
    extern_dat = diff(hosp_cumu(cid, gt_lidx-35:7:gt_lidx)') - diff(hosp_cumu_s(cid, gt_lidx-35:7:gt_lidx)');
    % [~, midx] = max(extern_dat); extern_dat(midx) = [];
    extern_dat = extern_dat - mean(extern_dat) + mean_preds_deaths(cid, :);
    thisdata = [thisdata; repmat(extern_dat, [3 1])];    
    quant_preds_deaths(cid, :, :) = movmean(quantile(thisdata, quant_deaths)', 1, 1);
end
quant_preds_deaths = 0.5*(quant_preds_deaths+abs(quant_preds_deaths));



%% Plot
cidx = 1:56;
sel_idx = 11; %sel_idx = contains(abvs, 'MA');
dt = hosp_cumu(cidx, :);
dts = hosp_cumu_s(cidx, :);
thisquant = squeeze(nansum(quant_preds_deaths(sel_idx, :, [1 3 7 17 21 23]), 1))*100000/sum(popu(sel_idx));
thismean = (nansum(mean_preds_deaths(sel_idx, :), 1))*100000/sum(popu(sel_idx));
gt_len = 25;
gt_lidx = size(dt, 2); gt_idx = (gt_lidx-gt_len*7:7:gt_lidx);
thisdate = zero_date + gt_lidx;
gt = diff(nansum(dt(sel_idx, gt_idx), 1))';
gts = diff(nansum(dts(sel_idx, gt_idx), 1))';

plot((thisdate-gt_len*7+7):7:thisdate, [gt gts]*100000/sum(popu(sel_idx))); hold on;
plot(thisdate+7:7:thisdate+7*size(thisquant, 1), [thisquant]); hold on;
plot(thisdate+7:7:thisdate+7*size(thisquant, 1),  [thismean], 'o'); hold off;

if length(sel_idx) == 1
    title(['Hospitalizations ' abvs{sel_idx}]);
else
    title(['Hospitalizations US national-level']);
end

%% Date correction
now_date = datetime((now),'ConvertFrom','datenum');
now_days = floor(days(now_date - zero_date));
if thisday < now_days
    disp('Correcting dates'); disp('WARNING: This simply displaces the forecasts along time axis');
    thisday = now_days;
end
%%
Ti = table;
thesevals = quant_preds_deaths(:);
[cid, wh, qq] = ind2sub(size(quant_preds_deaths), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
Ti.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
Ti.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
Ti.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
Ti.location = fips(cid);
Ti.type = repmat({'quantile'}, [length(thesevals) 1]);
Ti.quantile = num2cell(quant_deaths(qq));
Ti.value = compose('%g', round(thesevals, 1));
%%

Tm = table;
thesevals = mean_preds_deaths(:);
[cid, wh] = ind2sub(size(mean_preds_deaths), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
Tm.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
Tm.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
Tm.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
Tm.location = fips(cid);
Tm.type = repmat({'point'}, [length(thesevals) 1]);
Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
Tm.value = compose('%g', round(thesevals, 1));

T_all = [Ti; Tm];
%%
Ti = table;
us_quants = sum(quant_preds_deaths, 1);
thesevals = us_quants(:);
[cid, wh, qq] = ind2sub(size(us_quants), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
Ti.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
Ti.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
Ti.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
Ti.location = repmat({'US'}, [length(thesevals) 1]);
Ti.type = repmat({'quantile'}, [length(thesevals) 1]);
Ti.quantile = num2cell(quant_deaths(qq));
Ti.value = compose('%g', round(thesevals, 1));
%%

Tm = table;
us_mean = sum(mean_preds_deaths, 1);
thesevals = us_mean(:);
[cid, wh] = ind2sub(size(us_mean), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
Tm.forecast_date = repmat({datestr(zero_date+thisday+1, 'YYYY-mm-DD')}, [length(thesevals) 1]);
Tm.target = strcat(wh_string(wh), ' wk ahead inc flu hosp');
Tm.target_end_date = datestr(thisday+zero_date + 6 + 7*(wh-1), 'YYYY-mm-DD');
Tm.location = repmat({'US'}, [length(thesevals) 1]);
Tm.type = repmat({'point'}, [length(thesevals) 1]);
Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
Tm.value = compose('%g', round(thesevals, 1));

T_all = [T_all; Ti; Tm];
%% Write file
bad_idx = ismember(T_all.location, {'60', '66', '69'});
T_all(bad_idx, :) = [];
pathname = '.';
thisdate = datestr(zero_date+thisday+1, 'yyyy-mm-dd');
fullpath = [pathname];
writetable(T_all, [fullpath '/' thisdate '-SGroup-SIkJalpha.csv']);