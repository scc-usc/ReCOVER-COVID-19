%%%% Calculates "Transmission score" used for "Contact Reduction Score" in https://arxiv.org/abs/2004.11372
%%%% Also calculates the Dynamic Reproduction Number with time

warning off;

eval(['load_data_' prefix]);

alpha_start = 5;
all_scores = [];
all_scores_f = [];
Rt_scores = [];
Rt_dev = [];
MFR_scores = [];
MFR_dev = [];
skip_length = 7;
horizon = 7; % Same as validation
un = 20;

saved_days = 155; % Set it to higher number to avoid recomputing hypoerparameters from the beginning
start_day = 50;


data_4_s = [data_4(:, 1) cumsum(movmean(diff(data_4')', 7, 2), 2)];
deaths_s = [deaths(:, 1) cumsum(movmean(diff(deaths')', 7, 2), 2)];

%% Death hyperparams
dk = 3;
djp = 7;
dalpha = 1;
dwin = 50; % Choose a lower number if death rates evolve

%%

for daynum = start_day:skip_length:(size(data_4, 2))
    display(['Until ' num2str(daynum)]);
    fname = ['./hyper_params/' prefix '_hyperparam_ref_' num2str(daynum)];
    
    T_tr = daynum; % Choose reference day here
 
    if daynum <= saved_days
        load(fname);
    elseif T_tr+horizon <= size(data_4, 2)
        [best_param_list_no, MAPEtable_notravel_fixed_s] = hyperparam_tuning(data_4(:, 1:T_tr+horizon), data_4_s(:, 1:T_tr+horizon), popu, 0, un, T_tr+horizon);
        save(fname, 'MAPEtable_notravel_fixed_s', 'best_param_list_no');
    else
        horizon = 0;
    end
    
    % Compute scores
    
    [beta_notravel, ~, ci] = var_ind_beta_un(data_4_s(:, 1:T_tr+horizon), 0, best_param_list_no(:, 3)*0.1, best_param_list_no(:, 1), 1, popu, best_param_list_no(:, 2), 1);
    [death_rates, death_ci] = var_ind_deaths(data_4_s(:, 1:T_tr+horizon), deaths_s(:, 1:T_tr+horizon), dalpha, dk, djp, dwin, 1);

    
    [thisRt, Rtconf] = calc_Rt(beta_notravel, best_param_list_no(:, 1), best_param_list_no(:, 2), 1-data_4(:, T_tr)./popu, ci);    
    [thisscore] = calc_Rt(beta_notravel, best_param_list_no(:, 1), best_param_list_no(:, 2), ones(length(popu), 1), ci);
    MFR_ub = cellfun(@(xx)nansum(xx(:, 2)), death_ci).*djp;
    MFR_lb = cellfun(@(xx)nansum(xx(:, 1)), death_ci).*djp;
    
    all_scores = [all_scores thisscore];
    Rt_scores = [Rt_scores, thisRt];
    Rt_dev = [Rt_dev, (thisRt-Rtconf(:, 1))];
    MFR_scores = [MFR_scores, 0.5*(MFR_lb+MFR_ub)];
    MFR_dev = [MFR_dev, 0.5*(MFR_ub-MFR_lb)];
end

disp('DONE!');
%% Clean up and write files

badidx = MFR_dev>0.25 | deaths(:, start_day:skip_length:floor(size(data_4, 2)-horizon)) < 50;
MFR_scores(badidx) = NaN; MFR_dev(badidx) = NaN;

datecols = datestr(datetime(2020, 1, 21)+caldays(start_day:skip_length:floor(size(data_4, 2))-horizon), 'yyyy-mm-dd');
datecols = cellstr(datecols);
allcols = [{'id'; 'Region'}; datecols];
vectorarray  = num2cell(all_scores,1);
cidx = (0:length(countries)-1)';
tt = table(cidx, countries, vectorarray{:}, 'VariableNames',allcols);
vectorarray  = num2cell(Rt_dev,1);
tt1 = table(cidx, countries, vectorarray{:}, 'VariableNames',allcols);
vectorarray  = num2cell(Rt_scores,1);
tt2 = table(cidx, countries, vectorarray{:}, 'VariableNames',allcols);

vectorarray  = num2cell(MFR_dev,1);
tt3 = table(cidx, countries, vectorarray{:}, 'VariableNames',allcols);
vectorarray  = num2cell(MFR_scores,1);
tt4 = table(cidx, countries, vectorarray{:}, 'VariableNames',allcols);


writetable(tt, ['../results/scores/' prefix '_scores.csv']);
writetable(tt1, ['../results/scores/' prefix '_Rt_conf.csv']);
writetable(tt2, ['../results/scores/' prefix '_Rt_num.csv']);
writetable(tt3, ['../results/scores/' prefix '_MFR_conf.csv']);
writetable(tt4, ['../results/scores/' prefix '_MFR_num.csv']);
