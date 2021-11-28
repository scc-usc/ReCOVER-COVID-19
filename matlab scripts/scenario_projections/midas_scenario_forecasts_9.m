%%% Scenario forecasts
clear;
write_data = 1;
addpath('../../scripts/');
%% Load baselines
warning off;
load latest_us_data.mat
load us_hyperparam_latest.mat
load us_hospitalization.mat
CDC_sero;

%%%% Date correction if the simulation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% is to be done on a previous date %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
now_date = datetime(2021, 09, 12);
thisday = floor(days((now_date) - datetime(2020, 1, 23)));
ns = size(data_4, 1);
data_4 = data_4(:, 1:thisday);
deaths = deaths(:, 1:thisday);
hosp_data_limit = min([hosp_data_limit, thisday]);
hosp_cumu = hosp_cumu(:, 1:min([thisday size(hosp_cumu, 2)]));
hosp_cumu_s = hosp_cumu_s(:, 1:min([thisday size(hosp_cumu_s, 2)]));

%%

un_list = [1 2 3];
rate_smooth = 28; % The death and hospitalizations will change slowly over these days
hc_num = 18000000; % Number of health care workers ahead of age-groups


%% Age-specific data and vaccine modeling;
vacc_download_age_state;
[vacc_given_by_age] = get_vacc_preds(vacc_num_age_est, pop_by_age, 200);

%%
horizon = 200;
smooth_factor = 14;
dhlags_list = 0:7:7*2;

data_4_s = smooth_epidata(data_4, smooth_factor/2, 1, 1);
deaths_s = smooth_epidata(deaths, smooth_factor/2, 1, 1);

k_l = 2; jp_l = 7; alpha = 0.9;
best_death_hyperparam(:, 1) = 5; 
best_death_hyperparam(:, 2) = 7;
best_death_hyperparam(:, 3) = 75;
best_death_hyperparam(:, 4) = 3;

best_hosp_hyperparam(:, 1) = 4;
best_hosp_hyperparam(:, 2) = 7;
best_hosp_hyperparam(:, 3) = 75;
best_hosp_hyperparam(:, 4) = 2;

dk = best_death_hyperparam(:, 1);
djp = best_death_hyperparam(:, 2);
dwin = best_death_hyperparam(:, 3);
dlags = best_death_hyperparam(:, 4);
dalpha = 0.9; dhorizon = horizon+28;

hk = best_hosp_hyperparam(:, 1);
hjp = best_hosp_hyperparam(:, 2);
hwin = best_hosp_hyperparam(:, 3);
hlags = best_hosp_hyperparam(:, 4);
halpha = 0.9; hhorizon = horizon + 28;


 %% variants data
 
 % Load and pad with an extra variant "wildcard"
xx = load('variants.mat', "var_frac_all*","lineages", 'valid_lins');
var_frac_all = padarray(xx.var_frac_all(:, :, 1:thisday), [0 1 0], 'post');
var_frac_all_low = padarray(xx.var_frac_all_low(:, :, 1:thisday), [0 1 0], 'post'); 
var_frac_all_low(var_frac_all_low < 0) = 0;
var_frac_all_high = padarray(xx.var_frac_all_high(:, :, 1:thisday), [0 1 0], 'post');
var_frac_all_high(var_frac_all_high>1) = 1;
lineages = [xx.lineages; {'wildcard'}];
valid_lins = padarray(xx.valid_lins, [0 1], 'post');

other_idx = find(strcmpi(lineages, 'other'));
b117_idx = find(strcmpi(lineages, 'B.1.1.7'));
delta_idx = find(strcmpi(lineages, 'B.1.617.2'));

delta_missing = valid_lins(:, delta_idx) < 1;

% Readjust bounds to focus on uncertainty in delta
xx = var_frac_all_low(:, delta_idx, :);
var_frac_all_low = var_frac_all.*(1 - xx)./(1 - var_frac_all(:, delta_idx, :));
var_frac_all_low(:, delta_idx, :) = xx;

