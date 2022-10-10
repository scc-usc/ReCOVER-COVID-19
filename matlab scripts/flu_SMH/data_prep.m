%% Load state data (Check for age wise popu)
popu = load('us_states_population_data.txt');
popu_age = load('pop_by_age.csv'); %(0-4, 5-11, 12-17, 18-64, 65+)
%0-4, 5-17, 18-49, 50-64, and 65+
abvs = readcell('us_states_abbr_list.txt');
state_list = readcell('us_states_abbr_list2.txt');
age_groups = readcell('age_groups_list.txt');
ns = length(abvs);
%% Fetch updated data
sel_url = 'https://healthdata.gov/api/views/g62h-syeh/rows.csv?accessType=DOWNLOAD';
urlwrite(sel_url, 'dummy.csv');
hosp_tab = readtable('dummy.csv');
%Change to ReCOVER Format
%projection_date = datetime(2022,8,14);
zero_date = datetime(2021, 9, 1);%datetime(2021, 10, 9);% %10/9/2021 this is MMWR week 40
fips_tab = readtable('reich_fips.txt', 'Format', '%s%s%s%d');
%hosp_tab = hosp_tab(datetime(hosp_tab.date, 'InputFormat', 'yyyy/MM/dd') <= projection_date,:);
all_days = days(datetime(hosp_tab.date, 'InputFormat', 'yyyy/MM/dd') - zero_date);
bad_idx = all_days <= 0;
hosp_tab(bad_idx, :) = [];
all_days = all_days(~bad_idx);

maxt = max(all_days);
fips = cell(ns, 1);
hosp_dat = nan(ns, maxt);

for cid = 1:length(abvs)
    fips(cid) = fips_tab.location(strcmp(fips_tab.abbreviation, abvs(cid)));
end

for idx = 1:size(hosp_tab, 1)
    
    cid = find(strcmp(abvs, hosp_tab.state(idx)));
    if isempty(cid)
        disp(['Error at ' num2str(idx)]);
    end

    date_idx = all_days(idx);
    if date_idx <= maxt
        hosp_dat(cid, date_idx) = hosp_tab.previous_day_admission_influenza_confirmed(idx);
    end
end
%% Load age-wise & historical data
age_tab = readtable('FluSurveillance_Custom_Download_Data.csv');
indx = ((age_tab.MMWR_YEAR==2021 & age_tab.MMWR_WEEK>=40) | (age_tab.MMWR_YEAR==2022 & age_tab.MMWR_WEEK<=23)) & (age_tab.SEXCATEGORY == "Overall") & (age_tab.RACECATEGORY == "Overall");
data = age_tab(indx,:);
%Find distribution of age ratios at a weekly basis
% total_indx = data.AGECATEGORY == "Overall";
% total=data(total_indx,:);
age_indx1 = data.AGECATEGORY == "0-4 yr";
age_1=data(age_indx1,:);
age_indx2 = data.AGECATEGORY == "5-17 yr";
age_2=data(age_indx2,:);
age_indx3 = data.AGECATEGORY == "18-49 yr";
age_3=data(age_indx3,:);
age_indx4 = data.AGECATEGORY == "50-64 yr";
age_4=data(age_indx4,:);
age_indx5 = data.AGECATEGORY == "65+ yr";
age_5=data(age_indx5,:);

total = age_1.WEEKLYRATE + age_2.WEEKLYRATE + age_3.WEEKLYRATE + age_4.WEEKLYRATE + age_5.WEEKLYRATE;
rate_1 = age_1.WEEKLYRATE./total;
% rate_1(isnan(rate_1))=0.2; %nan2zero(rate_1);
rate_2 = age_2.WEEKLYRATE./total;
% rate_2(isnan(rate_2))=0.2;% rate_2 = nan2zero(rate_2);
rate_3 = age_3.WEEKLYRATE./total;
% rate_3(isnan(rate_3))=0.2;% rate_3 = nan2zero(rate_3);
rate_4 = age_4.WEEKLYRATE./total;
% rate_4(isnan(rate_4))=0.2;% rate_4 = nan2zero(rate_4);
rate_5 = age_5.WEEKLYRATE./total;
% rate_5(isnan(rate_5))=0.2;% rate_5 = nan2zero(rate_5);

rates = [rate_1 rate_2 rate_3 rate_4 rate_5];
avg_rate = nanmean(rates);
% Assume avg rate for missing/0 data
rates(find(all(isnan(rates),2)),:) = repmat(avg_rate,size(rates(find(all(isnan(rates),2)),:),1),1);
daily_rates=[];
for i =1:length(rates)
    temp = repmat(rates(i,:),7,1);
    daily_rates = [daily_rates;temp];
