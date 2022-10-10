%% Load prepped data
clear;
write_data = 1;
load flu_age_outcomes.mat;
load flu_age_outcomes_old.mat;
% addpath('../../scripts/');
%% death data
deaths = readtable('In-season-National-Burden.csv');
deaths = deaths(38:end,:);
[r, lags] = xcorr(deaths.incident_hosp,deaths.incident_death);
[M,I] = max(r);
lags_d = lags(I);
multiplier_T = deaths.incident_death./deaths.incident_hosp;
multiplier = [0.013 0.007537 0.02957 0.06647 0.0698;
    0.01036 0.0088496 0.03015 0.0577 0.10393;
    0.004198 0.0219 0.02873 0.04718 0.0922;
    0.007203 0.006079 0.026246 0.04808 0.09909
    0.0117 0.009479 0.032086 0.04668 0.13667];
multiplier = mean(multiplier,1);
%%
warning off;
popu = load('us_states_population_data.txt');
popu_ag = load('pop_by_age.csv'); %(0-4, 5-11, 12-17, 18-64, 65+)
popu_ag(2) = sum(popu_ag(2:3)); %5-17
popu_ag(3) = 0.6809*popu_ag(4); %18-49
popu_ag(4) = (1-0.6809)*popu_ag(4); %50-64
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end
%popu_ag = popu_ag./sum(popu_ag,2);

% popu_ag = sum(popu_ag,1);
% CDC_sero; %This gets the uncertainties

%%%% Date correction if the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% is to be done on a previous date %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
zero_date = datetime(2021, 9, 1);
now_date = datetime(2022,10,3);%datetime(now,'ConvertFrom','datenum')-1; %datetime(2021, 11, 21);
thisday = floor(days((now_date) - zero_date));%datetime(2020, 1, 23)));
orig_thisday = thisday;
ns = size(hosp_dat, 1);
data_4 = hosp_dat(:, 1:thisday,:);
%if the last hospitalization entry is zero, change it to 0.1 (SET I.C)
% for i =0:14
%     indx = data_4(:,end-i,:)==0;
%     data_4(indx(:,:,1),end-i,1) = 0.1;
%     data_4(indx(:,:,2),end-i,2) = 0.1;
%     data_4(indx(:,:,3),end-i,3) = 0.1;
%     data_4(indx(:,:,4),end-i,4) = 0.1;
%     data_4(indx(:,:,5),end-i,5) = 0.1;
% end
% % (j~=52 && j~=53 && j~=55 && j~=56)
% data_4([52 53 55 56],:,:) = 0;
% deaths = deaths(:, 1:thisday);
% hosp_data_limit = min([hosp_data_limit, thisday]);
hosp_cumu = cumsum(data_4,2,'omitnan');%hosp_cumu(:, 1:min([thisday size(hosp_cumu, 2)]));
hosp_cumu_s = nan(size(hosp_cumu));
for i = 1:size(hosp_cumu,3)
    xx = smooth_epidata(squeeze(hosp_cumu(:,:,i)), 1, 0, 1);
    hosp_cumu_s(:,:,i) = smooth_epidata(xx, 'csaps'); 
end
% hosp_cumu_s = hosp_cumu_s(:, 1:min([thisday size(hosp_cumu_s, 2)]));
%%
horizon = 42*7;

% un_list = [1 2 3];
rate_smooth = 28; % The death and hospitalizations will change slowly over these days
% hc_num = 18000000; % Number of health care workers ahead of age-groups

%%
smooth_factor = 14;
dhlags_list = 0:7:7*2;
%
% data_4_s = smooth_epidata(data_4, smooth_factor/2, 1, 1);
% deaths_s = smooth_epidata(deaths, smooth_factor, 1, 1);

%k_l = 2; jp_l = 7; alpha = 0.8;

best_hosp_hyperparam(:, 1) = 2;%4;
best_hosp_hyperparam(:, 2) = 7;
best_hosp_hyperparam(:, 3) = 75;
best_hosp_hyperparam(:, 4) = 2;

