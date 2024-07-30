fips = fips(:);

disp('creating inc quant table for states');
all_samps_diff = sum(all_run_states, 6);
T = table;
first_day_pred = 7;
% scen_date = '2022-10-29';
% dt_name = {' case'; ' death'; ' hosp'};
dt_name = dat_type;
thesevals = all_samps_diff(:);
[ss, dt, cid, qq, wh] = ind2sub(size(all_samps_diff), (1:length(thesevals))');
wh_string = sprintfc('%d', [1:max(wh)]');
T.model_projection_date = repmat({datestr(zero_date+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
T.scenario_name = scen_names(ss);
T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
T.target_end_date = datestr(thisday+zero_date+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
T.location = fips(cid);
T.sample = num2cell((qq));
T.value = compose('%g', round(thesevals, 1));
% Repeat for US

disp('creating inc quant table for US');

us_all_samps_diff = squeeze(nansum(all_samps_diff, 3));

us_T = table;

wh_string = sprintfc('%d', [1:max(wh)]');
thesevals = us_all_samps_diff(:);
[ss, dt, qq, wh] = ind2sub(size(us_all_samps_diff), (1:length(thesevals))');
us_T.model_projection_date = repmat({datestr(zero_date+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
us_T.scenario_name = scen_names(ss);
us_T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
us_T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
us_T.target_end_date = datestr(thisday+zero_date+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
us_T.location = repmat({'US'}, [length(thesevals) 1]);
us_T.sample = num2cell((qq));
us_T.value = compose('%g', round(thesevals, 1));

disp('Creating combined table');
%%
full_T_s = [T; us_T];
bad_idx = contains(full_T_s.target, compose('%g wk ', [27:60])) | contains(full_T_s.location, '50');
nanidx = (strcmpi(full_T_s.value, 'NaN'));
full_T_s(bad_idx|nanidx, :) = [];

%% Write files on disk
disp('Writing File');
tic;
writetable(full_T_s, ['../../../../data_dumps/' datestr(now_date, 'YYYY-mm-DD') '-USC-SIkJalpha-sample.csv']);
toc