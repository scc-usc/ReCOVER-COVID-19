%% Request Oct 14
result = [];
for dt = 1:length(dat_type)
    this_row = [];
    for scen = 1:length(scen_ids)
        xx = eval(['net_' dat_type{dt} '_' scen_ids{scen}]);
        t1 = days(datetime(2021, 11, 1) - datetime(2020, 1, 23))  - thisday;
        t2 = days(datetime(2022, 3, 12) - datetime(2020, 1, 23))  - thisday;
        temp = zeros(4, 2);
        temp(1, 1) = squeeze(mean(sum(xx(:, :, t1), 2), 1));
        temp(1, 2) = squeeze(mean(sum(xx(:, :, t2), 2), 1));
        temp(2, 1) = squeeze(var(sum(xx(:, :, t1), 2), 1));
        temp(2, 2) = squeeze(var(sum(xx(:, :, t2), 2), 1));
        temp(3, 1) = squeeze(mean(log10(sum(xx(:, :, t1), 2)), 1));
        temp(3, 2) = squeeze(mean(log10(sum(xx(:, :, t2), 2)), 1));
        temp(4, 1) = squeeze(var(log10(sum(xx(:, :, t1), 2)), 1));
        temp(4, 2) = squeeze(var(log10(sum(xx(:, :, t2), 2)), 1));
        
        this_row = [this_row temp];
    end
    result = [result; this_row];
