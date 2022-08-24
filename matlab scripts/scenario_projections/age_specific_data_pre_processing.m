%% Download data from CDC
% sel_url = 'https://data.cdc.gov/resource/n8mc-b4w4.csv';
% 
% urlwrite(sel_url, 'dummy.csv');
% data = readtable('dummy.csv');
addpath('../');
%% Loading data from local
tic;
filename2 = '../../../../data_dumps/COVID-19_Case_Surveillance_Public_Use_Data_with_Geography.csv';
data = readtable(filename2);
data.case_month = cellfun(@(x)[x '-23'], data.case_month, 'uni', false);

abvstate = readcell('us_states_abbr_list.txt');

toc;
%%
age_groups = unique(data.age_group);
age_groups = age_groups(1:4);
%%
tic;
dates = sort(data.case_month);
for j = length(dates):-1:1
    if dates(j) ~= "NA-23"
        final_date = dates(j);
        break
    end
    %q = [q q_int+(j*0.1)];
end
days_total = days(final_date - datetime(2020, 1, 23)) + 1; %Assuming jan23 is day 1

cases_3D = nan(length(abvstate), days_total, length(age_groups));
hosp_3D = nan(length(abvstate), days_total, length(age_groups));
deaths_3D = nan(length(abvstate), days_total, length(age_groups));

dayspermonth = [31 28 31 30 31 30 31 31 30 31 30 31];
toc;
%%
tic;
for k = 1:length(abvstate)
    for i = 1:length(age_groups)
        
        %cases
        index = (data.res_state == string(abvstate{k})) & (data.age_group == string(age_groups{i}) & (data.case_month ~= "NA-23"));
        cases = data(index,:); %%ismember
              
        xx= table2array(cases(:,1));
        Dates= unique(xx,'stable');        
        b=cell2table(cellfun(@(x) sum(ismember(xx,x)),Dates,'un',0));
        
        T = [cell2table(Dates) b];        
        T.Properties.VariableNames = {'date', 'cases'};
        try
            T.date = datetime(T{:,1}, 'format', 'yyyy-MM-dd');
        catch
            continue
        end
        t= table2timetable(T);
        tt = sortrows(t);
        TT = retime(tt, 'daily', 'fillwithmissing');
        TT.cases = TT.cases./(dayspermonth(month(TT.date)));
        TT = timetable2table(TT);
        TT.date = days(TT.date - datetime(2020, 1, 23)) + 1; %%Assuming 23 is day 1 (not 0)        
        TT.cases = fillmissing(TT.cases, 'next');
        p=1;
        for l = TT.date(1):TT.date(end)
            cases_3D(k,l, i) = TT.cases(p);
            p = p + 1;
        end
        
        %Hospitilizations
        index = cases.hosp_yn == "Yes";
        hosp = cases(index,:);
      
        yy= table2array(hosp(:,1));
        Dates_h= unique(yy,'stable');        
        b_h=cell2table(cellfun(@(x) sum(ismember(yy,x)),Dates_h,'un',0));
        
        T_h = [cell2table(Dates_h) b_h];        
        T_h.Properties.VariableNames = {'date', 'hosp'};
        try
            T_h.date = datetime(T_h{:,1}, 'format', 'yyyy-MM-dd');
        catch
            continue
        end
        t_h= table2timetable(T_h);
        tt_h = sortrows(t_h);
        TT_h = retime(tt_h, 'daily', 'fillwithmissing');
        TT_h.hosp = TT_h.hosp./(dayspermonth(month(TT_h.date)));
        TT_h = timetable2table(TT_h);
        TT_h.date = days(TT_h.date - datetime(2020, 1, 23)) + 1; %%Assuming 23 is day 1 (not 0)
        TT_h.hosp = fillmissing(TT_h.hosp, 'next');
        p=1;
        for l = TT_h.date(1):TT_h.date(end)
            hosp_3D(k,l, i) = TT_h.hosp(p);
            p = p + 1;
        end
        
        %death
        index = cases.death_yn == "Yes";
        deaths = cases(index,:);
        
        zz= table2array(deaths(:,1));
        Dates_d= unique(zz,'stable');        
        b_d=cell2table(cellfun(@(x) sum(ismember(zz,x)),Dates_d,'un',0));
        
        T_d = [cell2table(Dates_d) b_d];        
        T_d.Properties.VariableNames = {'date', 'deaths'};
        try
            T_d.date = datetime(T_d{:,1}, 'format', 'yyyy-MM-dd');
        catch
            continue
        end
        t_d= table2timetable(T_d);
        tt_d = sortrows(t_d);
        TT_d = retime(tt_d, 'daily', 'fillwithmissing');
        TT_d.deaths = TT_d.deaths./(dayspermonth(month(TT_d.date)));
        TT_d = timetable2table(TT_d);
        TT_d.date = days(TT_d.date - datetime(2020, 1, 23)) + 1; %%Assuming 23 is day 1 (not 0)
        TT_d.deaths = fillmissing(TT_d.deaths, 'next');
        p=1;
        for l = TT_d.date(1):TT_d.date(end)
            deaths_3D(k,l, i) = TT_d.deaths(p);
            p = p + 1;
        end        
    end
