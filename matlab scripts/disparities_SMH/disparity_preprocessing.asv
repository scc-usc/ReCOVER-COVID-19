clear;
%% Read all data
%Load pop data
pop_data = readtable('joint_population_data.csv');

%Create a variable with the ordering of groups
groups = pop_data(1:15,2:3);
%insert missing group in NC 
newRow1 = {37, 'latino', '0-17', 0, 10698973};
newRow2 = {37, 'latino', '18-64', 0, 10698973};
newRow3 = {37, 'latino', '65+', 0, 10698973};
columnNames = pop_data.Properties.VariableNames;
newRow1 = cell2table(newRow1, 'VariableNames', columnNames);
newRow2 = cell2table(newRow2, 'VariableNames', columnNames);
newRow3 = cell2table(newRow3, 'VariableNames', columnNames);
pop_data = [pop_data(1:15, :); newRow1; pop_data(16:19, :); newRow2;pop_data(20:23, :);newRow3;pop_data(24:end, :);];
%Put pop_data in ocrrect format (2x15)
popColumn = pop_data.percent.*pop_data.total_population;
pop_data.popColumn = popColumn;
popu = removevars(pop_data, {'race_ethnicity','age','percent', 'total_population'});
popu = [popu.popColumn(1:15)'; popu.popColumn(16:end)'];

clear newRow1 newRow2 newRow3 popColumn columnNames;

%Load location data
locations = readtable('locations.csv');
locations = locations([6,35],1:2);

%Load Target data (weekly)
data_phase1 = readtable("target_data_phase1.csv");
data_phase2 = readtable("target_data_phase2.csv");

%Load case imputation data (do not start till march 7th, 2020)
case_imputation = readtable("case_imputation.csv");

%Load hospitalization data
hosp_CA = readtable("hospitalization_rates_ca.csv");
hosp_NC = readtable("hospitalization_nc.csv");

%Load Vaccination data (does not start till december 12th)
vax_data = readtable("vaccination_data.csv");

%Load Serology data
serology_data = readtable("serology_data.csv");
serology_full_data = readtable("serology_full_data.csv");

%% Split into case and death data
data_phase1_case = data_phase1(string(data_phase1.target) == "inc case",:);
data_phase1_death = data_phase1(string(data_phase1.target) == 'inc death',:);

data_phase2_case = data_phase2(string(data_phase2.target) == 'inc case',:);
data_phase2_death = data_phase2(string(data_phase2.target) == 'inc death',:);

date_diff = between(data_phase2_death.date(1), data_phase2_death.date(end), 'weeks');
total_weeks = calweeks(date_diff)+1;
%% load total case data to fill missing
case_full_data = readtable('cases_overall_jhu.csv');
case_full_dataCA = case_full_data(case_full_data.location == 6, :);
case_full_dataCA = sortrows(case_full_dataCA,'date','ascend');
case_full_dataNC = case_full_data(case_full_data.location == 37, :);
case_full_dataNC = sortrows(case_full_dataNC,'date','ascend');
case_full_data = nan(2,total_weeks);
case_full_data(1,4:end) = (case_full_dataCA.value);
case_full_data(2,4:end) = (case_full_dataNC.value);
case_full_data = fillmissing(case_full_data, 'constant',0);
%% load total case data to fill missing
% opts = detectImportOptions('covid_confirmed_usafacts.csv', 'VariableNamesLine', 1);
% case_full_data = readtable('covid_confirmed_usafacts.csv', opts);
% case_full_data = case_full_data(2:end,:);
% case_full_data = case_full_data(case_full_data.State == "CA" | case_full_data.State == "NC", :);
% case_full_data = groupsummary(case_full_data, 'State', 'sum', [5:1269]);
% case_full_data = case_full_data(:,[1 3:440]);
% case_full_data = table2array(case_full_data(:,2:end));
% date_diff = between(datetime("2020-01-04"), datetime("2020-01-22"), 'days');
% days_offset = caldays(date_diff);
% nanPadding = NaN(2, days_offset);
% case_full_data = [nanPadding, case_full_data];
% case_full_data = case_full_data(:,end:-7:1);
% case_full_data = case_full_data(:,end:-1:1);
% 
% zer = zeros(2, 1);
% case_full_data = [zer, case_full_data];
% case_full_data = fillmissing(case_full_data, 'pchip',2);
% case_full_data(case_full_data<0) = 0;
% case_full_data = movmean(case_full_data, 7, 2, 'Endpoints', 'shrink');
% case_full_data = diff(case_full_data,[],2);
% case_full_data(case_full_data<0) = 0;
% 
% nanPadding =  NaN(2, 1);
% case_full_data(case_full_data<0) = nan;
% case_full_data = [case_full_data, nanPadding];
% case_full_data = fillmissing(case_full_data, 'linear',2);
% case_full_data = case_full_data(:,1:end-1);
%% Load age-wise data to find distibution
load age_outcomes %Data starts from jan23rd
datetime1 = datetime('2020-01-23', 'InputFormat', 'yyyy-MM-dd');
date_diff = between(data_phase2_death.date(1), datetime1, 'days');
days_diff = caldays(date_diff);
%case data
case_age = c_3d([3,16],3:(total_weeks*7)-days_diff,:); %starts on jan 25th
%Change to weekly
case_age = reshape(case_age, size(case_age,1), 7, total_weeks-3, size(case_age,3));
case_age = sum(case_age, 2);
case_age = squeeze(case_age);
%Combine age groups
case_age(:,:,1) = sum(case_age(:,:,1:3),3);
case_age(:,:,2) = sum(case_age(:,:,4:5),3);
case_age(:,:,3) = case_age(:,:,6);
case_age = case_age(:,:,1:3);
case_age_T = sum(case_age,3);