hk = best_hosp_hyperparam(:, 1);
hjp = best_hosp_hyperparam(:, 2);
hwin = best_hosp_hyperparam(:, 3);
hlags = best_hosp_hyperparam(:, 4);
halpha = 0.99; hhorizon = horizon + 28;

window_size = 40;

%%
% [X1, X2, X3, X4, X5, X6, X7] = ndgrid(rlag_list);
% scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:) X6(:) X7(:)];
% size(scen_list)
num_dh_rates_sample = 3;
rlags = [0 7];% 7];
rlag_list = 1:length(rlags);

un_array = popu*0 + [50 75 100 125 150];
un_list = [1 2 3 4 5];
% halpha_list = 0.9:0.02:0.98;
shifts = [0]; %[0 3*7 -10*7 -5*7]; %Based on Ausie data & a zero value
past_seasons = 0:4; %0 is for 2021-22. and 1 to 5 is for 2019 to 2015 seasons (We can choose less)

%Still need to add: Passed seasons, and the shift
[X1, X2, X3, X4] = ndgrid(un_list, rlag_list,past_seasons,shifts);%, halpha_list);, X3]
scen_list = [X1(:), X2(:), X3(:), X4(:)];
% nb_of_samples = 3;
%% Hosp rate if needed (2010-2020, yearxage)
base_hosp_rate = [0.0070 0.0027 0.0056 0.0106 0.0909];
base_hosp_rate = repmat(base_hosp_rate,56,1,horizon);
base_hosp_rate = permute(base_hosp_rate,[1 3 2]);
%% vaccine coverage
%sep1st -> oct1st
prev_cov = repmat(vacc_cov(:,1,:),1,30,1);
vacc_cov = cat(2,prev_cov,vacc_cov);
days_missing = size(data_4,2) - size(vacc_cov,2);
next_cov = repmat(vacc_cov(:,end,:),1,days_missing,1);
vacc_cov = cat(2,vacc_cov,next_cov);
%Fill nan states with mean states
avg_cov = nanmean(vacc_cov,1);
vacc_cov(26,:,:) = avg_cov;
vacc_cov(9,:,4:5) = avg_cov(:,:,4:5);
vacc_cov(35,:,5) = avg_cov(:,:,5);
vacc_cov(43,:,5) = avg_cov(:,:,5);
vacc_cov(46,:,5) = avg_cov(:,:,5);
nans = isnan(vacc_cov(:,1,1));
vacc_cov(nans,:,:) = repmat(avg_cov,sum(nans),1,1);

% vacc_cov(:,end+1,:) = vacc_cov(:,end,:);%?comment
% diffed = diff(vacc_cov,2);
% vacc_cov = max(diffed,0);
%% Max peaks for thresholding bad simulations
max_peaks = zeros(ns, 1);
for j = 1:ns
    xx = sum(hosp_dat_old(:, j, :, :), 4);
    max_peaks(j) = max(xx(:));
end

%%
parpool(32);
pctRunOnAll warning('off', 'all');

%%
high_VE(:) = 0.6;
low_VE(:) = 0.3;

%% A
tic;
T = thisday; %+1?
disp('Executing Scenario A');

vacc_ag = vacc_A_B;
vacc_effi = high_VE;
M0 = 0.33;

flu_scenario_simulator;

% net_infec_A = net_infec_0;
net_death_A = net_death_0;
net_hosp_A = net_hosp_0;

% new_infec_ag_A = new_infec_ag_0;
new_death_ag_A = new_death_ag_0;
new_hosp_ag_A = new_hosp_ag_0;
toc;

%% B
tic;
T = thisday; %+1?
disp('Executing Scenario B');

vacc_ag = vacc_A_B;
vacc_effi = high_VE;
M0 = 0.165;

flu_scenario_simulator;

% net_infec_A = net_infec_0;
net_death_B = net_death_0;
net_hosp_B = net_hosp_0;