end
%%
T = table;
for dt = 1:length(dat_type)
    for scen = 1:length(scen_ids)
        xx = dat_type{dt}; yy = scen_ids{scen};
        zz = eval(['cumsum(new_' xx '_ag_' yy ', 3);']);
        cumu_data = zz(:, :, 7:7:7*26, :);
        cumu_data_us = squeeze(sum(zz(:, :, 7:7:7*num_wk_ahead, :), 2));
        
        thesevals = cumu_data(:);
        [qq, cid, dd, g] = ind2sub(size(cumu_data), (1:length(thesevals))');
        
        T1 = table;
        T1.scenario = repmat(scen_ids(scen), [length(thesevals), 1]);
        T1.type = repmat(dat_type(dt), [length(thesevals), 1]);
        T1.location = fips(cid);
        T1.date = datetime(2020, 1, 23) + thisday + 7*dd;
        T1.simulation_no = qq;
        T1.age_group = age_groups(g);
        T1.value = thesevals;
        T = [T; T1];
        
        thesevals = cumu_data_us(:);
        [qq, dd, g] = ind2sub(size(cumu_data_us), (1:length(thesevals))');
        T1 = table;
        T1.scenario = repmat(scen_ids(scen), [length(thesevals), 1]);
        T1.type = repmat(dat_type(dt), [length(thesevals), 1]);
        T1.location = repmat({'US'}, [length(thesevals), 1]);
        T1.date = datetime(2020, 1, 23) + thisday + 7*dd;
        T1.simulation_no = qq;
        T1.age_group = age_groups(g);
        T1.value = thesevals;
        T = [T; T1];
    end
end

%%
sel_ag = 1:5;
T = table;
for dt = 1:length(dat_type)
    xx = dat_type{dt};
    zz = eval(['sum(cumsum(new_'  xx '_ag_B(:, :, :, sel_ag) - new_' xx '_ag_A(:, :, :, sel_ag), 3), 4)']);
    eval([ xx '_adv_novar = squeeze(quantile(zz(:, :, 7:7:7*26, :), quants, 1));']);
    zz = eval(['sum(cumsum(new_'  xx '_ag_D(:, :, :, sel_ag) - new_' xx '_ag_C(:, :, :, sel_ag), 3), 4)']);
    eval([ xx '_adv_var = squeeze(quantile(zz(:, :, 7:7:7*26, :), quants, 1));']);
    
    zz = eval(['sum(sum(cumsum(new_'  xx '_ag_B(:, :, :, sel_ag) - new_' xx '_ag_A(:, :, :, sel_ag), 3), 2), 4)']);
    eval([ xx '_adv_novar_us = squeeze(quantile(zz(:, :, 7:7:7*26, :), quants, 1));']);
    zz = eval(['sum(sum(cumsum(new_'  xx '_ag_D(:, :, :, sel_ag) - new_' xx '_ag_C(:, :, :, sel_ag), 3), 2), 4)']);
    eval([ xx '_adv_var_us = squeeze(quantile(zz(:, :, 7:7:7*26, :), quants, 1));']);
    temp = eval([ xx '_adv_novar']);
    thesevals = temp(:);
    [qq, cid, dd] = ind2sub(size(temp), (1:length(thesevals))');
    T1 = table;
    T1.scenario = repmat({'B vs A'}, [length(thesevals), 1]);
    T1.type = repmat(dat_type(dt), [length(thesevals), 1]);
    T1.location = fips(cid);
    T1.date = datetime(2020, 1, 23) + thisday + 7*dd;
    T1.quantile = quants(qq);
    T1.value = thesevals;
    T = [T; T1];
    
    temp = eval([ xx '_adv_var']);
    thesevals = temp(:);
    [qq, cid, dd] = ind2sub(size(temp), (1:length(thesevals))');
    T1 = table;
    T1.scenario = repmat({'D vs C'}, [length(thesevals), 1]);
    T1.type = repmat(dat_type(dt), [length(thesevals), 1]);
    T1.location = fips(cid);
    T1.date = datetime(2020, 1, 23) + thisday + 7*dd;
    T1.quantile = quants(qq);
    T1.value = thesevals;
    T = [T; T1];
    
    temp = eval([ xx '_adv_novar_us']);
    thesevals = temp(:);
    [qq, dd] = ind2sub(size(temp), (1:length(thesevals))');
    T1 = table;
    T1.scenario = repmat({'B vs A'}, [length(thesevals), 1]);
    T1.type = repmat(dat_type(dt), [length(thesevals), 1]);
    T1.location = repmat({'US'}, [length(thesevals), 1]);
    T1.date = datetime(2020, 1, 23) + thisday + 7*dd;
    T1.quantile = quants(qq);
    T1.value = thesevals;
    T = [T; T1];
    
    temp = eval([ xx '_adv_var_us']);
    thesevals = temp(:);
    [qq, dd] = ind2sub(size(temp), (1:length(thesevals))');
    T1 = table;
    T1.scenario = repmat({'D vs C'}, [length(thesevals), 1]);
    T1.type = repmat(dat_type(dt), [length(thesevals), 1]);
    T1.location = repmat({'US'}, [length(thesevals), 1]);
    T1.date = datetime(2020, 1, 23) + thisday + 7*dd;
    T1.quantile = quants(qq);
    T1.value = thesevals;
    T = [T; T1];
    
end

%%
% cases_cumu_ag = cumsum([zeros(ns, 1) diff(data_4, 1, 2)].*c_3d1, 2); %cases_cumu_ag = squeeze(cases_cumu_ag(:, end, :));
% deaths_cumu_ag = cumsum([zeros(ns, 1) diff(deaths, 1, 2)].*d_3d1, 2); %deaths_cumu_ag = squeeze(deaths_cumu_ag(:, end, :));
% hosp_cumu_ag = cumsum([zeros(ns, 1) diff(hosp_cumu, 1, 2)].*h_3d1, 2); %hosp_cumu_ag = squeeze(hosp_cumu_ag(:, end, :));
% %%
% vectorarray = num2cell(cases_cumu_ag, 1) ; T_c = table(fips, vectorarray{:}, 'VariableNames', [{'fips'}, age_groups']);
% vectorarray = num2cell(deaths_cumu_ag, 1) ; T_d = table(fips, vectorarray{:}, 'VariableNames', [{'fips'}, age_groups']);
% vectorarray = num2cell(hosp_cumu_ag, 1) ; T_h = table(fips, vectorarray{:}, 'VariableNames', [{'fips'}, age_groups']);
% 
% 
% writetable(T_c, 'observed_cases.csv');
% writetable(T_d, 'observed_deaths.csv');
% writetable(T_h, 'observed_hosps.csv');

%%
