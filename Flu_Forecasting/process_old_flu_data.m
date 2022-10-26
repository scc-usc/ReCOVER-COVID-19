filename = 'FluSurveillance_Custom_Download_Data.csv';
data = readtable(filename);
%%

index_T = (data.AGECATEGORY == "Overall") & (data.SEXCATEGORY == "Overall") & (data.RACECATEGORY == "Overall");
data_T = data(index_T,:);

%%
seasons = unique(data_T.YEAR);
all_dat = struct;

for ss = 1:length(seasons)
    idx = strcmpi(data_T.YEAR, seasons(ss));
    all_dat(ss).MMWR_week = data_T.MMWR_WEEK(idx);
    t = datetime(data_T.MMWR_YEAR(idx), 1, 1, 'Format', 'dd-MMMM-yyyy');  % First day of the year
    all_dat(ss).date = t - days(weekday(t)-1) + days((data_T.MMWR_WEEK(idx)-1).*7);
    all_dat(ss).hosp_cumu = data_T.CUMULATIVERATE(idx);
end
save flu_history;

%% Plot one
ss = 4;
dd = all_dat(ss).date;
plot(dd, [0; diff(all_dat(ss).hosp_cumu)]);

%% Plot all
for ss = 1:length(seasons)
    dd = all_dat(ss).date - 365*(ss-1);
    plot(dd, [0; diff(all_dat(ss).hosp_cumu)]); hold on;
end
hold off;