% new_infec_ag_A = new_infec_ag_0;
new_death_ag_B = new_death_ag_0;
new_hosp_ag_B = new_hosp_ag_0;
toc;

%% C
tic;
T = thisday; %+1?
disp('Executing Scenario C');

vacc_ag = vacc_C_D;
vacc_effi = low_VE;
M0 = 0.33;

flu_scenario_simulator;

% net_infec_A = net_infec_0;
net_death_C = net_death_0;
net_hosp_C = net_hosp_0;

% new_infec_ag_A = new_infec_ag_0;
new_death_ag_C = new_death_ag_0;
new_hosp_ag_C = new_hosp_ag_0;
toc;

%% D
tic;
T = thisday; %+1?
disp('Executing Scenario D');

vacc_ag = vacc_C_D;
vacc_effi = low_VE;
M0 = 0.165;

flu_scenario_simulator;

% net_infec_A = net_infec_0;
net_death_D = net_death_0;
net_hosp_D = net_hosp_0;

% new_infec_ag_A = new_infec_ag_0;
new_death_ag_D = new_death_ag_0;
new_hosp_ag_D = new_hosp_ag_0;
toc;

%%
cid = 3;
tiledlayout(4, 1, 'TileSpacing','compact');

% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_A(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_A(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :, :), [1 3]))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_A(:, cid, :), 2))')); hold off

% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_B(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_B(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :, :), [1 3]))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_B(:, cid, :), 2))')); hold off

% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_C(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_C(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :, :), [1 3]))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_C(:, cid, :), 2))')); hold off

% nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_D(:, cid, :), 2))')); hold off
% nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_D(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :, :), [1 3]))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_D(:, cid, :), 2))')); hold off


%% Prepare quantiles
quants = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
scen_ids = {'A'; 'B'; 'C'; 'D'};
dat_type = {'hosp';'death'};
scen_names = {'highVac_optImm'; 'highVac_pesImm'; 'lowVac_optImm'; 'lowVac_pesImm'};
all_quant_diff = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), horizon/7,length(age_groups));
all_mean_diff = zeros(length(scen_ids), length(dat_type), length(popu), horizon/7,length(age_groups));
all_quant_cum = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), horizon/7,length(age_groups));
all_mean_cum = zeros(length(scen_ids), length(dat_type), length(popu), horizon/7,length(age_groups));

all_quant_diff_T = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), horizon/7);
all_mean_diff_T = zeros(length(scen_ids), length(dat_type), length(popu), horizon/7);
all_quant_cum_T = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), horizon/7);
all_mean_cum_T = zeros(length(scen_ids), length(dat_type), length(popu), horizon/7);

all_run_states = zeros(length(scen_ids), length(dat_type), length(popu), size(net_hosp_A, 1), horizon/7, length(age_groups));

season_peaks = nan(length(scen_ids), length(dat_type), size(new_hosp_ag_0,1),length(popu));
season_peaks_US = nan(length(scen_ids), length(dat_type), size(new_hosp_ag_0,1));

