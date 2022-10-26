filename = 'FluSurveillance_Custom_Download_Data.csv';
data = readtable(filename);
%data.case_month = cellfun(@(x)[x '-23'], data.case_month, 'uni', false);
%Filter and choose only overall & age wise data
index_T = (data.AGECATEGORY == "Overall") & (data.SEXCATEGORY == "Overall") & (data.RACECATEGORY == "Overall");
data_T = data(index_T,:);
data_T_Cum = data_T(:,1:end-1);
data_T_wkly = removevars(data_T,{'CUMULATIVERATE'});

subindx = (data.AGECATEGORY == "0-4 yr") | (data.AGECATEGORY == "5-11  yr") | (data.AGECATEGORY == "12-17 yr") | (data.AGECATEGORY == "18-49 yr") | (data.AGECATEGORY == "50-64 yr") | (data.AGECATEGORY == "65+ yr");
index_T = subindx & (data.AGECATEGORY ~= "Overall") & (data.SEXCATEGORY == "Overall") & (data.RACECATEGORY == "Overall");
data_age = data(index_T,:);
data_age_Cum = data_age(:,1:end-1);
data_age_wkly = removevars(data_age,{'CUMULATIVERATE'});


abvstate = readcell('us_states_abbr_list.txt');
age_groups = {'0-4 yr', '5-11  yr', '12-17 yr', '18-49 yr', '50-64 yr', '65+ yr'}'; %Inclusive
popdata = readtable('pop_by_age.csv');

%% Prepare older data
hosps_age = zeros(size(abvstate,1),size(data_T,1),size(age_groups,1)); %Weekly data per 100k
hosps_T = zeros(size(abvstate,1),size(data_T,1)); %Weekly data per 100k
hosps_FluServeNet_Wkly = zeros(size(data_T,1),size(age_groups,1));
hosps_FluServeNet_Cum = zeros(size(data_T,1),size(age_groups,1));
% find initial total hosps (These account for the 14 states)
for i=1:length(age_groups)
    %group = age_groups(i);
    temp = ismember(data_age_wkly.AGECATEGORY, age_groups(i));
    hosps_FluServeNet_Wkly(:,i) = table2array(data_age_wkly(temp,end));
    temp = ismember(data_age_Cum.AGECATEGORY, age_groups(i));
    hosps_FluServeNet_Cum(:,i) = table2array(data_age_Cum(temp,end));
end
%35-17. 40-17. 40-17. 40-17. 40-17. 40-17 (with 53). 40-17. 40-17. 40-17. 40-17. 40-17 (with 53) (N/A)
mmrwweeksperseason = [35, 30, 30, 30, 30, 31, 30, 30, 30, 30, 30, 31];
% 4D matrix: season x states x weeks x age
total = 0;
hosps_wkly = zeros(size(mmrwweeksperseason,2),max(mmrwweeksperseason),size(age_groups,1));
hosps_cum = zeros(size(mmrwweeksperseason,2),max(mmrwweeksperseason),size(age_groups,1));
for i = 1:size(mmrwweeksperseason,2)
    current_s = mmrwweeksperseason(i);
    if i == 1
        hosps_wkly(i,:,:) = hosps_FluServeNet_Wkly(1:current_s, :);
        hosps_cum(i,:,:) = hosps_FluServeNet_Cum(1:current_s, :);
    else
        hosps_wkly(i,:,:) = padarray(hosps_FluServeNet_Wkly(total+1:total+current_s, :),35-current_s,'pre');
        hosps_cum(i,:,:) = padarray(hosps_FluServeNet_Cum(total+1:total+current_s, :),35-current_s,'pre');
    end
    total = total + current_s;
        
    
end
% find popu % of these 14 states compared to total popu. 
participating_states = ["CA", "CO", 'CT', 'GA', 'IA', 'MD', 'MI', 'MN', 'NM', 'NY', 'OH', 'OR', 'TN', 'UT'];
indicies = [];
for i =1:length(participating_states)
    index = find(string(abvstate)==participating_states(i));
    indicies = [indicies, index];
end
data_pop = sum(popdata{indicies,:},'all');
pop_total = sum(popdata{:,:},'all');

% then find % over total population. (& Scale it accordingly for total US popu)
ratio = data_pop/pop_total; %(Should be ~ 9%? Not 40%?)

hosps_wkly = hosps_wkly/ratio;
hosps_cum = hosps_cum/ratio;
% then distribute it accordingly over the rest of state-age wise populations
pop_ratios = popdata{:,:}/pop_total;
state_ratio = sum(pop_ratios,2);
%age_ratio = sum(pop_ratios,1);
%Just combine age groups to be consistent with population
hosps_wkly(:,:,4) = sum(hosps_wkly(:,:,4:5),3);
hosps_wkly(:,:,5) = hosps_wkly(:,:,end);
hosps_wkly = hosps_wkly(:,:,1:5);

hosps_cum(:,:,4) = sum(hosps_cum(:,:,4:5),3);
hosps_cum(:,:,5) = hosps_cum(:,:,end);
hosps_cum = hosps_cum(:,:,1:5);

hosps_Cum = zeros(size(mmrwweeksperseason,2),size(abvstate,1), max(mmrwweeksperseason),size(age_groups,1)-1);
hosps_Wkly = zeros(size(mmrwweeksperseason,2),size(abvstate,1), max(mmrwweeksperseason),size(age_groups,1)-1);
for i = 1:size(mmrwweeksperseason,2) %Loops over each season
    for j = 1:size(abvstate,1)
        hosps_Cum(i,j,:,:) = hosps_cum(i,:,:)*state_ratio(j); %Distribute according to state ratio
        hosps_Wkly(i,j,:,:) = hosps_wkly(i,:,:)*state_ratio(j);
    end
end

%% visualizations for older data (Hosps per 100,000)
season =1;
%for jj = 1:5

jj=1:56;
figure;
% plot(squeeze(nansum(hosps_Wkly(season,jj, :, :),2)));
plot(squeeze(nansum(hosps_Cum(season,jj, :, :),2)));
%end



