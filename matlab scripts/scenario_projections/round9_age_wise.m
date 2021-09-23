%% Prepare quantiles
quants = [0.01, 0.025, (0.05:0.05:0.95), 0.975, 0.99]';
ag = size(vacc_ag, 3);
scen_ids = {'A'; 'B'; 'C'; 'D'};
dat_type = {'infec'; 'death'; 'hosp'};
scen_names = {'ChildVax_noVar'; 'noChildVax_noVar'; 'ChildVax_Var'; 'noChildVax_Var'};
all_quant_ag = zeros(length(scen_ids), length(dat_type), length(popu), length(quants), 26, ag);
all_mean_ag = zeros(length(scen_ids), length(dat_type), length(popu), 26, ag);

f = zeros(26*7, 26);
for jj=1:26
    f((jj-1)*7+1: jj*7, jj) = 1;
end

for g = 1:ag
    for ss = 1:length(scen_ids)
        for dt = 1:length(dat_type)
            net_dat = eval(['new_' dat_type{dt} '_ag_' scen_ids{ss}]);
            for cid = 1:length(popu)
                thisdata = squeeze(net_dat(:, cid, :, g));
                thisdata = thisdata(:, 1:26*7)*f;
                all_quant_ag(ss, dt, cid, :, :, g) = quantile(thisdata, quants);
                all_mean_ag(ss, dt, cid, :, g) = mean(thisdata, 1);
            end
        end
    end
end
% all_quant_vals(isnan(all_quant_vals)) = 0;
% all_mean_vals(isnan(all_mean_vals)) = 0;

%% Create tables from the matrices
if write_data == 1
    disp('creating inc quant table for states');
    T = table;
    scen_date = '2021-09-14';
    dt_name = {' case'; ' death'; ' hosp'};
    thesevals = all_quant_ag(:);
    [ss, dt, cid, qq, wh, g] = ind2sub(size(all_quant_ag), (1:length(thesevals))');
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
    T.age = age_groups(g);
    
    disp('creating inc mean table for states');
    
    Tm = table;
    thesevals = all_mean_ag(:);
    [ss, dt, cid, wh, g] = ind2sub(size(all_mean_ag), (1:length(thesevals))');
    Tm.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    Tm.scenario_name = scen_names(ss);
    Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    Tm.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    Tm.location = fips(cid);
    Tm.type = repmat({'point'}, [length(thesevals) 1]);
    Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    Tm.value = compose('%g', round(thesevals, 1));
    Tm.age = age_groups(g);
    
    
    % Repeat for US
 %%   
    disp('creating inc quant table for US');
    
    us_all_quant_ag = squeeze(nansum(all_quant_ag, 3));
    us_all_mean_ag = squeeze(nansum(all_mean_ag, 3));
    
    us_T = table;
    dt_name = {' case'; ' death'; ' hosp'};
    wh_string = sprintfc('%d', [1:max(wh)]');
    thesevals = us_all_quant_ag(:);
    [ss, dt, qq, wh, g] = ind2sub(size(us_all_quant_ag), (1:length(thesevals))');
    us_T.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_T.scenario_name = scen_names(ss);
    us_T.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_T.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_T.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_T.location = repmat({'US'}, [length(thesevals) 1]);
    us_T.type = repmat({'quantile'}, [length(thesevals) 1]);
    us_T.quantile = num2cell(quants(qq));
    us_T.value = compose('%g', round(thesevals, 1));
    us_T.age = age_groups(g);
    
    
    disp('creating inc mean table for US');
    
    us_Tm = table;
    thesevals = us_all_mean_ag(:);
    [ss, dt, wh, g] = ind2sub(size(us_all_mean_ag), (1:length(thesevals))');
    us_Tm.model_projection_date = repmat({datestr(datetime(2020, 1, 23)+thisday, 'YYYY-mm-DD')}, [length(thesevals) 1]);
    us_Tm.scenario_name = scen_names(ss);
    us_Tm.scenario_id = strcat(scen_ids(ss), ['-' scen_date]);
    us_Tm.target = strcat(wh_string(wh), ' wk ahead inc', dt_name(dt));
    us_Tm.target_end_date = datestr(size(data_4, 2)+datetime(2020, 1, 23)+first_day_pred-1 + 7*(wh-1), 'YYYY-mm-DD');
    us_Tm.location = repmat({'US'}, [length(thesevals) 1]);
    us_Tm.type = repmat({'point'}, [length(thesevals) 1]);
    us_Tm.quantile = repmat({'NA'}, [length(thesevals) 1]);
    us_Tm.value = compose('%g', round(thesevals, 1));
    us_Tm.age = age_groups(g);
    
    
    disp('Creating combined table');
    
    full_T = [T; Tm; us_T; us_Tm];
    full_T(contains(full_T.target, '27 wk'), :) = [];
    full_T(contains(full_T.target, '28 wk'), :) = [];
    nanidx = (strcmpi(full_T.value, 'NaN'));
    full_T(nanidx, :) = [];
    
    % Write files on disk
    disp('Writing File');
    tic;
    writetable(full_T, ['../../results/to_reich/' datestr(now_date, 'YYYY-mm-DD') '-USC-SIkJalpha_age_wise.csv']);
    toc
    
end