for ss = 1:length(scen_ids)
    for dt = 1:length(dat_type)
        %         net_dat = eval(['net_' dat_type{dt} '_' scen_ids{ss}]);
        new_dat = eval(['new_' dat_type{dt} '_ag_' scen_ids{ss}]);
        net_dat = sum(new_dat,4);%cumsum(sum(new_dat,4),3);
        if dt == 1
            dat_US = squeeze(nansum(net_dat,2));
            dat_US = dat_US(:, 1: 7 : horizon,:) + dat_US(:, 2: 7 : horizon,:)+ dat_US(:, 3: 7 : horizon,:)+ dat_US(:, 4: 7 : horizon,:)+ dat_US(:, 5: 7 : horizon,:)+ dat_US(:, 6: 7 : horizon,:)+ dat_US(:, 7: 7 : horizon,:);
            [M,I] = max(dat_US,[],2);
            season_peaks_US(ss,dt,:) = I;
        end

        for cid = 1:length(popu)
            thisdata = squeeze(new_dat(:, cid, :,:));
            thisdata_T = squeeze(net_dat(:, cid, :));

            max_peaks = squeeze(max(sum(thisdata, 3), [], 2));
            prev_peaks = max(diff(sum(hosp_cumu_s(cid, :, :), [1 3]), 1, 2), [], 2);
            bad_sims = max_peaks > 400*prev_peaks | max_peaks < prev_peaks/400;
            thisdata(bad_sims, :, :) = nan;
            thisdata_T(bad_sims, :) = nan;

            if all(isnan(thisdata_T))
                fprintf('No result for %s in sceanrio %s\n', abvs{cid}, scen_ids{ss});
                continue;
            end
            if dt == 1
                base_val = zeros(1,1,5);%data_4(cid, thisday,:);
                base_val_T = 0;%nansum(data_4,3);
                %Change to weekly data
                diffdata = thisdata(:, 1: 7 : horizon,:) + thisdata(:, 2: 7 : horizon,:)+ thisdata(:, 3: 7 : horizon,:)+ thisdata(:, 4: 7 : horizon,:)+ thisdata(:, 5: 7 : horizon,:)+ thisdata(:, 6: 7 : horizon,:)+ thisdata(:, 7: 7 : horizon,:);
                diffdata_T = thisdata_T(:, 1: 7 : horizon,:) + thisdata_T(:, 2: 7 : horizon,:)+ thisdata_T(:, 3: 7 : horizon,:)+ thisdata_T(:, 4: 7 : horizon,:)+ thisdata_T(:, 5: 7 : horizon,:)+ thisdata_T(:, 6: 7 : horizon,:)+ thisdata_T(:, 7: 7 : horizon,:);
                %                 diffdata = diff(thisdata(:, 1: 7 : horizon), 1, 2);
                thisdata = repmat(base_val, [size(thisdata, 1) 1]) + cumsum(diffdata, 2);
                thisdata_T = repmat(base_val_T, [size(thisdata_T, 1) 1]) + cumsum(diffdata_T, 2);
            elseif dt == 2
                base_val = zeros(1,1,5);%deaths(cid, thisday,:);
                base_val_T = 0;%nansum(deaths,3);
                %Change to weekly data
                diffdata = thisdata(:, 1: 7 : horizon,:) + thisdata(:, 2: 7 : horizon,:)+ thisdata(:, 3: 7 : horizon,:)+ thisdata(:, 4: 7 : horizon,:)+ thisdata(:, 5: 7 : horizon,:)+ thisdata(:, 6: 7 : horizon,:)+ thisdata(:, 7: 7 : horizon,:);
                diffdata_T = thisdata_T(:, 1: 7 : horizon,:) + thisdata_T(:, 2: 7 : horizon,:)+ thisdata_T(:, 3: 7 : horizon,:)+ thisdata_T(:, 4: 7 : horizon,:)+ thisdata_T(:, 5: 7 : horizon,:)+ thisdata_T(:, 6: 7 : horizon,:)+ thisdata_T(:, 7: 7 : horizon,:);
                %                 diffdata = diff(thisdata(:, 1: 7 : horizon), 1, 2);
                thisdata = repmat(base_val, [size(thisdata, 1) 1]) + cumsum(diffdata, 2);
                thisdata_T = repmat(base_val_T, [size(thisdata_T, 1) 1]) + cumsum(diffdata_T, 2);
                %             else
                %                 base_val = 0*hosp_cumu(cid, thisday);
                %                 thisdata = thisdata(:, 7:7:horizon);
                %                 diffdata = diff([repmat(base_val, [size(thisdata, 1) 1]), thisdata], 1, 2);
            end

            if dt==1
                [M,I] = max(diffdata_T,[],2);
                season_peaks(ss,dt,:,cid) = I;
            end

            all_run_states(ss, dt, cid, :, :, :) = diffdata;

            all_quant_diff(ss, dt, cid, :, :,:) = quantile(diffdata, quants);
            all_quant_cum(ss, dt, cid, :, :,:) = quantile(thisdata, quants);
            all_mean_diff(ss, dt, cid, :,:) = median(diffdata, 1, 'omitnan');
            all_mean_cum(ss, dt, cid, :,:) = median(thisdata, 1, 'omitnan');

            all_quant_diff_T(ss, dt, cid, :, :) = quantile(diffdata_T, quants);
            all_quant_cum_T(ss, dt, cid, :, :) = quantile(thisdata_T, quants);
            all_mean_diff_T(ss, dt, cid, :) = median(diffdata_T, 1, 'omitnan');
            all_mean_cum_T(ss, dt, cid, :) = median(thisdata_T, 1, 'omitnan');
        end
    end
