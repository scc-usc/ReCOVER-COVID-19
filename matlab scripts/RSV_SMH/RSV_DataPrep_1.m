clear;
%%
addpath('../scenario_projections/');
addpath('../');
addpath('../../../shapelets/shapelet_space_matlab/');
addpath('../../scripts/utils/');
%%
% Get from 
% https://healthdata.gov/dataset/covid-19-reported-patient-impact-and-hospital-capacity-state-timeseries
% sel_url = 'https://healthdata.gov/sites/default/files/reported_hospital_utilization_timeseries_20210306_1105.csv';
sel_url = "https://raw.githubusercontent.com/midas-network/rsv-scenario-modeling-hub/main/target-data/rsvnet_hospitalization.csv";
urlwrite(sel_url, 'RSV_data.csv');
hosp_tab = readtable('RSV_data.csv');

sel_url = "https://raw.githubusercontent.com/midas-network/rsv-scenario-modeling-hub/main/auxiliary-data/vaccine_coverage/RSV_round1_Coverage_2023_2024.csv";
urlwrite(sel_url, 'RSV_Coverage_data.csv');
%% Convert hospital data to ReCOVER format
% popu = load('us_states_population_data.txt');
abvs = readcell('us_states_abbr_list.txt');
% ns = length(abvs);

%incidident 
hosp_tab = hosp_tab(hosp_tab.target=="inc hosp",:);
%age_groups: required targets <1,1-4,5-64,and 65+. But scenarios: <6 & 60+
age_groups = table2cell(readtable('age_groups.csv')); %unique(hosp_tab.age_group);
% age_groups = age_groups([1 4 5 7 8 9 10 11]);

age_groups_l = [-0.01, 0.5, 1, 2, 5, 18, 50, 65]';
age_groups_r = [0.5, 1, 2, 5, 18, 50, 65, 80]';


hosp_tab = hosp_tab(ismember(hosp_tab.age_group,age_groups),:);

fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
zero_date = datetime(2020, 10, 10); %2018-10-06 %This is set to 2018 because states were still joining fomr 2014-2018 and children surveillence only began in 2018-2019 season
all_weeks = days(datetime(hosp_tab.date, 'InputFormat', 'yyyy/MM/dd') - zero_date)/7; %data is weekly
bad_idx = all_weeks < 0;
hosp_tab(bad_idx, :) = [];
all_weeks = all_weeks(~bad_idx);

maxt = max(all_weeks);

%NaN location = US
%assume nans are 0s (off season it seems)
fips =  unique(hosp_tab.location(~isnan(hosp_tab.location)));
ns = length(fips);
% fips = cell(ns, 1);

abvs_new = {};
for c = 1:ns %length(abvs)
    cid = fips(c);
    abvs_new(c) = fips_tab.abbreviation(cid);
end
abvs_new(end+1) = {"US"};
ns = ns+1;

%% prepare hosp data
ag = length(age_groups);
hosps_3D = zeros(length(abvs_new), maxt, length(age_groups));
for k = 1:length(abvs_new)
    for i = 1:length(age_groups)
        
        %cases
        if k == length(abvs_new)
            index = isnan(hosp_tab.location) & (hosp_tab.age_group == string(age_groups{i}));
        else
            index = (hosp_tab.location == (fips(k))) & (hosp_tab.age_group == string(age_groups{i}));
        end
        hosps = hosp_tab(index,:); %%ismember
        hosps = sortrows(hosps,'date','ascend');       
        for l = 1:maxt
            hosps_3D(k,l, i) = hosps.value(l);
            %p = p + 1;
        end     
    end
end
%nans to zero
hosps_3D(isnan(hosps_3D)) = 0;

%%

hosps_3D_s = hosps_3D;
for gg = 1:size(hosps_3D, 3)
    hosps_3D_s(:, :, gg) = movmean(hosps_3D(:, :, gg), 5, 2);
end

%%
cid = 1:12; agr = [1];
plot(squeeze(sum(hosps_3D_s(cid, :, agr), 1))); hold on
plot(squeeze(sum(hosps_3D(cid, :, agr), 1))); hold on

%% Load population data
popu_tbl = readtable('state_pop_data.csv');
pop_by_age = zeros(ns, ag);
popu = zeros(ns, 1);
for cid = 1:ns
    if cid < ns
        this_loc = fips(cid);
    else
        this_loc = 0;
    end
    for gg=1:ag-1 % Last age group handled differently
        idx = (popu_tbl.STATE == this_loc) & (popu_tbl.AGE > age_groups_l(gg)) & (popu_tbl.AGE <= age_groups_r(gg));
        idx = idx & popu_tbl.SEX == 0;
        pop_by_age(cid, gg) = sum(popu_tbl.POPEST2022_CIV(idx));
    end
    idx = (popu_tbl.STATE == this_loc) & (popu_tbl.AGE == 999);
    idx = idx & popu_tbl.SEX == 0;
    popu(cid) = sum(popu_tbl.POPEST2022_CIV(idx));
    pop_by_age(cid, ag) = popu(cid) - sum(pop_by_age(cid, 1:ag-1));
end
%%
horizon = 40; T = maxt; thisday = maxt;
%% Load vaccine data
coverage_tab = readtable('RSV_Coverage_data.csv');

infants_dose_opt = zeros(ns, maxt + horizon);
infants_dose_pes = zeros(ns, maxt + horizon);
over65_dose_opt = zeros(ns, maxt + horizon);
over65_dose_pes = zeros(ns, maxt + horizon);
from60_65_dose_opt = zeros(ns, maxt + horizon);
from60_65_dose_pes = zeros(ns, maxt + horizon);

tab_tt = days(coverage_tab.Week_Ending_Sat - zero_date)/7;
for j = 1:length(tab_tt)
    if isnan(coverage_tab.fips(j))
        loc_id = 13;
    else
        loc_id = find(fips==coverage_tab.fips(j));
    end
    infants_dose_opt(loc_id, tab_tt(j)) = coverage_tab.rsv_cov_infants_opt(j)*pop_by_age(loc_id, 1)/100;
    infants_dose_pes(loc_id, tab_tt(j)) = coverage_tab.rsv_cov_infants_pes(j)*pop_by_age(loc_id, 1)/100;
    over65_dose_opt(loc_id, tab_tt(j)) = coverage_tab.rsv_cov_over60_opt(j)*pop_by_age(loc_id, ag)/100;
    over65_dose_pes(loc_id, tab_tt(j)) = coverage_tab.rsv_cov_over60_pes(j)*pop_by_age(loc_id, ag)/100;
    from60_65_dose_opt(loc_id, tab_tt(j)) = coverage_tab.rsv_cov_over60_opt(j)*(5/15)*pop_by_age(loc_id, ag-1)/100;
    from60_65_dose_pes(loc_id, tab_tt(j)) = coverage_tab.rsv_cov_over60_pes(j)*(5/15)*pop_by_age(loc_id, ag-1)/100;
end
%%

