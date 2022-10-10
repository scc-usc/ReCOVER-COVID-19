%% Load state data (Check for age wise popu)
popu = load('us_states_population_data.txt');
popu_age = load('pop_by_age.csv'); %(0-4, 5-11, 12-17, 18-64, 65+)
%0-4, 5-17, 18-49, 50-64, and 65+
abvs = readcell('us_states_abbr_list.txt');
state_list = readcell('us_states_abbr_list2.txt');
age_groups = readcell('age_groups_list.txt');
popu = load('us_states_population_data.txt');
ns = length(abvs);

old_seasons = [2015:2019];
hosp_dat_old_T = nan(length(old_seasons),400,5);
hosp_dat_old = nan(length(old_seasons),ns,400,5);
%% Load age-wise & historical data
age_tab = readtable('FluSurveillance_Custom_Download_Data.csv');
for s=old_seasons
    indx = ((age_tab.MMWR_YEAR==s & age_tab.MMWR_WEEK>=40) | (age_tab.MMWR_YEAR==s+1 & age_tab.MMWR_WEEK<=23)) & (age_tab.SEXCATEGORY == "Overall") & (age_tab.RACECATEGORY == "Overall");
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

    rate_1 = age_1.WEEKLYRATE;
    rate_2 = age_2.WEEKLYRATE;
    rate_3 = age_3.WEEKLYRATE;
    rate_4 = age_4.WEEKLYRATE;
    rate_5 = age_5.WEEKLYRATE;

    rates = [rate_1 rate_2 rate_3 rate_4 rate_5];
    avg_rate = nanmean(rates);

    rates(find(all(isnan(rates),2)),:) = repmat(avg_rate,size(rates(find(all(isnan(rates),2)),:),1),1);
    daily_rates=[];
    for i =1:length(rates)
        temp = repmat(rates(i,:)/7,7,1);
        daily_rates = [daily_rates;temp];
    end
    zero_date = datetime(s, 9, 1);
    skip = 7-weekday(datetime(s,10,1))+1;
    mmr_date = datetime(s,10,1) + days(skip);

%     left_pad = days(mmr_date - zero_date) - 7;
%     daily_rates = [repmat(daily_rates(1,:),left_pad,1);daily_rates];
%     right_pad = size(hosp_dat_old_T,2) - size(daily_rates,1);
    
     hosp_dat_old_T(s-2014,1:size(daily_rates,1),:) = daily_rates;
%     hosp_dat_old_T(s-2014,size(daily_rates,1)+1:end,:) = repmat(daily_rates(end,:),right_pad,1);
end

%Distribute among that states

for j=1:size(abvs,1)
    for g = 1:size(popu_age, 2)
        hosp_dat_old(:,j,:,:) = hosp_dat_old_T.*popu_age(j,g)/100000;
    end
end


%%
save flu_age_outcomes_old.mat hosp_dat_old