xx = var_frac_all_high(:, delta_idx, :);
var_frac_all_high = var_frac_all.*(1 - xx)./(1 - var_frac_all(:, delta_idx, :));
var_frac_all_high(:, delta_idx, :) = xx;

% Readjust to include delta uncertainty where delta is not observed yet
xx = squeeze(var_frac_all_high(:, delta_idx, end));
xx(delta_missing) = Inf;
[~, cidx] = min(xx); xx = var_frac_all_high(cidx, delta_idx, :);
var_frac_all_high(delta_missing, :, :) = var_frac_all_high(delta_missing, :, :) ...
    .*(1 - xx);
var_frac_all_high(delta_missing, delta_idx, :) = repmat(xx, [sum(delta_missing), 1]);

var_prev_q = [1 2 3];
var_frac_all(isnan(var_frac_all)) = 0;
var_frac_all_low(isnan(var_frac_all_low)) = 0;
var_frac_all_high(isnan(var_frac_all_high)) = 0;
var_frac_range{1} = var_frac_all_low;
var_frac_range{2} = var_frac_all;
var_frac_range{3} = var_frac_all_high;

%%
% Reference Rt values for NPI

mob_data = readtable('cuebiq_mobility.csv');
[aa, bb] = ismember(mob_data.place_, countries);
cic = nan(length(popu), 1);
cic(bb) = mob_data.Openness;
bad_cic = isnan(cic) | cic < 0.1;
cic(bad_cic) = median(cic(~bad_cic));

Target_Rt = [cic]; %, cic+(1-cic)/4];  % openness
current_Rt = cic; 

Rt_final_scens = [1:size(Target_Rt, 2)];
Rt_init_scens = [1:size(current_Rt, 2)];
scenario_forecasts = 1;
rlag_list = [0 7 14];

%% age-group management

ag_case_frac = c_3d1;
ag_popu_frac = pop_by_age./sum(pop_by_age, 2);
pop_by_age = popu.*pop_by_age./sum(pop_by_age, 2);

data_4_ag = cumsum([zeros(ns, 1) diff(data_4_s, 1, 2)].*c_3d1, 2);
deaths_ag = cumsum([zeros(ns, 1) diff(deaths_s, 1, 2)].*d_3d1, 2);
hosp_cumu_ag = cumsum([zeros(ns, 1) diff(hosp_cumu_s, 1, 2)].*h_3d1, 2);

%% Waning possibilities: Taken from Round 8
num_wan = [1:4];
ag_wan_lb_list = [repmat([1 0.7 0.5 0.5], [4 1]); 1 0.35 0.25 0.25];
ag_wan_param_list = repmat([365*3 365 365*3 365], [5 1]);
P_list = [1 0.9 0.8 0.8];

%%
temp = nan(ns, 27); 
temp(:, 1) = un_array(:, 1);
temp(:, 27) = un_array(:, 3);
temp(:, 14) = un_array(:, 2);
temp = fillmissing(temp, 'linear', 2);
un_list = [1:27];
un_array = temp;

%% Prepare scenario list
[X1, X2, X3, X4, X5, X6] = ndgrid(un_list, [2], Rt_init_scens, Rt_final_scens, rlag_list, num_wan);
scen_list = [X1(:), X2(:), X3(:), X4(:), X5(:), X6(:)];

%% Scenario A. High Vaccination, Low transmission advantage
tic;
disp('Executing Scenario A');

vacc_effi1 = 0.35; vacc_effi2 = 0.85 - vacc_effi1;

%%%%%%%%%%%% Age 5-11 Future Vaccination %%%%%%%%%%%%%%%%%%%%%
vacc_ag = vacc_given_by_age;
child_vax_day = days(datetime(2021, 11, 1) - datetime(2020, 1, 23));
ref_day = days(datetime(2021, 05, 13) - datetime(2020, 1, 23));
tshift = child_vax_day - ref_day;
child_vax_ts = squeeze(vacc_ag(:, :, 2));
ref_ts = squeeze(vacc_ag(:, :, 3));
lb = squeeze(vacc_ag(:, end, 2))./pop_by_age(:, 2);
ub = squeeze(vacc_ag(:, end, 3))./pop_by_age(:, 3);
pop_rat = pop_by_age(:, 2)./pop_by_age(:, 3);
to_add = [zeros(ns,  tshift) (pop_rat.*(ub-lb).*ref_ts)];
child_vax_ts = child_vax_ts + to_add(:, 1: T+horizon);
vacc_ag(:, :, 2) = child_vax_ts;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Circulate a new variant %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wildcard_ad = 0;
external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