%death data
death_age = d_3d([3,16],3:(total_weeks*7)-days_diff,:); %starts on jan 25th
%Change to weekly
death_age = reshape(death_age, size(death_age,1), 7, total_weeks-3, size(death_age,3));
death_age = sum(death_age, 2);
death_age = squeeze(death_age);
%Combine age groups
death_age(:,:,1) = sum(death_age(:,:,1:3),3);
death_age(:,:,2) = sum(death_age(:,:,4:5),3);
death_age(:,:,3) = death_age(:,:,6);
death_age = death_age(:,:,1:3);
death_age_T = sum(death_age,3);

%hosp data
hosp_age = h_3d([3,16],3:(total_weeks*7)-days_diff,:); %starts on jan 25th
%Change to weekly
hosp_age = reshape(hosp_age, size(hosp_age,1), 7, total_weeks-3, size(hosp_age,3));
hosp_age = sum(hosp_age, 2);
hosp_age = squeeze(hosp_age);
%Combine age groups
hosp_age(:,:,1) = sum(hosp_age(:,:,1:3),3);
hosp_age(:,:,2) = sum(hosp_age(:,:,4:5),3);
hosp_age(:,:,3) = hosp_age(:,:,6);
hosp_age = hosp_age(:,:,1:3);
hosp_age_T = sum(hosp_age,3);

%% load and fix vax data
vax_data_age = vax_data(string(vax_data.demographic_category) == "age",:);
vax_data_ethnic = vax_data(string(vax_data.demographic_category) == "race_ethnicity",:);
varNames = vax_data_age.Properties.VariableNames;

% Create an empty table with the same column names
aggregatedData =vax_data_age([], :);% array2table(zeros(0, length(varNames)), 'VariableNames', varNames);
aggregatedData2 =vax_data_age([], :);% array2table(zeros(0, length(varNames)), 'VariableNames', varNames);

% Unique dates in the table
uniqueDates = unique(vax_data_age.date);
uniqueLoc = unique(vax_data_age.location);

%Combine age groups
% Loop through each unique date
for j = length(uniqueLoc):-1:1
    % Get the data for the current date
    currentLoc = uniqueLoc(j);
    for i=1:length(uniqueDates)
        currentDate = uniqueDates(i);
        dateData = vax_data_age((vax_data_age.date == currentDate) & (vax_data_age.location == currentLoc), :);
        if isempty(dateData)
            continue
        end
        % Check if both '18-49' and '50-64' are present
        if any(strcmp(dateData.demographic_value, '18-49')) && any(strcmp(dateData.demographic_value, '50-64'))
            % Sum the values for '18-49' and '50-64'
            combinedValue1 = sum(dateData.partial_vax(strcmp(dateData.demographic_value, '18-49'))) + sum(dateData.partial_vax(strcmp(dateData.demographic_value, '50-64')));
            combinedValue2 = sum(dateData.full_vax(strcmp(dateData.demographic_value, '18-49'))) + sum(dateData.full_vax(strcmp(dateData.demographic_value, '50-64')));
            % Remove the '18-49' and '50-64' rows from the original data
            dateData(strcmp(dateData.demographic_value, '18-49') | strcmp(dateData.demographic_value, '50-64'), :) = [];
            % Add a new row with the combined '18-64' values
            dateData = [dateData; {currentLoc, currentDate, combinedValue1, combinedValue2, 'age', '18-64'}];
        end
    
        % Append the date's data to the aggregated data  
        if j==2
            aggregatedData = [aggregatedData; dateData];
        else
            aggregatedData2 = [aggregatedData2; dateData];
        end
    end
    if j==2
        aggregatedData = sortrows(aggregatedData,'demographic_value','ascend');
    else
        aggregatedData2 = sortrows(aggregatedData2,'demographic_value','ascend');
    end
end

vax_data_age = [aggregatedData; aggregatedData2];

% Now interpolate missing dates (make it each Sat rather than each Mon)
% Initialize new table
SC_vax_age = vax_data_age(vax_data_age.location==37,:);
SC_vax_ethnic = vax_data_ethnic(vax_data_ethnic.location==37,:);
uniqueDates = unique(SC_vax_age.date);
dates_interp = uniqueDates(1) + caldays(5):caldays(7):uniqueDates(end);
uniqueGroups = unique(SC_vax_age.demographic_value);
uniqueGroupsE = unique(SC_vax_ethnic.demographic_value);

