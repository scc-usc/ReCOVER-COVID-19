lastday = 131;
firstday = 116;
skipdays = 7;
total = 1 + (lastday - firstday)./skipdays;

time_stamps = containers.Map((1:total), (firstday:skipdays:lastday));
methods = {'CU', 'JHU', 'UCLA'};
%%
for mm = 1:length(methods)
    for tt = 1:length(time_stamps)
        fname = [methods{mm}, '_', num2str(time_stamps(tt)), '.csv'];
        preds = readtable(['../results/others_death_forecasts/', fname]);
        preds = preds{2:end, 4:end};
        eval([methods{mm}, '{',  num2str(tt),'} = ', 'preds;']);
    end
end

%% Generate own results

T_full = 116;
dk = 3;
djp = 7;
dalpha = 1;
dwin = 49;
horizon = 20;
dhorizon = horizon; % days of deaths predcitions
un = 20;

for tt = 1:length(time_stamps)
    T_full = time_stamps(tt);
    eval(['load '  prefix '_hyperparam_ref_' num2str(T_full - 3)]);
    best_param_list = best_param_list_no;
    
    beta_after = var_ind_beta_un(data_4_s(:, 1:T_full), passengerFlow*0, best_param_list(:, 3)*0.1, best_param_list(:, 1), un, popu, best_param_list(:, 2));
    infec_un = var_simulate_pred_un(data_4_s(:, 1:T_full), passengerFlow*0, beta_after, popu, best_param_list(:, 1), horizon, best_param_list(:, 2), un);
    infec_data = [data_4_s(:, T_full-dk*djp:T_full), infec_un];
    
    base_deaths = deaths(:, T_full);
    
    [death_rates] = var_ind_deaths(data_4_s, deaths_s, dalpha, dk, djp, dwin);
    [pred_deaths] = var_simulate_deaths(infec_data, death_rates, dk, djp, dhorizon, base_deaths);
      
    T_val = 14; % For error calculation
    preds = diff(pred_deaths')';
    SIkJa{tt} = preds(:, 1:T_val);
    disp('Done!');
end
methods = [methods {'SIkJa'}];

%%
cidx = deaths(:, firstday)>10; cidx([51, 52, 53, 55, 56]) = 0;
for mm = 1:length(methods)
    for tt = 1:length(time_stamps)
        eval(['preds = ' methods{mm}, '{',  num2str(tt),'};']);
        gt = deaths(:, time_stamps(tt):end);
        gt = diff(gt')';
        gt = gt(:, 1:T_val);
        eval(['preds = ', methods{mm}, '{',  num2str(tt),'};']);
        %preds = (preds + abs(preds))/2;
        preds = abs(preds);
        [meanMSE, meanMAPE] = calc_errors(gt(cidx, 2:end), preds(cidx, 2:end));
        eval(['MSE_' methods{mm}, '(',  num2str(tt),') = meanMSE;']);
        eval(['MAPE_' methods{mm}, '(',  num2str(tt),') = meanMAPE;']);
    end
end

%% Present results
for tt = 1:length(time_stamps)
    fprintf('For day %d\n', time_stamps(tt));
    for mm = 1:length(methods)
        eval(['meanMSE = MSE_' methods{mm} '(' num2str(tt) ');']);
        eval(['meanMAPE = MAPE_' methods{mm} '(' num2str(tt) ');']);
        disp([methods{mm} '::' num2str([meanMSE meanMAPE])]);
    end
    fprintf('_______________\n');
end