end
toc;
%% Dummy variables for debugging & filling of early day values
c_3d=fillmissing(cases_3D, 'next', 2);%cases_3D;
h_3d=fillmissing(hosp_3D, 'next', 2);%hosp_3D;
%d_3d=fillmissing(deaths_3D, 'next', 2);%deaths_3D;
%% deaths
sel_url2 = 'https://data.cdc.gov/resource/vsak-wrfu.csv';
urlwrite(sel_url2, 'dummy2.csv'); %Download is outdated
data2 = readtable('dummy2.csv');
%%
data2_index = (data2.sex == "All Sex") & (days(data2.EndWeek - datetime(2020, 1, 23)) > 0);
data_D = data2(data2_index,:);
deaths_2d = nan(days_total, 6); %5,11,17,64 % linear interpolate from 14-17 / 5-14
%% fix death age groups
age_cases = nan(1, 6);
for i = 1:12:height(data_D)
    temp1 = data_D(data_D.AgeGroup ~= "All Ages" & data_D.EndWeek == data_D.EndWeek(i),:);
    age_cases(1) = sum(temp1.COVID_19Deaths(1:2));% + (temp1.COVID_19Deaths(4)/2);
    age_cases(3) =interp1(temp1.COVID_19Deaths(3:4), 1.3); %12-17 consists of 30% of ages 5-24
    age_cases(2) = interp1([temp1.COVID_19Deaths(3) age_cases(3)],(1+3/13)) - temp1.COVID_19Deaths(3); %12-14 consist of 3/13 of 5-17
    age_cases(4) = sum(temp1.COVID_19Deaths(3:4))-(age_cases(2) + age_cases(3)) + sum(temp1.COVID_19Deaths(5:6)) + (temp1.COVID_19Deaths(7)/2);
    age_cases(5) = (temp1.COVID_19Deaths(7)/2) + temp1.COVID_19Deaths(8);
    age_cases(6) = sum(temp1.COVID_19Deaths(9:end)); 
    day = days(data_D.EndWeek(i) - datetime(2020, 1, 23))+ 1;
    deaths_2d(day,:) = age_cases/dayspermonth(month(data_D.EndWeek(i)));
end
deaths_2d = fillmissing(deaths_2d(1:days_total,:), "next");
%deaths_2d(isnan(deaths_2d))=0;
%% Fill out missing values for states with median values
%c_3d(c_3d==0)=NaN;
%h_3d(h_3d==0)=NaN;
%d_3d(d_3d==0)=NaN;
median_c=nanmedian(c_3d(:,:,:));
median_h=nanmedian(h_3d(:,:,:));
median_d=nanmedian(deaths_2d(:,:));
for i = 1:length(abvstate)
    for j = 1:days_total
%         for k = 1:4
%             if isnan(c_3d(i,j,k))
%                 c_3d(i,j,k) = median_c(1,j,k);
%             end
%             
%             if isnan(h_3d(i,j,k))
%                 h_3d(i,j,k) = median_h(1,j,k);
%             end            
%         end
    if sum(isnan(c_3d(i,:,:))) == 579  %No data across any age group for state i
        c_3d(i,:,:) = median_c;
    end
    
    if sum(isnan(h_3d(i,:,:))) == 579  %No data across any age group for state i
        h_3d(i,:,:) = median_h;
    end
    end
end
for j = 1:days_total
    for k = 1:6
        if isnan(deaths_2d(j,k))
            deaths_2d(j,k) = median_d(1,k);
        end
    end
end
c_3d=fillmissing(c_3d, 'previous');%cases_3D;
h_3d=fillmissing(h_3d, 'previous');

%% Add the extra age groups for cases/hosps
popdata = readtable('pop_by_age.csv');
%%
age_groups = {'0-4', '5-11', '12-17', '18 to 49', '50 to 64', '65+ years'}';
c_3d(:,:,4:6) = c_3d(:,:,2:4);
h_3d(:,:,4:6) = h_3d(:,:,2:4);

val1 = popdata{:,1}./sum(popdata{:,1:3},2);
val2 = popdata{:,2}./sum(popdata{:,1:3},2);
val3 = popdata{:,3}./sum(popdata{:,1:3},2);
for i=1:length(abvstate)
    c_3d(i,:,2) = c_3d(i,:,1) * val2(i);
    c_3d(i,:,3) = c_3d(i,:,1) * val3(i);
    c_3d(i,:,1) = c_3d(i,:,1) * val1(i);
    
    h_3d(i,:,2) = h_3d(i,:,1) * val2(i);
    h_3d(i,:,3) = h_3d(i,:,1) * val3(i);
    h_3d(i,:,1) = h_3d(i,:,1) * val1(i);
end
%% Find distribution of hospitilizations across states & apply to deaths
d_3d = nan(size(h_3d));
for j=1:length(abvstate)
    for i=1:length(h_3d)
        for k = 1:length(age_groups)
            d_3d(j,i,k) = (h_3d(j,i,k)/sum(h_3d(:,i,k)))*deaths_2d(i,k);
        end
    end
end
%% Get fraction per day across age groups
tic;
for i = 1:length(abvstate)
    for j = 1:days_total
        c_3d(i,j,:) = c_3d(i,j,:)/sum(c_3d(i,j,:));
        h_3d(i,j,:) = h_3d(i,j,:)/sum(h_3d(i,j,:));
        d_3d(i,j,:) = d_3d(i,j,:)/sum(d_3d(i,j,:));
    end
end
toc;
%Remove Nans from 0/0s
c_3d(isnan(c_3d))=0;
h_3d(isnan(h_3d))=0;
d_3d(isnan(d_3d))=0;
%% Visualize
for jj = 1:5
  figure; tiledlayout(1, 3)
  nexttile; plot(squeeze(c_3d(jj, :, :)));
  nexttile; plot(squeeze(h_3d(jj, :, :)));
  nexttile; plot(squeeze(d_3d(jj, :, :)));
end

save age_outcomes.mat abvstate age_groups c_3d d_3d days_total h_3d;
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