midas_scenario_simulator9;

net_infec_A = net_infec_0;
net_death_A = net_death_0;
net_hosp_A = net_hosp_0;

new_infec_ag_A = new_infec_ag_0;
new_death_ag_A = new_death_ag_0;
new_hosp_ag_A = new_hosp_ag_0;
toc;
%% Scenario B: High Vaccination, High transmission advantage

disp('Executing Scenario B');


vacc_effi1 = 0.35; vacc_effi2 = 0.85 - vacc_effi1;

%%%%%%%%%%% No new vaccines %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vacc_ag = vacc_given_by_age;
%%%%%%%%%%% Circulate a new variant %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wildcard_ad = 0;
external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

midas_scenario_simulator9;

net_infec_B = net_infec_0;
net_death_B = net_death_0;
net_hosp_B = net_hosp_0;

new_infec_ag_B = new_infec_ag_0;
new_death_ag_B = new_death_ag_0;
new_hosp_ag_B = new_hosp_ag_0;

%% Scenario C: Low Vaccination, Low transmission advantage

disp('Executing Scenario C');

vacc_effi1 = 0.35; vacc_effi2 = 0.85 - vacc_effi1;

%%%%%%%%%%%% Age 5-11 Future Vaccination %%%%%%%%%%%%%%%%%%%%%
vacc_ag = vacc_given_by_age;
child_vax_day = days(datetime(2021, 11, 1) - datetime(2020, 1, 23));
ref_day = days(datetime(2021, 05, 13) - datetime(2020, 1, 23));
tshift = child_vax_day - ref_day;
child_vax_ts = squeeze(vacc_ag(:, :, 2));
ref_ts = squeeze(vacc_ag(:, :, 3));
lb = squeeze(vacc_ag(:, end, 2))./pop_by_age(:, 2);
ub = squeeze(vacc_ag(:, end, 3))./pop_by_age(:, 3);
pop_rat = pop_by_age(:, 2)./pop_by_age(:, 3);
to_add = [zeros(ns,  tshift) (pop_rat.*(ub-lb).*ref_ts)];
child_vax_ts = child_vax_ts + to_add(:, 1: T+horizon);
vacc_ag(:, :, 2) = child_vax_ts;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Circulate a new variant %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wildcard_ad = 1.5;
external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
wildcard_day = days(datetime(2021, 11, 15) - datetime(2020, 1, 23)) - thisday;
external_infec_perc(:, length(lineages), wildcard_day-13:wildcard_day, :) = repmat(0.01/14:0.01/14:0.01, [ns 1 size(vacc_ag, 3)]);

midas_scenario_simulator9;

net_infec_C = net_infec_0;
net_death_C = net_death_0;
net_hosp_C = net_hosp_0;

new_infec_ag_C = new_infec_ag_0;
new_death_ag_C = new_death_ag_0;
new_hosp_ag_C = new_hosp_ag_0;
%% Scenario D: Low Vaccination & High transmission advantage

disp('Executing Scenario D');

vacc_effi1 = 0.35; vacc_effi2 = 0.85 - vacc_effi1;