end

%% find cumilative probabilities for seasonal targets
season_peaks_p  = nan(length(scen_ids), 1, length(popu),horizon/7);
season_peaks_US_p = nan(length(scen_ids), 1, horizon/7);
for ss = 1:length(scen_ids)
    for dt = 1:length(dat_type)-1
        %for g= 1:length(age_groups)
        p = histogram(season_peaks_US(ss,dt,:),horizon/7,'Normalization','cdf');
        season_peaks_US_p(ss,dt,:) =p.Values;
        for cid = 1:length(popu)
            p = histogram(season_peaks(ss,dt,:,cid),horizon/7,'Normalization','cdf');
            season_peaks_p(ss,dt,cid,:) =p.Values;
        end
        % end
    end
end

% all_quant_vals(isnan(all_quant_vals)) = 0;
% all_mean_vals(isnan(all_mean_vals)) = 0;

%% Quant plots
%cid = popu>-1;
cid = 3;
quant_show = [2 7 12 17 22];
xvals = size(hosp_cumu(cid, 1:7:end, :), 2):size(hosp_cumu(cid, 1:7:end, :), 2)+size(all_quant_diff, 5)-1;
tiledlayout(2, 2, 'TileSpacing','compact');

for ss=1:4
    nexttile; plot(zero_date + (1:7:size(hosp_cumu, 2)-7), squeeze(nansum(diff(hosp_cumu(cid, 1:7:end,:), 1, 2), [1 3]))); hold on;
         h = plot(zero_date + 7*xvals, squeeze(nansum(nansum(all_quant_diff(ss, 1, cid, quant_show, :,:), 3),6))'); hold on;
         plot(zero_date + 7*xvals, squeeze(nansum(nansum(all_mean_diff(ss, 1, cid,  :,:), 3),5))', 'o'); hold off;
    % plot( squeeze(nansum(nansum(all_mean_diff(ss, 1, cid, :,:), 3),5))'); hold off;

    %nexttile; %plot(squeeze(nansum(nansum(deaths(cid, 1:7:end,:), 1),3)));  hold on;
    %     plot(xvals, s queeze(nansum(nansum(all_quant_diff(ss, 2, cid, quant_show, :,:), 3),6))');hold on;
   %  plot(squeeze(nansum(nansum(all_mean_diff(ss, 2, cid, :,:), 3),5))'); hold off;

    %     nexttile; plot(diff(nansum(hosp_cumu(cid, 52:7:end), 1))); hold on;
    %     plot(xvals, squeeze(nansum(all_quant_diff(ss, 3, cid, quant_show, :), 3))'); hold on;
    %     plot(xvals, squeeze(nansum(all_mean_diff(ss, 3, cid, :), 3))'); hold off;
    ylim([0, 4000]);
    title(scen_names{ss}, 'interpreter', 'none');              
end

%% Save data
save ../../../../data_dumps/flu_round_1.mat

%% Create tables from the matrices

first_day_pred = 7;
age_groups(1) = {'0-4'};
age_groups(2) = {'5-17'};
age_groups(3) = {'18-49'};
age_groups(4) = {'50-64'};
age_groups(5) = {'65-130'};

%if write_data == 1
    disp('BY AGE GROUP');
    disp('creating inc quant table for states');
    T = table;
    scen_date = '2022-08-14';
    dt_name = {' hosp'};
    temp = all_quant_diff(:,1,:,:,:,:);
    thesevals = temp(:);
    [ss, dt, cid, qq, wh,ag] = ind2sub(size(temp), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T.scenario_name = scen_names(ss);
    T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    T.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    T.location = fips(cid)';
    T.type = repmat({'quantile'}, [length(thesevals) 1]);
    T.quantile = num2cell(quants(qq));
    %     T.sample = 1;
    T.value = compose('%g', round(thesevals, 1));
    T.age_group = age_groups(ag);

    disp('creating cum quant table for states');

    temp = all_quant_cum(:,1,:,:,:,:);
    thesevals = temp(:);
    Tc = T;
    Tc.value = compose('%g', round(thesevals, 1));
    Tc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    disp('creating inc mean table for states');

    Tm = table;
    temp = all_mean_diff(:,1,:,:,:);
    thesevals = temp(:);
    [ss, dt, cid, wh,ag] = ind2sub(size(temp), (1:length(thesevals))');
    Tm.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tm.scenario_name = scen_names(ss);
    Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    Tm.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Tm.location = fips(cid)';
    Tm.type = repmat({'point'}, [length(thesevals) 1]);
    Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Tm.value = compose('%g', round(thesevals, 1));
    Tm.age_group = age_groups(ag);

    disp('creating cum mean table for states');

    temp = all_mean_cum(:,1,:,:,:);
    thesevals = temp(:);
    Tmc = Tm;
    Tmc.value = compose('%g', round(thesevals, 1));
    Tmc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    % Repeat for US

    disp('creating inc quant table for US');

    us_all_quant_diff = squeeze(nansum(all_quant_diff, 3));
    us_all_mean_diff = squeeze(nansum(all_mean_diff, 3));
    us_all_quant_cum = squeeze(nansum(all_quant_cum, 3));
    us_all_mean_cum = squeeze(nansum(all_mean_cum, 3));

    us_T = table;
    dt_name = {' hosp'; ' death'};
    wh_string = sprintfc('%d', [1:max(wh)]');
    thesevals = us_all_quant_diff(:);
    [ss, dt, qq, wh,ag] = ind2sub(size(us_all_quant_diff), (1:length(thesevals))');
    us_T.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_T.scenario_name = scen_names(ss);
    us_T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_T.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_T.location = repmat({'US'}, [length(thesevals) 1]);
    us_T.type = repmat({'quantile'}, [length(thesevals) 1]);
    us_T.quantile = num2cell(quants(qq));
    us_T.value = compose('%g', round(thesevals, 1));
    us_T.age_group = age_groups(ag);

    disp('creating cum quant table for US');

    thesevals = us_all_quant_cum(:);
    us_Tc = us_T;
    us_Tc.value = compose('%g', round(thesevals, 1));
    us_Tc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    disp('creating inc mean table for US');

    us_Tm = table;
    thesevals = us_all_mean_diff(:);
    [ss, dt, wh,ag] = ind2sub(size(us_all_mean_diff), (1:length(thesevals))');
    us_Tm.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Tm.scenario_name = scen_names(ss);
    us_Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_Tm.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Tm.location = repmat({'US'}, [length(thesevals) 1]);
    us_Tm.type = repmat({'point'}, [length(thesevals) 1]);
    us_Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    us_Tm.value = compose('%g', round(thesevals, 1));
    us_Tm.age_group = age_groups(ag);

    disp('creating cum mean table for US');

    thesevals = us_all_mean_cum(:);
    us_Tmc = us_Tm;
    us_Tmc.value = compose('%g', round(thesevals, 1));
    us_Tmc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    %%%%%%%%%%%%%Repeat for cumilative age groups

    disp('BY CUM AGE GROUPS');
    disp('creating inc quant table for states');
    Tt = table;
    scen_date = '2022-08-14';
    dt_name = {' hosp'};
    temp = all_quant_diff_T(:,1,:,:,:);
    thesevals = temp(:);
    [ss, dt, cid, qq, wh] = ind2sub(size(temp), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    Tt.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tt.scenario_name = scen_names(ss);
    Tt.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Tt.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    Tt.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Tt.location = fips(cid)';
    Tt.type = repmat({'quantile'}, [length(thesevals) 1]);
    Tt.quantile = num2cell(quants(qq));
    %     T.sample = 1;
    Tt.value = compose('%g', round(thesevals, 1));
    Tt.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('creating cum quant table for states');

    temp = all_quant_cum_T(:,1,:,:,:);
    thesevals = temp(:);
    Tct = Tt;
    Tct.value = compose('%g', round(thesevals, 1));
    Tct.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    disp('creating inc mean table for states');

    Tmt = table;
    temp = all_mean_diff_T(:,1,:,:);
    thesevals = temp(:);
    [ss, dt, cid, wh] = ind2sub(size(temp), (1:length(thesevals))');
    Tmt.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tmt.scenario_name = scen_names(ss);
    Tmt.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Tmt.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    Tmt.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Tmt.location = fips(cid)';
    Tmt.type = repmat({'point'}, [length(thesevals) 1]);
    Tmt.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Tmt.value = compose('%g', round(thesevals, 1));
    Tmt.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('creating cum mean table for states');

    temp = all_mean_cum_T(:,1,:,:);
    thesevals = temp(:);
    Tmct = Tmt;
    Tmct.value = compose('%g', round(thesevals, 1));
    Tmct.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    % Repeat for US

    disp('creating inc quant table for US');

    us_all_quant_diff_T = squeeze(nansum(all_quant_diff_T, 3));
    us_all_mean_diff_T = squeeze(nansum(all_mean_diff_T, 3));
    us_all_quant_cum_T = squeeze(nansum(all_quant_cum_T, 3));
    us_all_mean_cum_T = squeeze(nansum(all_mean_cum_T, 3));

    us_Tt = table;
    dt_name = {' hosp'; ' death'};
    wh_string = sprintfc('%d', [1:max(wh)]');
    thesevals = us_all_quant_diff_T(:);
    [ss, dt, qq, wh] = ind2sub(size(us_all_quant_diff_T), (1:length(thesevals))');
    us_Tt.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Tt.scenario_name = scen_names(ss);
    us_Tt.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Tt.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_Tt.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Tt.location = repmat({'US'}, [length(thesevals) 1]);
    us_Tt.type = repmat({'quantile'}, [length(thesevals) 1]);
    us_Tt.quantile = num2cell(quants(qq));
    us_Tt.value = compose('%g', round(thesevals, 1));
    us_Tt.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('creating cum quant table for US');

    thesevals = us_all_quant_cum_T(:);
    us_Tct = us_Tt;
    us_Tct.value = compose('%g', round(thesevals, 1));
    us_Tct.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    disp('creating inc mean table for US');

    us_Tmt = table;
    thesevals = us_all_mean_diff_T(:);
    [ss, dt, wh] = ind2sub(size(us_all_mean_diff_T), (1:length(thesevals))');
    us_Tmt.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Tmt.scenario_name = scen_names(ss);
    us_Tmt.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Tmt.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_Tmt.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Tmt.location = repmat({'US'}, [length(thesevals) 1]);
    us_Tmt.type = repmat({'point'}, [length(thesevals) 1]);
    us_Tmt.quantile = repmat({'NA'}, [length(thesevals) 1]);
    us_Tmt.value = compose('%g', round(thesevals, 1));
    us_Tmt.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('creating cum mean table for US');

    thesevals = us_all_mean_cum_T(:);
    us_Tmct = us_Tmt;
    us_Tmct.value = compose('%g', round(thesevals, 1));
    us_Tmct.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));

    %%%%%%%%%%%%%Seasonal targets

    disp('creating table for seasonal state targets')
    dt_name = {' peak time hosp'};
    Ts = table;
    thesevals = season_peaks_p(:);
    [ss, dt, cid, wh] = ind2sub(size(season_peaks_p), (1:length(thesevals))');
    Ts.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Ts.scenario_name = scen_names(ss);
    Ts.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Ts.target = strcat(wh_string(wh), ' wk ahead', dt_name(dt));
    Ts.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Ts.location = fips(cid)';
    Ts.type = repmat({'point'}, [length(thesevals) 1]);
    Ts.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Ts.value = compose('%g', round(thesevals, 1));
    Ts.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('creating table for seasonal US targets')
    us_Ts = table;
    thesevals = season_peaks_US_p(:);
    [ss, dt, wh] = ind2sub(size(season_peaks_US_p), (1:length(thesevals))');
    us_Ts.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Ts.scenario_name = scen_names(ss);
    us_Ts.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Ts.target = strcat(wh_string(wh), ' wk ahead', dt_name(dt));
    us_Ts.target_end_date = datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Ts.location = repmat({'US'}, [length(thesevals) 1]);
    us_Ts.type = repmat({'point'}, [length(thesevals) 1]);
    us_Ts.quantile = repmat({'NA'}, [length(thesevals) 1]);
    us_Ts.value = compose('%g', round(thesevals, 1));
    us_Ts.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('peak size hosp for each state')
    temp = max(sum(all_quant_diff(:,1,:,:,:,:),6),[],5);
    dt_name = {'peak size hosp'};
    Tp = table;
    thesevals = temp(:);
    [ss, dt, cid, qq] = ind2sub(size(temp), (1:length(thesevals))');
    Tp.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tp.scenario_name = scen_names(ss);
    Tp.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Tp.target = dt_name(dt);%strcat(wh_string(wh), ' wk ahead', dt_name(dt));
    Tp.target_end_date = repmat("NA", [length(thesevals) 1]);%datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Tp.location = fips(cid)';
    Tp.type = repmat({'quantile'}, [length(thesevals) 1]);
    Tp.quantile = num2cell(quants(qq));
    Tp.value = compose('%g', round(thesevals, 1));
    Tp.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('peak size hosp for US')
    temp = max(sum(us_all_quant_diff(:,1,:,:,:),5),[],4);
    dt_name = {'peak size hosp'};
    us_Tp = table;
    thesevals = temp(:);
    [ss, dt, qq, wh] = ind2sub(size(temp), (1:length(thesevals))');
    us_Tp.model_projection_date = repmat({datestr(datetime(2021, 9, 1)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Tp.scenario_name = scen_names(ss);
    us_Tp.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Tp.target = dt_name(dt);%strcat(wh_string(wh), ' wk ahead', dt_name(dt));
    us_Tp.target_end_date = repmat("NA", [length(thesevals) 1]);%datestr(size(data_4, 2)+datetime(2021, 9, 1)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Tp.location = repmat({'US'}, [length(thesevals) 1]);
    us_Tp.type = repmat({'quantile'}, [length(thesevals) 1]);
    us_Tp.quantile = num2cell(quants(qq));
    us_Tp.value = compose('%g', round(thesevals, 1));
    us_Tp.age_group = repmat({'0-130'}, [length(thesevals) 1]);

    disp('Creating combined table');

    full_T = [T; Tc; Tm; Tmc; us_T; us_Tc; us_Tm; us_Tmc; Ts; us_Ts; Tt; Tct; Tmt; Tmct; us_Tt; us_Tct; us_Tmt; us_Tmc; Tp; us_Tp];

    %     full_T(contains(full_T.target, '27 wk'), :) = [];
    %     full_T(contains(full_T.target, '28 wk'), :) = [];
    %     nanidx = (strcmpi(full_T.value, 'NaN'));
    %     full_T(nanidx, :) = [];
    %%
    % Write files on disk
    disp('Writing File');
    tic;
    writetable(full_T, ['../../../../data_dumps/' datestr(now_date, 'YYYY-mm-DD') '-USC-SIkJalpha.csv']);
    toc

%end

