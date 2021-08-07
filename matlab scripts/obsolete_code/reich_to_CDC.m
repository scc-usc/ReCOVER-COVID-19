fips_info = readtable('reich_fips.txt');
sel_url = 'https://raw.githubusercontent.com/reichlab/covid19-forecast-hub/master/data-processed/USC-SI_kJalpha/2020-11-08-USC-SI_kJalpha.csv';
urlwrite(sel_url, 'dummy.csv');
USC_preds = readtable('dummy.csv');
%%
fips = cell(79, 1);
val_fips = fips_info.location > 0 & fips_info.location < 79;
fips(fips_info.location(val_fips)) = fips_info.location_name(val_fips);
fips{79} = "National";
%%
val_idx = USC_preds.location > 0 & USC_preds.location < 79 ;
sel_preds = USC_preds(val_idx, :);
idx = isnan(USC_preds.location);
sel_preds = [sel_preds; USC_preds(idx, :)];
sel_preds.location(isnan(sel_preds.location)) = 79;
%%
T = table;
T.model = repmat("USC", [length(sel_preds.location) 1]);
T.forecast_date = repmat(USC_preds.forecast_date(1)+1, [length(sel_preds.location) 1]);
T.target = sel_preds.target;
T.target_week_end_date = sel_preds.target_end_date;
T.location_name = fips(sel_preds.location);
T.point = sel_preds.value;
T.quantile_0025 = repmat("NA", [length(sel_preds.location) 1]);
T.quantile_025 = repmat("NA", [length(sel_preds.location) 1]);
T.quantile_075 = repmat("NA", [length(sel_preds.location) 1]);
T.quantile_0975 = repmat("NA", [length(sel_preds.location) 1]);

writetable(T, ['../results/to_reich/USC_' datestr(USC_preds.forecast_date(1), 'YYYY-mm-DD')]);