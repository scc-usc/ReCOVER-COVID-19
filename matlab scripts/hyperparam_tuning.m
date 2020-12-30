function [best_param_list, MAPEtable_s] = hyperparam_tuning(data_4, data_4_s, popu, passengerFlow, un_list, T_full, T_val, k_array, jp_array, ff_array, window_size)
% Script to identify optimal hyperparameters of the model
%% Configure

if nargin <7
    T_val = 7;
end

if nargin < 8
    k_array = (1:4);
end

if nargin < 9
    jp_array = (7:7:14);
end

if nargin < 10
    ff_array = (7:10);
end

if nargin < 11
    window_size = [100];
end

T_tr = T_full - T_val; % Jan 21 is day 0
F_notravel = passengerFlow;

if length(un_list) < length(popu)
    [X, Y, Z, A, B] = ndgrid(k_array, jp_array, ff_array, un_list, window_size);
else
     %un_list is actually not used. un_list(1) is passed only for the
     %consistency of the data structure
    [X, Y, Z, A, B] = ndgrid(k_array, jp_array, ff_array, un_list(1), window_size);
end
param_list = [X(:), Y(:), Z(:), A(:) B(:)];

idx = param_list(:, 1).*param_list(:, 2) <=21; % filter out long horizons
if length(idx)<1
    idx = param_list(:, 1)>0; % Use all parameters without filtering
end

param_list = param_list(idx, :);

RMSE_all = zeros(size(data_4, 1), size(param_list, 1));

%% Full
base_infec = data_4(:, T_tr);
for ii = 1:size(param_list, 1)
    
    k = param_list(ii, 1);
    jp = param_list(ii, 2);
    alpha = 0.1*param_list(ii, 3);
    
    if length(un_list) < length(popu)
        un = param_list(ii, 4); % un_list contains different "un" values to try
    else
        un = un_list; % un_list is the actual list of values to be used
    end
    win_size = param_list(ii, 5);
    [beta_notravel, fC] = var_ind_beta_un(data_4_s(:, 1:T_tr), F_notravel, alpha, k, un, popu, jp, 0, popu>-1, win_size);
    
    if T_val > 0
    infec_notravel = var_simulate_pred_un(data_4_s(:, 1:T_tr), F_notravel, beta_notravel, popu, k, T_val, jp, un, base_infec);
    gtruth = diff(data_4(:, T_tr : T_tr + T_val)')';
    predvals = diff([data_4(:, T_tr) infec_notravel]')';
    [~, ~, thisrmse] = calc_errors(gtruth, predvals, 7);
    else
        thisrmse = zeros(length(popu), 1);
        for jj=1:length(popu)
            thisrmse(jj) = sum((fC{jj}(:, 1) - fC{jj}(:, 2)).^2);
        end
    end
    RMSE_all(:, ii) = thisrmse;
    
    fprintf('.');
end
fprintf('\n');


%% Identify best param per country
best_param_list = zeros(length(popu), size(param_list, 2));
for jj=1:length(popu)
    [~, ii] = min(RMSE_all(jj, :));
    best_param_list(jj, :) = param_list(ii, :);
end
    
%% Identify single best params
xx = nanmean(RMSE_all, 1);
[~, ii] = min(xx);
MAPEtable_s = param_list(ii, :);