% Interpolate and insert new rows
for i = 1:length(uniqueGroupsE)
    % Current and next date
   tempTableE = SC_vax_ethnic(SC_vax_ethnic.demographic_value == string(uniqueGroupsE(i)),:);
   
    % Interpolate values
    if i~=5
        tempTable = SC_vax_age(SC_vax_age.demographic_value == string(uniqueGroups(i)),:);
        interpolated_partial_values = interp1(tempTable.date, tempTable.partial_vax, dates_interp,'cubic');
        interpolated_partial_values(interpolated_partial_values < 0) = 0;
        interpolated_full_values = interp1(tempTable.date, tempTable.full_vax, dates_interp,'cubic');
        interpolated_full_values(interpolated_full_values < 0) = 0;
    end
    interpolated_partial_valuesE = interp1(tempTableE.date, tempTableE.partial_vax, dates_interp,'cubic');
    interpolated_partial_valuesE(interpolated_partial_valuesE < 0) = 0;
    interpolated_full_valuesE = interp1(tempTableE.date, tempTableE.full_vax, dates_interp,'cubic');
    interpolated_full_valuesE(interpolated_full_valuesE < 0) = 0;
    % Append to new dates and values
    index_ethnic = (vax_data_ethnic.demographic_value == string(uniqueGroupsE(i))) & (vax_data_ethnic.location==37);
    
    if i~=5
        index_age = (vax_data_age.demographic_value == string(uniqueGroups(i))) & (vax_data_age.location==37);
        vax_data_age(index_age,:).date = [dates_interp';"2021-04-05"];
        vax_data_age(index_age,:).partial_vax = [interpolated_partial_values';0];
        vax_data_age(index_age,:).full_vax = [interpolated_full_values';0];
    end
    
    
    vax_data_ethnic(index_ethnic,:).date = [dates_interp';"2021-04-05"];
    vax_data_ethnic(index_ethnic,:).partial_vax = [interpolated_partial_valuesE';0];
    vax_data_ethnic(index_ethnic,:).full_vax = [interpolated_full_valuesE';0];
end
vax_data_age(vax_data_age.date=="2021-04-05",:) = [];
vax_data_ethnic(vax_data_ethnic.date=="2021-04-05",:) = [];

age_groups = unique(groups{:,2});
%% prep serology data
serology_full_data = serology_full_data((serology_full_data.RegionAbbreviation == "CA-3") | (serology_full_data.RegionAbbreviation == "CA-2") | (serology_full_data.RegionAbbreviation == "CA-1") | (serology_full_data.RegionAbbreviation == "NC"),[1:4 9 10 13 14 17 18 21 22 33 34 37 38 41 42 45 46 49  50]);
serology_full_data = serology_full_data(serology_full_data.MedianDonationDate < "2021-04-17",:);

%%
serology_NC_data = serology_full_data(serology_full_data.RegionAbbreviation == "NC",:);
serology_CA_data = serology_full_data(serology_full_data.RegionAbbreviation ~= "NC",:);

%Sum the 3 cali regions into one. Use median of date
% Group by year-month and calculate the median date for each group
[uniqueYearMonths, ~, groupIdx] = unique(serology_CA_data.YearAndMonth);
medianDates = arrayfun(@(x) median(serology_CA_data.MedianDonationDate(groupIdx == x)), 1:numel(uniqueYearMonths))';
serology_CA_data.MedianDonationDate = medianDates(groupIdx);
for i = 5:2:22
    newColumn = (serology_CA_data{:, i} .* serology_CA_data{:, i+1})./100;
    newColumn2 = (serology_NC_data{:, i} .* serology_NC_data{:, i+1})./100;
    
    % Insert the new column into the table
    C = serology_CA_data.Properties.VariableNames{i};
    newColumnName = C(3:end);%sprintf('Abs_val%s', C);
    
    % Insert the new column into the table with the dynamic name
    serology_CA_data.(newColumnName) = newColumn;
    serology_NC_data.(newColumnName) = newColumn2;
end
serology_CA_data = groupsummary(serology_CA_data, 'MedianDonationDate', 'sum',  [5:2:23 24:31]);%[5:2: 23:31]);
serology_CA_data.location = repmat({'CA'}, height(serology_CA_data),1);
serology_CA_data = removevars(serology_CA_data, 'GroupCount');
for i =2:width(serology_CA_data)/2
    serology_CA_data{:,i} = serology_CA_data{:,i+9}./serology_CA_data{:,i};
end
serology_CA_data = serology_CA_data(:, [20 1:10]);
%serology_CA_data = serology_CA_data(:, [11 1:10]);
serology_NC_data = serology_NC_data(:,[1:4 5:2:23 24:31]);
for i =5:13
    serology_NC_data{:,i} = serology_NC_data{:,i+9}./serology_NC_data{:,i};
end
serology_NC_data = serology_NC_data(:, [2 4 5:13]);
serology_NC_data = renamevars(serology_NC_data, 'RegionAbbreviation', 'location');

%Interpolate (2020-7-18)
uniqueDates1 = unique(serology_CA_data.MedianDonationDate);
dates_interp1 = uniqueDates1(1) + caldays(5):caldays(7):uniqueDates1(end) - caldays(10);

uniqueDates2 = unique(serology_NC_data.MedianDonationDate);
dates_interp2 = uniqueDates2(1) + caldays(4):caldays(7):uniqueDates2(end) - caldays(13);

% interpData1 =serology_CA_data([], :);
% interpData2 =serology_NC_data([], :);
interpData1 = table();
interpData1.date = dates_interp1';
interpData1.location = repmat({'CA'}, height(interpData1),1);
interpData1 = interpData1(:, [2 1]);

interpData2 = table();
interpData2.date = dates_interp2';
interpData2.location = repmat({'NC'}, height(interpData2),1);
interpData2 = interpData2(:, [2 1]);


columnNames = serology_CA_data.Properties.VariableNames;

% Loop over each column and interp
for i = 3:length(columnNames)
    C = columnNames{i};
    interpolated_values1 = interp1(serology_CA_data.MedianDonationDate, serology_CA_data.(C), dates_interp1,'cubic');
    interpolated_values1(interpolated_values1 < 0) = 0; 
    C = C(5:end);
    interpData1.(C) = interpolated_values1';

    interpolated_values2 = interp1(serology_NC_data.MedianDonationDate, serology_NC_data.(C), dates_interp2,'cubic');
    interpolated_values2(interpolated_values2 < 0) = 0; 
    interpData2.(C) = interpolated_values2';
end
% multiply by pop to get total counts
pop_data2 = readtable('state_pop_data.csv');
pop_data2 = pop_data2((pop_data2.NAME=="California") | (pop_data2.NAME=="North Carolina"),:);
pop_data2 = pop_data2((pop_data2.SEX==0),:);
pop_data2 = pop_data2(:,[5 7 20]);
%CA
interpData1{:,3} = interpData1{:,3}.*sum(pop_data2{17:30,3}); %16-29
interpData1{:,4} = interpData1{:,4}.*sum(pop_data2{31:50,3}); %30-49
interpData1{:,5} = interpData1{:,5}.*sum(pop_data2{51:65,3}); %50-64
interpData1{:,6} = interpData1{:,6}.*sum(pop_data2{66:86,3}); %65+

interpData1{:,7} = interpData1{:,7}.*sum(popu(1,[2 7 12])); %White
interpData1{:,8} = interpData1{:,8}.*sum(popu(1,[4 9 14])); %Black
interpData1{:,9} = interpData1{:,9}.*sum(popu(1,[3 8 13])); %Asian
interpData1{:,10} = interpData1{:,10}.*sum(popu(1,[1 6 11])); %Hispanic
interpData1{:,11} = interpData1{:,11}.*sum(popu(1,[5 10 15])); %Other
%NC
pop_data2 = pop_data2((pop_data2.NAME=="North Carolina"),:);
interpData2{:,3} = interpData2{:,3}.*sum(pop_data2{17:30,3}); %16-29
interpData2{:,4} = interpData2{:,4}.*sum(pop_data2{31:50,3}); %30-49
interpData2{:,5} = interpData2{:,5}.*sum(pop_data2{51:65,3}); %50-64
interpData2{:,6} = interpData2{:,6}.*sum(pop_data2{66:86,3}); %65+

interpData2{:,7} = interpData2{:,7}.*sum(popu(2,[2 7 12])); %White
interpData2{:,8} = interpData2{:,8}.*sum(popu(2,[4 9 14])); %Black
interpData2{:,9} = interpData2{:,9}.*sum(popu(2,[3 8 13])); %Asian
interpData2{:,10} = interpData2{:,10}.*sum(popu(2,[1 6 11])); %Hispanic
interpData2{:,11} = interpData2{:,11}.*sum(popu(2,[5 10 15])); %Other

%Combine Age groups
interpData1.("n_16_29YearsPrevalence_") = sum(interpData1{:,[3 4 5]},2);
interpData1.Properties.VariableNames{"n_16_29YearsPrevalence_"} = 'n_18_64YearsPrevalence_';
interpData1 = removevars(interpData1, 'n_30_49YearsPrevalence_');
interpData1 = removevars(interpData1, 'n_50_64YearsPrevalence_');

interpData2.("n_16_29YearsPrevalence_") = sum(interpData2{:,[3 4 5]},2);
interpData2.Properties.VariableNames{"n_16_29YearsPrevalence_"} = 'n_18_64YearsPrevalence_';
interpData2 = removevars(interpData2, 'n_30_49YearsPrevalence_');
interpData2 = removevars(interpData2, 'n_50_64YearsPrevalence_');

%Restructure such that new row entries rather than columns for groups
% Get the size of the original table
[rows, cols] = size(interpData1);

% Create a cell array to hold the reshaped data with four columns
reshapedData = cell(rows*(cols-2), 4);
reshapedData2 = cell(rows*(cols-2), 4);

% Loop through each column of the original table
index = 1;
for i = 3:cols
    % Extract the column values
    columnValues = interpData1(:, i);
    columnValues2 = interpData2(:, i);
    
    % Reshape the column values into a single column
    columnValuesReshaped = reshape(table2array(columnValues), [], 1);
    columnValuesReshaped2 = reshape(table2array(columnValues2), [], 1);
    % Extract the column name
    columnName = interpData1.Properties.VariableNames{i};
    columnName2 = interpData2.Properties.VariableNames{i};
    
    % Determine the demographic value and date corresponding to the current column
    demographic_value = repmat(columnName, rows, 1);
    demographic_value2 = repmat(columnName2, rows, 1);

    date = datetime(interpData1.date, 'InputFormat', 'MM/dd/yyyy');%interpData1.date;%repmat(, 1, rows)';
    loc = interpData1.location;%repmat(, 1, rows)';
    
    date2 = datetime(interpData2.date, 'InputFormat', 'MM/dd/yyyy');%interpData1.date;%repmat(, 1, rows)';
    loc2 = interpData2.location;
    % Assign the reshaped data to the reshapedData matrix
    reshapedData(index:index+rows-1, :) = cellstr([loc, string(date), string(demographic_value), columnValuesReshaped]);
    reshapedData2(index:index+rows-1, :) = cellstr([loc2, string(date2), string(demographic_value2), columnValuesReshaped2]);
    
    % Update the index
    index = index + rows;
end

% Create a table from the reshaped data matrix
finalTable = array2table(reshapedData, 'VariableNames', {'location', 'date', 'demographic_value', 'value'});
finalTable.date = datetime(finalTable.date, 'InputFormat', 'MM/dd/yyyy');
finalTable.value = cellfun(@str2double, finalTable.value);
finalTable2 = array2table(reshapedData2, 'VariableNames', {'location', 'date', 'demographic_value', 'value'});
finalTable2.date = datetime(finalTable2.date, 'InputFormat', 'MM/dd/yyyy');
finalTable2.value = cellfun(@str2double, finalTable2.value);

finalTable.location = categorical(finalTable.location);
locationCategories = categories(finalTable.location);
CA_index = find(locationCategories == "CA");
numericLocation = zeros(size(finalTable.location));
numericLocation(finalTable.location == locationCategories{CA_index}) = 6;
finalTable.location = numericLocation;

finalTable2.location = categorical(finalTable2.location);
locationCategories = categories(finalTable2.location);
NC_index = find(locationCategories == "NC");
numericLocation = zeros(size(finalTable2.location));
numericLocation(finalTable2.location == locationCategories{NC_index}) = 37;
finalTable2.location = numericLocation;

serology_full_data = [finalTable;finalTable2];
demo_gr = unique(serology_full_data.demographic_value);
needed_gr = {'18-64'; '65+'; 'asian'; 'black'; 'latino'; 'other'; 'white'};

for i =1:length(demo_gr)
    indx = serology_full_data.demographic_value == string(demo_gr(i));
    serology_full_data.demographic_value(indx) = needed_gr(i);
end
%Do mapping for location and demographic_val
%%
%Need to account for other offsets
%NC cases and cali hosp 2020-03-07
date_diff = between(data_phase2_death.date(1),data_phase2_case.date(1), 'weeks');
week_diff1 = calweeks(date_diff)+1;
%Cali cases 2020-04-18
date_diff = between(data_phase2_death.date(1),data_phase2_case.date(229), 'weeks');
week_diff2 = calweeks(date_diff)+1;
%NC hosps 2020-10-03
date_diff = between(data_phase2_death.date(1),hosp_NC.date(1), 'weeks');
week_diff3 = calweeks(date_diff)+1;
%phase1 end
date_diff = between(data_phase2_death.date(1),data_phase1_case.date(end), 'weeks');
week_diff4 = calweeks(date_diff)+1;
%Vax start dates 12-14(NC) and 12-19 (Cali). NC now also 12-19 after
%interpolation
date_diff = between(data_phase2_death.date(1),vax_data_age.date(65), 'weeks');
week_diff5 = calweeks(date_diff)+1;
%start of serology
date_diff = between(data_phase2_death.date(1),serology_full_data.date(1), 'weeks');
week_diff6 = calweeks(date_diff)+1;
%% Redistribute the data (By age/ethnic group) Put in correct format (2xTx15)
cases_3D_phase1 = nan(size(locations,1), total_weeks, size(groups,1));
cases_3D_phase2 = nan(size(locations,1), total_weeks, size(groups,1));
cases_3D_imputated = nan(size(locations,1), total_weeks, size(groups,1));

deaths_3D_phase1 = nan(size(locations,1), total_weeks, size(groups,1));
deaths_3D_phase2 = nan(size(locations,1), total_weeks, size(groups,1));

hosp_3D = nan(size(locations,1), total_weeks, size(groups,1));

vax_3D_partial = nan(size(locations,1), total_weeks, size(groups,1));
vax_3D_full = nan(size(locations,1), total_weeks, size(groups,1));

sero_3D = nan(size(locations,1), total_weeks, size(groups,1));

for k = 1:size(locations,1)
    for i = 1:size(groups,1)
        if k==1 %Cali
            offset = week_diff2;
            hosp_data = hosp_CA;
            offset_hosp = week_diff1;
        else
            offset = week_diff1;
            hosp_data = hosp_NC;
            offset_hosp = week_diff3;
        end
        if (k==2) && (string(groups{i,1})=="latino")
            cases_3D_phase1(k,:,i) = zeros(total_weeks,1);
            cases_3D_phase2(k,:,i) = zeros(total_weeks,1);
            cases_3D_imputated(k,:,i) = zeros(total_weeks,1);
            deaths_3D_phase1(k,:,i) = zeros(total_weeks,1);
            deaths_3D_phase2(k,:,i) = zeros(total_weeks,1);
            hosp_3D(k,:,i) = zeros(total_weeks,1);
            vax_3D_partial(k,:,i) = zeros(total_weeks,1);
            vax_3D_full(k,:,i) = zeros(total_weeks,1);
            sero_3D(k,:,i) = zeros(total_weeks,1);
            continue
        end

        %cases (phase 1 and 2) & case imputations
        age_idx = find(cellfun(@(x) isequal(x, string(groups{i,2})), age_groups));
        case_age_group = case_age(k,:,age_idx);
        age_prop = (case_age_group./case_age_T(k,:))'; %starting jan 25

        %phase 1
        index_e = (data_phase1_case.location == (locations.location(k))) & (data_phase1_case.race_ethnicity == string(groups{i,1}));
        index_o = (data_phase1_case.location == (locations.location(k)));
        cases = data_phase1_case(index_e,:); %%ismember            
        cases = sortrows(cases,'date','ascend');

        cases_total = data_phase1_case(index_o,:);
        cases_total = groupsummary(cases_total, 'date', 'sum', {'value'});
        cases_total = sortrows(cases_total,'date','ascend');

        ethnic_prop = cases.value./cases_total.sum_value;

        cases_3D_phase1(k,offset:week_diff4,i) = (ethnic_prop.*age_prop(offset-3:week_diff4-3)).*cases_total.sum_value;

        %phase 2
        index_e = (data_phase2_case.location == (locations.location(k))) & (data_phase2_case.race_ethnicity == string(groups{i,1}));
        index_o = (data_phase2_case.location == (locations.location(k)));
        cases = data_phase2_case(index_e,:); %%ismember            
        cases = sortrows(cases,'date','ascend');

        cases_total = data_phase2_case(index_o,:);
        cases_total = groupsummary(cases_total, 'date', 'sum', {'value'});
        cases_total = sortrows(cases_total,'date','ascend');

        ethnic_prop = cases.value./cases_total.sum_value;

        cases_3D_phase2(k,offset:end,i) = (ethnic_prop.*age_prop(offset-3:end)).*cases_total.sum_value;

        %case imputations
        index_e = (case_imputation.location == (locations.location(k))) & (case_imputation.race_ethnicity == string(groups{i,1}));
        index_o = (case_imputation.location == (locations.location(k)));
        cases = case_imputation(index_e,:); %%ismember            
        cases = sortrows(cases,'date','ascend');

        cases_total = case_imputation(index_o,:);
        cases_total = groupsummary(cases_total, 'date', 'sum', {'value'});
        cases_total = sortrows(cases_total,'date','ascend');

        ethnic_prop = cases.value./cases_total.sum_value;

        cases_3D_imputated(k,offset:end,i) = (ethnic_prop.*age_prop(offset-3:end)).*cases_total.sum_value;

        
        %death (phase 1 and 2)
        death_age_group = death_age(k,:,age_idx);
        age_prop = (death_age_group./death_age_T(k,:))'; %starting jan 25
        firstElement = age_prop(1);
        paddingArray = repmat(firstElement, 1, 3);
        age_prop = [paddingArray'; age_prop];

        %phase 1
        index_e = (data_phase1_death.location == (locations.location(k))) & (data_phase1_death.race_ethnicity == string(groups{i,1}));
        index_o = (data_phase1_death.location == (locations.location(k)));
        deaths = data_phase1_death(index_e,:);          
        deaths = sortrows(deaths,'date','ascend');

        deaths_total = data_phase1_death(index_o,:);
        deaths_total = groupsummary(deaths_total, 'date', 'sum', {'value','min_suppressed'});
        deaths_total.sum_value = deaths_total.sum_value + deaths_total.sum_min_suppressed;

        deaths_total = sortrows(deaths_total,'date','ascend');

        ethnic_prop = deaths.value./deaths_total.sum_value;

        temp = (ethnic_prop.*age_prop(1:week_diff4)).*deaths_total.sum_value;
        temp(isnan(temp)) = 0; %This removes nans for cases where total = 0
        deaths_3D_phase1(k,1:week_diff4,i) = temp;

        %phase 2
        index_e = (data_phase2_death.location == (locations.location(k))) & (data_phase2_death.race_ethnicity == string(groups{i,1}));
        index_o = (data_phase2_death.location == (locations.location(k)));
        deaths = data_phase2_death(index_e,:);          
        deaths = sortrows(deaths,'date','ascend');

        deaths_total = data_phase2_death(index_o,:);
        deaths_total = groupsummary(deaths_total, 'date', 'sum', {'value','min_suppressed'});
        deaths_total.sum_value = deaths_total.sum_value + deaths_total.sum_min_suppressed;

        deaths_total = sortrows(deaths_total,'date','ascend');

        ethnic_prop = deaths.value./deaths_total.sum_value;

        temp = (ethnic_prop.*age_prop).*deaths_total.sum_value;
        temp(isnan(temp)) = 0; %This removes nans for cases where total = 0
        deaths_3D_phase2(k,:,i) = temp;
        
        %Hospitilizations ("other" is missing, considered noise.  in a rate 
        % per 100,000 people for California and number of hospitalization 
        % for North Carolina.)
        hosp_age_group = hosp_age(k,:,age_idx);
        age_prop = (hosp_age_group./hosp_age_T(k,:))';
        if k ==1
            if (string(groups{i,1})=="other") %This is considered noise and negligable
                hosp_3D(k,:,i) = zeros(total_weeks,1);
            else
                index_e = (hosp_data.location == (locations.location(k))) & (hosp_data.race_ethnicity == string(groups{i,1}));
                %index_o = (hosp_data.location == (locations.location(k)));
                hosps = hosp_data(index_e,:); %%ismember            
                hosps = sortrows(hosps,'date','ascend');
                if mod(i,5)~=0
                    ethnic_pop = popu(k,mod(i,5):5:end);
                else
                    ethnic_pop = popu(k,5:5:end);
                end
                hosps.value = hosps.rate.*(sum(ethnic_pop)/100000); %change from rate to absolute value
        
                ethnic_groups = unique(string(groups{:,1}));
                ethnic_groups= ethnic_groups((ethnic_groups ~= string(groups{i,1})) & (ethnic_groups~="other"));
                total_vals = hosps.value;%zeros(size(hosps.value,1));
                for e = 1:length(ethnic_groups)
                    grp = ethnic_groups(e);
                    index_e = (hosp_data.location == (locations.location(k))) & (hosp_data.race_ethnicity == grp);
                    temp = hosp_data(index_e,:); %%ismember            
                    temp = sortrows(temp,'date','ascend');
                    temp_pop = popu(grp==groups{:,1});
                    temp.value = temp.rate.*(sum(temp_pop)/100000);
                    total_vals = total_vals + temp.value;
                end
                ethnic_prop = hosps.value./total_vals;%hosps_total.sum_value;
        
                hosp_3D(k,offset_hosp:end,i) = (ethnic_prop.*age_prop(offset_hosp-3:end)).*total_vals;%hosps_total.sum_value;
            end
        else 
            index_e = (hosp_data.location == (locations.location(k))) & (hosp_data.race_ethnicity == string(groups{i,1}));
            index_o = (hosp_data.location == (locations.location(k))  & (hosp_data.race_ethnicity ~= "unknown"));
            index_u = (hosp_data.location == (locations.location(k)) & (hosp_data.race_ethnicity == "unknown"));
            hosps = hosp_data(index_e,:); %%ismember            
            hosps = sortrows(hosps,'date','ascend');
    
            hosps_total = hosp_data(index_o,:);
            hosps_total = groupsummary(hosps_total, 'date', 'sum', {'value'});
            hosps_total = sortrows(hosps_total,'date','ascend');
    
            ethnic_prop = hosps.value./hosps_total.sum_value;
            %redistribute unknowns
            hosps_unknown = hosp_data(index_u,:); 
            hosps_unknown = sortrows(hosps_unknown,'date','ascend');
    
            hosp_3D(k,offset_hosp:end,i) = ((ethnic_prop.*age_prop(offset_hosp-3:end)).*hosps_total.sum_value) + ((ethnic_prop.*age_prop(offset_hosp-3:end)).*hosps_unknown.value);
        end

        %Vax (need to redistirbute unknowns)
        index_e = (vax_data_ethnic.location == (locations.location(k))) & (vax_data_ethnic.demographic_value == string(groups{i,1}));
        index_o = (vax_data_ethnic.location == (locations.location(k)) & (vax_data_ethnic.demographic_value ~= "unknown"));
        index_u = (vax_data_ethnic.location == (locations.location(k)) & (vax_data_ethnic.demographic_value == "unknown"));
        vax = vax_data_ethnic(index_e,:); %%ismember            
        vax = sortrows(vax,'date','ascend');

        vax_total = vax_data_ethnic(index_o,:);
        vax_total = groupsummary(vax_total, 'date', 'sum', {'partial_vax','full_vax'});
        vax_total = sortrows(vax_total,'date','ascend');

        ethnic_prop_partial = vax.partial_vax./vax_total.sum_partial_vax;
        ethnic_prop = vax.full_vax./vax_total.sum_full_vax;
        
        index_ae = (vax_data_age.location == (locations.location(k))) & (vax_data_age.demographic_value == string(groups{i,2}));
        index_ao = (vax_data_age.location == (locations.location(k))  & (vax_data_age.demographic_value ~= "unknown"));
        index_au = (vax_data_age.location == (locations.location(k))  & (vax_data_age.demographic_value == "unknown"));
        vax_a = vax_data_age(index_ae,:); %%ismember            
        vax_a = sortrows(vax_a,'date','ascend');

        vax_total_a = vax_data_age(index_ao,:);
        vax_total_a = groupsummary(vax_total_a, 'date', 'sum', {'partial_vax','full_vax'});
        vax_total_a = sortrows(vax_total_a,'date','ascend');

        age_prop_partial = vax_a.partial_vax./vax_total_a.sum_partial_vax;
        age_prop = vax_a.full_vax./vax_total_a.sum_full_vax;

        %redistribute unknowns
        vax_unknown = vax_data_ethnic(index_u,:); 
        vax_unknown = sortrows(vax_unknown,'date','ascend');
        vax_unknown_a = vax_data_age(index_au,:); 
        vax_unknown_a = sortrows(vax_unknown_a,'date','ascend');
        
        vax_3D_partial(k,week_diff5:end,i) = ((ethnic_prop_partial.*age_prop_partial).*vax_total.sum_partial_vax) + ((ethnic_prop_partial.*age_prop_partial).*vax_unknown.partial_vax);
        vax_3D_full(k,week_diff5:end,i) = ((ethnic_prop.*age_prop).*vax_total.sum_full_vax)  + ((ethnic_prop.*age_prop).*vax_unknown.full_vax);
        
        %Serology (for 0-17, 0)
        if groups{i,2} == "0-17"
            sero_3D(k,:,i) = zeros(total_weeks,1);
            continue
        end
        index_e = (serology_full_data.location == (locations.location(k))) & (serology_full_data.demographic_value == string(groups{i,1}));
        index_o = (serology_full_data.location == (locations.location(k)) & (serology_full_data.demographic_value ~= "18-64") & (serology_full_data.demographic_value ~= "65+"));
        sero = serology_full_data(index_e,:); %%ismember            
        sero = sortrows(sero,'date','ascend');

        sero_total = serology_full_data(index_o,:);
        sero_total = groupsummary(sero_total, 'date', 'sum', {'value'});
        sero_total = sortrows(sero_total,'date','ascend');

        ethnic_prop = sero.value./sero_total.sum_value;
        
        index_ae = (serology_full_data.location == (locations.location(k))) & (serology_full_data.demographic_value == string(groups{i,2}));
        index_ao = (serology_full_data.location == (locations.location(k)) & ((serology_full_data.demographic_value == "18-64") | (serology_full_data.demographic_value == "65+")));
        sero_a = serology_full_data(index_ae,:); %%ismember            
        sero_a = sortrows(sero_a,'date','ascend');

        sero_total_a = serology_full_data(index_ao,:);
        sero_total_a = groupsummary(sero_total_a, 'date', 'sum', {'value'});
        sero_total_a = sortrows(sero_total_a,'date','ascend');

        age_prop = sero_a.value./sero_total_a.sum_value;

        sero_3D(k,week_diff6:end,i) = (ethnic_prop.*age_prop).*sero_total.sum_value;
        
    end
end

p = movmean(case_full_data, 3, 2, 'Endpoints', 'shrink');
vax_3D_partial(isnan(vax_3D_partial)) = 0;
vax_3D_full(isnan(vax_3D_full)) = 0;
%fill missing data
CA_index = find(~isnan(cases_3D_phase1(1,:,:)),1);
NC_index = find(~isnan(cases_3D_phase1(2,:,2:end)),1);
%j(t)*s(t0)/j(t0) for all t < t0
s_t0_CA = cases_3D_phase1(1,CA_index,:);
s_t0_NC = cases_3D_phase1(2,NC_index,:);
j_t0_CA = sum(s_t0_CA);
j_t0_NC = sum(s_t0_CA);
s_t_CA = case_full_data(1,1:CA_index-1)'*squeeze((s_t0_CA/j_t0_CA))';
s_t_NC = case_full_data(2,1:NC_index-1)'*squeeze((s_t0_NC/j_t0_NC))';
cases_3D_phase1(1,1:CA_index-1,:) = s_t_CA;
cases_3D_phase1(2,1:NC_index-1,:) = s_t_NC;

s_t0_CA = cases_3D_phase2(1,CA_index,:);
s_t0_NC = cases_3D_phase2(2,NC_index,:);
s_t_CA = case_full_data(1,1:CA_index-1)'*squeeze((s_t0_CA/j_t0_CA))';
s_t_NC = case_full_data(2,1:NC_index-1)'*squeeze((s_t0_NC/j_t0_NC))';
cases_3D_phase2(1,1:CA_index-1,:) = s_t_CA;
cases_3D_phase2(2,1:NC_index-1,:) = s_t_NC;

cases_3D_imputated = fillmissing(cases_3D_imputated, 'next', 2);
s_t0_CA = cases_3D_imputated(1,CA_index,:);
s_t0_NC = cases_3D_imputated(2,NC_index,:);
s_t_CA = case_full_data(1,1:CA_index-1)'*squeeze((s_t0_CA/j_t0_CA))';
s_t_NC = case_full_data(2,1:NC_index-1)'*squeeze((s_t0_NC/j_t0_NC))';
cases_3D_imputated(1,1:CA_index-1,:) = s_t_CA;
cases_3D_imputated(2,1:NC_index-1,:) = s_t_NC;

hosp_3D = fillmissing(hosp_3D, 'constant', 0);
%sero_3D = fillmissing(sero_3D, 'next', 2); %Keep nans for missing data
%% Load mobility data
%% Make data Daily
%insert 0s
zerosMatrix = zeros(size(locations,1), 1, size(groups,1));

%Cases
%phase1
cum_cases_3D_phase1 = cat(2, zerosMatrix, cases_3D_phase1);
cum_cases_3D_phase1 = cumsum(cum_cases_3D_phase1,2);
cum_cases_3D_phase1_daily = weekly2daily(cum_cases_3D_phase1);
cum_cases_3D_phase1_daily = diff(cum_cases_3D_phase1_daily, 1, 2);
cases_3D_phase1_daily = cum_cases_3D_phase1_daily(:,1:7*total_weeks,:);
cases_3D_phase1_daily(cases_3D_phase1_daily<0) = 0;

%phase2
cum_cases_3D_phase2 = cat(2, zerosMatrix, cases_3D_phase2);
cum_cases_3D_phase2 = cumsum(cum_cases_3D_phase2,2);
cum_cases_3D_phase2_daily = weekly2daily(cum_cases_3D_phase2);
cum_cases_3D_phase2_daily = diff(cum_cases_3D_phase2_daily, 1, 2);
cases_3D_phase2_daily = cum_cases_3D_phase2_daily(:,1:7*total_weeks,:);
cases_3D_phase2_daily(cases_3D_phase2_daily<0) = 0;

%imputations
cum_cases_3D_imputated = cat(2, zerosMatrix, cases_3D_imputated);
cum_cases_3D_imputated = cumsum(cum_cases_3D_imputated,2);
cum_cases_3D_imputated_daily = weekly2daily(cum_cases_3D_imputated);
cum_cases_3D_imputated_daily = diff(cum_cases_3D_imputated_daily, 1, 2);
cases_3D_imputated_daily = cum_cases_3D_imputated_daily(:,1:7*total_weeks,:);
cases_3D_imputated_daily(cases_3D_imputated_daily<0) = 0;

%deaths
%phase1
cum_deaths_3D_phase1 = cat(2, zerosMatrix, deaths_3D_phase1);
cum_deaths_3D_phase1 = cumsum(cum_deaths_3D_phase1,2);
cum_deaths_3D_phase1_daily = weekly2daily(cum_deaths_3D_phase1);
cum_deaths_3D_phase1_daily = diff(cum_deaths_3D_phase1_daily, 1, 2);
deaths_3D_phase1_daily = cum_deaths_3D_phase1_daily(:,1:7*total_weeks,:);
deaths_3D_phase1_daily(deaths_3D_phase1_daily<0) = 0;

%phase2
cum_deaths_3D_phase2 = cat(2, zerosMatrix, deaths_3D_phase2);
cum_deaths_3D_phase2 = cumsum(cum_deaths_3D_phase2,2);
cum_deaths_3D_phase2_daily = weekly2daily(cum_deaths_3D_phase2);
cum_deaths_3D_phase2_daily = diff(cum_deaths_3D_phase2_daily, 1, 2);
deaths_3D_phase2_daily = cum_deaths_3D_phase2_daily(:,1:7*total_weeks,:);
deaths_3D_phase2_daily(deaths_3D_phase2_daily<0) = 0;

%hosp
cum_hosps_3D = cat(2, zerosMatrix, hosp_3D);
cum_hosps_3D = cumsum(cum_hosps_3D,2);
cum_hosps_3D_daily = weekly2daily(cum_hosps_3D);
cum_hosps_3D_daily = diff(cum_hosps_3D_daily, 1, 2);
hosps_3D_daily = cum_hosps_3D_daily(:,1:7*total_weeks,:);
hosps_3D_daily(hosps_3D_daily<0) = 0;

%Vax
%partial
cum_vax_partial_3D = cat(2, zerosMatrix, vax_3D_partial);
cum_vax_partial_3D = cumsum(cum_vax_partial_3D,2);
cum_vax_partial_3D_daily = weekly2daily(cum_vax_partial_3D);
cum_vax_partial_3D_daily = diff(cum_vax_partial_3D_daily, 1, 2);
vax_partial_3D_daily = cum_vax_partial_3D_daily(:,1:7*total_weeks,:);
vax_partial_3D_daily(vax_partial_3D_daily<0) = 0;

%full
cum_vax_full_3D = cat(2, zerosMatrix, vax_3D_full);
cum_vax_full_3D = cumsum(cum_vax_full_3D,2);
cum_vax_full_3D_daily = weekly2daily(cum_vax_full_3D);
cum_vax_full_3D_daily = diff(cum_vax_full_3D_daily, 1, 2);
vax_full_3D_daily = cum_vax_full_3D_daily(:,1:7*total_weeks,:);
vax_full_3D_daily(vax_full_3D_daily<0) = 0;

%sero
cum_sero_3D = cat(2, zerosMatrix, sero_3D);
cum_sero_3D = cumsum(cum_sero_3D,2);
cum_sero_3D_daily = weekly2daily(cum_sero_3D);
cum_sero_3D_daily = diff(cum_sero_3D_daily, 1, 2);
sero_3D_daily = cum_sero_3D_daily(:,1:7*total_weeks,:);
sero_3D_daily(sero_3D_daily<0) = 0;

demo_groups = groups;
%% save data
save disparity_data.mat cases_3D_phase1_daily cases_3D_phase2_daily cases_3D_imputated_daily deaths_3D_phase1_daily deaths_3D_phase2_daily hosps_3D_daily vax_partial_3D_daily vax_full_3D_daily sero_3D_daily demo_groups total_weeks locations popu;
%% Visualize
for jj = 1:2
  figure; tiledlayout(1, 3)
  nexttile; plot(squeeze(cases_3D_phase2_daily(jj, :, :)));
  nexttile; plot(squeeze(hosps_3D_daily(jj, :, :)));
  nexttile; plot(squeeze(deaths_3D_phase2_daily(jj, :, :)));
end

%% Some Debugging
% count = 0;
% for i = 1:length(abvstate)
%     for j = 1:days_total
%         for k = 1:length(age_groups)
%             if (c_3d(i,j,k)==0) && (d_3d(i,j,k)==0)
%                 disp("Error")
%                 count = count + 1;
%             end
%         end
%     end
% end