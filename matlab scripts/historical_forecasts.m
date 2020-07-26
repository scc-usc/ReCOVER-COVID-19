%%% Must run the appropriate data loading script first
%% Setup
daynums = 100:1:183;
path = '../results/historical_forecasts/';
smooth_factor = 7;
dalpha = 1;
un = 20;
horizon = 100; % days of predcitions
dhorizon = horizon;
passengerFlow = 0;

%% Compute for all days

for day_idx = 1:length(daynums)
    thisday = daynums(day_idx);
    forecast_date = datetime(2020, 1, 23)+caldays(thisday);
    dirname = datestr(forecast_date, 'yyyy-mm-dd');
    fullpath = [path dirname];
       
    if ~exist(fullpath, 'dir')
        mkdir(fullpath);
    end
    
    T_full = thisday;
    data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4(:, 1:T_full)')', smooth_factor, 2), 2)];
    deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths(:, 1:T_full)')', smooth_factor, 2), 2)];
    
    [best_param_list] = hyperparam_tuning(data_4(:, 1:T_full), data_4_s, popu, 0, 20, T_full);
    [best_death_hyperparam, one_hyperparam] = death_hyperparams(deaths(:, 1:T_full), data_4_s, deaths_s, T_full, 7, popu, 0, best_param_list, 20);
    dk = best_death_hyperparam(:, 1);
    djp = best_death_hyperparam(:, 2);
    dwin = best_death_hyperparam(:, 3);
    
    base_infec = data_4(:, T_full);
    beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2));
    infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un, base_infec);
    
    infec_data = [data_4_s(:, 1:T_full), infec_un];
    base_deaths = deaths(:, T_full);
    
    [death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin);
    [pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths, T_full-1);
    
    lowidx = popu < 1; % No lowidx
    
    writetable(infec2table(infec_un, countries, lowidx, forecast_date), [fullpath '/' prefix '_forecasts_cases.csv']);
    writetable(infec2table(pred_deaths, countries, lowidx, forecast_date), [fullpath '/' prefix '_forecasts_deaths.csv']);
    
    disp(['Finished for day' dirname]);
end


