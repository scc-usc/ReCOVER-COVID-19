function [beta_best, beta_worst, param_best, param_worst, Rt_smooth, beta_cells, params] = best_and_worst(dayarray, prefix)
% To identify the best and the worst case infection rates from the past to generate
% scenarios
% Input: array for hyperparameter days
num_weeks = length(dayarray);
beta_cells = cell(num_weeks, 1);
params = cell(num_weeks, 1);
daynum = dayarray(1);
fname = ['./hyper_params/' prefix '_hyperparam_ref_' num2str(daynum)];
load(fname, 'ci'); % Load one file to identify the number of regions
nn = length(ci); % Number of regions
Rt_mat = zeros(nn, num_weeks);
Rt_smooth = zeros(nn, num_weeks);
beta_best = cell(nn, 1);
beta_worst = cell(nn, 1);
param_best = zeros(nn, 2);
param_worst = zeros(nn, 2);

for day_id = 1:length(dayarray)
    daynum = dayarray(day_id);
    fname = ['./hyper_params/' prefix '_hyperparam_ref_' num2str(daynum)];
    load(fname, 'thisscore', 'ci', 'best_param_list_no');
    beta_cells{day_id} = ci;
    Rt_mat(:, day_id) = thisscore;
    params{day_id} = best_param_list_no;
end

Rt_smooth = movmean(Rt_mat, 3, 2);

for j=1:nn
    [~, minid] = min(Rt_smooth(j, :));
    [~, maxid] = max(Rt_smooth(j, :));
    
    temp = beta_cells{minid}{j};
    temp(isnan(temp)) = 0;
        
    param_best(j, :) = params{minid}(j, 1:2);
    beta_best{j} = (0.5*(temp(:, 1) + temp(:, 2)))./sum((0.5*(temp(:, 1) + temp(:, 2)))) * Rt_smooth(j, minid)./param_best(j, 2);
    
    temp = beta_cells{maxid}{j};
    temp(isnan(temp)) = 0;
    
    param_worst(j, :) = params{maxid}(j, 1:2);
    beta_worst{j} = (0.5*(temp(:, 1) + temp(:, 2)))./sum((0.5*(temp(:, 1) + temp(:, 2)))) * Rt_smooth(j, maxid)./param_worst(j, 2);
    
end
xx = 1;