end
%change rates to daily & padd with avg rates
left_pad = days(datetime(2021, 10, 9) - zero_date) - 7;
daily_rates = [repmat(avg_rate,left_pad,1);daily_rates];
right_pad = size(hosp_dat,2) - size(daily_rates,1);
daily_rates = [daily_rates;repmat(avg_rate,right_pad,1)];

temp = nan(ns,size(daily_rates,1),5);
%Apply distribution to our data
for i =1:size(hosp_dat,1)
    temp(i,:,:) = hosp_dat(i,:)'.*daily_rates;
end
hosp_dat = temp;
%% Fetch vaccine coverage data
% sel_url = 'https://data.cdc.gov/resource/3myw-4j4q.csv';
% urlwrite(sel_url, 'dummy.csv');
adult_cov = readtable('dummy3.csv'); %18-49, 50-64, and 65+
adult_vacc_Cov = nan(ns,176,3); %oct1st till march26th
for i =1:length(state_list)
    indx_1 = (adult_cov.Age_Group== "18-49 yrs") & (adult_cov.Geography == string(state_list{i})) & adult_cov.Race=="Overall";
    indx_2 = (adult_cov.Age_Group== "50-64 yrs") & (adult_cov.Geography == string(state_list{i})) & adult_cov.Race=="Overall";
    indx_3 = (adult_cov.Age_Group == "65+ yrs") & (adult_cov.Geography == string(state_list{i})) & adult_cov.Race=="Overall";
   
    if sum(indx_1) == 0
        continue;
    end

    temp = adult_cov(indx_1,:);
    temp = sortrows(temp,'Week_Ending','ascend');
    adult_vacc_Cov(i,1:30,1) = temp.Point_Estimate(1);
    adult_vacc_Cov(i,31:58,1) = temp.Point_Estimate(2);
    adult_vacc_Cov(i,59:92,1) = temp.Point_Estimate(3);
    adult_vacc_Cov(i,93:120,1) = temp.Point_Estimate(4);
    adult_vacc_Cov(i,121:148,1) = temp.Point_Estimate(5);
    adult_vacc_Cov(i,149:end,1) = temp.Point_Estimate(6);

    temp = adult_cov(indx_2,:);
    temp = sortrows(temp,'Week_Ending','ascend');
    adult_vacc_Cov(i,1:30,2) = temp.Point_Estimate(1);
    adult_vacc_Cov(i,31:58,2) = temp.Point_Estimate(2);
    adult_vacc_Cov(i,59:92,2) = temp.Point_Estimate(3);
    adult_vacc_Cov(i,93:120,2) = temp.Point_Estimate(4);
    adult_vacc_Cov(i,121:148,2) = temp.Point_Estimate(5);
    adult_vacc_Cov(i,149:end,2) = temp.Point_Estimate(6);

    temp = adult_cov(indx_3,:);
    temp = sortrows(temp,'Week_Ending','ascend');
    adult_vacc_Cov(i,1:30,3) = temp.Point_Estimate(1);
    adult_vacc_Cov(i,31:58,3) = temp.Point_Estimate(2);
    adult_vacc_Cov(i,59:92,3) = temp.Point_Estimate(3);
    adult_vacc_Cov(i,93:120,3) = temp.Point_Estimate(4);
    adult_vacc_Cov(i,121:148,3) = temp.Point_Estimate(5);
    adult_vacc_Cov(i,149:end,3) = temp.Point_Estimate(6);
    

end

% sel_url = 'https://data.cdc.gov/resource/eudc-n39h.csv';
% urlwrite(sel_url, 'dummy2.csv');
child_cov = readtable('dummy4.csv'); %0-17
indx = child_cov.Week_Ending>=datetime("10/09/2021"); 
child_cov = child_cov(indx,:);
child_vacc = nan(ns,189); %oct3rd till april9
for i =1:length(state_list)
    indx = (child_cov.Geography_Name == string(state_list{i})) & child_cov.Race_Ethnicity=="Overall";
    temp = child_cov(indx,:);
    L = temp.Point_Estimate;
    for j =1:length(L)
        child_vacc(i,(j-1)*7+1: j*7) = L(j);
    end
end
child_vacc = child_vacc*100;
%Assume 0-4 and 5-17 same coverage
child_vacc(:,:,2) = child_vacc;
%combine to final matrix
%% padd smaller matrix with repeated values
pad = abs(size(adult_vacc_Cov,2) - size(child_vacc,2));
rep_values = adult_vacc_Cov(:,end-pad:end,:);
adult_vacc_Cov(:,end:end+pad,:) = rep_values;