vacc_ag = vacc_given_by_age;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%% Circulate a new variant %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
wildcard_ad = 1.5;
external_infec_perc = zeros(ns, length(lineages), horizon, size(vacc_ag, 3));
wildcard_day = days(datetime(2021, 11, 15) - datetime(2020, 1, 23)) - thisday;
external_infec_perc(:, length(lineages), wildcard_day-13:wildcard_day, :) = repmat(0.01/14:0.01/14:0.01, [ns 1 size(vacc_ag, 3)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

midas_scenario_simulator9;

net_infec_D = net_infec_0;
net_death_D = net_death_0;
net_hosp_D = net_hosp_0;

new_infec_ag_D = new_infec_ag_0;
new_death_ag_D = new_death_ag_0;
new_hosp_ag_D = new_hosp_ag_0;

%%
cid = 1:56;
tiledlayout(4, 3, 'TileSpacing','compact');

nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_A(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_A(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_A(:, cid, :), 2))')); hold off

nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_B(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_B(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_B(:, cid, :), 2))')); hold off

nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_C(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_C(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_C(:, cid, :), 2))')); hold off

nexttile; plot(diff(nansum(data_4(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_infec_D(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(deaths(cid, :), 1))); hold on; plot(size(deaths, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_death_D(:, cid, :), 2))')); hold off
nexttile; plot(diff(nansum(hosp_cumu(cid, :), 1))); hold on; plot(size(data_4, 2):size(data_4, 2)+horizon-2, diff(squeeze(nansum(net_hosp_D(:, cid, :), 2))')); hold off


%% Prepare quantiles
quants = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
scen_ids = {'A'; 'B'; 'C'; 'D'};
dat_type = {'infec'; 'death'; 'hosp'};
scen_names = {'ChildVax_noVar'; 'noChildVax_noVar'; 'ChildVax_Var'; 'noChildVax_Var'};
all_quant_diff = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), 26);
all_mean_diff = zeros(length(scen_ids), length(dat_type), length(popu), 26);
all_quant_cum = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), 26);
all_mean_cum = zeros(length(scen_ids), length(dat_type), length(popu), 26);

for ss = 1:length(scen_ids)
    for dt = 1:length(dat_type)
        net_dat = eval(['net_' dat_type{dt} '_' scen_ids{ss}]);
        for cid = 1:length(popu)
            thisdata = squeeze(net_dat(:, cid, :));
            
            if dt == 1
                base_val = data_4(cid, thisday);
                diffdata = diff(thisdata(:, 1: 7 : 7*26+1), 1, 2);
                thisdata = repmat(base_val, [size(thisdata, 1) 1]) + cumsum(diffdata, 2);
            elseif dt == 2
                base_val = deaths(cid, thisday);
                thisdata = thisdata(:, 7:7:26*7);
                diffdata = diff([repmat(base_val, [size(thisdata, 1) 1]), thisdata], 1, 2);
            else
                base_val = 0*hosp_cumu(cid, thisday);
                thisdata = thisdata(:, 7:7:26*7);
                diffdata = diff([repmat(base_val, [size(thisdata, 1) 1]), thisdata], 1, 2);
            end
            
            
            all_quant_diff(ss, dt, cid, :, :) = quantile(diffdata, quants);
            all_quant_cum(ss, dt, cid, :, :) = quantile(thisdata, quants);
            all_mean_diff(ss, dt, cid, :) = mean(diffdata, 1);
            all_mean_cum(ss, dt, cid, :) = mean(thisdata, 1);
        end
    end
end
% all_quant_vals(isnan(all_quant_vals)) = 0;
% all_mean_vals(isnan(all_mean_vals)) = 0;

%% Quant plots
%cid = popu>-1;
cid = 1:56;
quant_show = [1 7 12 17 23];
xvals = size(data_4(cid, 52:7:end), 2):size(data_4(cid, 52:7:end), 2)+size(all_quant_diff, 5)-1;
tiledlayout(4, 3, 'TileSpacing','compact');

for ss=1:4
    nexttile; plot(diff(nansum(data_4(cid, 52:7:end), 1))); hold on;
    plot(xvals, squeeze(nansum(all_quant_diff(ss, 1, cid, quant_show, :), 3))'); hold on;
    plot(xvals, squeeze(nansum(all_mean_diff(ss, 1, cid, :), 3))'); hold off;
        
    nexttile; plot(diff(nansum(deaths(cid, 52:7:end), 1))); hold on;
    plot(xvals, squeeze(nansum(all_quant_diff(ss, 2, cid, quant_show, :), 3))'); hold on;
    plot(xvals, squeeze(nansum(all_mean_diff(ss, 2, cid, :), 3))'); hold off;
    
    nexttile; plot(diff(nansum(hosp_cumu(cid, 52:7:end), 1))); hold on;
    plot(xvals, squeeze(nansum(all_quant_diff(ss, 3, cid, quant_show, :), 3))'); hold on;
    plot(xvals, squeeze(nansum(all_mean_diff(ss, 3, cid, :), 3))'); hold off;
end


%% Create tables from the matrices

first_day_pred = 7;

if write_data == 1
    disp('creating inc quant table for states');
    T = table;
    scen_date = '2021-09-14';
    dt_name = {' case'; ' death'; ' hosp'};
    thesevals = all_quant_diff(:);
    [ss, dt, cid, qq, wh] = ind2sub(size(all_quant_diff), (1:length(thesevals))');
    wh_string = sprintfc('%d', [1:max(wh)]');
    T.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    T.scenario_name = scen_names(ss);
    T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    T.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    T.location = fips(cid);
    T.type = repmat({'quantile'}, [length(thesevals) 1]);
    T.quantile = num2cell(quants(qq));
    T.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum quant table for states');
    
    thesevals = all_quant_cum(:);
    Tc = T;
    Tc.value = compose('%g', round(thesevals, 1));
    Tc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));
    
    disp('creating inc mean table for states');
    
    Tm = table;
    thesevals = all_mean_diff(:);
    [ss, dt, cid, wh] = ind2sub(size(all_mean_diff), (1:length(thesevals))');
    Tm.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tm.scenario_name = scen_names(ss);
    Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    Tm.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Tm.location = fips(cid);
    Tm.type = repmat({'point'}, [length(thesevals) 1]);
    Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Tm.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum mean table for states');
    
    thesevals = all_mean_cum(:);
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
    dt_name = {' case'; ' death'; ' hosp'};
    wh_string = sprintfc('%d', [1:max(wh)]');
    thesevals = us_all_quant_diff(:);
    [ss, dt, qq, wh] = ind2sub(size(us_all_quant_diff), (1:length(thesevals))');
    us_T.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_T.scenario_name = scen_names(ss);
    us_T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_T.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_T.location = repmat({'US'}, [length(thesevals) 1]);
    us_T.type = repmat({'quantile'}, [length(thesevals) 1]);
    us_T.quantile = num2cell(quants(qq));
    us_T.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum quant table for US');
    
    thesevals = us_all_quant_cum(:);
    us_Tc = us_T;
    us_Tc.value = compose('%g', round(thesevals, 1));
    us_Tc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));
    
    disp('creating inc mean table for US');
    
    us_Tm = table;
    thesevals = us_all_mean_diff(:);
    [ss, dt, wh] = ind2sub(size(us_all_mean_diff), (1:length(thesevals))');
    us_Tm.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Tm.scenario_name = scen_names(ss);
    us_Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_Tm.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Tm.location = repmat({'US'}, [length(thesevals) 1]);
    us_Tm.type = repmat({'point'}, [length(thesevals) 1]);
    us_Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    us_Tm.value = compose('%g', round(thesevals, 1));
    
    disp('creating cum mean table for US');
    
    thesevals = us_all_mean_cum(:);
    us_Tmc = us_Tm;
    us_Tmc.value = compose('%g', round(thesevals, 1));
    us_Tmc.target = strcat(wh_string(wh), ' wk ahead cum', dt_name(dt));
    
    disp('Creating combined table');
    
    full_T = [T; Tc; Tm; Tmc; us_T; us_Tc; us_Tm; us_Tmc];
    full_T(contains(full_T.target, '27 wk'), :) = [];
    full_T(contains(full_T.target, '28 wk'), :) = [];
    nanidx = (strcmpi(full_T.value, 'NaN'));
    full_T(nanidx, :) = [];
    
    % Write files on disk
    disp('Writing File');
    tic;
    writetable(full_T, ['../../results/to_reich/' datestr(now_date, 'YYYY-mm-DD') '-USC-SIkJalpha.csv']);
    toc
    
end