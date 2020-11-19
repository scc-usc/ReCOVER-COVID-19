%% Setup: Assumes  the corresponding load script has been executed
last_day = size(data_4_JHU, 2);
daynums = 122:7:last_day;
%daynums = size(data_4, 2)-10:1:size(data_4, 2);
path = '../results/historical_forecasts/';
dalpha = 1;
horizon = 100; % days of predcitions
dhorizon = horizon;
passengerFlow = 0;
alpha_test = 1; % Set this to one to indicate experimental nature. Will write to "other forecasts"
test_suffix = '_custom_un'; % indicates sescription
 
smooth_factor = 14; un = 10;
un = load(['../results/unreported/' prefix 'unreported.txt']); 
T_val = 7;
if strcmpi(prefix, 'us') || strcmpi(prefix, 'global')
    ihme_countries = readcell(['ihme_' prefix '.txt']);
else
    ihme_countries = countries;
end
%% Compute for all days

for day_idx = 1:length(daynums)
    thisday = daynums(day_idx);
    forecast_date = datetime(2020, 1, 23)+caldays(thisday);
    dirname = datestr(forecast_date, 'yyyy-mm-dd');
    fullpath = [path dirname];      
    
    xx = readtable([fullpath '/' prefix '_data.csv']); data_4 = table2array(xx(2:end, 3:end));
    xx = readtable([fullpath '/' prefix '_deaths.csv']); deaths = table2array(xx(2:end, 3:end));
    lcorrection = daynums(day_idx) - size(data_4, 2); data_4 = [zeros(size(data_4, 1), lcorrection) data_4];
    lcorrection = daynums(day_idx) - size(deaths, 2); deaths = [zeros(size(data_4, 1), lcorrection) deaths];
    
    T_full = thisday;
    
    data_4_s = smooth_epidata(data_4(:, 1:T_full), smooth_factor);
    deaths_s = smooth_epidata(deaths(:, 1:T_full), smooth_factor);
    
    [best_param_list] = hyperparam_tuning(data_4(:, 1:T_full), data_4_s, popu, 0, un, T_full, T_val); %, (1:3), [7 14], [1], [25 50 100]);
    [best_death_hyperparam, one_hyperparam] = death_hyperparams(deaths(:, 1:T_full), data_4_s, deaths_s, T_full, T_val, popu, 0, best_param_list, un);
    dk = best_death_hyperparam(:, 1);
    djp = best_death_hyperparam(:, 2);
    dwin = best_death_hyperparam(:, 3);
    lag = best_death_hyperparam(:, 4);
    
    base_infec = data_4(:, T_full);
    beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2));
    infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec);
    
    infec_un_re = infec_un - repmat(base_infec - data_4_s(:, T_full), [1, size(infec_un, 2)]);
    infec_data = [data_4_s(:, 1:T_full), infec_un_re];
    base_deaths = deaths(:, T_full);
    
    [death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin);
    [pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
    
    pred_deaths = pred_deaths(:, 1:horizon); infec_un = infec_un(:, 1:horizon);
    
    lowidx = popu < 1; % No lowidx
    
    if alpha_test == 1
        target_path_deaths = ['../results/others_death_forecasts/biweekly_reports/state-death/SIkJa' test_suffix '_' num2str(thisday+1) '.csv'];
        target_path_cases = ['../results/others_death_forecasts/biweekly_reports/state-case/SIkJa' test_suffix '_' num2str(thisday+1) '.csv'];
        a_sunday = 94;
        dow = mod(thisday-a_sunday,7);
        first_sunday = thisday + 7-dow;
        base_deaths1 = deaths(:, T_full-dow);
        base_infec1 = data_4(:, T_full-dow);
        deaths_to_write = round([base_deaths diff([base_deaths1 pred_deaths(:, 7-dow:7:end)]')']);
        cases_to_write = round([base_infec diff([base_infec1 infec_un(:, 7-dow:7:end)]')']);
        dcols = [thisday+1 first_sunday:7:(first_sunday+7*(size(deaths_to_write, 2)-2))];
        writecell([{''} {'State'} num2cell(dcols); [num2cell([0:length(ihme_countries)-1]')] ihme_countries num2cell(deaths_to_write)], target_path_deaths);
        writecell([{''} {'State'} num2cell(dcols); [num2cell([0:length(ihme_countries)-1]')] ihme_countries num2cell(cases_to_write)], target_path_cases);
    else
    writetable(infec2table([base_infec infec_un], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_cases.csv']);
    writetable(infec2table([base_deaths pred_deaths], ihme_countries, lowidx, forecast_date-1, 1, 1), [fullpath '/' prefix '_forecasts_deaths.csv']);
    end
    
    disp(['Finished for day' dirname]);
end