%(oct1st till april9th)
vacc_cov =child_vacc;
vacc_cov(:,:,end+1:end+3) = adult_vacc_Cov;
%% Load  vaccine efficacy data
US_age = sum(popu_age); % IS (0-4, 5-11, 12-17, 18-64, 65+). need %0-4, 5-17, 18-49, 50-64, and 65+
%High VE 0-2,3-8,9-49,50-64,65+
% high_VE = [58,69,51,51,36];
high_VE = [(3/5)*58 + (2/5)*69,(4/13)*69 + (9/13),51,51,36];
high_VE(:) = 60;
%Low VE 0-8,9-17,18-49,50-64,65+
%low_VE = [48,7,25,14,12];
low_VE = [48,((4*US_age(1)*48/5)+(9*sum(US_age(2:3))*7/13))/(0.8*US_age(1) + (9/13)*sum(US_age(2:3))),25,14,12];
low_VE(:) = 30;
%% Load Vaccine projection data (Starting from the week ending @ 2022-08-06)
vacc_proj = readtable('Age_Specific_Coverage_Flu_RD1_2022_23_Sc_A_B_C_D.csv');
st = unique(vacc_proj.Geography);
vacc_A_B = nan(ns,44*7,5);
vacc_C_D = nan(ns,44*7,5);
for i =1:length(state_list)
    indx_1 = (vacc_proj.Age == "6 Months - 4 Years") & (vacc_proj.Geography == string(state_list{i}));
    indx_2 = (vacc_proj.Age == "5-12 Years") & (vacc_proj.Geography == string(state_list{i}));
    indx_3 = (vacc_proj.Age == "13-17 Years") & (vacc_proj.Geography == string(state_list{i}));
    indx_4 = (vacc_proj.Age == "18-49 Years") & (vacc_proj.Geography == string(state_list{i}));
    indx_5 = (vacc_proj.Age == "50-64 Years") & (vacc_proj.Geography == string(state_list{i}));
    indx_6 = (vacc_proj.Age == "65+ Years") & (vacc_proj.Geography == string(state_list{i}));
    
    if sum(indx_1) == 0
        continue;
    end
    
    popu_2 = vacc_proj(indx_2,:).Population(1);
    popu_3 = vacc_proj(indx_3,:).Population(1);
    age_1_A_B = vacc_proj(indx_1,:).Boost_coverage_rd1_sc_A_B;
    age_2_A_B = (vacc_proj(indx_2,:).Boost_coverage_rd1_sc_A_B*popu_2 + vacc_proj(indx_3,:).Boost_coverage_rd1_sc_A_B*popu_3)/(popu_2+popu_3);
%     age_3_A_B = vacc_proj(indx_3,:).Boost_coverage_rd1_sc_A_B;
    age_3_A_B = vacc_proj(indx_4,:).Boost_coverage_rd1_sc_A_B;
    age_4_A_B = vacc_proj(indx_5,:).Boost_coverage_rd1_sc_A_B;
    age_5_A_B = vacc_proj(indx_6,:).Boost_coverage_rd1_sc_A_B;

    age_1_C_D = vacc_proj(indx_1,:).Boost_coverage_rd1_sc_C_D;
    age_2_C_D = (vacc_proj(indx_2,:).Boost_coverage_rd1_sc_C_D*popu_2 + vacc_proj(indx_3,:).Boost_coverage_rd1_sc_C_D*popu_3)/(popu_2+popu_3);
    age_3_C_D = vacc_proj(indx_4,:).Boost_coverage_rd1_sc_C_D;
    age_4_C_D = vacc_proj(indx_5,:).Boost_coverage_rd1_sc_C_D;
    age_5_C_D = vacc_proj(indx_6,:).Boost_coverage_rd1_sc_C_D;

    temp1 = [age_1_A_B age_2_A_B age_3_A_B age_4_A_B age_5_A_B];
    temp2 = [age_1_C_D age_2_C_D age_3_C_D age_4_C_D age_5_C_D]; 
    
    daily_cov1 =[];
    daily_cov2 = [];
    for k =1:length(temp1)
        temp11 = repmat(temp1(k,:),7,1);
        daily_cov1 = [daily_cov1;temp11];

        temp22 = repmat(temp2(k,:),7,1);
        daily_cov2 = [daily_cov2;temp22];
    end

    vacc_A_B(i,:,:) = daily_cov1;
    vacc_C_D(i,:,:) = daily_cov2;
end
% 
%%
save flu_age_outcomes.mat abvs age_groups vacc_A_B vacc_C_D hosp_dat low_VE high_VE vacc_cov;% vacc_Cov;